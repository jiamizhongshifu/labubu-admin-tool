# 🚀 Labubu CoreML模型快速开始指南

## 📋 概述

本指南将帮助你快速将训练好的CoreML模型集成到Jitata应用中，实现Labubu系列识别功能。

## 🎯 准备工作

### 1. 确保你有以下模型文件：
```
LabubuQuickClassifier.mlmodel      # 快速二分类模型 (<2MB)
LabubuFeatureExtractor.mlmodel     # 特征提取模型 (<10MB)  
LabubuAdvancedClassifier.mlmodel   # 高级分类模型 (<20MB)
```

### 2. 安装验证工具（可选）：
```bash
pip install coremltools
```

## 🔧 添加步骤

### 步骤1: 验证模型（推荐）
```bash
cd jitata/MLModels
python3 validate_models.py /path/to/your/models/
```

### 步骤2: 复制模型文件
```bash
cd jitata/MLModels
./add_models.sh /path/to/your/models/
```

### 步骤3: 添加到Xcode项目
1. 在Xcode中打开 `jitata.xcodeproj`
2. 右键点击项目根目录 `jitata`
3. 选择 **"Add Files to 'jitata'"**
4. 导航到 `jitata/MLModels/` 目录
5. 选择所有 `.mlmodel` 文件：
   - `LabubuQuickClassifier.mlmodel`
   - `LabubuFeatureExtractor.mlmodel`
   - `LabubuAdvancedClassifier.mlmodel`
6. 确保 **"Add to target"** 勾选了 `jitata`
7. 点击 **"Add"**

### 步骤4: 验证集成
1. 重新编译项目 (`Cmd+B`)
2. 运行应用 (`Cmd+R`)
3. 查看控制台输出，应该看到：
```
✅ 成功从Bundle加载模型: LabubuQuickClassifier
✅ 成功从Bundle加载模型: LabubuFeatureExtractor
✅ 成功从Bundle加载模型: LabubuAdvancedClassifier
```

## 🧪 测试识别功能

1. 启动应用
2. 拍摄一张Labubu图片
3. 在资料页点击 **"识别Labubu"** 按钮
4. 观察识别结果和置信度

## 📊 性能监控

应用会自动记录以下性能指标：
- 快速检测时间 (目标: <30ms)
- 特征提取时间 (目标: <100ms)
- 系列分类时间 (目标: <200ms)
- 整体识别时间 (目标: <500ms)

## 🔄 模型更新

### 方法1: 替换Bundle中的模型
1. 删除Xcode项目中的旧模型文件
2. 添加新的模型文件
3. 重新编译

### 方法2: 运行时下载（高级）
应用支持OTA模型更新，新模型会下载到Documents目录并自动加载。

## ⚠️ 常见问题

### Q: 模型加载失败怎么办？
A: 检查以下几点：
- 模型文件是否正确添加到Xcode项目
- 模型文件名是否正确
- 模型格式是否符合要求（使用验证脚本检查）

### Q: 识别准确率低怎么办？
A: 可能的原因：
- 训练数据质量不够
- 模型复杂度不够
- 需要更多的数据增强

### Q: 识别速度慢怎么办？
A: 优化建议：
- 使用更轻量的模型架构（如MobileNet）
- 减少模型精度（如使用16位浮点）
- 优化图像预处理流程

## 📈 模型训练建议

如果你需要训练自己的模型，建议：

### 数据集要求：
- 每个系列至少100张图片
- 包含不同角度、光照条件
- 高质量标注

### 模型架构：
- **快速分类器**: MobileNetV3-Small
- **特征提取器**: ResNet50 (去掉最后一层)
- **高级分类器**: EfficientNet-B0

### 训练参数：
- 输入尺寸: 224x224
- 批次大小: 32
- 学习率: 0.001
- 数据增强: 旋转、缩放、颜色变换

## 🎉 完成！

恭喜！你已经成功集成了Labubu识别功能。现在用户可以：
- 拍摄Labubu照片
- 自动识别系列和稀有度
- 查看族谱和价格信息
- 享受完整的收藏体验

## 📞 技术支持

如果遇到问题，请检查：
1. 控制台日志输出
2. 模型文件完整性
3. Xcode项目配置

更多技术细节请参考 `README.md` 文件。 