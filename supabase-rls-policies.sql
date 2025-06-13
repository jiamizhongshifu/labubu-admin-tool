-- Supabase RLS策略配置
-- 用于允许iOS应用使用Anon Key读取Labubu数据

-- 1. 为labubu_series表启用RLS并设置读取策略
ALTER TABLE labubu_series ENABLE ROW LEVEL SECURITY;

-- 允许所有用户（包括匿名用户）读取活跃的系列数据
CREATE POLICY "Allow public read access to active series" ON labubu_series
    FOR SELECT USING (is_active = true);

-- 2. 为labubu_models表启用RLS并设置读取策略
ALTER TABLE labubu_models ENABLE ROW LEVEL SECURITY;

-- 允许所有用户（包括匿名用户）读取活跃的模型数据
CREATE POLICY "Allow public read access to active models" ON labubu_models
    FOR SELECT USING (is_active = true);

-- 3. 为labubu_reference_images表启用RLS并设置读取策略（如果存在）
ALTER TABLE labubu_reference_images ENABLE ROW LEVEL SECURITY;

-- 允许所有用户读取参考图片
CREATE POLICY "Allow public read access to reference images" ON labubu_reference_images
    FOR SELECT USING (true);

-- 4. 为labubu_price_history表启用RLS并设置读取策略（如果存在）
ALTER TABLE labubu_price_history ENABLE ROW LEVEL SECURITY;

-- 允许所有用户读取价格历史
CREATE POLICY "Allow public read access to price history" ON labubu_price_history
    FOR SELECT USING (true);

-- 注意：以上策略只允许读取（SELECT），不允许写入、更新或删除
-- 管理操作仍需要使用Service Role Key 