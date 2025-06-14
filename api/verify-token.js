import jwt from 'jsonwebtoken';

export default async function handler(req, res) {
    // 只允许POST请求
    if (req.method !== 'POST') {
        return res.status(405).json({ error: '方法不允许' });
    }

    try {
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ error: '缺少token' });
        }

        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            return res.status(500).json({ error: '服务器配置错误' });
        }

        // 验证token
        const decoded = jwt.verify(token, jwtSecret);
        
        // 检查token是否包含必要信息
        if (!decoded.email || decoded.role !== 'admin') {
            return res.status(401).json({ error: '无效的token' });
        }

        return res.status(200).json({
            success: true,
            valid: true,
            user: {
                email: decoded.email,
                role: decoded.role
            }
        });

    } catch (error) {
        console.error('Token verification error:', error);
        
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token已过期' });
        }
        
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ error: '无效的token' });
        }

        return res.status(500).json({ error: 'Token验证失败' });
    }
} 