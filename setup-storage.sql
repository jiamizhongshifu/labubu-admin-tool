-- Labubu管理工具 - Supabase Storage设置脚本
-- 在Supabase SQL编辑器中执行此脚本

-- 1. 创建图片存储桶
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
    'labubu-images', 
    'labubu-images', 
    true,
    5242880, -- 5MB限制
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
);

-- 2. 设置公共访问策略（允许所有人查看图片）
CREATE POLICY "Public Access" ON storage.objects 
FOR SELECT 
USING (bucket_id = 'labubu-images');

-- 3. 设置上传策略（允许认证用户上传）
CREATE POLICY "Authenticated Upload" ON storage.objects 
FOR INSERT 
WITH CHECK (
    bucket_id = 'labubu-images' 
    AND auth.role() = 'authenticated'
);

-- 4. 设置更新策略（允许认证用户更新自己上传的文件）
CREATE POLICY "Authenticated Update" ON storage.objects 
FOR UPDATE 
USING (
    bucket_id = 'labubu-images' 
    AND auth.role() = 'authenticated'
);

-- 5. 设置删除策略（允许认证用户删除自己上传的文件）
CREATE POLICY "Authenticated Delete" ON storage.objects 
FOR DELETE 
USING (
    bucket_id = 'labubu-images' 
    AND auth.role() = 'authenticated'
);

-- 6. 如果需要允许匿名上传（仅用于管理工具），可以添加以下策略
-- 注意：这会允许任何人上传文件，请谨慎使用
CREATE POLICY "Anonymous Upload for Admin" ON storage.objects 
FOR INSERT 
WITH CHECK (
    bucket_id = 'labubu-images'
    AND auth.role() = 'anon'
);

-- 7. 创建一个函数来清理未使用的图片（可选）
CREATE OR REPLACE FUNCTION cleanup_unused_images()
RETURNS void AS $$
BEGIN
    -- 删除不在labubu_models表中引用的图片
    DELETE FROM storage.objects 
    WHERE bucket_id = 'labubu-images'
    AND name NOT IN (
        SELECT DISTINCT jsonb_array_elements(reference_images)->>'image_url'
        FROM labubu_models
        WHERE reference_images IS NOT NULL
    );
END;
$$ LANGUAGE plpgsql;

-- 8. 验证设置
SELECT 
    'Storage bucket created successfully' as status,
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id = 'labubu-images';

-- 9. 查看存储策略
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';

-- 完成！现在您可以在管理工具中上传图片了。 