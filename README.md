# Jitata - 潮玩虚拟图鉴应用

## 项目简介
Jitata是一款创新的潮玩收集应用，用户可以通过拍照来收集喜爱的潮流玩具，应用会自动提取画面主体，去除背景，制作成精美的潮玩贴纸，形成专属的虚拟潮玩图鉴。

## 核心功能

### 1. 智能拍照收集 📸
- **拍照功能**：用户可以拍摄潮流玩具
- **智能抠图**：利用iOS VisionKit自动提取画面主体，去除背景
- **贴纸制作**：将抠图后的潮玩制作成精美贴纸效果
- **即时预览**：实时预览抠图效果，支持手动调整

### 2. 我的潮玩图鉴 📚
- **分类管理**：按品牌、系列、类型等维度分类管理
- **搜索功能**：快速查找特定潮玩
- **详情查看**：查看潮玩详细信息和收集时间
- **统计展示**：显示收集进度和统计数据

## 技术架构

### 开发环境
- **语言**：Swift 5.9+
- **框架**：SwiftUI
- **最低版本**：iOS 16.0+
- **开发工具**：Xcode 15.0+

### 核心技术
- **VisionKit**：背景移除和图像处理
- **SwiftData**：本地数据存储
- **Camera API**：拍照功能
- **Core Image**：图像特效和处理
- **PhotosUI**：相册访问

### 项目结构
```
jitata/
├── App/
│   ├── jitataApp.swift           # 应用入口
│   └── ContentView.swift         # 主视图
├── Views/
│   ├── Camera/
│   │   ├── CameraView.swift      # 相机界面
│   │   └── PhotoCaptureView.swift # 拍照处理
│   ├── Collection/
│   │   ├── CollectionView.swift   # 图鉴主界面
│   │   ├── StickerDetailView.swift # 贴纸详情
│   │   └── CategoryView.swift     # 分类视图
│   └── Components/
│       ├── StickerCard.swift     # 贴纸卡片组件
│       └── CategorySelector.swift # 分类选择器
├── Models/
│   ├── ToySticker.swift          # 潮玩贴纸数据模型
│   └── Category.swift            # 分类数据模型
├── Services/
│   ├── VisionService.swift       # VisionKit服务
│   ├── ImageProcessor.swift      # 图像处理服务
│   └── DataManager.swift         # 数据管理服务
└── Resources/
    └── Assets.xcassets/          # 图片资源
```

## 开发计划

### Phase 1: 基础架构 ✅
- [x] 项目初始化
- [x] 数据模型设计 (ToySticker, Category)
- [x] 基础UI架构 (TabView双页面结构)

### Phase 2: 拍照功能 ✅
- [x] 相机界面实现 (CameraView)
- [x] VisionKit集成 (VisionService)
- [x] 背景移除功能 (iOS原生VisionKit + Vision框架降级)
- [x] 贴纸效果制作 (ImageProcessor)

### Phase 3: 图鉴功能 ✅
- [x] 图鉴展示界面 (CollectionView)
- [x] 分类管理 (Category模型 + 默认分类)
- [x] 搜索功能 (DataManager搜索方法)
- [x] 数据持久化 (SwiftData + DataManager)

### Phase 4: 优化完善 🔄
- [x] 基础错误处理
- [x] 数据管理服务
- [ ] 性能优化
- [ ] UI/UX改进
- [ ] 用户引导

## 功能特色

### VisionKit背景移除
- 使用iOS原生VisionKit模块实现精准抠图
- 与Capwords和苹果自带抠图保持一致的用户体验
- 支持实时预览和手动调整
- 高质量的边缘检测和处理

### 智能分类系统
- 自动识别潮玩类型（可选功能）
- 支持自定义分类标签
- 多维度分类展示
- 智能推荐相似潮玩

### 贴纸效果
- 多种贴纸边框样式
- 阴影和光效处理
- 支持自定义贴纸样式
- 高清输出保存

## 用户体验设计

### 界面设计原则
- 简洁现代的设计风格
- 直观的操作流程
- 流畅的动画效果
- 适配深色模式

### 交互设计
- 一键拍照收集
- 手势操作支持
- 即时反馈
- 无障碍访问支持

## 数据隐私
- 所有数据本地存储
- 不上传用户照片
- 符合Apple隐私准则
- 用户完全控制数据

## 版本历史
- **v1.0.0** (已完成核心功能) - 基础拍照和图鉴功能
  - ✅ 智能拍照收集 (VisionKit背景移除)
  - ✅ 我的潮玩图鉴 (分类管理、搜索、收藏)
  - ✅ 数据持久化 (SwiftData)
  - ✅ 贴纸效果制作

---

## 开发者
**钟庆标** - iOS开发工程师

## 许可证
版权所有 © 2025 jitata项目组 