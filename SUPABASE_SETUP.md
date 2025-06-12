# 🚀 Supabase图床配置指南

## 📋 配置步骤

### 1. 获取Supabase项目信息

1. 访问 [supabase.com](https://supabase.com) 并登录
2. 选择您的项目或创建新项目
3. 在项目Dashboard中，点击左侧的 **"Settings"** → **"API"**

### 2. 复制必要的配置信息

在API设置页面，您需要复制以下信息：

#### 📝 Project URL
- 在 **"Project URL"** 部分找到类似这样的URL：
  ```
  https://your-project-id.supabase.co
  ```

#### 🔑 API Keys
- **anon public key**: 用于客户端访问
- **service_role key**: 用于服务端操作（⚠️ 保密！）

### 3. 更新.env文件

将 `jitata/.env` 文件中的占位符替换为实际值：

```bash
# 替换这些值：
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_STORAGE_BUCKET=jitata-images
```

### 4. 创建存储桶

1. 在Supabase Dashboard中，点击左侧的 **"Storage"**
2. 点击 **"Create a new bucket"**
3. 输入桶名称：`jitata-images`
4. ✅ 勾选 **"Public bucket"** （重要！）
5. 点击 **"Create bucket"**

### 5. 配置RLS策略（如果需要）

如果您的存储桶不是Public，需要配置RLS策略：

```sql
-- 允许所有人上传到 jitata-images 存储桶
CREATE POLICY "Allow public uploads to jitata-images" ON storage.objects
FOR INSERT WITH CHECK (
    bucket_id = 'jitata-images'
);

-- 允许所有人读取 jitata-images 存储桶的文件
CREATE POLICY "Allow public downloads from jitata-images" ON storage.objects
FOR SELECT USING (
    bucket_id = 'jitata-images'
);
```

## 🧪 测试配置

配置完成后，运行测试脚本验证：

```bash
./test_supabase_upload.sh
```

期望看到的结果：
- 上传请求：`HTTP/1.1 200 OK`
- 读取请求：`HTTP/1.1 200 OK`

## ❌ 常见问题排查

### 问题1：403 Forbidden
**原因**：RLS策略阻止了操作
**解决**：
1. 确保存储桶设置为Public
2. 或者配置正确的RLS策略

### 问题2：404 Not Found
**原因**：存储桶不存在
**解决**：
1. 检查存储桶名称是否正确
2. 确保存储桶已创建

### 问题3：401 Unauthorized
**原因**：API密钥错误
**解决**：
1. 检查API密钥是否正确复制
2. 确保使用service_role key进行上传操作

## 📱 应用中的使用

配置完成后，应用将自动：
1. 在用户拍摄照片后预上传到Supabase
2. AI增强时使用预上传的URL（速度更快）
3. 在详情页显示预上传状态指示器

## 🔒 安全注意事项

1. **永远不要**将service_role key提交到代码仓库
2. 确保`.env`文件在`.gitignore`中
3. 定期轮换API密钥
4. 监控存储使用量和API调用次数 

# Labubu数据库设置指南

## 1. Supabase项目创建

1. 访问 [Supabase](https://supabase.com) 并创建新项目
2. 记录项目的URL和API密钥
3. 进入项目的SQL编辑器

## 2. 数据库表结构创建

在Supabase的SQL编辑器中执行以下SQL脚本：

```sql
-- =============================================
-- Labubu数据库表结构设计
-- 用于存储Labubu合集的预置数据
-- =============================================

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
    rarity_level VARCHAR(50) CHECK (rarity_level IN ('common', 'uncommon', 'rare', 'ultra_rare', 'secret')),
    estimated_price_min DECIMAL(10,2),
    estimated_price_max DECIMAL(10,2),
    currency VARCHAR(10) DEFAULT 'CNY',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Labubu参考图片表
CREATE TABLE labubu_reference_images (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    image_type VARCHAR(50) CHECK (image_type IN ('front', 'back', 'side', 'detail', 'package')),
    is_primary BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Labubu价格历史表
CREATE TABLE labubu_price_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    price DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'CNY',
    source VARCHAR(255),
    condition VARCHAR(50) CHECK (condition IN ('new', 'used', 'damaged')),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Labubu视觉特征表（用于识别）
CREATE TABLE labubu_visual_features (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    model_id UUID REFERENCES labubu_models(id) ON DELETE CASCADE,
    dominant_colors JSONB, -- 主要颜色 [{"color": "#FF5733", "percentage": 0.4}]
    color_palette JSONB,   -- 完整色板
    shape_features JSONB,  -- 形状特征
    texture_features JSONB, -- 纹理特征
    size_category VARCHAR(50), -- 尺寸类别
    distinctive_marks TEXT, -- 特征描述
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 索引创建
-- =============================================

-- 系列表索引
CREATE INDEX idx_labubu_series_active ON labubu_series(is_active);
CREATE INDEX idx_labubu_series_year ON labubu_series(release_year);

-- 模型表索引
CREATE INDEX idx_labubu_models_series ON labubu_models(series_id);
CREATE INDEX idx_labubu_models_active ON labubu_models(is_active);
CREATE INDEX idx_labubu_models_rarity ON labubu_models(rarity_level);
CREATE INDEX idx_labubu_models_number ON labubu_models(model_number);

-- 图片表索引
CREATE INDEX idx_labubu_images_model ON labubu_reference_images(model_id);
CREATE INDEX idx_labubu_images_primary ON labubu_reference_images(is_primary);
CREATE INDEX idx_labubu_images_sort ON labubu_reference_images(sort_order);

-- 价格表索引
CREATE INDEX idx_labubu_prices_model ON labubu_price_history(model_id);
CREATE INDEX idx_labubu_prices_date ON labubu_price_history(recorded_at);

-- 特征表索引
CREATE INDEX idx_labubu_features_model ON labubu_visual_features(model_id);

-- =============================================
-- 视图创建
-- =============================================

-- 完整模型信息视图（包含系列信息）
CREATE VIEW labubu_complete_info AS
SELECT 
    m.id,
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
    s.id as series_id,
    s.name as series_name,
    s.name_en as series_name_en,
    s.release_year
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id
WHERE m.is_active = true AND s.is_active = true;

-- 模型与系列关联视图
CREATE VIEW labubu_models_with_series AS
SELECT 
    m.*,
    s.name as series_name,
    s.name_en as series_name_en,
    s.release_year
FROM labubu_models m
LEFT JOIN labubu_series s ON m.series_id = s.id;

-- =============================================
-- 触发器函数
-- =============================================

-- 更新时间戳触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为需要的表添加更新时间戳触发器
CREATE TRIGGER update_labubu_series_updated_at 
    BEFORE UPDATE ON labubu_series 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_labubu_models_updated_at 
    BEFORE UPDATE ON labubu_models 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_labubu_visual_features_updated_at 
    BEFORE UPDATE ON labubu_visual_features 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 行级安全策略 (RLS)
-- =============================================

-- 启用行级安全
ALTER TABLE labubu_series ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_reference_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE labubu_visual_features ENABLE ROW LEVEL SECURITY;

-- 允许匿名用户读取活跃数据
CREATE POLICY "Allow anonymous read access to active series" ON labubu_series
    FOR SELECT USING (is_active = true);

CREATE POLICY "Allow anonymous read access to active models" ON labubu_models
    FOR SELECT USING (is_active = true);

CREATE POLICY "Allow anonymous read access to images" ON labubu_reference_images
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous read access to prices" ON labubu_price_history
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous read access to features" ON labubu_visual_features
    FOR SELECT USING (true);

-- 允许服务角色完全访问
CREATE POLICY "Allow service role full access to series" ON labubu_series
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Allow service role full access to models" ON labubu_models
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Allow service role full access to images" ON labubu_reference_images
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Allow service role full access to prices" ON labubu_price_history
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Allow service role full access to features" ON labubu_visual_features
    FOR ALL USING (auth.role() = 'service_role');

-- =============================================
-- 示例数据插入
-- =============================================

-- 插入示例系列
INSERT INTO labubu_series (name, name_en, description, release_year, total_models) VALUES
('经典系列', 'Classic Series', 'Labubu的经典造型系列，包含最受欢迎的基础款式', 2019, 12),
('限定系列', 'Limited Edition', '限量发售的特殊版本，具有独特设计和稀有度', 2020, 8),
('节日系列', 'Holiday Series', '为特殊节日设计的主题系列', 2021, 6),
('艺术家合作系列', 'Artist Collaboration', '与知名艺术家合作推出的特别版本', 2022, 4),
('盲盒系列', 'Mystery Box Series', '盲盒形式发售的惊喜系列', 2023, 15);

-- 获取系列ID（用于后续插入模型数据）
-- 注意：在实际使用中，需要先查询获取实际的UUID

-- 示例：插入经典系列的模型（需要替换为实际的series_id）
/*
INSERT INTO labubu_models (series_id, name, name_en, model_number, description, rarity_level, estimated_price_min, estimated_price_max) VALUES
('your-series-uuid-here', '经典粉色Labubu', 'Classic Pink Labubu', 'LB-CL-001', '经典粉色造型，最受欢迎的基础款', 'common', 89.00, 120.00),
('your-series-uuid-here', '经典蓝色Labubu', 'Classic Blue Labubu', 'LB-CL-002', '经典蓝色造型，沉稳大气', 'common', 89.00, 120.00),
('your-series-uuid-here', '经典黄色Labubu', 'Classic Yellow Labubu', 'LB-CL-003', '经典黄色造型，活泼可爱', 'uncommon', 120.00, 180.00);
*/
```

## 3. 环境变量配置

在您的项目中设置以下环境变量：

```bash
# Supabase配置
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_STORAGE_BUCKET=jitata-images
```

## 4. iOS应用配置

更新 `jitata/Config/APIConfig.swift` 文件：

```swift
struct APIConfig {
    // 现有配置...
    
    // Supabase配置
    static let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
    static let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    static let supabaseServiceRoleKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"]
    static let supabaseStorageBucket = ProcessInfo.processInfo.environment["SUPABASE_STORAGE_BUCKET"] ?? "jitata-images"
}
```

## 5. 管理员工具使用

1. 打开 `admin_tool/index.html`
2. 输入Supabase URL和Service Role Key
3. 连接到数据库
4. 开始管理Labubu数据：
   - **系列管理**：添加、编辑、删除Labubu系列
   - **模型管理**：管理具体的Labubu模型
   - **图片管理**：上传和管理参考图片
   - **价格管理**：记录价格历史
   - **数据导入**：批量导入JSON数据

## 6. 数据结构说明

### 系列表 (labubu_series)
- `id`: 唯一标识符
- `name`: 系列名称（中文）
- `name_en`: 系列名称（英文）
- `description`: 系列描述
- `release_year`: 发布年份
- `total_models`: 该系列包含的模型总数
- `is_active`: 是否活跃

### 模型表 (labubu_models)
- `id`: 唯一标识符
- `series_id`: 所属系列ID
- `name`: 模型名称
- `model_number`: 型号
- `rarity_level`: 稀有度（common, uncommon, rare, ultra_rare, secret）
- `estimated_price_min/max`: 估价范围

### 参考图片表 (labubu_reference_images)
- `model_id`: 关联的模型ID
- `image_url`: 图片URL
- `image_type`: 图片类型（front, back, side, detail, package）
- `is_primary`: 是否为主图

### 价格历史表 (labubu_price_history)
- `model_id`: 关联的模型ID
- `price`: 价格
- `currency`: 货币类型
- `source`: 价格来源
- `condition`: 商品状态

## 7. API端点

创建的视图提供以下查询端点：

- `GET /rest/v1/labubu_series` - 获取所有系列
- `GET /rest/v1/labubu_complete_info` - 获取完整模型信息
- `GET /rest/v1/labubu_models_with_series` - 获取模型与系列关联信息
- `GET /rest/v1/labubu_reference_images` - 获取参考图片
- `GET /rest/v1/labubu_price_history` - 获取价格历史

## 8. 安全配置

- 启用了行级安全策略（RLS）
- 匿名用户只能读取活跃数据
- 管理员工具使用Service Role Key进行完全访问
- iOS应用使用Anon Key进行只读访问

## 9. 下一步

1. 执行SQL脚本创建数据库结构
2. 配置环境变量
3. 使用管理员工具添加初始数据
4. 更新iOS应用以使用新的Supabase服务
5. 测试识别功能

## 10. 故障排除

### 常见问题：

1. **连接失败**：检查URL和API密钥是否正确
2. **权限错误**：确保使用了正确的Service Role Key
3. **数据不显示**：检查RLS策略是否正确配置
4. **图片无法显示**：确保图片URL可公开访问

### 调试技巧：

1. 在Supabase控制台查看实时日志
2. 使用浏览器开发者工具检查网络请求
3. 检查数据库表的RLS策略设置
4. 验证API密钥的权限范围 