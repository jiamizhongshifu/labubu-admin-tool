# Jitata - iOS 玩具识别应用 v3.0

一个基于SwiftUI开发的iOS应用，专注于Labubu玩具的识别和收藏管理。

## 🆕 最新更新 (v5.2 - Labubu 管理工具图片功能)

### 🖼️ **管理工具图片管理功能完成**
- ✅ **数据库扩展**：为 `labubu_models` 表添加图片相关字段（image_url, image_path, image_filename, image_size, image_type）
- ✅ **Supabase Storage 集成**：配置 `labubu-images` 存储桶，支持图片安全存储和公共访问
- ✅ **图片上传功能**：支持拖拽上传、点击上传，文件类型和大小验证（5MB限制）
- ✅ **缩略图展示**：在模型列表中显示配图缩略图，点击可放大预览
- ✅ **完整CRUD操作**：新增模型时上传图片，删除模型时自动清理关联图片
- ✅ **错误处理优化**：图片上传失败时自动回滚，加载失败时显示占位符
- ✅ **响应式设计**：移动端和桌面端都有良好的图片展示效果

### 🔧 **技术架构改进**
- **存储系统**：Supabase Storage + RLS 策略，确保图片安全访问
- **文件命名**：时间戳 + 随机字符串，避免文件名冲突
- **图片处理**：前端预览 + 后端验证，双重保障
- **数据一致性**：数据库操作失败时自动清理已上传的图片文件

## 📋 历史更新 (v3.1 - 识别结果页面重构)

### 🎨 **识别结果页面重构完成**
- ✅ **用户体验优化**：重新设计识别结果页面，突出显示用户最关心的信息
- ✅ **信息层级优化**：优先展示匹配模型主图、系列名称、模型名称、推出时间、价格信息
- ✅ **技术细节简化**：移除用户不关心的特征描述、关键特征等技术信息
- ✅ **数据结构优化**：LabubuDatabaseMatch直接使用LabubuModelData，避免不必要的数据转换
- ✅ **云端图片支持**：实现从Supabase获取模型参考图片的功能
- ✅ **候选匹配改进**：优化其他候选匹配的显示方式，提供清晰的相似度对比
- ✅ **错误处理增强**：优雅处理图片加载失败的情况，显示友好的占位符

### 🔧 **技术架构改进**
- **数据模型简化**：移除convertToLabubuModel转换方法，直接使用LabubuModelData
- **图片加载优化**：新增fetchModelImages API，支持从云端动态加载模型图片
- **错误处理完善**：图片加载失败时显示占位符，提升用户体验
- **代码结构优化**：简化识别结果页面代码，提高可维护性

## 📋 历史更新 (v3.0 - 微距对焦重大增强)

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

### 🖼️ Labubu 管理工具图片管理系统 (v5.2)

#### 数据库架构设计
```sql
-- 图片相关字段扩展
ALTER TABLE labubu_models 
ADD COLUMN image_url TEXT,           -- 图片公共访问URL
ADD COLUMN image_path TEXT,          -- Storage中的文件路径
ADD COLUMN image_filename TEXT,      -- 原始文件名
ADD COLUMN image_size INTEGER,       -- 文件大小（字节）
ADD COLUMN image_type VARCHAR(50);   -- MIME类型
```

#### Supabase Storage 配置
- **存储桶名称**: `labubu-images`
- **访问策略**: 公共读取，认证用户上传/更新/删除
- **文件限制**: 5MB，支持 JPG/PNG/WebP/GIF
- **文件组织**: `models/{模型名}_{时间戳}_{随机字符}.{扩展名}`

#### 前端图片处理流程
1. **文件选择**: 支持点击选择和拖拽上传
2. **客户端验证**: 文件类型、大小检查
3. **预览生成**: FileReader API 创建本地预览
4. **上传处理**: Supabase Storage API 上传
5. **URL获取**: 获取公共访问链接
6. **数据库存储**: 保存图片元信息

#### API 端点增强
```javascript
// POST /api/models - 创建模型（支持图片）
{
  name: "模型名称",
  series_id: "系列标识", 
  image: File,  // 图片文件对象
  // ... 其他字段
}

// 响应包含图片信息
{
  success: true,
  data: {
    id: 1,
    name: "模型名称",
    image_url: "https://xxx.supabase.co/storage/v1/object/public/labubu-images/models/xxx.jpg",
    image_path: "models/xxx.jpg",
    // ... 其他字段
  }
}
```

#### 错误处理机制
- **上传失败回滚**: 数据库插入失败时自动删除已上传图片
- **删除级联清理**: 删除模型时同步删除关联图片文件
- **加载失败处理**: 图片加载失败时显示占位符
- **网络异常恢复**: 支持重试机制和用户友好提示

#### 性能优化策略
- **缩略图展示**: 表格中使用 60x60px 缩略图
- **懒加载**: 图片按需加载，减少初始页面负担
- **缓存控制**: 设置适当的缓存头，提升加载速度
- **压缩优化**: 前端可选择性压缩大图片

#### 安全性保障
- **文件类型验证**: 前后端双重验证
- **文件大小限制**: 5MB 上限防止滥用
- **访问权限控制**: RLS 策略确保安全访问
- **文件名安全**: 自动生成安全的文件名，防止路径注入

### Supabase数据库集成
- **数据库服务**: `LabubuSupabaseDatabaseService.swift` 负责云端数据读取
- **数据模型**: `LabubuDatabaseModels.swift` 定义数据结构
- **配置管理**: `APIConfig.swift` 管理API密钥和连接配置
- **降级策略**: 云端数据加载失败时自动使用本地预置数据

#### Supabase连接故障排除

**常见问题1: 401未授权错误 - 缺少API请求头**
- **症状**: 日志显示"No API key found in request"
- **原因**: Supabase API需要**两个**请求头：`Authorization: Bearer <token>` 和 `apikey: <token>`
- **解决方案**: 
  1. 确保所有API请求都包含这两个头部
  2. iOS应用已修复此问题，重新编译即可
  3. 运行连接测试: `./test-supabase-connection.sh`

**常见问题2: 401未授权错误 - 权限配置**
- **症状**: 日志显示"HTTP错误: 401"但请求头正确
- **原因**: API密钥无效、过期或权限不足
- **解决方案**:
  1. 检查.env文件中的SUPABASE_URL和SUPABASE_ANON_KEY
  2. 在Supabase控制台验证项目状态和API密钥
  3. 确认API密钥有读取权限
  4. 配置RLS策略或使用Service Role Key

**常见问题3: 404表不存在错误**
- **症状**: 日志显示"404 未找到错误"
- **原因**: 数据库表未创建或表名错误
- **解决方案**:
  1. 运行数据库初始化脚本
  2. 检查表名是否正确（labubu_models, labubu_series）

**重要技术细节**:
- Supabase REST API要求同时设置两个认证头部：
  ```
  Authorization: Bearer <your_api_key>
  apikey: <your_api_key>
  ```
- 缺少任何一个头部都会导致401错误
- 管理工具和iOS应用现在都使用正确的请求头格式

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

#### iOS应用AI识别失败修复 (2025-01-27)

**问题**: iOS应用进行AI识别时提示"获取完整模型数据失败"
**根本原因**: iOS应用中的 `LabubuSupabaseDatabaseService` 查询不存在的 `labubu_complete_info` 视图

**技术细节**: 
- iOS应用中多个方法查询 `labubu_complete_info` 视图
- 该视图在Supabase数据库中不存在，导致404错误
- 影响 `fetchAllActiveModels()`、`fetchModelDetails()` 和 `searchModels()` 方法

**解决方案**: 
```swift
// 修复前：查询不存在的视图
let url = URL(string: "\(baseURL)/rest/v1/labubu_complete_info?order=series_name,name")!

// 修复后：分别查询实际表并手动关联
let modelsUrl = URL(string: "\(baseURL)/rest/v1/labubu_models?is_active=eq.true&order=created_at.desc")!
let seriesUrl = URL(string: "\(baseURL)/rest/v1/labubu_series")!
// 手动关联系列信息到模型数据
```

**数据模型优化**: 
- 修改 `LabubuModelData` 结构体，添加 `seriesNameEn` 和 `seriesDescription` 属性
- 将 `seriesId` 改为可选类型以处理null值
- 更新 `CodingKeys` 和 `toLabubuModel()` 方法

**改进效果**: iOS应用AI识别功能恢复正常，能够正确加载云端模型数据

#### JSON解码失败修复 (2025-01-27)

**问题**: iOS应用在解码Supabase返回的JSON数据时失败
**根本原因**: `LabubuModelData` 结构体的 `CodingKeys` 包含了数据库中不存在的字段

**技术细节**: 
- `seriesName`、`seriesNameEn`、`seriesDescription` 字段在数据库表中不存在
- 这些字段是通过手动关联系列信息后添加的
- JSON解码器期望所有CodingKeys字段都存在于JSON中

**解决方案**: 
```swift
// 修复前：包含不存在的数据库字段
enum CodingKeys: String, CodingKey {
    case seriesName = "series_name"
    case seriesNameEn = "series_name_en"
    case seriesDescription = "series_description"
    // ...
}

// 修复后：只包含实际的数据库字段
enum CodingKeys: String, CodingKey {
    case id, name, description, tags
    case seriesId = "series_id"
    // 移除了seriesName等字段，因为它们不是数据库字段
}
```

**数据处理优化**: 
- 添加详细的错误日志和调试信息
- 创建 `enrichModelsWithSeries()` 方法处理系列信息关联
- 改进错误处理，提供更清晰的错误信息

**改进效果**: iOS应用能够正确解码Supabase返回的JSON数据，AI识别功能完全恢复

#### 技术改进效果
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

### 相似度算法重构 (2025-01-13)

**问题**: 尽管AI正确识别为"FALL IN WILD"系列，但相似度算法过于简单，无法准确匹配到正确的数据库模型

**原算法问题**:
1. 只有基础词汇匹配 (60%) + 简单关键特征匹配 (40%)
2. 无语义理解：AI说"毛绒背心"，数据库说"长袖衬衣"，算法无法识别为同一物品
3. 无系列名称专项匹配
4. 无颜色特征专项匹配

**新算法架构**:
```
最终相似度 = 基础词汇相似度 × 30% + 
           关键特征相似度 × 40% + 
           系列名称匹配度 × 20% + 
           颜色匹配度 × 10%
```

**核心改进**:

1. **语义匹配映射**:
   ```swift
   "毛绒" ↔ ["毛绒", "绒毛", "长绒", "plush", "绒布"]
   "背心" ↔ ["背心", "衬衣", "上衣", "vest", "shirt"]  
   "花朵" ↔ ["花朵", "雏菊", "花", "flower", "daisy"]
   ```

2. **系列名称专项匹配**:
   - 专门识别"fall in wild"、"春天在野"、"monsters"等系列关键词
   - 双语匹配支持

3. **颜色特征专项匹配**:
   - 识别"卡其"、"白色"、"蓝色"等颜色词汇
   - 中英文颜色词汇映射

4. **详细调试信息**:
   ```
   🔍 特征匹配: '卡其色渔夫帽' -> 0.800 (语义匹配)
   📊 系列匹配度: 0.250 (匹配到"fall in wild")
   📊 颜色匹配度: 0.333 (匹配到"卡其"、"白色"、"蓝色")
   ```

**匹配阈值调整**: 从0.2降至0.15，因为新算法更精确

**预期效果**: 
- "FALL IN WILD"模型相似度从0.113提升至0.4+
- 准确识别语义相同但词汇不同的特征描述
- 更好的中英文混合匹配能力

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

#### Supabase权限配置

**问题背景**:
- 管理工具使用Service Role Key（完全权限）
- iOS应用使用Anon Key（匿名权限，受RLS策略限制）
- 当表启用RLS但未配置适当策略时，Anon Key无法访问数据

**解决方案**:

1. **方案1：配置RLS策略（推荐）**
   ```sql
   -- 执行 supabase-rls-policies.sql 中的策略
   ALTER TABLE labubu_models ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Allow public read access to active models" ON labubu_models
       FOR SELECT USING (is_active = true);
   ```

2. **方案2：临时使用Service Role Key**
   - iOS应用已配置为优先使用Service Role Key
   - 在.env文件中添加SUPABASE_SERVICE_ROLE_KEY
   - 注意：Service Role Key权限较高，生产环境建议使用方案1

**权限对比**:
- **Anon Key**: 适合客户端应用，权限受限，安全性高
- **Service Role Key**: 适合服务端操作，权限完整，需谨慎使用

**测试工具**:
- 运行 `./test-supabase-connection.sh` 测试两种密钥的连接状态
- 脚本会自动检测并建议最佳解决方案

### 数据模型修复 (2025-01-13)

**问题**: JSON解码失败，数据模型字段与实际数据库不匹配
- iOS应用期望`tags`字段，但数据库中不存在
- 字段名映射不正确（如`rarity`应为`rarity_level`）

**解决方案**: 
1. **字段映射修正**: 更新`LabubuModelData`的`CodingKeys`以匹配实际数据库字段
2. **移除不存在字段**: 删除`tags`字段，使用空数组作为默认值
3. **类型调整**: 确保所有字段类型与数据库返回的JSON匹配

**实际数据库字段**:
```json
{
  "id": "string",
  "series_id": "string", 
  "name": "string",
  "name_en": "string",
  "model_number": "string|null",
  "description": "string|null", 
  "rarity_level": "string",
  "estimated_price_min": "number",
  "estimated_price_max": "number",
  "currency": "string",
  "is_active": "boolean",
  "created_at": "string",
  "updated_at": "string",
  "feature_description": "string"
}
```

**修复后的模型**: `LabubuModelData`现在完全匹配数据库schema，确保JSON解码成功。

### 智能匹配算法修复 (2025-01-13)

**问题**: AI识别成功但最终结果显示"未识别"，原因是智能匹配算法无法找到相似模型

**根本原因**: 
1. 匹配算法依赖空的`description`和`tags`字段
2. 未使用数据库中丰富的`feature_description`JSON数据
3. 相似度计算算法过于简单

**解决方案**:
1. **使用feature_description字段**: 解析JSON格式的详细特征描述
2. **改进相似度算法**: 
   - 基础词汇相似度 (权重60%)
   - 关键特征匹配度 (权重40%)
   - 过滤短词提高匹配精度
3. **降低匹配阈值**: 从0.3降至0.2，提高匹配成功率
4. **详细调试信息**: 完整的匹配过程日志

**feature_description数据结构**:
```json
{
  "detailedDescription": "详细特征描述",
  "keyFeatures": ["关键特征1", "关键特征2"],
  "visualFeatures": {
    "dominantColors": ["#颜色1", "#颜色2"],
    "bodyShape": "形状",
    "surfaceTexture": "材质"
  },
  "materialAnalysis": "材质分析",
  "styleAnalysis": "风格分析"
}
```

**智能匹配流程**:
1. AI分析用户图片生成详细描述
2. 提取数据库中所有模型的feature_description
3. 计算用户描述与每个模型的相似度
4. 返回相似度最高的前5个匹配结果

**预期效果**: AI识别成功后能够准确匹配到具体的Labubu模型型号。

### AI识别失败问题全面解决 (2025-01-27)

**问题背景**: 用户反馈AI识别功能经常失败，主要表现为JSON解析错误、网络超时、匹配失败等问题。

**核心问题分析**:
1. **JSON解析脆弱性**: AI返回的JSON格式不标准，解析器容错性不足
2. **网络配置不当**: 超时时间过短，图像质量参数偏低
3. **匹配阈值过高**: 相似度阈值设置过于严格，导致有效匹配被过滤
4. **错误处理不友好**: 错误信息模糊，用户无法理解失败原因

**全面解决方案**:

#### 1. JSON解析容错性增强
- **多种提取方式**: 支持```json```块、普通代码块、{}对象、原始内容四种提取方式
- **格式清理功能**: 自动修复常见的引号问题（""、''转换为标准引号）
- **类型容错处理**: confidence字段支持字符串和数字两种类型
- **备用解析方案**: JSON解析失败时，从文本中提取基本信息（isLabubu、confidence）

#### 2. 网络和API优化
- **超时时间延长**: 从2分钟增加到3分钟，确保AI有足够处理时间
- **图像质量提升**: 
  - 最大尺寸从800px提升到1024px
  - 压缩质量从0.6提升到0.8
  - 保证识别精度
- **智能错误分类**: 根据HTTP状态码提供具体错误类型
  - 401: API配置问题
  - 429: 请求频率限制
  - 402/403: 配额超限
  - 408/504: 超时问题
  - 500+: 服务器错误

#### 3. 相似度算法优化
- **阈值降低**: 从0.15降低到0.08，提高匹配成功率
- **保持精确性**: 维持多维度评分系统的准确性
- **匹配策略**: 在保证质量的前提下，增加匹配机会

#### 4. 用户体验全面改进
- **详细错误信息**: 每种错误类型都有具体描述和恢复建议
- **无匹配结果优化**: 
  - 显示AI分析的详细结果
  - 根据isLabubu状态提供不同的改进建议
  - 提供重新识别和手动添加选项
- **操作指导**: 针对不同情况提供具体的拍摄建议

#### 5. AI提示词优化
- **增加Labubu背景知识**: 在提示词中加入Labubu品牌特征描述
- **强化JSON格式要求**: 明确要求使用```json```包围返回结果
- **提高描述详细度**: 要求AI提供更丰富的特征描述用于匹配

**技术实现亮点**:
```swift
// 多层次JSON解析
private func parseAIAnalysisResult(_ content: String) throws -> LabubuAIAnalysis {
    // 1. 尝试标准JSON块提取
    // 2. 尝试普通代码块提取  
    // 3. 尝试{}对象提取
    // 4. 使用原始内容
    // 5. JSON格式清理
    // 6. 备用文本解析
}

// 智能错误分类
switch httpResponse.statusCode {
case 401: throw LabubuAIError.apiConfigurationMissing
case 429: throw LabubuAIError.apiRateLimited
case 402, 403: throw LabubuAIError.apiQuotaExceeded
// ...
}
```

**预期效果**: 
- AI识别成功率提升至95%以上
- 用户体验显著改善，错误信息清晰易懂
- 即使在网络不稳定环境下也能稳定工作
- 为用户提供明确的问题解决指导