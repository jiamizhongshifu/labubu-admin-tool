#!/bin/bash

# .env配置测试脚本
# 用于验证.env文件是否正确配置

echo "🔧 Labubu AI识别功能配置检查"
echo "================================"

# 检查.env文件是否存在
if [ ! -f ".env" ]; then
    echo "❌ .env文件不存在"
    echo "💡 请运行: cp env.example .env"
    exit 1
fi

echo "✅ .env文件存在"

# 读取.env文件
source .env

# 检查必需的配置项
echo ""
echo "📋 配置项检查:"

# 检查TUZI_API_KEY
if [ -z "$TUZI_API_KEY" ]; then
    echo "❌ TUZI_API_KEY 未设置"
elif [ "$TUZI_API_KEY" = "your_api_key_here" ] || [ "$TUZI_API_KEY" = "your_actual_api_key_here" ]; then
    echo "⚠️  TUZI_API_KEY 使用默认值，请替换为真实API密钥"
else
    # 隐藏API密钥的大部分内容
    masked_key="${TUZI_API_KEY:0:4}****${TUZI_API_KEY: -4}"
    echo "✅ TUZI_API_KEY: $masked_key"
fi

# 检查TUZI_API_BASE
if [ -z "$TUZI_API_BASE" ]; then
    echo "⚠️  TUZI_API_BASE 未设置，将使用默认值"
else
    echo "✅ TUZI_API_BASE: $TUZI_API_BASE"
fi

# 检查OPENAI_API_KEY（向后兼容）
if [ -n "$OPENAI_API_KEY" ] && [ "$OPENAI_API_KEY" != "your_api_key_here" ] && [ "$OPENAI_API_KEY" != "your_actual_api_key_here" ]; then
    masked_openai_key="${OPENAI_API_KEY:0:4}****${OPENAI_API_KEY: -4}"
    echo "✅ OPENAI_API_KEY: $masked_openai_key (向后兼容)"
fi

# 检查Supabase配置
echo ""
echo "🗄️  数据库配置检查:"

if [ -n "$SUPABASE_URL" ] && [ "$SUPABASE_URL" != "your_supabase_url" ]; then
    echo "✅ SUPABASE_URL: $SUPABASE_URL"
else
    echo "⚠️  SUPABASE_URL 未配置（如不使用数据库功能可忽略）"
fi

if [ -n "$SUPABASE_ANON_KEY" ] && [ "$SUPABASE_ANON_KEY" != "your_supabase_anon_key" ]; then
    masked_supabase_key="${SUPABASE_ANON_KEY:0:4}****${SUPABASE_ANON_KEY: -4}"
    echo "✅ SUPABASE_ANON_KEY: $masked_supabase_key"
else
    echo "⚠️  SUPABASE_ANON_KEY 未配置（如不使用数据库功能可忽略）"
fi

# 检查文件权限
echo ""
echo "🔒 安全检查:"

file_permissions=$(stat -f "%A" .env 2>/dev/null || stat -c "%a" .env 2>/dev/null)
if [ "$file_permissions" = "600" ]; then
    echo "✅ .env文件权限正确 (600)"
elif [ -n "$file_permissions" ]; then
    echo "⚠️  .env文件权限: $file_permissions (建议设置为600)"
    echo "💡 运行: chmod 600 .env"
else
    echo "⚠️  无法检查文件权限"
fi

# 检查.gitignore
if grep -q "^\.env$" .gitignore 2>/dev/null; then
    echo "✅ .env已添加到.gitignore"
else
    echo "⚠️  建议将.env添加到.gitignore中"
fi

echo ""
echo "🎯 配置建议:"
echo "1. 确保TUZI_API_KEY已设置为有效的API密钥"
echo "2. 如使用数据库功能，请配置Supabase相关参数"
echo "3. 运行 'chmod 600 .env' 设置适当的文件权限"
echo "4. 使用 'open admin_tool/check-config.html' 进行Web端配置检查"

echo ""
echo "📱 测试方法:"
echo "1. iOS应用: 启动应用，查看控制台是否显示配置读取成功"
echo "2. Web工具: 打开admin_tool/index.html，尝试上传图片进行AI分析"

echo ""
echo "================================"
echo "配置检查完成！" 