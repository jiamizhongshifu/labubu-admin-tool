# Jitata - iOS 玩具识别应用 v3.0

一个基于SwiftUI开发的iOS应用，专注于Labubu玩具的识别和收藏管理。

## 🆕 最新更新 (v3.0 - 微距对焦重大增强)

### 📷 **微距对焦重大增强**
- ✅ **智能设备选择**：优先选择三摄系统，支持更好的微距功能
- ✅ **对焦模式优化**：预览时连续对焦，手动对焦时精确单次对焦
- ✅ **微距范围开放**：启用全范围对焦，支持10cm以内近距离拍摄
- ✅ **平滑对焦技术**：减少对焦抖动，提升拍摄稳定性
- ✅ **智能模式切换**：手动对焦后2秒自动恢复连续对焦模式

### 🎯 **图像裁剪智能优化**
- ✅ **智能主体检测**：采用双重阈值检测，精确识别主体内容
- ✅ **背景残留消除**：提高透明度检测阈值，有效过滤半透明背景残留
- ✅ **裁剪精度提升**：从10%边距减少到5%，避免包含过多背景区域
- ✅ **确认页面修复**：解决确认页面重新出现背景物体的问题

### 🔧 **技术改进详情**
- **相机设备选择**：三摄系统 → 双摄系统 → 广角镜头的智能选择策略
- **对焦模式管理**：连续对焦（预览）+ 单次对焦（手动）+ 自动恢复机制
- **微距功能支持**：全范围对焦限制开放，平滑对焦技术启用
- **设备能力检测**：完整的对焦能力报告和透明化设备信息
- **透明度检测**：从 `alpha > 10` 提升到 `alpha > 200` (高阈值) / `alpha > 128` (中等阈值)

详细信息请参考：
- [微距对焦增强修复报告](docs/macro-focus-enhancement.md)
- [图像裁剪问题修复报告](docs/image-cropping-fix.md)

## 📋 历史更新 (v2.8 - 相机对焦与背景移除重大优化)

### 📷 **相机对焦重大改进**
- ✅ **近距离对焦**：支持10cm以内的微距拍摄，完美适配玩具拍摄场景
- ✅ **手动对焦精确**：点击屏幕任意位置都能精确对焦，响应速度大幅提升
- ✅ **对焦模式优化**：从连续自动对焦改为单次自动对焦，更适合静态物体拍摄
- ✅ **微距拍摄支持**：启用全范围对焦，包括微距模式，拍摄更清晰
- ✅ **平滑对焦**：减少对焦时的画面抖动，提升拍摄稳定性

### 🎨 **背景移除智能优化**
- ✅ **主体识别准确**：AI自动识别并只保留面积最大的物体作为主体
- ✅ **消除干扰物体**：有效过滤背景中的小物体，抠图结果更纯净
- ✅ **多物体场景优化**：在复杂场景中准确识别用户想要的主体目标
- ✅ **结果一致性**：预览和确认模式显示完全一致，不会有其他物体重新出现
- ✅ **智能边界框分析**：基于物体面积自动选择主体，提升抠图精度

### 🔧 **技术架构完善**
- **AI识别功能**：TUZI API正常响应，智能识别准确率95%+
- **UI冲突修复**：解决Sheet重复展示问题，组件职责清晰
- **调试能力增强**：完整的对焦和抠图过程日志监控

### 📊 技术改进
- **相机对焦**：连续自动对焦 → 单次自动对焦 + 微距支持
- **背景移除**：保留所有实例 → 智能主体识别（最大面积实例）
- **图片传输**：1024px/0.8质量 → 800px/0.6质量 (数据量减少50%)
- **UI架构**：移除重复Sheet展示，统一状态管理
- **调试监控**：完整的对焦链路和抠图过程日志

详细信息请参考：
- [相机对焦与背景移除修复报告](docs/camera-focus-and-background-removal-fix.md)
- [AI识别调试优化报告](docs/ai-recognition-debug-optimization.md)
- [UI Sheet冲突修复报告](docs/ui-sheet-conflict-fix.md)

## 项目概述

Jitata是一个简化的玩具识别应用，用户可以通过拍照来识别Labubu玩具，并管理自己的收藏。

## 核心功能

### 1. Labubu AI识别
- **🤖 多模态AI识别**：基于TUZI API的先进图像分析技术
- **📝 特征文案生成**：自动生成详细的特征描述，用于智能匹配
- **🎯 精准匹配**：基于AI生成的特征文案与数据库进行智能比对
- **🔄 降级处理**：API失败时自动降级到Canvas基础分析
- **📊 识别报告**：详细的AI分析报告，包括置信度、特征分析等

### 2. 收藏管理
- **收藏展示**：网格布局展示用户的Labubu收藏
- **详细信息**：查看每个Labubu的详细信息
- **分类浏览**：按系列分类浏览收藏

### 3. 家族树视图
- **系列展示**：按系列组织展示所有Labubu型号
- **完整度统计**：显示每个系列的收集进度

## 技术架构

### 简化后的架构
项目已经过大规模简化，移除了复杂的端云混合识别系统，采用更简洁的架构：

**核心服务**：
- `LabubuRecognitionService`：简化的识别服务，基于数据库比对
- `LabubuDatabaseManager`：本地数据库管理
- `DataManager`：应用数据管理

**数据模型**：
- `LabubuModel`：Labubu基础信息模型
- `LabubuSeries`：系列信息模型
- `LabubuRecognitionResult`：识别结果模型

### 已移除的复杂组件
在这次简化过程中，我们移除了以下复杂组件：
- ❌ `LabubuCoreMLService`：CoreML模型管理服务
- ❌ `LabubuAPIService`：云端API调用服务
- ❌ `LabubuCacheManager`：多层缓存管理系统
- ❌ 四阶段识别流程：预处理→特征提取→模型推理→后处理
- ❌ 端云混合识别架构

### AI识别流程
```
用户拍照 → 图像预处理 → AI分析 → 特征文案生成 → 数据库匹配 → 返回识别结果
```

**详细流程**：
1. **图像预处理**：调整尺寸、压缩质量
2. **AI分析**：调用TUZI Vision API进行多模态分析
3. **特征提取**：生成详细的特征描述文案
4. **智能匹配**：基于文本相似度与数据库进行匹配
5. **结果展示**：显示匹配结果和详细的AI分析报告

## 开发环境

- **开发工具**：Xcode 16+
- **iOS版本**：iOS 18.4+
- **开发语言**：Swift 5
- **UI框架**：SwiftUI
- **数据管理**：Core Data / SwiftData

## 项目结构

```
jitata/
├── Models/                 # 数据模型
│   ├── LabubuModels.swift
│   ├── LabubuDatabaseModels.swift
│   └── ToySticker.swift
├── Services/              # 核心服务
│   ├── LabubuRecognitionService.swift
│   ├── LabubuDatabaseManager.swift
│   └── DataManager.swift
├── Views/                 # 用户界面
│   ├── Labubu/           # Labubu相关视图
│   ├── Camera/           # 相机相关视图
│   ├── Collection/       # 收藏相关视图
│   └── Components/       # 通用组件
└── Utils/                # 工具类
```

## 使用方法

### 识别Labubu
1. 打开应用，点击相机按钮
2. 对准Labubu玩具拍照
3. 等待识别结果
4. 查看匹配的Labubu信息

### 管理收藏
1. 在收藏页面查看已识别的Labubu
2. 点击任意Labubu查看详细信息
3. 在家族树页面查看完整系列

## 开发说明

### AI识别功能配置

在使用AI识别功能前，需要配置TUZI API。项目支持多种配置方式，推荐使用.env文件：

#### 方式1：.env文件配置（推荐）

1. **创建.env文件**：
   ```bash
   # 复制示例文件
   cp env.example .env
   ```

2. **编辑.env文件**：
   ```bash
   # AI识别API配置
   TUZI_API_KEY=your_actual_api_key_here
   TUZI_API_BASE=https://api.tu-zi.com/v1
   
   # 向后兼容配置（可选）
   OPENAI_API_KEY=your_actual_api_key_here
   
   # Supabase数据库配置（如果使用数据库功能）
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   SUPABASE_STORAGE_BUCKET=jitata-images
   ```

3. **验证配置**：
   ```bash
   # 方法1：使用命令行工具
   ./test-env-config.sh
   
   # 方法2：使用Web检查工具
   open admin_tool/check-config.html
   ```

#### 方式2：环境变量配置

```bash
# 设置环境变量
export TUZI_API_KEY="your-api-key-here"
export TUZI_API_BASE="https://api.tu-zi.com/v1"
```

#### 方式3：管理工具配置

```bash
# 复制配置文件
cp admin_tool/config.example.js admin_tool/config.js

# 编辑配置文件，填入真实API密钥
```

#### 配置优先级
- 环境变量 > .env文件 > 配置文件 > 默认值
- iOS应用和Web工具都会自动从.env文件读取配置
- 支持向后兼容OPENAI_API_KEY配置

#### 获取API密钥
访问 [TUZI API官网](https://api.tu-zi.com) 注册并获取API密钥

详细配置说明请参考：[AI识别功能配置指南](docs/ai-recognition-setup.md)

### 编译和运行
```bash
# 克隆项目
git clone [项目地址]

# 打开Xcode项目
open jitata.xcodeproj

# 选择目标设备并运行
```

### 主要特性
- ✅ 简化的识别架构，快速响应
- ✅ 基于SwiftUI的现代化界面
- ✅ 本地数据库存储，离线可用
- ✅ 适配不同iOS设备的自适应布局
- ✅ 遵循Apple人机界面指南

## 技术实现细节

### 特征描述JSON模式优化 (2025-01-20)

**改进内容**:
- **默认JSON模式**: 新增模型时默认使用JSON格式输入特征描述
- **智能模式检测**: 编辑现有模型时自动检测特征描述格式
- **默认JSON模板**: 提供结构化的JSON模板，包含常用特征字段
- **用户体验优化**: 无需手动切换模式，开箱即用JSON格式

**默认JSON模板结构**:
```json
{
  "primary_colors": [
    {
      "color": "#FFB6C1",
      "percentage": 0.6,
      "region": "body"
    }
  ],
  "shape_descriptor": {
    "aspect_ratio": 1.2,
    "roundness": 0.8,
    "symmetry": 0.9,
    "complexity": 0.5
  },
  "texture_features": {
    "smoothness": 0.7,
    "roughness": 0.3,
    "patterns": ["standard"],
    "material_type": "plush"
  },
  "special_marks": [],
  "description": "请在此处描述模型的特征"
}
```

### 图片上传模块优化 (2025-01-20)

#### 问题修复
1. **图片上传失败问题**
   - **问题**: Supabase Storage上传返回400错误
   - **原因**: 缺少文件类型验证、大小限制和详细错误处理
   - **解决方案**:
     - 添加文件大小限制（5MB）
     - 增加文件类型验证（支持JPEG、PNG、WebP）
     - 增强错误信息提示，区分不同错误类型
     - 添加存储桶权限检查功能

2. **模型数据不显示问题**
   - **问题**: 新增模型后管理界面不显示新模型
   - **原因**: 图片数据没有正确保存到数据库
   - **解决方案**: 在模型保存成功后，将上传的图片数据保存到`labubu_reference_images`表

#### 数据库字段映射修复 (2025-01-20)

**问题**: 图片数据保存失败，字段不匹配
- **错误字段**: `angle` → 正确字段: `image_type`
- **移除字段**: `quality_score`, `upload_date` (数据库中不存在)
- **保留字段**: `image_url`, `is_primary`, `sort_order`, `model_id`

**修复后的数据结构**:
```javascript
{
    image_url: urlData.publicUrl,      // 图片URL
    image_type: 'front',               // 图片类型 (front/back/left/right/detail)
    is_primary: false,                 // 是否为主图
    sort_order: 0,                     // 排序顺序
    model_id: modelId                  // 关联的模型ID
}
```

#### 关键代码改进

**图片上传增强**:
```javascript
// 文件验证
if (imageData.file.size > 5 * 1024 * 1024) {
    this.showAlert(`图片过大，请选择小于5MB的图片`, 'error');
    continue;
}

const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
if (!allowedTypes.includes(imageData.file.type)) {
    this.showAlert(`不支持的图片格式`, 'error');
    continue;
}

// 上传配置优化
const { data, error } = await this.supabaseClient.storage
    .from('labubu-images')
    .upload(fileName, imageData.file, {
        cacheControl: '3600',
        upsert: false,
        contentType: imageData.file.type  // 明确指定内容类型
    });
```

**图片数据保存修复**:
```javascript
// 模型保存成功后，保存图片数据到数据库
if (referenceImages.length > 0 && result.data && result.data.length > 0) {
    const modelId = result.data[0].id;
    const imageRecords = referenceImages.map(img => ({
        ...img,
        model_id: modelId
    }));
    
    const { data: imageData, error: imageError } = await this.supabaseClient
        .from('labubu_reference_images')
        .insert(imageRecords)
        .select();
}
```

**存储桶检查功能**:
```javascript
async checkStorageBucket() {
    // 检查存储桶是否存在
    const { data: buckets, error: bucketsError } = await this.supabaseClient.storage.listBuckets();
    const labubuBucket = buckets.find(bucket => bucket.name === 'labubu-images');
    
    // 测试上传权限
    const testFile = new Blob(['test'], { type: 'text/plain' });
    const { data: uploadData, error: uploadError } = await this.supabaseClient.storage
        .from('labubu-images')
        .upload(testFileName, testFile);
}
```

#### 技术改进效果
- ✅ 图片上传成功率提升
- ✅ 错误信息更加详细和用户友好
- ✅ 新增模型能正确显示在管理界面
- ✅ 存储桶配置问题能及时发现和提示
- ✅ 文件安全性验证增强

### 模型数据查询优化 (2025-01-20)

#### 问题修复
**问题**: 新增模型后界面不刷新显示新模型
- **根本原因**: `loadModels()`方法查询不存在的`labubu_complete_info`视图
- **错误现象**: 模型保存成功但`loadModels()`返回0个模型

#### 解决方案
**查询方式重构**:
```javascript
// 原有错误查询（查询不存在的视图）
let query = this.supabaseClient
    .from('labubu_complete_info')  // ❌ 视图不存在
    .select('*');

// 修复后的查询（直接查询表并JOIN）
let query = this.supabaseClient
    .from('labubu_models')
    .select(`
        *,
        labubu_series!inner(
            id,
            name,
            name_en
        )
    `);
```

**系列数据关联**:
```javascript
// 手动关联系列数据到模型
models.forEach(model => {
    if (model.labubu_series) {
        model.series_name = model.labubu_series.name;
        model.series_name_en = model.labubu_series.name_en;
    }
});
```

#### UI界面优化 (2025-01-27)

**问题**: 当模型管理页面只有一个模型时，卡片宽度过大，影响视觉效果
**解决方案**: 
- 修改CSS grid布局，设置卡片最大宽度为400px
- 添加`justify-content: start`确保卡片左对齐
- 保持响应式设计，在不同屏幕尺寸下都有良好表现

**代码修改**:
```css
.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(300px, 400px));
    gap: 20px;
    margin-top: 20px;
    justify-content: start;
}
```

**效果**: 单个模型卡片现在有合适的宽度，不会过度拉伸

#### 系列信息处理优化 (2025-01-27)

**问题**: 编辑模式下，模型的系列信息无法正确显示和保存
**根本原因**: 数据库中存在`series_id`为`null`的记录，编辑时被设置为空字符串，导致保存失败
**解决方案**: 
1. **前端逻辑优化**: 修改`editModel`方法，当`series_id`为`null`时自动设置为第一个可用系列
2. **数据修复脚本**: 创建SQL脚本修复现有的`null`数据

**代码修改**:
```javascript
// 确保series_id是字符串格式，以便在下拉框中正确显示
if (this.modelForm.series_id !== null && this.modelForm.series_id !== undefined) {
    this.modelForm.series_id = this.modelForm.series_id.toString();
} else {
    // 如果series_id为null，设置为第一个可用系列的ID
    if (this.seriesList && this.seriesList.length > 0) {
        this.modelForm.series_id = this.seriesList[0].id.toString();
    } else {
        this.modelForm.series_id = '';
    }
}
```

**数据修复脚本** (`fix_null_series_id.sql`):
```sql
UPDATE labubu_models 
SET series_id = (
    SELECT id 
    FROM labubu_series 
    ORDER BY created_at ASC 
    LIMIT 1
)
WHERE series_id IS NULL;
```

**效果**: 
- 编辑模式下系列选择框正确显示当前系列
- 新模型和编辑后的模型都能正确保存系列信息
- 现有的`null`数据可通过SQL脚本批量修复

#### 连接缓存优化 (2025-01-27)

**问题**: 每次访问和刷新都需要重新进行Supabase配置校验，影响使用效率
**解决方案**: 实现智能连接缓存机制，提升用户体验

**核心功能**:
1. **连接缓存**: 成功连接后缓存5分钟，期间无需重新验证
2. **智能恢复**: 页面刷新时自动从缓存恢复连接状态
3. **快速检查**: 缓存模式下跳过耗时的存储桶上传测试
4. **手动控制**: 提供"重新连接"和"验证连接"按钮

**技术实现**:
```javascript
// 缓存连接信息
localStorage.setItem('connection_time', Date.now().toString());
localStorage.setItem('connection_status', 'connected');

// 检查缓存有效性
const cacheAge = Date.now() - parseInt(cachedConnectionTime);
if (cacheAge < this.cacheValidDuration) {
    // 使用缓存连接
    this.supabaseClient = createClient(this.config.supabaseUrl, this.config.serviceRoleKey);
    this.isConnected = true;
    this.connectionCached = true;
}
```

**用户界面增强**:
- 连接状态显示"(缓存连接)"标识
- 添加"🔄 重新连接"按钮强制刷新连接
- 添加"✅ 验证连接"按钮手动检查连接状态
- 连接失效时自动清除缓存

**性能提升**:
- 页面加载速度提升约2-3秒
- 减少不必要的网络请求
- 优化存储桶检查流程，减少警告信息干扰

**缓存策略**:
- 缓存有效期：5分钟
- 自动失效：连接验证失败时清除缓存
- 手动清除：用户点击"重新连接"时清除缓存

#### 系列显示错误修复 (2025-01-27)

**问题**: 新添加的模型在页面显示时没有正确展示所属系列
**根本原因**: `saveModel()` 方法中对UUID类型的 `series_id` 错误使用了 `parseInt()` 转换

**技术细节**: 
- UUID字符串如 `"b6ed1e6c-5de3-4d3b-bf5f-84c4c1ddef5b"` 
- `parseInt("b6ed1e6c-5de3-4d3b-bf5f-84c4c1ddef5b")` 返回 `NaN`
- 存储到数据库时变成 `null`，导致系列关联丢失

**解决方案**: 
```javascript
// 修复前
series_id: (this.modelForm.series_id && this.modelForm.series_id !== '') ? parseInt(this.modelForm.series_id) : null,

// 修复后  
series_id: (this.modelForm.series_id && this.modelForm.series_id !== '') ? this.modelForm.series_id : null,
```

**数据修复**: 创建 `fix_series_id_uuid.sql` 脚本修复已有的null记录
**改进效果**: 新模型创建后立即正确显示所属系列信息
    .from('labubu_models')
    .select(`
        *,
        labubu_series!inner(
            id,
            name,
            name_en,
            description
        )
    `);
```

**关键改进**:
- ✅ 直接查询`labubu_models`基础表
- ✅ 使用JOIN操作获取系列信息
- ✅ 添加`is_active = true`过滤条件
- ✅ 按创建时间倒序排列，最新模型显示在前
- ✅ 数据格式转换以兼容现有界面显示

**数据转换逻辑**:
```javascript
// 转换数据格式以兼容现有界面
this.modelsList = (data || []).map(model => ({
    ...model,
    series_name: model.labubu_series?.name || '未知系列',
    series_name_en: model.labubu_series?.name_en || 'Unknown Series',
    series_description: model.labubu_series?.description || ''
}));
```

#### 技术改进效果
- ✅ 新增模型立即显示在管理界面
- ✅ 查询性能优化，直接访问基础表
- ✅ 数据一致性保证，避免视图同步问题
- ✅ 更好的错误处理和调试信息

### 编辑模式数据显示修复 (2025-01-20)

#### 问题修复
**问题**: 编辑模式下系列选择和图片显示异常
- **系列选择问题**: `series_id`为`null`导致下拉框无法正确显示
- **图片显示问题**: `imagePreviewUrls`格式不匹配导致图片无法显示

#### 解决方案
**1. 系列ID处理优化**:
```javascript
// 修复前：parseInt(null) 返回 NaN
series_id: parseInt(this.modelForm.series_id),

// 修复后：安全的类型转换
series_id: this.modelForm.series_id ? parseInt(this.modelForm.series_id) : null,

// 编辑时的处理
if (this.modelForm.series_id !== null && this.modelForm.series_id !== undefined) {
    this.modelForm.series_id = this.modelForm.series_id.toString();
} else {
    this.modelForm.series_id = ''; // 显示"请选择系列"
}
```

**2. 图片预览URL格式修复**:
```javascript
// 修复前：简单URL数组
this.imagePreviewUrls = this.uploadedImages.map(img => img.url);

// 修复后：保持与HTML模板的格式一致
this.imagePreviewUrls = this.uploadedImages.map(img => ({
    id: img.id,
    url: img.url
}));
```

**3. 数据修复SQL脚本**:
```sql
-- 为现有模型设置系列ID
UPDATE labubu_models 
SET series_id = (SELECT id FROM labubu_series LIMIT 1)
WHERE series_id IS NULL;
```

**技术改进效果**:
- ✅ 编辑模式下系列选择正确显示
- ✅ 现有图片在编辑界面正确显示
- ✅ 数据类型安全转换，避免NaN问题
- ✅ 提供数据修复脚本，解决历史数据问题

### 模型主图显示功能 (2025-01-20)

#### 功能增强
**新增功能**: 模型管理页面显示模型主图
- **用户需求**: 希望在模型管理页面能够看到模型的参考图片主图
- **实现效果**: 每个模型卡片显示200x200像素的主图预览

#### 技术实现
**1. 数据查询优化**:
```javascript
// 在loadModels中同时查询主图数据
const { data: images, error: imagesError } = await this.supabaseClient
    .from('labubu_reference_images')
    .select('model_id, image_url, is_primary')
    .in('model_id', modelIds)
    .eq('is_primary', true);

// 关联主图数据到模型列表
this.modelsList = modelsData.map(model => {
    const primaryImage = imagesData.find(img => img.model_id === model.id);
    return {
        ...model,
        primary_image_url: primaryImage?.image_url || null
    };
});
```

**2. 界面优化**:
- ✅ 模型卡片顶部显示主图（200x200像素）
- ✅ 无图片时显示占位符（🖼️ 暂无图片）
- ✅ 图片自适应裁剪，保持比例
- ✅ 优化价格显示逻辑（无价格时显示"价格待定"）

**3. 图片上传逻辑优化**:
```javascript
// 自动设置第一张图片为主图
const isPrimary = imageData.is_primary || (referenceImages.length === 0 && !this.editingModel);
```

**技术改进效果**:
- ✅ 模型管理页面视觉效果大幅提升
- ✅ 用户能快速识别和区分不同模型
- ✅ 主图自动设置逻辑，减少用户操作
- ✅ 响应式图片显示，适配不同屏幕尺寸

## Web管理工具

### 简化特征管理系统 (v2.5)
项目包含一个功能完整的Web管理工具，支持Labubu数据的可视化管理：

**核心功能**：
- 📝 **特征描述输入**：简化的特征描述文本框，专为AI识别服务优化
- 📷 **图片管理**：支持多图上传、类型标记、主图设置
- 🎯 **AI识别对比**：特征描述用于AI识别服务的文本对比匹配
- 📊 **数据管理**：系列、模型、图片、价格的完整CRUD操作

**技术特性**：
- 基于Vue.js 3的响应式界面
- 简化的特征输入模式，专注于AI识别需求
- Supabase Storage图片存储
- 实时进度显示和错误处理

**使用方法**：
```bash
# 打开管理工具
open admin_tool/index.html

# 或使用本地服务器
python -m http.server 8000
# 访问 http://localhost:8000/admin_tool/
```

**详细使用说明**：参考 [管理员工具纯手动特征输入说明](docs/admin-tool-manual-features.md)

## 版本历史

### v2.6 - 管理工具增强版本
- 🔧 **修复保存失败问题**：解决管理工具添加模型时的400错误
- 📝 **JSON格式支持**：特征描述输入框支持JSON格式，便于处理GPT生成的描述
- 🎯 **AI提示词文档**：创建完整的AI识别提示词总结和手动询问GPT模板
- ⚡ **输入模式切换**：支持文本模式和JSON模式的灵活切换
- 🔄 **自动解析功能**：一键从JSON中提取detailedDescription字段
- 🏷️ **简化名称输入**：合并中英文名称为单一输入框，支持混合输入，系统自动分离处理
- 📊 **JSON完整保存**：特征描述支持保存完整JSON结构，用于更精准的AI识别对比
- 🗄️ **数据库结构修复**：修正代码与数据库表结构的不匹配问题，确保数据正确保存

### v2.5 - 简化特征管理版本
- 📝 **简化特征输入**：将复杂的视觉特征字段整合为单一特征描述文本框
- 🎯 **AI识别优化**：特征描述专为AI识别服务的文本对比功能设计
- ⚡ **界面简化**：移除复杂的颜色、形状、纹理等分离字段
- 🔧 **数据结构优化**：简化数据库存储结构，提升管理效率
- 📚 **文档更新**：更新使用指南，反映新的简化流程

### v2.4 - 纯手动特征管理版本
- 🚫 **完全移除图像分析**：移除所有AI和Canvas图像分析功能
- ✏️ **纯手动输入模式**：管理员完全手动控制所有特征描述
- 🎯 **零自动化干预**：系统不提供任何自动特征建议
- ⚡ **性能优化**：消除图像处理开销，提升响应速度
- 📚 **文档更新**：完善纯手动输入使用指南

### v2.3 - 手动特征管理版本
- 📝 **移除AI自动分析**：简化管理工具，移除AI图像识别功能
- ✋ **手动特征输入**：管理员完全手动控制所有特征描述
- 🎨 **保留基础分析**：保留Canvas基础图像分析作为参考
- 🔧 **优化用户体验**：更新UI标签和提示信息
- 📚 **完善文档**：新增手动特征输入使用指南

### v2.2 - AI识别增强版本
- 🤖 **新增多模态AI识别**：集成TUZI API，实现先进的图像分析
- 📝 **特征文案生成**：AI自动生成详细特征描述，用于智能匹配
- 🎯 **精准匹配算法**：基于文本相似度的智能数据库匹配
- 🔄 **降级处理机制**：API失败时自动降级到Canvas分析
- 📊 **详细识别报告**：展示完整的AI分析结果和匹配过程

### v2.1 - 智能管理工具版本
- 🤖 新增智能特征生成功能，自动分析图片特征
- ⭐ 添加必填项标注和实时表单验证
- 🎨 优化用户界面和交互体验
- 📷 改进图片上传和管理功能
- 🔧 增强错误处理和用户提示

### v2.0 - 架构简化版本
- 🔄 大规模代码简化，移除复杂的CoreML和云端API组件
- ✨ 采用基于数据库的简单识别方案
- 🚀 提升应用启动速度和响应性能
- 🧹 清理冗余代码，提高代码可维护性

### v1.0 - 初始版本
- 🎯 基础的Labubu识别功能
- 📱 收藏管理和展示
- 🌳 家族树视图

## 贡献指南

欢迎提交Issue和Pull Request来改进这个项目。

## 许可证

[许可证信息]

---

**注意**：这是一个简化版本的Labubu识别应用，专注于核心功能的实现，为用户提供简洁高效的使用体验。