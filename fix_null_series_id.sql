-- 修复现有模型数据中的null series_id
-- 将所有null的series_id设置为第一个可用系列的ID

UPDATE labubu_models 
SET series_id = (
    SELECT id 
    FROM labubu_series 
    ORDER BY created_at ASC 
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
ORDER BY m.created_at DESC; 