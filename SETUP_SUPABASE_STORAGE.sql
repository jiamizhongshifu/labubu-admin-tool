-- 🗄️ Supabase Storage 配置脚本 - Labubu 图片存储
-- 创建日期: 2024-12-19
-- 功能: 配置 Labubu 模型图片的存储桶和访问策略

-- 1. 创建存储桶
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

-- 2. 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Allow public read access" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated update" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated delete" ON storage.objects;

-- 3. 创建公共读取策略
CREATE POLICY "Allow public read access" ON storage.objects
    FOR SELECT 
    USING (bucket_id = 'labubu-images');

-- 4. 创建认证用户上传策略
CREATE POLICY "Allow authenticated upload" ON storage.objects
    FOR INSERT 
    WITH CHECK (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );

-- 5. 创建认证用户更新策略
CREATE POLICY "Allow authenticated update" ON storage.objects
    FOR UPDATE 
    USING (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    )
    WITH CHECK (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );

-- 6. 创建认证用户删除策略
CREATE POLICY "Allow authenticated delete" ON storage.objects
    FOR DELETE 
    USING (
        bucket_id = 'labubu-images' 
        AND auth.role() = 'authenticated'
    );

-- 7. 验证存储桶创建
SELECT id, name, public, file_size_limit, allowed_mime_types 
FROM storage.buckets 
WHERE id = 'labubu-images';

-- 8. 验证策略创建
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage'; 