const bcrypt = require('bcryptjs');

// 获取命令行参数中的密码
const password = process.argv[2];

if (!password) {
    console.log('使用方法: node generate-password.js <your_password>');
    console.log('例如: node generate-password.js mySecretPassword123');
    process.exit(1);
}

// 生成bcrypt哈希
const saltRounds = 10;
const hashedPassword = bcrypt.hashSync(password, saltRounds);

console.log('原始密码:', password);
console.log('哈希密码:', hashedPassword);
console.log('\n请将哈希密码复制到环境变量 ADMIN_PASSWORD 中');

// 验证哈希是否正确
const isValid = bcrypt.compareSync(password, hashedPassword);
console.log('验证结果:', isValid ? '✅ 正确' : '❌ 错误');

// 生成一个随机的JWT密钥
const crypto = require('crypto');
const jwtSecret = crypto.randomBytes(64).toString('hex');
console.log('\n建议的JWT密钥:');
console.log(jwtSecret);
console.log('\n请将此密钥复制到环境变量 JWT_SECRET 中'); 