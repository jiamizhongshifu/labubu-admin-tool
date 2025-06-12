#!/bin/bash

# Labubu Supabase配置脚本
# 用于快速配置Supabase环境变量

echo "🎭 Labubu Supabase配置向导"
echo "================================"
echo ""

# 检查是否已存在.env文件
if [ -f ".env" ]; then
    echo "⚠️  发现现有的.env文件"
    read -p "是否要备份现有配置？(y/n): " backup_choice
    if [ "$backup_choice" = "y" ] || [ "$backup_choice" = "Y" ]; then
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
        echo "✅ 已备份到 .env.backup.$(date +%Y%m%d_%H%M%S)"
    fi
fi

echo ""
echo "请输入您的Supabase配置信息："
echo "（可以在Supabase控制台 → 项目设置 → API 中找到）"
echo ""

# 获取Supabase URL
read -p "🔗 Supabase URL (https://your-project.supabase.co): " supabase_url
while [ -z "$supabase_url" ]; do
    echo "❌ URL不能为空"
    read -p "🔗 Supabase URL: " supabase_url
done

# 获取Anon Key
echo ""
read -p "🔑 Anon Key (eyJhbGciOiJIUzI1NiIs...): " anon_key
while [ -z "$anon_key" ]; do
    echo "❌ Anon Key不能为空"
    read -p "🔑 Anon Key: " anon_key
done

# 获取Service Role Key
echo ""
read -p "🔐 Service Role Key (eyJhbGciOiJIUzI1NiIs...): " service_key
while [ -z "$service_key" ]; do
    echo "❌ Service Role Key不能为空"
    read -p "🔐 Service Role Key: " service_key
done

# 获取存储桶名称（可选）
echo ""
read -p "🪣 Storage Bucket (默认: jitata-images): " storage_bucket
if [ -z "$storage_bucket" ]; then
    storage_bucket="jitata-images"
fi

# 写入.env文件
echo ""
echo "📝 正在创建.env文件..."

cat > .env << EOF
# Supabase配置
SUPABASE_URL=$supabase_url
SUPABASE_ANON_KEY=$anon_key
SUPABASE_SERVICE_ROLE_KEY=$service_key
SUPABASE_STORAGE_BUCKET=$storage_bucket

# 其他API配置（如果需要）
TUZI_API_KEY=your_api_key_here
TUZI_API_BASE=https://api.tu-zi.com/v1
EOF

echo "✅ .env文件创建成功！"
echo ""

# 测试连接
echo "🔍 正在测试连接..."
echo ""

# 创建简单的测试脚本
cat > test_connection.js << 'EOF'
const fs = require('fs');

// 读取.env文件
const envContent = fs.readFileSync('.env', 'utf8');
const envVars = {};
envContent.split('\n').forEach(line => {
    if (line.trim() && !line.startsWith('#')) {
        const [key, value] = line.split('=');
        if (key && value) {
            envVars[key.trim()] = value.trim();
        }
    }
});

// 测试连接
async function testConnection() {
    try {
        const response = await fetch(`${envVars.SUPABASE_URL}/rest/v1/`, {
            headers: {
                'apikey': envVars.SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${envVars.SUPABASE_ANON_KEY}`
            }
        });
        
        if (response.ok) {
            console.log('✅ Supabase连接测试成功！');
            console.log('🎉 您现在可以使用管理工具了');
        } else {
            console.log('❌ 连接测试失败，请检查配置');
            console.log('状态码:', response.status);
        }
    } catch (error) {
        console.log('❌ 连接测试失败:', error.message);
        console.log('请检查网络连接和配置信息');
    }
}

testConnection();
EOF

# 如果有Node.js，运行测试
if command -v node &> /dev/null; then
    node test_connection.js
    rm test_connection.js
else
    echo "💡 提示：安装Node.js后可以自动测试连接"
    rm test_connection.js
fi

echo ""
echo "🚀 接下来的步骤："
echo "1. 打开管理工具: open admin_tool/index.html"
echo "2. 在管理工具中输入您的Supabase配置"
echo "3. 点击'测试连接'确认配置正确"
echo "4. 开始管理您的Labubu数据！"
echo ""
echo "📚 详细使用指南: docs/admin-tool-guide.md"
echo ""
echo "🎭 祝您使用愉快！" 