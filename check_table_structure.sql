-- 检查 labubu_reference_images 表结构
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'labubu_reference_images' 
ORDER BY ordinal_position;

-- 检查表是否存在
SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_name = 'labubu_reference_images'
);

-- 查看表的约束
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'labubu_reference_images'; 