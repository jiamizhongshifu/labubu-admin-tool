-- 修复模型的series_id字段（UUID格式）
-- 将series_id为null的模型关联到第一个可用的系列

-- 首先查看当前状态
SELECT 
    m.id,
    m.name,
    m.series_id,
    s.name as series_name
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id
ORDER BY m.created_at DESC;

-- 查看可用的系列
SELECT id, name, name_en FROM labubu_series ORDER BY created_at;

-- 修复series_id为null的记录
-- 将它们关联到第一个可用的系列
UPDATE labubu_models 
SET series_id = (
    SELECT id 
    FROM labubu_series 
    ORDER BY created_at 
    LIMIT 1
)
WHERE series_id IS NULL;

-- 验证修复结果
SELECT 
    m.id,
    m.name,
    m.series_id,
    s.name as series_name
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id
WHERE m.series_id IS NOT NULL
ORDER BY m.created_at DESC; 