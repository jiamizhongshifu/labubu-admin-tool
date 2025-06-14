import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

export default async function handler(req, res) {
    // 只允许POST请求
    if (req.method !== 'POST') {
        return res.status(405).json({ error: '方法不允许' });
    }

    try {
        const { email, password } = req.body;

        // 验证输入
        if (!email || !password) {
            return res.status(400).json({ error: '邮箱和密码不能为空' });
        }

        // 从环境变量获取管理员凭据
        const adminEmail = process.env.ADMIN_EMAIL;
        const adminPasswordHash = process.env.ADMIN_PASSWORD_HASH;
        const jwtSecret = process.env.JWT_SECRET;

        if (!adminEmail || !adminPasswordHash || !jwtSecret) {
            console.error('Missing environment variables:', {
                adminEmail: !!adminEmail,
                adminPasswordHash: !!adminPasswordHash,
                jwtSecret: !!jwtSecret
            });
            return res.status(500).json({ error: '服务器配置错误' });
        }

        // 验证邮箱
        if (email !== adminEmail) {
            return res.status(401).json({ error: '邮箱或密码错误' });
        }

        // 验证密码
        const isPasswordValid = await bcrypt.compare(password, adminPasswordHash);
        if (!isPasswordValid) {
            return res.status(401).json({ error: '邮箱或密码错误' });
        }

        // 生成JWT token
        const token = jwt.sign(
            { 
                email: adminEmail,
                role: 'admin',
                exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60) // 24小时过期
            },
            jwtSecret
        );

        return res.status(200).json({
            success: true,
            token,
            message: '登录成功'
        });

    } catch (error) {
        console.error('Login error:', error);
        return res.status(500).json({ error: '登录失败，请稍后重试' });
    }
} 