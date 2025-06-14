import { createClient } from '@supabase/supabase-js';

export default async function handler(req, res) {
    try {
        // 设置CORS头
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

        if (req.method === 'OPTIONS') {
            return res.status(200).end();
        }

        if (req.method !== 'GET') {
            return res.status(405).json({ error: '方法不允许' });
        }

        const diagnostics = {
            timestamp: new Date().toISOString(),
            environment: {},
            supabase: {},
            database: {},
            errors: []
        };

        // 1. 检查环境变量
        const requiredEnvVars = [
            'SUPABASE_URL',
            'SUPABASE_SERVICE_ROLE_KEY',
            'JWT_SECRET'
        ];

        requiredEnvVars.forEach(envVar => {
            const value = process.env[envVar];
            diagnostics.environment[envVar] = {
                exists: !!value,
                length: value ? value.length : 0,
                preview: value ? `${value.substring(0, 10)}...` : 'undefined'
            };

            if (!value) {
                diagnostics.errors.push(`缺少环境变量: ${envVar}`);
            }
        });

        // 2. 测试Supabase连接
        try {
            const supabaseUrl = process.env.SUPABASE_URL;
            const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

            if (supabaseUrl && supabaseKey) {
                const supabase = createClient(supabaseUrl, supabaseKey);
                
                diagnostics.supabase.client_created = true;
                diagnostics.supabase.url = supabaseUrl;
                diagnostics.supabase.key_length = supabaseKey.length;

                // 3. 测试数据库查询
                const { data, error, count } = await supabase
                    .from('labubu_models')
                    .select('*', { count: 'exact' });

                if (error) {
                    diagnostics.database.connection = 'error';
                    diagnostics.database.error = error.message;
                    diagnostics.errors.push(`数据库查询错误: ${error.message}`);
                } else {
                    diagnostics.database.connection = 'success';
                    diagnostics.database.record_count = count;
                    diagnostics.database.sample_data = data ? data.slice(0, 2) : [];
                }

                // 4. 测试表结构
                const { data: tableInfo, error: tableError } = await supabase
                    .from('labubu_models')
                    .select('*')
                    .limit(1);

                if (!tableError && tableInfo && tableInfo.length > 0) {
                    diagnostics.database.table_structure = Object.keys(tableInfo[0]);
                } else if (tableError) {
                    diagnostics.errors.push(`表结构查询错误: ${tableError.message}`);
                }

            } else {
                diagnostics.supabase.client_created = false;
                diagnostics.errors.push('Supabase配置不完整');
            }

        } catch (supabaseError) {
            diagnostics.supabase.error = supabaseError.message;
            diagnostics.errors.push(`Supabase连接错误: ${supabaseError.message}`);
        }

        // 5. 系统信息
        diagnostics.system = {
            node_version: process.version,
            platform: process.platform,
            memory_usage: process.memoryUsage(),
            uptime: process.uptime()
        };

        return res.status(200).json({
            success: diagnostics.errors.length === 0,
            message: diagnostics.errors.length === 0 ? '所有检查通过' : `发现 ${diagnostics.errors.length} 个问题`,
            diagnostics
        });

    } catch (error) {
        console.error('Diagnostics error:', error);
        return res.status(500).json({
            success: false,
            error: '诊断过程中发生错误',
            details: error.message
        });
    }
} 