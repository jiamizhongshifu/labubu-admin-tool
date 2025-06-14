-- 🖼️ Labubu 模型表添加图片字段 - v5.2
-- 创建日期: 2024-12-19
-- 功能: 为 labubu_models 表添加图片存储字段

-- 1. 添加图片相关字段
ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS image_path TEXT,
ADD COLUMN IF NOT EXISTS image_filename TEXT,
ADD COLUMN IF NOT EXISTS image_size INTEGER,
ADD COLUMN IF NOT EXISTS image_type VARCHAR(50);

-- 2. 添加字段注释
COMMENT ON COLUMN labubu_models.image_url IS '模型配图的完整URL地址';
COMMENT ON COLUMN labubu_models.image_path IS 'Supabase Storage中的图片路径';
COMMENT ON COLUMN labubu_models.image_filename IS '原始图片文件名';
COMMENT ON COLUMN labubu_models.image_size IS '图片文件大小（字节）';
COMMENT ON COLUMN labubu_models.image_type IS '图片MIME类型';

-- 3. 创建图片存储桶（如果不存在）
-- 注意：这需要在 Supabase 控制台中执行，或通过 Storage API
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('labubu-images', 'labubu-images', true)
-- ON CONFLICT (id) DO NOTHING;

-- 4. 验证字段添加
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'labubu_models' 
AND column_name LIKE 'image%'
ORDER BY column_name;

-- 5. 显示表结构（使用标准SQL查询）
SELECT 
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'labubu_models'
ORDER BY ordinal_position; 