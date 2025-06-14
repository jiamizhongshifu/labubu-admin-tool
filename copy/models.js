import { createClient } from '@supabase/supabase-js';
import jwt from 'jsonwebtoken';

// 验证token的中间件函数
function verifyToken(req) {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('未提供有效的认证令牌');
    }

    const token = authHeader.substring(7);
    const jwtSecret = process.env.JWT_SECRET;

    if (!jwtSecret) {
        throw new Error('服务器配置错误');
    }

    const decoded = jwt.verify(token, jwtSecret);
    
    if (!decoded.email || decoded.role !== 'admin') {
        throw new Error('无效的认证令牌');
    }

    return decoded;
}

// 初始化Supabase客户端
function getSupabaseClient() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
        throw new Error('Supabase配置缺失');
    }

    return createClient(supabaseUrl, supabaseKey);
}

export default async function handler(req, res) {
    try {
        // 验证身份
        verifyToken(req);
        
        const supabase = getSupabaseClient();
        const { method } = req;

        switch (method) {
            case 'GET':
                // 获取所有模型
                const { data: models, error: fetchError } = await supabase
                    .from('labubu_models')
                    .select('*')
                    .order('created_at', { ascending: false });

                if (fetchError) {
                    throw fetchError;
                }

                return res.status(200).json({
                    success: true,
                    data: models
                });

            case 'POST':
                // 创建新模型
                const { data: newModel, error: createError } = await supabase
                    .from('labubu_models')
                    .insert([req.body])
                    .select()
                    .single();

                if (createError) {
                    throw createError;
                }

                return res.status(201).json({
                    success: true,
                    data: newModel,
                    message: '模型创建成功'
                });

            case 'PUT':
                // 更新模型
                const { id, ...updateData } = req.body;
                
                if (!id) {
                    return res.status(400).json({ error: '缺少模型ID' });
                }

                const { data: updatedModel, error: updateError } = await supabase
                    .from('labubu_models')
                    .update(updateData)
                    .eq('id', id)
                    .select()
                    .single();

                if (updateError) {
                    throw updateError;
                }

                return res.status(200).json({
                    success: true,
                    data: updatedModel,
                    message: '模型更新成功'
                });

            case 'DELETE':
                // 删除模型
                const { id: deleteId } = req.query;
                
                if (!deleteId) {
                    return res.status(400).json({ error: '缺少模型ID' });
                }

                const { error: deleteError } = await supabase
                    .from('labubu_models')
                    .delete()
                    .eq('id', deleteId);

                if (deleteError) {
                    throw deleteError;
                }

                return res.status(200).json({
                    success: true,
                    message: '模型删除成功'
                });

            default:
                return res.status(405).json({ error: '方法不允许' });
        }

    } catch (error) {
        console.error('Models API error:', error);
        
        if (error.message.includes('认证') || error.message.includes('令牌')) {
            return res.status(401).json({ error: error.message });
        }
        
        if (error.message.includes('配置')) {
            return res.status(500).json({ error: '服务器配置错误' });
        }

        return res.status(500).json({ 
            error: '操作失败',
            details: error.message 
        });
    }
} 