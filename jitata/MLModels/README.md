# CoreML模型文件说明

## 📁 模型文件位置

请将以下CoreML模型文件放置在此目录中：

```
jitata/MLModels/
├── LabubuQuickClassifier.mlmodel      # 快速二分类模型
├── LabubuFeatureExtractor.mlmodel     # 特征提取模型
└── LabubuAdvancedClassifier.mlmodel   # 高级分类模型
```

## 🎯 模型规格要求

### 1. LabubuQuickClassifier.mlmodel
- **功能**：快速判断图片是否为Labubu
- **输入**：224x224 RGB图像
- **输出**：二分类概率 (isLabubu: Float)
- **大小**：建议 < 1MB
- **性能**：推理时间 < 30ms

### 2. LabubuFeatureExtractor.mlmodel  
- **功能**：提取图像特征向量
- **输入**：224x224 RGB图像
- **输出**：512维特征向量 ([Float])
- **大小**：建议 < 5MB
- **性能**：推理时间 < 100ms

### 3. LabubuAdvancedClassifier.mlmodel
- **功能**：精确识别Labubu系列
- **输入**：224x224 RGB图像
- **输出**：系列分类概率 (seriesId: String, confidence: Float)
- **大小**：建议 < 10MB
- **性能**：推理时间 < 200ms

## 🔧 添加步骤

### 步骤1：复制模型文件
将训练好的.mlmodel文件复制到此目录：
```bash
cp /path/to/your/models/*.mlmodel jitata/MLModels/
```

### 步骤2：添加到Xcode项目
1. 在Xcode中右键点击 `jitata` 项目
2. 选择 "Add Files to 'jitata'"
3. 选择 `MLModels` 文件夹
4. 确保 "Add to target" 勾选了 `jitata`
5. 点击 "Add"

### 步骤3：验证模型加载
重新编译并运行应用，查看控制台输出：
```
✅ 成功加载模型: LabubuQuickClassifier
✅ 成功加载模型: LabubuFeatureExtractor  
✅ 成功加载模型: LabubuAdvancedClassifier
```

## 🚀 模型训练建议

如果你需要训练自己的模型，建议使用以下架构：

### 快速分类器
```python
# 使用MobileNetV3作为backbone
import coremltools as ct
from torchvision import models

model = models.mobilenet_v3_small(pretrained=True)
# 修改最后一层为二分类
model.classifier[-1] = torch.nn.Linear(model.classifier[-1].in_features, 2)

# 转换为CoreML
traced_model = torch.jit.trace(model, example_input)
coreml_model = ct.convert(traced_model, inputs=[ct.ImageType(shape=(1, 3, 224, 224))])
coreml_model.save("LabubuQuickClassifier.mlmodel")
```

### 特征提取器
```python
# 使用ResNet50作为特征提取器
model = models.resnet50(pretrained=True)
# 移除最后的分类层，输出特征向量
model = torch.nn.Sequential(*list(model.children())[:-1])

coreml_model = ct.convert(traced_model, inputs=[ct.ImageType(shape=(1, 3, 224, 224))])
coreml_model.save("LabubuFeatureExtractor.mlmodel")
```

### 高级分类器
```python
# 使用EfficientNet作为分类器
model = models.efficientnet_b0(pretrained=True)
# 修改最后一层为Labubu系列数量
num_series = 50  # 假设有50个不同系列
model.classifier[-1] = torch.nn.Linear(model.classifier[-1].in_features, num_series)

coreml_model = ct.convert(traced_model, inputs=[ct.ImageType(shape=(1, 3, 224, 224))])
coreml_model.save("LabubuAdvancedClassifier.mlmodel")
```

## ⚠️ 注意事项

1. **模型版本**：确保模型是用最新版本的coremltools生成的
2. **输入格式**：所有模型的输入都应该是224x224的RGB图像
3. **输出格式**：确保输出格式与代码中的期望一致
4. **性能测试**：在真机上测试模型性能，确保满足实时性要求
5. **模型签名**：生产环境建议对模型文件进行签名验证

## 🔄 备用方案

如果暂时没有训练好的模型，应用会自动使用基于规则的备用识别方案：
- 基于颜色特征的简单分类
- 基于形状特征的匹配
- 基于纹理特征的识别

虽然准确率较低，但足以进行功能演示和测试。 