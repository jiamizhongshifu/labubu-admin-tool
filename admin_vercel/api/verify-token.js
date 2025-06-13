const jwt = require('jsonwebtoken');

export default async function handler(req, res) {
    // 只允许POST请求
    if (req.method !== 'POST') {
        return res.status(405).json({ error: '方法不允许' });
    }

    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: '未提供有效的认证令牌' });
        }

        const token = authHeader.substring(7); // 移除 "Bearer " 前缀
        const jwtSecret = process.env.JWT_SECRET;

        if (!jwtSecret) {
            console.error('Missing JWT_SECRET environment variable');
            return res.status(500).json({ error: '服务器配置错误' });
        }

        // 验证token
        const decoded = jwt.verify(token, jwtSecret);
        
        // 检查token是否包含必要的信息
        if (!decoded.email || decoded.role !== 'admin') {
            return res.status(401).json({ error: '无效的认证令牌' });
        }

        // 返回成功响应
        res.status(200).json({
            success: true,
            user: {
                email: decoded.email,
                role: decoded.role
            }
        });

    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ error: '无效的认证令牌' });
        } else if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: '认证令牌已过期' });
        } else {
            console.error('Token verification error:', error);
            return res.status(500).json({ error: '服务器内部错误' });
        }
    }
} 