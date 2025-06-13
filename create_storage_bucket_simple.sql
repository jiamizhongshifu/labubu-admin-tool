-- 简化版本：创建 labubu-images 存储桶
-- 请逐个执行以下SQL语句

-- 步骤1：检查存储桶是否已存在
SELECT * FROM storage.buckets WHERE id = 'labubu-images';

-- 步骤2：如果上面查询返回空结果，则执行下面的创建语句
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'labubu-images',
    'labubu-images', 
    true,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
);

-- 步骤3：删除可能存在的旧策略
DROP POLICY IF EXISTS "Allow public access" ON storage.objects;

-- 步骤4：删除可能存在的旧策略
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;

-- 步骤5：删除可能存在的旧策略
DROP POLICY IF EXISTS "Allow public deletes" ON storage.objects;

-- 步骤6：创建公开访问策略
CREATE POLICY "Allow public access" ON storage.objects
FOR SELECT USING (bucket_id = 'labubu-images');

-- 步骤7：创建公开上传策略
CREATE POLICY "Allow public uploads" ON storage.objects
FOR INSERT WITH CHECK (bucket_id = 'labubu-images');

-- 步骤8：创建公开删除策略
CREATE POLICY "Allow public deletes" ON storage.objects
FOR DELETE USING (bucket_id = 'labubu-images');

-- 步骤9：验证创建结果
SELECT * FROM storage.buckets WHERE id = 'labubu-images'; 