# Jitata - iOS 玩具识别应用

一个基于SwiftUI开发的iOS应用，专注于Labubu玩具的识别和收藏管理。

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