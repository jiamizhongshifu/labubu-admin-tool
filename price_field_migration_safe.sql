-- 价格字段重命名迁移脚本（安全版本）
-- 将 estimated_price_min 改为 release_price (发售价格)
-- 将 estimated_price_max 改为 reference_price (参考价格)

-- 检查当前数据库状态
DO $$
BEGIN
    -- 检查表是否存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'labubu_models') THEN
        RAISE EXCEPTION 'Table labubu_models does not exist';
    END IF;
    
    -- 检查旧字段是否存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'estimated_price_min') THEN
        RAISE EXCEPTION 'Column estimated_price_min does not exist';
    END IF;
    
    -- 检查新字段是否已存在
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'release_price') THEN
        RAISE EXCEPTION 'Column release_price already exists';
    END IF;
    
    RAISE NOTICE 'Pre-migration checks passed';
END $$;

-- 开始事务
BEGIN;

-- 1. 备份当前视图定义（记录到日志）
DO $$
DECLARE
    view_def TEXT;
BEGIN
    -- 记录现有视图
    RAISE NOTICE 'Backing up existing views...';
    
    -- 检查并记录 labubu_complete_info 视图
    SELECT pg_get_viewdef('labubu_complete_info'::regclass) INTO view_def;
    RAISE NOTICE 'labubu_complete_info view definition: %', view_def;
    
    -- 检查并记录 labubu_models_with_series 视图
    SELECT pg_get_viewdef('labubu_models_with_series'::regclass) INTO view_def;
    RAISE NOTICE 'labubu_models_with_series view definition: %', view_def;
    
EXCEPTION
    WHEN undefined_table THEN
        RAISE NOTICE 'Some views do not exist, continuing...';
END $$;

-- 2. 删除依赖的视图
DO $$ BEGIN RAISE NOTICE 'Dropping dependent views...'; END $$;
DROP VIEW IF EXISTS labubu_models_with_series CASCADE;
DROP VIEW IF EXISTS labubu_complete_info CASCADE;

-- 3. 添加新字段
DO $$ BEGIN RAISE NOTICE 'Adding new price columns...'; END $$;
ALTER TABLE labubu_models 
ADD COLUMN release_price DECIMAL(10,2),
ADD COLUMN reference_price DECIMAL(10,2);

-- 4. 迁移现有数据
DO $$ BEGIN RAISE NOTICE 'Migrating existing price data...'; END $$;
UPDATE labubu_models 
SET 
    release_price = estimated_price_min,
    reference_price = estimated_price_max;

-- 5. 验证数据迁移
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM labubu_models WHERE estimated_price_min IS NOT NULL;
    SELECT COUNT(*) INTO new_count FROM labubu_models WHERE release_price IS NOT NULL;
    
    IF old_count != new_count THEN
        RAISE EXCEPTION 'Data migration failed: old_count=%, new_count=%', old_count, new_count;
    END IF;
    
    RAISE NOTICE 'Data migration verified: % records migrated', new_count;
END $$;

-- 6. 删除旧字段
DO $$ BEGIN RAISE NOTICE 'Dropping old price columns...'; END $$;
ALTER TABLE labubu_models 
DROP COLUMN estimated_price_min,
DROP COLUMN estimated_price_max;

-- 7. 重新创建视图（使用新字段名）
DO $$ BEGIN RAISE NOTICE 'Recreating views with new column names...'; END $$;

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

-- 8. 最终验证
DO $$
DECLARE
    model_count INTEGER;
    view_count INTEGER;
BEGIN
    -- 验证表结构
    SELECT COUNT(*) INTO model_count FROM labubu_models;
    SELECT COUNT(*) INTO view_count FROM labubu_complete_info;
    
    RAISE NOTICE 'Final verification: % models in table, % in complete_info view', model_count, view_count;
    
    -- 验证新字段存在
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'release_price') THEN
        RAISE EXCEPTION 'Migration failed: release_price column not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'reference_price') THEN
        RAISE EXCEPTION 'Migration failed: reference_price column not found';
    END IF;
    
    -- 验证旧字段已删除
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'labubu_models' AND column_name = 'estimated_price_min') THEN
        RAISE EXCEPTION 'Migration failed: estimated_price_min column still exists';
    END IF;
    
    RAISE NOTICE 'Migration completed successfully!';
END $$;

-- 提交事务
COMMIT;

-- 显示迁移结果统计
SELECT 
    'Migration Summary' as summary,
    COUNT(*) as total_models,
    COUNT(release_price) as models_with_release_price,
    COUNT(reference_price) as models_with_reference_price,
    ROUND(AVG(release_price), 2) as avg_release_price,
    ROUND(AVG(reference_price), 2) as avg_reference_price
FROM labubu_models 
WHERE is_active = true;

-- 显示视图验证
SELECT 
    'View Verification' as verification,
    (SELECT COUNT(*) FROM labubu_complete_info) as complete_info_count,
    (SELECT COUNT(*) FROM labubu_models_with_series) as models_with_series_count; 