-- 创建 labubu-images 存储桶的SQL脚本
-- 在Supabase SQL编辑器中运行此脚本

-- 1. 检查并创建存储桶（如果不存在）
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
SELECT 
    'labubu-images',
    'labubu-images', 
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE NOT EXISTS (
    SELECT 1 FROM storage.buckets WHERE id = 'labubu-images'
);

-- 2. 删除可能存在的旧策略（避免冲突）
DROP POLICY IF EXISTS "Allow public access" ON storage.objects;
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
DROP POLICY IF EXISTS "Allow public deletes" ON storage.objects;

-- 3. 创建新的公开访问策略
CREATE POLICY "Allow public access" ON storage.objects
FOR SELECT USING (bucket_id = 'labubu-images');

-- 4. 创建新的公开上传策略
CREATE POLICY "Allow public uploads" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'labubu-images');

-- 5. 创建新的公开删除策略（可选）
CREATE POLICY "Allow public deletes" ON storage.objects
FOR DELETE USING (bucket_id = 'labubu-images');

-- 6. 验证存储桶是否创建成功
SELECT * FROM storage.buckets WHERE id = 'labubu-images'; 