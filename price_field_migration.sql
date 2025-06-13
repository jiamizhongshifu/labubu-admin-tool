-- 价格字段重命名迁移脚本
-- 将 estimated_price_min 改为 release_price (发售价格)
-- 将 estimated_price_max 改为 reference_price (参考价格)

-- 开始事务
BEGIN;

-- 1. 先删除依赖的视图
DROP VIEW IF EXISTS labubu_models_with_series CASCADE;
DROP VIEW IF EXISTS labubu_complete_info CASCADE;

-- 2. 添加新字段
ALTER TABLE labubu_models 
ADD COLUMN release_price DECIMAL(10,2),
ADD COLUMN reference_price DECIMAL(10,2);

-- 3. 迁移现有数据
UPDATE labubu_models 
SET 
    release_price = estimated_price_min,
    reference_price = estimated_price_max;

-- 4. 删除旧字段
ALTER TABLE labubu_models 
DROP COLUMN estimated_price_min,
DROP COLUMN estimated_price_max;

-- 5. 重新创建视图（使用新字段名）

-- 重新创建完整模型信息视图
CREATE VIEW labubu_complete_info AS
SELECT 
    m.id,
    m.series_id,
    m.name,
    m.name_en,
    m.model_number,
    m.description,
    m.rarity_level,
    m.release_price,
    m.reference_price,
    m.currency,
    m.is_active,
    m.created_at,
    m.updated_at,
    s.name as series_name,
    s.name_en as series_name_en,
    s.description as series_description,
    s.release_year,
    s.total_models,
    -- 计算价格统计
    CASE 
        WHEN m.release_price IS NOT NULL AND m.reference_price IS NOT NULL 
        THEN (m.release_price + m.reference_price) / 2.0
        WHEN m.release_price IS NOT NULL 
        THEN m.release_price
        WHEN m.reference_price IS NOT NULL 
        THEN m.reference_price
        ELSE NULL
    END as average_price
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id
WHERE m.is_active = true;

-- 重新创建模型与系列关联视图
CREATE VIEW labubu_models_with_series AS
SELECT 
    m.id,
    m.series_id,
    m.name,
    m.name_en,
    m.model_number,
    m.description,
    m.rarity_level,
    m.release_price,
    m.reference_price,
    m.currency,
    m.is_active,
    m.created_at,
    m.updated_at,
    s.name as series_name,
    s.name_en as series_name_en,
    s.description as series_description,
    s.release_year as series_release_year,
    s.total_models as series_total_models,
    s.is_active as series_is_active
FROM labubu_models m
INNER JOIN labubu_series s ON m.series_id = s.id;

-- 提交事务
COMMIT;

-- 验证迁移结果
SELECT 
    COUNT(*) as total_models,
    COUNT(release_price) as models_with_release_price,
    COUNT(reference_price) as models_with_reference_price,
    AVG(release_price) as avg_release_price,
    AVG(reference_price) as avg_reference_price
FROM labubu_models 
WHERE is_active = true; 