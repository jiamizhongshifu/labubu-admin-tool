#!/bin/bash

# 从.env文件读取配置
source .env

# 创建测试图片
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > test_image.png

echo "🧪 测试Supabase上传权限..."
echo "📝 存储桶: $SUPABASE_STORAGE_BUCKET"
echo "📝 URL: $SUPABASE_URL"

# 测试上传
curl -X POST \
  "$SUPABASE_URL/storage/v1/object/$SUPABASE_STORAGE_BUCKET/test_upload.png" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: image/png" \
  -H "Cache-Control: no-cache" \
  --data-binary @test_image.png \
  -v

echo ""
echo "🧪 测试Supabase读取权限..."

# 测试读取
curl -X GET \
  "$SUPABASE_URL/storage/v1/object/public/$SUPABASE_STORAGE_BUCKET/test_upload.png" \
  -v

# 清理测试文件
rm -f test_image.png

echo ""
echo "✅ 测试完成！"
echo "💡 如果看到 HTTP 200，说明权限配置正确"
echo "💡 如果看到 HTTP 403，说明需要配置RLS策略"
echo "💡 如果看到 HTTP 404，说明存储桶不存在" 