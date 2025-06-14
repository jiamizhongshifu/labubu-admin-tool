# 🖼️ Labubu 管理工具图片管理功能部署指南

## 📋 部署概览

**版本**: v5.2 图片管理版本  
**部署日期**: 2024-12-19  
**功能**: 为 Labubu 管理工具添加完整的图片上传、存储、展示功能

## 🗄️ 数据库部署步骤

### 1. 执行数据库表结构修改
```sql
-- 在 Supabase SQL 编辑器中执行
-- 文件: ADD_IMAGE_FIELD_TO_LABUBU_MODELS.sql

ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS image_path TEXT,
ADD COLUMN IF NOT EXISTS image_filename TEXT,
ADD COLUMN IF NOT EXISTS image_size INTEGER,
ADD COLUMN IF NOT EXISTS image_type VARCHAR(50);

-- 添加字段注释
COMMENT ON COLUMN labubu_models.image_url IS '模型配图的完整URL地址';
COMMENT ON COLUMN labubu_models.image_path IS 'Supabase Storage中的图片路径';
COMMENT ON COLUMN labubu_models.image_filename IS '原始图片文件名';
COMMENT ON COLUMN labubu_models.image_size IS '图片文件大小（字节）';
COMMENT ON COLUMN labubu_models.image_type IS '图片MIME类型';
```

### 2. 配置 Supabase Storage
```sql
-- 在 Supabase SQL 编辑器中执行
-- 文件: SETUP_SUPABASE_STORAGE.sql

-- 创建存储桶
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'labubu-images',
    'labubu-images', 
    true,
    5242880,  -- 5MB 限制
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 创建访问策略
CREATE POLICY "Allow public read access" ON storage.objects
    FOR SELECT 
    USING (bucket_id = 'labubu-images');

CREATE POLICY "Allow authenticated upload" ON storage.objects
    FOR INSERT 
    WITH CHECK (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Allow authenticated update" ON storage.objects
    FOR UPDATE 
    USING (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Allow authenticated delete" ON storage.objects
    FOR DELETE 
    USING (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );
```

## 🚀 应用部署步骤

### 1. 代码部署
```bash
# 确保所有文件已更新
git add .
git commit -m "🖼️ v5.2: 添加图片管理功能 - 完整的上传、存储、展示系统"
git push origin master
```

### 2. Vercel 自动构建
- Vercel 将自动检测到 `package.json` 的存在
- 执行 `npm run build` 命令
- 将 `public/dashboard.html` 复制到 `dist/` 目录
- 部署更新后的应用

### 3. 验证部署
访问 https://labubu-admin-tool.vercel.app/dashboard 确认：
- ✅ 页面标题显示 "v5.2 图片管理版本"
- ✅ 控制台显示 "v5.2 图片管理版本 - 2024-12-19"
- ✅ 新增模型区域包含图片上传功能
- ✅ 模型列表显示配图缩略图列

## 🔧 环境变量配置

确保 Vercel 环境变量包含：
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
JWT_SECRET=your-jwt-secret
```

## 📊 功能验证清单

### 数据库验证
- [ ] `labubu_models` 表包含新的图片字段
- [ ] `labubu-images` 存储桶已创建
- [ ] RLS 策略正确配置

### 前端功能验证
- [ ] 图片上传区域正常显示
- [ ] 支持拖拽和点击上传
- [ ] 文件类型和大小验证工作正常
- [ ] 图片预览功能正常
- [ ] 模型列表显示缩略图
- [ ] 点击缩略图可放大预览

### API 功能验证
- [ ] 创建模型时支持图片上传
- [ ] 图片成功保存到 Supabase Storage
- [ ] 图片信息正确保存到数据库
- [ ] 删除模型时图片文件被清理
- [ ] 错误处理机制正常工作

## 🛠️ 故障排除

### 常见问题1: 图片上传失败
**症状**: 上传时显示错误信息
**排查步骤**:
1. 检查 Supabase Storage 存储桶是否存在
2. 验证 RLS 策略是否正确配置
3. 确认文件大小不超过 5MB
4. 检查文件类型是否支持

### 常见问题2: 缩略图不显示
**症状**: 模型列表中显示"无图片"
**排查步骤**:
1. 检查 `image_url` 字段是否有值
2. 验证图片 URL 是否可访问
3. 检查浏览器控制台是否有 CORS 错误

### 常见问题3: 删除模型后图片未清理
**症状**: Storage 中仍有孤立的图片文件
**排查步骤**:
1. 检查 API 删除逻辑是否包含图片清理
2. 验证 Storage 删除权限
3. 查看服务器日志确认删除操作

## 📈 性能监控

### 关键指标
- **图片上传成功率**: 目标 >95%
- **页面加载时间**: 目标 <3秒
- **缩略图加载时间**: 目标 <1秒
- **存储空间使用**: 监控增长趋势

### 监控方法
- Vercel Analytics 监控页面性能
- Supabase Dashboard 监控存储使用
- 浏览器开发者工具检查网络请求

## 🔄 回滚计划

如果部署出现问题，可以执行以下回滚步骤：

### 1. 代码回滚
```bash
# 回滚到上一个稳定版本
git revert HEAD
git push origin master
```

### 2. 数据库回滚
```sql
-- 如需回滚数据库更改（谨慎操作）
ALTER TABLE labubu_models 
DROP COLUMN IF EXISTS image_url,
DROP COLUMN IF EXISTS image_path,
DROP COLUMN IF EXISTS image_filename,
DROP COLUMN IF EXISTS image_size,
DROP COLUMN IF EXISTS image_type;
```

### 3. Storage 清理
- 在 Supabase 控制台手动删除 `labubu-images` 存储桶（如需要）

## 📝 部署记录

| 时间 | 版本 | 操作 | 状态 | 备注 |
|------|------|------|------|------|
| 2024-12-19 | v5.2 | 初始部署 | ✅ 成功 | 图片管理功能完整部署 |

## 🎯 下一步计划

- [ ] 添加图片批量上传功能
- [ ] 实现图片压缩和优化
- [ ] 添加图片编辑功能（裁剪、旋转）
- [ ] 支持更多图片格式
- [ ] 添加图片标签和分类功能 