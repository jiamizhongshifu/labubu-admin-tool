-- 价格字段重命名回滚脚本
-- 将 release_price 改回 estimated_price_min
-- 将 reference_price 改回 estimated_price_max

-- 检查当前状态
DO $$
BEGIN
    -- 检查新字段是否存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'release_price') THEN
        RAISE EXCEPTION 'Column release_price does not exist - migration may not have been applied';
    END IF;
    
    -- 检查旧字段是否已经存在
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'estimated_price_min') THEN
        RAISE EXCEPTION 'Column estimated_price_min already exists - rollback may have already been applied';
    END IF;
    
    RAISE NOTICE 'Pre-rollback checks passed';
END $$;

-- 开始回滚事务
BEGIN;

-- 1. 删除使用新字段的视图
DO $$ BEGIN RAISE NOTICE 'Dropping views with new column names...'; END $$;
DROP VIEW IF EXISTS labubu_models_with_series CASCADE;
DROP VIEW IF EXISTS labubu_complete_info CASCADE;

-- 2. 添加旧字段
DO $$ BEGIN RAISE NOTICE 'Adding back old price columns...'; END $$;
ALTER TABLE labubu_models 
ADD COLUMN estimated_price_min DECIMAL(10,2),
ADD COLUMN estimated_price_max DECIMAL(10,2);

-- 3. 迁移数据回旧字段
DO $$ BEGIN RAISE NOTICE 'Migrating data back to old columns...'; END $$;
UPDATE labubu_models 
SET 
    estimated_price_min = release_price,
    estimated_price_max = reference_price;

-- 4. 验证回滚数据迁移
DO $$
DECLARE
    new_count INTEGER;
    old_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO new_count FROM labubu_models WHERE release_price IS NOT NULL;
    SELECT COUNT(*) INTO old_count FROM labubu_models WHERE estimated_price_min IS NOT NULL;
    
    IF new_count != old_count THEN
        RAISE EXCEPTION 'Rollback data migration failed: new_count=%, old_count=%', new_count, old_count;
    END IF;
    
    RAISE NOTICE 'Rollback data migration verified: % records migrated back', old_count;
END $$;

-- 5. 删除新字段
DO $$ BEGIN RAISE NOTICE 'Dropping new price columns...'; END $$;
ALTER TABLE labubu_models 
DROP COLUMN release_price,
DROP COLUMN reference_price;

-- 6. 重新创建原始视图
DO $$ BEGIN RAISE NOTICE 'Recreating original views...'; END $$;

-- 重新创建原始完整模型信息视图
CREATE VIEW labubu_complete_info AS
SELECT 
    m.id,
    m.series_id,
    m.name,
    m.name_en,
    m.model_number,
    m.description,
    m.rarity_level,
    m.estimated_price_min,
    m.estimated_price_max,
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
        WHEN m.estimated_price_min IS NOT NULL AND m.estimated_price_max IS NOT NULL 
        THEN (m.estimated_price_min + m.estimated_price_max) / 2.0
        WHEN m.estimated_price_min IS NOT NULL 
        THEN m.estimated_price_min
        WHEN m.estimated_price_max IS NOT NULL 
        THEN m.estimated_price_max
        ELSE NULL
    END as average_price
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id
WHERE m.is_active = true;

-- 重新创建原始模型与系列关联视图
CREATE VIEW labubu_models_with_series AS
SELECT 
    m.id,
    m.series_id,
    m.name,
    m.name_en,
    m.model_number,
    m.description,
    m.rarity_level,
    m.estimated_price_min,
    m.estimated_price_max,
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

-- 7. 最终验证
DO $$
DECLARE
    model_count INTEGER;
    view_count INTEGER;
BEGIN
    -- 验证表结构
    SELECT COUNT(*) INTO model_count FROM labubu_models;
    SELECT COUNT(*) INTO view_count FROM labubu_complete_info;
    
    RAISE NOTICE 'Final rollback verification: % models in table, % in complete_info view', model_count, view_count;
    
    -- 验证旧字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'estimated_price_min') THEN
        RAISE EXCEPTION 'Rollback failed: estimated_price_min column not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'estimated_price_max') THEN
        RAISE EXCEPTION 'Rollback failed: estimated_price_max column not found';
    END IF;
    
    -- 验证新字段已删除
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'release_price') THEN
        RAISE EXCEPTION 'Rollback failed: release_price column still exists';
    END IF;
    
    RAISE NOTICE 'Rollback completed successfully!';
END $$;

-- 提交回滚事务
COMMIT;

-- 显示回滚结果统计
SELECT 
    'Rollback Summary' as summary,
    COUNT(*) as total_models,
    COUNT(estimated_price_min) as models_with_min_price,
    COUNT(estimated_price_max) as models_with_max_price,
    ROUND(AVG(estimated_price_min), 2) as avg_min_price,
    ROUND(AVG(estimated_price_max), 2) as avg_max_price
FROM labubu_models 
WHERE is_active = true; 