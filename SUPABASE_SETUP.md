# 🚀 Supabase图床配置指南

## 📋 配置步骤

### 1. 获取Supabase项目信息

1. 访问 [supabase.com](https://supabase.com) 并登录
2. 选择您的项目或创建新项目
3. 在项目Dashboard中，点击左侧的 **"Settings"** → **"API"**

### 2. 复制必要的配置信息

在API设置页面，您需要复制以下信息：

#### 📝 Project URL
- 在 **"Project URL"** 部分找到类似这样的URL：
  ```
  https://your-project-id.supabase.co
  ```

#### 🔑 API Keys
- **anon public key**: 用于客户端访问
- **service_role key**: 用于服务端操作（⚠️ 保密！）

### 3. 更新.env文件

将 `jitata/.env` 文件中的占位符替换为实际值：

```bash
# 替换这些值：
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_STORAGE_BUCKET=jitata-images
```

### 4. 创建存储桶

1. 在Supabase Dashboard中，点击左侧的 **"Storage"**
2. 点击 **"Create a new bucket"**
3. 输入桶名称：`jitata-images`
4. ✅ 勾选 **"Public bucket"** （重要！）
5. 点击 **"Create bucket"**

### 5. 配置RLS策略（如果需要）

如果您的存储桶不是Public，需要配置RLS策略：

```sql
-- 允许所有人上传到 jitata-images 存储桶
CREATE POLICY "Allow public uploads to jitata-images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'jitata-images'
);

-- 允许所有人读取 jitata-images 存储桶的文件
CREATE POLICY "Allow public downloads from jitata-images" ON storage.objects
FOR SELECT USING (
    bucket_id = 'jitata-images'
);
```

## 🧪 测试配置

配置完成后，运行测试脚本验证：

```bash
./test_supabase_upload.sh
```

期望看到的结果：
- 上传请求：`HTTP/1.1 200 OK`
- 读取请求：`HTTP/1.1 200 OK`

## ❌ 常见问题排查

### 问题1：403 Forbidden
**原因**：RLS策略阻止了操作
**解决**：
1. 确保存储桶设置为Public
2. 或者配置正确的RLS策略

### 问题2：404 Not Found
**原因**：存储桶不存在
**解决**：
1. 检查存储桶名称是否正确
2. 确保存储桶已创建

### 问题3：401 Unauthorized
**原因**：API密钥错误
**解决**：
1. 检查API密钥是否正确复制
2. 确保使用service_role key进行上传操作

## 📱 应用中的使用

配置完成后，应用将自动：
1. 在用户拍摄照片后预上传到Supabase
2. AI增强时使用预上传的URL（速度更快）
3. 在详情页显示预上传状态指示器

## 🔒 安全注意事项

1. **永远不要**将service_role key提交到代码仓库
2. 确保`.env`文件在`.gitignore`中
3. 定期轮换API密钥
4. 监控存储使用量和API调用次数 