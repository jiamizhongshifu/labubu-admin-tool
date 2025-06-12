// API配置示例文件
// 复制此文件为 config.js 并填入真实的API密钥

// TUZI API配置
window.TUZI_API_CONFIG = {
    // TUZI API密钥 - 从 https://api.tu-zi.com 获取
    apiKey: 'your-tuzi-api-key-here',
    
    // API基础URL
    baseUrl: 'https://api.tu-zi.com/v1',
    
    // 模型配置
    model: 'gemini-2.5-flash-all',
    
    // 请求超时时间（毫秒）
    timeout: 120000,
    
    // 图像压缩质量 (0.1 - 1.0)
    imageQuality: 0.8,
    
    // 最大图像尺寸（像素）
    maxImageSize: 1024
};

// 使用说明：
// 1. 注册TUZI API账号：https://api.tu-zi.com
// 2. 获取API密钥
// 3. 将上面的 'your-tuzi-api-key-here' 替换为真实的API密钥
// 4. 保存文件为 config.js
// 5. 在 index.html 中引入此配置文件 

// 方法2：从.env文件读取配置（推荐用于开发环境）
// 如果你的.env文件在项目根目录，可以使用以下方法：
async function loadConfigFromEnv() {
    try {
        // 尝试读取.env文件
        const response = await fetch('../.env');
        if (response.ok) {
            const envContent = await response.text();
            const envVars = parseEnvFile(envContent);
            
            // 更新配置
            if (envVars.TUZI_API_KEY) {
                window.TUZI_API_CONFIG = {
                    apiKey: envVars.TUZI_API_KEY,
                    baseUrl: envVars.TUZI_API_BASE || 'https://api.tu-zi.com/v1'
                };
                console.log('✅ 成功从.env文件加载API配置');
            } else if (envVars.OPENAI_API_KEY) {
                // 向后兼容
                window.TUZI_API_CONFIG = {
                    apiKey: envVars.OPENAI_API_KEY,
                    baseUrl: envVars.TUZI_API_BASE || 'https://api.tu-zi.com/v1'
                };
                console.log('✅ 成功从.env文件加载API配置（使用OPENAI_API_KEY）');
            }
        }
    } catch (error) {
        console.warn('⚠️ 无法从.env文件读取配置，使用默认配置:', error);
    }
}

// 解析.env文件内容
function parseEnvFile(content) {
    const envVars = {};
    const lines = content.split('\n');
    
    for (const line of lines) {
        const trimmedLine = line.trim();
        if (trimmedLine && !trimmedLine.startsWith('#')) {
            const [key, ...valueParts] = trimmedLine.split('=');
            if (key && valueParts.length > 0) {
                const value = valueParts.join('=').trim();
                if (value && value !== 'your_api_key_here') {
                    envVars[key.trim()] = value;
                }
            }
        }
    }
    
    return envVars;
}

// 自动加载配置
document.addEventListener('DOMContentLoaded', function() {
    // 如果没有直接配置，尝试从.env文件加载
    if (!window.TUZI_API_CONFIG || 
        !window.TUZI_API_CONFIG.apiKey || 
        window.TUZI_API_CONFIG.apiKey === 'your-actual-api-key-here') {
        loadConfigFromEnv();
    }
});

// 配置验证函数
function validateConfig() {
    if (!window.TUZI_API_CONFIG) {
        return { valid: false, message: '未找到API配置' };
    }
    
    if (!window.TUZI_API_CONFIG.apiKey || window.TUZI_API_CONFIG.apiKey === 'your-actual-api-key-here') {
        return { valid: false, message: 'API密钥未配置或使用默认值' };
    }
    
    if (!window.TUZI_API_CONFIG.baseUrl) {
        return { valid: false, message: 'API基础URL未配置' };
    }
    
    return { valid: true, message: '配置验证通过' };
}

// 导出验证函数供其他脚本使用
window.validateTuziConfig = validateConfig; 