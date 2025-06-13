-- 数据库迁移脚本：添加feature_description字段
-- 用于保存JSON格式的特征描述

-- 在labubu_models表中添加feature_description字段
ALTER TABLE labubu_models 
ADD COLUMN feature_description TEXT;

-- 添加注释说明字段用途
COMMENT ON COLUMN labubu_models.feature_description IS 'JSON格式的特征描述，用于AI识别对比';

-- 创建索引以优化查询性能（如果需要搜索特征描述）
CREATE INDEX idx_labubu_models_feature_description ON labubu_models USING gin(to_tsvector('english', feature_description));

-- 验证字段添加成功
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'labubu_models' 
AND column_name = 'feature_description'; 