-- 🔧 Labubu 数据库表创建脚本 v5.1 - 语法修复版本
-- 修复日期: 2024-12-19
-- 修复内容: 解决 RLS 策略语法错误

-- 1. 删除现有表（如果存在）
DROP TABLE IF EXISTS labubu_models CASCADE;

-- 2. 创建 labubu_models 表
CREATE TABLE labubu_models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    series_id VARCHAR(100),  -- 使用 series_id 字段名（匹配远程数据库）
    release_price DECIMAL(10,2),
    reference_price DECIMAL(10,2),
    rarity VARCHAR(50),
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. 创建触发器
CREATE TRIGGER update_labubu_models_updated_at 
    BEFORE UPDATE ON labubu_models 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 5. 启用 RLS (Row Level Security)
ALTER TABLE labubu_models ENABLE ROW LEVEL SECURITY;

-- 6. 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Allow all operations" ON labubu_models;

-- 7. 创建允许所有操作的策略（修复语法）
CREATE POLICY "Allow all operations" ON labubu_models
    FOR ALL 
    USING (true)
    WITH CHECK (true);

-- 8. 授予公共访问权限
GRANT ALL ON labubu_models TO anon;
GRANT ALL ON labubu_models TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE labubu_models_id_seq TO anon;
GRANT USAGE, SELECT ON SEQUENCE labubu_models_id_seq TO authenticated;

-- 9. 插入测试数据
INSERT INTO labubu_models (name, series_id, release_price, reference_price, rarity, features) VALUES
('经典款 Labubu', 'Classic', 59.00, 89.00, 'Common', '{"color": "粉色", "size": "标准", "accessories": ["贴纸"]}'),
('限定版 Labubu', 'Limited', 199.00, 399.00, 'Rare', '{"color": "金色", "size": "大号", "accessories": ["证书", "特殊包装"]}'),
('盲盒系列 Labubu', 'Blind Box', 79.00, 129.00, 'Uncommon', '{"color": "随机", "size": "标准", "accessories": ["盲盒卡片"]}');

-- 10. 验证数据插入
SELECT 'Table created successfully!' as status;
SELECT COUNT(*) as total_records FROM labubu_models;
SELECT * FROM labubu_models LIMIT 3; 