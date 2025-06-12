-- Labubu数据库表结构设计
-- 用于存储Labubu合集的预置数据

-- 1. Labubu系列表
CREATE TABLE labubu_series (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    description TEXT,
    release_year INTEGER,
    total_models INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Labubu模型表
CREATE TABLE labubu_models (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    series_id UUID REFERENCES labubu_series(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    name_en VARCHAR(255),
    model_number VARCHAR(100),
    description TEXT,
    rarity_level VARCHAR(50), -- common, uncommon, rare, ultra_rare, secret
    estimated_price_min DECIMAL(10,2),
    estimated_price_max DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'CNY',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. 参考图片表
CREATE TABLE labubu_reference_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_type VARCHAR(50), -- front, back, side, detail, package
    is_primary BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. 视觉特征表
CREATE TABLE labubu_visual_features (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    
    -- 颜色特征
    dominant_colors JSONB, -- 主要颜色数组
    color_distribution JSONB, -- 颜色分布
    
    -- 形状特征
    body_shape VARCHAR(100), -- 身体形状描述
    head_shape VARCHAR(100), -- 头部形状描述
    ear_type VARCHAR(100), -- 耳朵类型
    
    -- 纹理特征
    surface_texture VARCHAR(100), -- 表面纹理
    pattern_type VARCHAR(100), -- 图案类型
    
    -- 尺寸特征
    height_cm DECIMAL(5,2),
    width_cm DECIMAL(5,2),
    depth_cm DECIMAL(5,2),
    
    -- 特殊标识
    special_marks TEXT, -- 特殊标记描述
    accessories JSONB, -- 配件信息
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. 识别标签表（用于机器学习训练）
CREATE TABLE labubu_recognition_tags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    tag_type VARCHAR(50), -- color, shape, pattern, accessory, pose
    tag_value VARCHAR(255),
    confidence DECIMAL(3,2), -- 0.00-1.00
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. 价格历史表
CREATE TABLE labubu_price_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'CNY',
    source VARCHAR(100), -- taobao, xianyu, official, etc.
    condition VARCHAR(50), -- new, used, damaged
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. 管理员操作日志表
CREATE TABLE admin_operation_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id VARCHAR(255), -- 管理员标识
    operation_type VARCHAR(100), -- create, update, delete, import
    table_name VARCHAR(100),
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    operation_time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 创建索引以优化查询性能
CREATE INDEX idx_labubu_models_series_id ON labubu_models(series_id);
CREATE INDEX idx_labubu_models_name ON labubu_models(name);
CREATE INDEX idx_labubu_models_model_number ON labubu_models(model_number);
CREATE INDEX idx_labubu_reference_images_model_id ON labubu_reference_images(model_id);
CREATE INDEX idx_labubu_visual_features_model_id ON labubu_visual_features(model_id);
CREATE INDEX idx_labubu_recognition_tags_model_id ON labubu_recognition_tags(model_id);
CREATE INDEX idx_labubu_recognition_tags_type_value ON labubu_recognition_tags(tag_type, tag_value);
CREATE INDEX idx_labubu_price_history_model_id ON labubu_price_history(model_id);
CREATE INDEX idx_admin_operation_logs_time ON admin_operation_logs(operation_time);

-- 创建更新时间触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_labubu_series_updated_at BEFORE UPDATE ON labubu_series FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_labubu_models_updated_at BEFORE UPDATE ON labubu_models FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_labubu_visual_features_updated_at BEFORE UPDATE ON labubu_visual_features FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据
INSERT INTO labubu_series (name, name_en, description, release_year, total_models) VALUES
('经典系列', 'Classic Series', 'Labubu的经典造型系列', 2019, 12),
('梦幻系列', 'Dream Series', '梦幻主题的特别版本', 2020, 8),
('节日系列', 'Festival Series', '节日限定版本', 2021, 6),
('艺术家合作系列', 'Artist Collaboration', '与知名艺术家合作的限量版', 2022, 4);

-- 为第一个系列插入示例模型
INSERT INTO labubu_models (series_id, name, name_en, model_number, description, rarity_level, estimated_price_min, estimated_price_max) 
SELECT 
    id,
    '经典粉色Labubu',
    'Classic Pink Labubu',
    'LB-CL-001',
    '经典粉色造型，最受欢迎的版本之一',
    'common',
    89.00,
    150.00
FROM labubu_series WHERE name = '经典系列' LIMIT 1;

INSERT INTO labubu_models (series_id, name, name_en, model_number, description, rarity_level, estimated_price_min, estimated_price_max) 
SELECT 
    id,
    '经典蓝色Labubu',
    'Classic Blue Labubu',
    'LB-CL-002',
    '经典蓝色造型，温和可爱',
    'common',
    89.00,
    150.00
FROM labubu_series WHERE name = '经典系列' LIMIT 1;

-- 启用行级安全策略（RLS）
ALTER TABLE labubu_series ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_reference_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_visual_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_recognition_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_operation_logs ENABLE ROW LEVEL SECURITY;

-- 创建公开读取策略（允许iOS应用读取数据）
CREATE POLICY "Allow public read access" ON labubu_series FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON labubu_models FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON labubu_reference_images FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON labubu_visual_features FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON labubu_recognition_tags FOR SELECT USING (true);
CREATE POLICY "Allow public read access" ON labubu_price_history FOR SELECT USING (true);

-- 创建管理员写入策略（需要service_role权限）
CREATE POLICY "Allow admin write access" ON labubu_series FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON labubu_models FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON labubu_reference_images FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON labubu_visual_features FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON labubu_recognition_tags FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON labubu_price_history FOR ALL USING (auth.role() = 'service_role');
CREATE POLICY "Allow admin write access" ON admin_operation_logs FOR ALL USING (auth.role() = 'service_role');

-- 创建视图以简化查询
CREATE VIEW labubu_models_with_series AS
SELECT 
    m.*,
    s.name as series_name,
    s.name_en as series_name_en,
    s.release_year
FROM labubu_models m
JOIN labubu_series s ON m.series_id = s.id
WHERE m.is_active = true AND s.is_active = true;

CREATE VIEW labubu_complete_info AS
SELECT 
    m.*,
    s.name as series_name,
    s.name_en as series_name_en,
    s.release_year,
    vf.dominant_colors,
    vf.body_shape,
    vf.head_shape,
    vf.surface_texture,
    vf.height_cm,
    vf.width_cm,
    vf.depth_cm,
    (
        SELECT json_agg(
            json_build_object(
                'url', image_url,
                'type', image_type,
                'is_primary', is_primary
            )
        )
        FROM labubu_reference_images 
        WHERE model_id = m.id
    ) as reference_images
FROM labubu_models m
JOIN labubu_series s ON m.series_id = s.id
LEFT JOIN labubu_visual_features vf ON vf.model_id = m.id
WHERE m.is_active = true AND s.is_active = true; 