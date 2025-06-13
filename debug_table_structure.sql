-- 方法1：查看表结构
\d labubu_reference_images

-- 方法2：如果上面不工作，用这个
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'labubu_reference_images' 
ORDER BY ordinal_position;

-- 方法3：查看表的示例数据（如果有的话）
SELECT * FROM labubu_reference_images LIMIT 1;

-- 方法4：测试插入一条简单数据
INSERT INTO labubu_reference_images (
    model_id,
    image_url,
    angle,
    is_primary,
    quality_score,
    upload_date
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'https://test.com/test.jpg',
    'front',
    false,
    0.9,
    NOW()
) RETURNING *; 