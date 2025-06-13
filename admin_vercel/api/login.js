const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

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

        // 获取环境变量中的管理员凭据
        const adminEmail = process.env.ADMIN_EMAIL;
        const adminPassword = process.env.ADMIN_PASSWORD;
        const jwtSecret = process.env.JWT_SECRET;

        if (!adminEmail || !adminPassword || !jwtSecret) {
            console.error('Missing environment variables');
            return res.status(500).json({ error: '服务器配置错误' });
        }

        // 验证邮箱
        if (email !== adminEmail) {
            return res.status(401).json({ error: '邮箱或密码错误' });
        }

        // 验证密码
        const isPasswordValid = await bcrypt.compare(password, adminPassword);
        if (!isPasswordValid) {
            return res.status(401).json({ error: '邮箱或密码错误' });
        }

        // 生成JWT token
        const token = jwt.sign(
            { 
                email: adminEmail,
                role: 'admin',
                iat: Math.floor(Date.now() / 1000)
            },
            jwtSecret,
            { expiresIn: '24h' }
        );

        // 返回成功响应
        res.status(200).json({
            success: true,
            token,
            message: '登录成功'
        });

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: '服务器内部错误' });
    }
} 