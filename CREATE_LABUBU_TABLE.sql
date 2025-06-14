-- 创建 labubu_models 表
CREATE TABLE IF NOT EXISTS public.labubu_models (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    series TEXT,
    release_price TEXT,
    reference_price TEXT,
    rarity TEXT,
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_labubu_models_updated_at 
    BEFORE UPDATE ON public.labubu_models 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 设置行级安全策略 (RLS)
ALTER TABLE public.labubu_models ENABLE ROW LEVEL SECURITY;

-- 创建策略：允许所有操作（适用于管理工具）
CREATE POLICY "Allow all operations on labubu_models" ON public.labubu_models
    FOR ALL USING (true) WITH CHECK (true);

-- 插入示例数据
INSERT INTO public.labubu_models (name, series, release_price, reference_price, rarity, features) VALUES
('Labubu The Monsters Tasty Macarons Series - Strawberry', 'The Monsters', '59', '120', '普通', '{"color": "粉色", "material": "PVC", "size": "约6cm", "theme": "草莓马卡龙"}'),
('Labubu The Monsters Tasty Macarons Series - Chocolate', 'The Monsters', '59', '150', '不常见', '{"color": "棕色", "material": "PVC", "size": "约6cm", "theme": "巧克力马卡龙"}'),
('Labubu The Monsters Tasty Macarons Series - Matcha', 'The Monsters', '59', '200', '稀有', '{"color": "绿色", "material": "PVC", "size": "约6cm", "theme": "抹茶马卡龙"}')
ON CONFLICT (id) DO NOTHING;

-- 验证表创建
SELECT 'Table created successfully' as status; 