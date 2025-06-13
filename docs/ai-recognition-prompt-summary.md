# AI识别提示词总结文档

## 📋 当前AI识别提示词

### 🎯 **核心提示词内容**

```
你是一个专业的Labubu玩具识别专家。请仔细分析这张用户拍摄的图片，判断是否为Labubu玩具，并提供详细的特征描述。

请按照以下JSON格式返回分析结果：

{
    "isLabubu": true/false,
    "confidence": 0.0-1.0,
    "detailedDescription": "详细的特征描述文案，包括颜色、形状、材质、图案、风格等特征，这段文案将用于与数据库中的Labubu模型进行智能匹配",
    "visualFeatures": {
        "dominantColors": ["#颜色1", "#颜色2", "#颜色3"],
        "bodyShape": "圆润/细长/方正",
        "headShape": "圆形/三角形/椭圆形",
        "earType": "尖耳/圆耳/垂耳",
        "surfaceTexture": "光滑/磨砂/粗糙/绒毛",
        "patternType": "纯色/渐变/图案/条纹",
        "estimatedSize": "小型/中型/大型"
    },
    "keyFeatures": [
        "特征1",
        "特征2", 
        "特征3"
    ],
    "seriesHints": "可能的系列名称或主题提示",
    "materialAnalysis": "材质分析（如毛绒、塑料、金属等）",
    "styleAnalysis": "风格分析（如可爱、酷炫、复古等）",
    "conditionAssessment": "状态评估（如全新、良好、一般等）",
    "rarityHints": "稀有度提示（如常见、稀有、限定等）"
}

重要说明：
1. 如果图片中不是Labubu玩具，请将isLabubu设为false
2. detailedDescription字段非常重要，请提供丰富详细的特征描述，这将用于后续的智能匹配
3. 颜色请使用十六进制格式
4. 请确保返回的是有效的JSON格式
5. 特征描述要具体且准确，包含足够的细节用于识别匹配
```

## 🔧 **手动询问GPT模板**

### **用于生成新Labubu模型描述的提示词**

```
你是一个专业的Labubu玩具识别专家。我需要为数据库中的Labubu模型生成详细的特征描述，用于AI识别服务的文本对比。

请为以下Labubu模型生成详细的特征描述：

**模型信息：**
- 名称：[在此填入模型名称，如：Classic Pink Labubu]
- 系列：[在此填入系列名称，如：经典系列]
- 稀有度：[在此填入稀有度，如：common/rare/ultra_rare]
- 参考图片：[如有图片，请上传或描述]

请按照以下JSON格式返回分析结果：

{
    "detailedDescription": "详细的特征描述文案，包括颜色、形状、材质、图案、风格等特征，这段文案将用于与用户拍摄的图片进行智能匹配",
    "visualFeatures": {
        "dominantColors": ["#颜色1", "#颜色2", "#颜色3"],
        "bodyShape": "圆润/细长/方正",
        "headShape": "圆形/三角形/椭圆形",
        "earType": "尖耳/圆耳/垂耳",
        "surfaceTexture": "光滑/磨砂/粗糙/绒毛",
        "patternType": "纯色/渐变/图案/条纹",
        "estimatedSize": "小型/中型/大型"
    },
    "keyFeatures": [
        "特征1",
        "特征2", 
        "特征3"
    ],
    "materialAnalysis": "材质分析（如毛绒、塑料、金属等）",
    "styleAnalysis": "风格分析（如可爱、酷炫、复古等）",
    "rarityHints": "稀有度相关特征（如限定标识、特殊包装等）"
}

重要要求：
1. detailedDescription字段要非常详细，包含所有可识别的视觉特征
2. 描述要具体且准确，避免模糊表达
3. 颜色请使用十六进制格式（如#FFB6C1）
4. 特征描述要考虑用户可能的拍摄角度和光线条件
5. 请确保返回的是有效的JSON格式
```

## 📝 **使用说明**

### **1. 获取现有模型的特征描述**
1. 复制上面的"手动询问GPT模板"
2. 填入具体的模型信息（名称、系列、稀有度等）
3. 如有参考图片，一并提供给GPT
4. 发送给GPT获取JSON格式的特征描述

### **2. 在管理工具中使用生成的描述**
1. 打开管理工具的"添加模型"功能
2. 在特征描述部分选择"JSON格式模式"
3. 将GPT生成的完整JSON粘贴到输入框中
4. 点击"验证JSON格式"按钮确保格式正确
5. 系统将保存完整的JSON结构化特征描述
6. 保存模型数据

### **3. 特征描述质量要求**
- **详细性**：包含颜色、形状、材质、图案、尺寸等所有可见特征
- **准确性**：描述要与实际模型完全一致
- **可识别性**：描述要足够具体，能够区分不同的模型
- **标准化**：使用统一的描述格式和术语

## 🎯 **示例输出**

### **Classic Pink Labubu示例**
```json
{
    "detailedDescription": "粉色圆润身体，椭圆形头部，尖耳朵，表面光滑，胸前有白色爱心图案，背部有彩虹条纹，标准尺寸约6.5cm高，毛绒材质，可爱风格，经典系列代表作",
    "visualFeatures": {
        "dominantColors": ["#FFB6C1", "#FFFFFF", "#FF69B4"],
        "bodyShape": "圆润",
        "headShape": "椭圆形",
        "earType": "尖耳",
        "surfaceTexture": "光滑",
        "patternType": "图案",
        "estimatedSize": "中型"
    },
    "keyFeatures": [
        "粉色",
        "圆润",
        "尖耳",
        "爱心图案",
        "彩虹条纹"
    ],
    "materialAnalysis": "毛绒材质，手感柔软",
    "styleAnalysis": "可爱风格，经典设计",
    "rarityHints": "经典系列，常见款式"
}
```

## 🔄 **更新记录**

- **2024-12-XX v2.6**: 更新为JSON完整保存模式，不再提取单一字段，保留完整结构化信息用于精准AI识别对比
- **2024-12-XX v2.5**: 创建初始版本，包含完整的AI识别提示词和手动生成模板
- **管理工具版本**: v2.6 "JSON Complete Storage"
- **AI识别服务**: LabubuAIRecognitionService.swift

---

**注意**: 此文档用于项目内部参考，确保AI识别服务和数据库管理的一致性。 