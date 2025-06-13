-- 为现有模型设置系列ID
UPDATE labubu_models 
SET series_id = (SELECT id FROM labubu_series LIMIT 1)
WHERE series_id IS NULL; 