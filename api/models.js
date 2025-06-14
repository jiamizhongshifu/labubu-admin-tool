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

// 🖼️ 图片上传处理函数
async function uploadImage(supabase, imageFile, modelName) {
    try {
        // 生成唯一文件名
        const timestamp = Date.now();
        const randomStr = Math.random().toString(36).substring(2, 8);
        const fileExt = imageFile.name.split('.').pop().toLowerCase();
        const fileName = `${modelName.replace(/[^a-zA-Z0-9]/g, '_')}_${timestamp}_${randomStr}.${fileExt}`;
        const filePath = `models/${fileName}`;

        // 上传到 Supabase Storage
        const { data, error } = await supabase.storage
            .from('labubu-images')
            .upload(filePath, imageFile, {
                cacheControl: '3600',
                upsert: false
            });

        if (error) {
            throw error;
        }

        // 获取公共URL
        const { data: urlData } = supabase.storage
            .from('labubu-images')
            .getPublicUrl(filePath);

        return {
            image_url: urlData.publicUrl,
            image_path: filePath,
            image_filename: imageFile.name,
            image_size: imageFile.size,
            image_type: imageFile.type
        };

    } catch (error) {
        console.error('图片上传失败:', error);
        throw new Error(`图片上传失败: ${error.message}`);
    }
}

// 🗑️ 删除图片函数
async function deleteImage(supabase, imagePath) {
    try {
        if (!imagePath) return;

        const { error } = await supabase.storage
            .from('labubu-images')
            .remove([imagePath]);

        if (error) {
            console.error('删除图片失败:', error);
            // 不抛出错误，因为删除图片失败不应该阻止其他操作
        }
    } catch (error) {
        console.error('删除图片异常:', error);
    }
}

export default async function handler(req, res) {
    try {
        // 验证身份
        verifyToken(req);
        
        const supabase = getSupabaseClient();
        const { method } = req;

        switch (method) {
            case 'GET':
                // 获取所有模型（包含图片信息）
                const { data: models, error: fetchError } = await supabase
                    .from('labubu_models')
                    .select(`
                        id,
                        name,
                        series_id,
                        release_price,
                        reference_price,
                        rarity,
                        features,
                        image_url,
                        image_path,
                        image_filename,
                        image_size,
                        image_type,
                        created_at,
                        updated_at
                    `)
                    .order('created_at', { ascending: false });

                if (fetchError) {
                    throw fetchError;
                }

                return res.status(200).json({
                    success: true,
                    data: models
                });

            case 'POST':
                // 创建新模型（支持图片上传）
                const formData = req.body;
                let imageData = {};

                // 处理图片上传
                if (formData.image && formData.image.size > 0) {
                    imageData = await uploadImage(supabase, formData.image, formData.name);
                }

                // 准备插入数据
                const insertData = {
                    name: formData.name,
                    series_id: formData.series_id,
                    release_price: formData.release_price,
                    reference_price: formData.reference_price,
                    rarity: formData.rarity,
                    features: formData.features,
                    ...imageData
                };

                const { data: newModel, error: createError } = await supabase
                    .from('labubu_models')
                    .insert([insertData])
                    .select()
                    .single();

                if (createError) {
                    // 如果数据库插入失败，删除已上传的图片
                    if (imageData.image_path) {
                        await deleteImage(supabase, imageData.image_path);
                    }
                    throw createError;
                }

                return res.status(201).json({
                    success: true,
                    data: newModel,
                    message: '模型创建成功'
                });

            case 'PUT':
                // 更新模型（支持图片更新）
                const { id, ...updateData } = req.body;
                
                if (!id) {
                    return res.status(400).json({ error: '缺少模型ID' });
                }

                // 获取现有模型信息
                const { data: existingModel, error: fetchExistingError } = await supabase
                    .from('labubu_models')
                    .select('image_path')
                    .eq('id', id)
                    .single();

                if (fetchExistingError) {
                    throw fetchExistingError;
                }

                let newImageData = {};

                // 处理新图片上传
                if (updateData.image && updateData.image.size > 0) {
                    // 删除旧图片
                    if (existingModel.image_path) {
                        await deleteImage(supabase, existingModel.image_path);
                    }

                    // 上传新图片
                    newImageData = await uploadImage(supabase, updateData.image, updateData.name);
                    
                    // 移除 image 字段，避免直接存储到数据库
                    delete updateData.image;
                }

                // 合并更新数据
                const finalUpdateData = {
                    ...updateData,
                    ...newImageData
                };

                const { data: updatedModel, error: updateError } = await supabase
                    .from('labubu_models')
                    .update(finalUpdateData)
                    .eq('id', id)
                    .select()
                    .single();

                if (updateError) {
                    // 如果更新失败，删除新上传的图片
                    if (newImageData.image_path) {
                        await deleteImage(supabase, newImageData.image_path);
                    }
                    throw updateError;
                }

                return res.status(200).json({
                    success: true,
                    data: updatedModel,
                    message: '模型更新成功'
                });

            case 'DELETE':
                // 删除模型（同时删除关联图片）
                const { id: deleteId } = req.query;
                
                if (!deleteId) {
                    return res.status(400).json({ error: '缺少模型ID' });
                }

                // 获取要删除的模型信息
                const { data: modelToDelete, error: fetchDeleteError } = await supabase
                    .from('labubu_models')
                    .select('image_path')
                    .eq('id', deleteId)
                    .single();

                if (fetchDeleteError) {
                    throw fetchDeleteError;
                }

                // 删除数据库记录
                const { error: deleteError } = await supabase
                    .from('labubu_models')
                    .delete()
                    .eq('id', deleteId);

                if (deleteError) {
                    throw deleteError;
                }

                // 删除关联图片
                if (modelToDelete.image_path) {
                    await deleteImage(supabase, modelToDelete.image_path);
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