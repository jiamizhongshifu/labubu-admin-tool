#!/bin/bash

# Supabase连接测试脚本
# 用于验证Supabase配置是否正确

echo "🔍 Supabase连接测试"
echo "===================="

# 检查.env文件是否存在
if [ ! -f ".env" ]; then
    echo "❌ .env文件不存在"
    echo "💡 请先创建.env文件并配置Supabase信息"
    exit 1
fi

# 读取.env文件
source .env

# 检查必需的配置项
echo ""
echo "📋 配置检查:"

if [ -z "$SUPABASE_URL" ]; then
    echo "❌ SUPABASE_URL 未设置"
    exit 1
elif [[ "$SUPABASE_URL" == *"your_supabase_project_url_here"* ]]; then
    echo "❌ SUPABASE_URL 使用占位符，请替换为真实URL"
    exit 1
else
    echo "✅ SUPABASE_URL: $SUPABASE_URL"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ SUPABASE_ANON_KEY 未设置"
    exit 1
elif [[ "$SUPABASE_ANON_KEY" == *"your_supabase_anon_key_here"* ]]; then
    echo "❌ SUPABASE_ANON_KEY 使用占位符，请替换为真实密钥"
    exit 1
else
    masked_key="${SUPABASE_ANON_KEY:0:4}****${SUPABASE_ANON_KEY: -4}"
    echo "✅ SUPABASE_ANON_KEY: $masked_key"
fi

echo ""
echo "🔗 测试连接..."

# 函数：测试API连接
test_api_connection() {
    local key_type=$1
    local api_key=$2
    
    echo ""
    echo "🔑 测试 $key_type 连接..."
    
    # 测试基本连接
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "apikey: $api_key" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        "$SUPABASE_URL/rest/v1/" 2>/dev/null)

    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

    if [ "$http_code" -eq 200 ]; then
        echo "✅ $key_type 基本API连接成功"
        
        # 测试labubu_models表访问
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
            -H "Authorization: Bearer $api_key" \
            -H "apikey: $api_key" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "$SUPABASE_URL/rest/v1/labubu_models?limit=1" 2>/dev/null)

        http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        body=$(echo $response | sed -e 's/HTTPSTATUS:.*//g')

        if [ "$http_code" -eq 200 ]; then
            echo "✅ $key_type labubu_models表访问成功"
            if echo "$body" | python3 -m json.tool > /dev/null 2>&1; then
                count=$(echo "$body" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
                echo "📊 表中有 $count 条记录"
            fi
            return 0
        elif [ "$http_code" -eq 401 ]; then
            echo "❌ $key_type 401未授权错误 - 无法访问labubu_models表"
            echo "💡 可能需要配置RLS策略"
            echo "📄 错误详情: $body"
            return 1
        elif [ "$http_code" -eq 404 ]; then
            echo "❌ $key_type 404未找到错误 - labubu_models表不存在"
            return 1
        else
            echo "❌ $key_type HTTP错误: $http_code"
            echo "📄 响应内容: $body"
            return 1
        fi
        
    elif [ "$http_code" -eq 401 ]; then
        echo "❌ $key_type 401未授权错误"
        echo "📄 错误详情: $body"
        echo "💡 可能的原因:"
        echo "   - API密钥无效或过期"
        echo "   - 项目URL不正确"
        echo "   - 项目已暂停或删除"
        return 1
    elif [ "$http_code" -eq 404 ]; then
        echo "❌ $key_type 404未找到错误"
        echo "💡 项目URL可能不正确"
        return 1
    else
        echo "❌ $key_type HTTP错误: $http_code"
        echo "响应内容: $body"
        return 1
    fi
}

# 测试Anon Key
anon_success=false
if test_api_connection "Anon Key" "$SUPABASE_ANON_KEY"; then
    anon_success=true
fi

# 测试Service Role Key（如果存在）
service_success=false
if [ "$HAS_SERVICE_KEY" = true ]; then
    if test_api_connection "Service Role Key" "$SUPABASE_SERVICE_ROLE_KEY"; then
        service_success=true
    fi
fi

echo ""
echo "🎯 测试总结:"

if [ "$anon_success" = true ]; then
    echo "✅ Anon Key连接正常 - iOS应用可以正常工作"
elif [ "$service_success" = true ]; then
    echo "⚠️ 只有Service Role Key可用 - 需要配置RLS策略或临时使用Service Role Key"
    echo ""
    echo "🔧 解决方案选择:"
    echo "1. 【推荐】配置RLS策略允许匿名用户读取数据:"
    echo "   - 在Supabase控制台执行 supabase-rls-policies.sql 中的SQL语句"
    echo "2. 【临时】让iOS应用使用Service Role Key:"
    echo "   - 已在代码中实现，重新编译应用即可"
else
    echo "❌ 所有连接都失败 - 请检查配置"
fi

echo ""
echo "📚 更多帮助:"
echo "   - RLS策略配置: supabase-rls-policies.sql"
echo "   - Supabase文档: https://supabase.com/docs"
echo "   - 项目配置指南: SUPABASE_SETUP.md" 