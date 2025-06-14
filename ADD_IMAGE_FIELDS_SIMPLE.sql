-- 🖼️ Labubu 模型表添加图片字段 - 简化版本
-- 创建日期: 2024-12-19
-- 使用说明: 在 Supabase SQL 编辑器中逐行执行

-- 添加图片相关字段
ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_path TEXT;

ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_filename TEXT;

ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_size INTEGER;

ALTER TABLE labubu_models 
ADD COLUMN IF NOT EXISTS image_type VARCHAR(50);

-- 添加字段注释
COMMENT ON COLUMN labubu_models.image_url IS '模型配图的完整URL地址';
COMMENT ON COLUMN labubu_models.image_path IS 'Supabase Storage中的图片路径';
COMMENT ON COLUMN labubu_models.image_filename IS '原始图片文件名';
COMMENT ON COLUMN labubu_models.image_size IS '图片文件大小（字节）';
COMMENT ON COLUMN labubu_models.image_type IS '图片MIME类型'; 