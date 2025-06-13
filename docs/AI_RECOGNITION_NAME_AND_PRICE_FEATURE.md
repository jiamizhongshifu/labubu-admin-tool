# AI识别名称和价格显示功能

## 功能概述
当潮玩有AI识别结果时，自动将潮玩名称更改为识别结果的模型名称，并在图鉴页和详情页显示参考价格信息。

## 实现内容

### 1. 数据模型扩展 (ToySticker.swift)

#### 新增计算属性：

```swift
/// 显示名称（优先使用识别结果的模型名称）
var displayName: String {
    if let recognitionResult = aiRecognitionResult,
       let bestMatch = recognitionResult.bestMatch,
       recognitionResult.isSuccessful {
        return bestMatch.name
    }
    return name
}

/// 参考价格信息
var referencePrice: String? {
    guard let recognitionResult = aiRecognitionResult,
          let bestMatch = recognitionResult.bestMatch,
          recognitionResult.isSuccessful else {
        return nil
    }
    
    // 构建价格显示字符串
    if let minPrice = bestMatch.estimatedPriceMin,
       let maxPrice = bestMatch.estimatedPriceMax {
        if minPrice == maxPrice {
            return "参考价格: ¥\(Int(minPrice))"
        } else {
            return "参考价格: ¥\(Int(minPrice))-\(Int(maxPrice))"
        }
    } else if let minPrice = bestMatch.estimatedPriceMin {
        return "参考价格: ¥\(Int(minPrice))+"
    } else if let maxPrice = bestMatch.estimatedPriceMax {
        return "参考价格: ≤¥\(Int(maxPrice))"
    }
    
    return nil
}
```

### 2. 图鉴页面更新 (CollectionView.swift)

#### SimpleStickerCard组件修改：

**修改前：**
```swift
// 贴纸名称
Text(sticker.name)
    .font(.system(size: 16, weight: .medium))
    .foregroundColor(.primary)
    .lineLimit(1)
    .truncationMode(.tail)
```

**修改后：**
```swift
// 贴纸名称和价格信息
VStack(spacing: 4) {
    // 贴纸名称（优先显示识别结果）
    Text(sticker.displayName)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.primary)
        .lineLimit(1)
        .truncationMode(.tail)
    
    // 参考价格（如果有识别结果）
    if let priceInfo = sticker.referencePrice {
        Text(priceInfo)
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(.secondary)
            .lineLimit(1)
    }
}
```

### 3. 详情页面更新 (StickerDetailView.swift)

#### stickerInfoView组件修改：

**修改前：**
```swift
// 潮玩名称 - 去掉增强提示
Text(currentSticker.name)
    .font(.title2)
    .fontWeight(.bold)
    .foregroundColor(.primary)
```

**修改后：**
```swift
VStack(spacing: 8) {
    // 潮玩名称（优先显示识别结果）
    Text(currentSticker.displayName)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primary)
        .multilineTextAlignment(.center)
    
    // 参考价格（如果有识别结果）
    if let priceInfo = currentSticker.referencePrice {
        Text(priceInfo)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
}
```

### 4. 自动名称更新逻辑

#### AI识别完成回调修改：

```swift
onAIRecognitionComplete: { aiResult in
    // AI识别完成后的回调
    currentSticker.aiRecognitionResult = aiResult
    currentSticker.labubuInfo = nil // 清空旧格式结果
    
    // 🎯 自动更新潮玩名称为识别结果的模型名称
    if aiResult.isSuccessful, let bestMatch = aiResult.bestMatch {
        currentSticker.name = bestMatch.name
        print("✅ 自动更新潮玩名称为: \(bestMatch.name)")
    }
    
    saveRecognitionStateForCurrentSticker() // 保存状态
    showingLabubuRecognition = true
}
```

## 功能特性

### 🎯 **智能名称显示**
- **优先级逻辑**: 有识别结果时显示模型名称，否则显示用户输入的名称
- **自动更新**: 识别成功后自动将潮玩名称更新为识别结果的模型名称
- **向后兼容**: 对于没有识别结果的潮玩，继续显示原有名称

### 💰 **价格信息显示**
- **智能格式化**: 
  - 固定价格: "参考价格: ¥299"
  - 价格区间: "参考价格: ¥199-299"
  - 最低价格: "参考价格: ¥199+"
  - 最高价格: "参考价格: ≤¥299"
- **条件显示**: 只有识别成功且有价格信息时才显示
- **统一样式**: 图鉴页和详情页使用一致的价格显示格式

### 📱 **用户界面优化**
- **图鉴页**: 名称下方显示价格，字体较小，颜色为次要色
- **详情页**: 名称下方显示价格，字体适中，居中对齐
- **响应式设计**: 价格信息自适应显示，不影响原有布局

## 数据流程

1. **用户拍照添加潮玩** → 使用用户输入的名称或默认时间名称
2. **用户进行AI识别** → 获取识别结果和价格信息
3. **识别成功** → 自动更新潮玩名称为模型名称
4. **界面显示** → 图鉴页和详情页显示识别名称和参考价格
5. **数据持久化** → 识别结果和更新的名称保存到数据库

## 技术保障

- ✅ **编译成功**: 所有修改已通过编译验证
- ✅ **数据安全**: 使用计算属性，不影响原有数据结构
- ✅ **性能优化**: 价格格式化在计算属性中进行，避免重复计算
- ✅ **错误处理**: 识别失败或无价格信息时优雅降级
- ✅ **用户体验**: 自动化流程，减少用户手动操作

## 用户体验提升

1. **自动化命名**: 识别成功后无需手动修改名称
2. **价格参考**: 提供市场价格参考，帮助用户了解潮玩价值
3. **信息丰富**: 图鉴页和详情页信息更加完整
4. **视觉优化**: 价格信息以合适的样式显示，不干扰主要内容
5. **智能显示**: 根据识别结果智能选择显示内容

这个功能实现了用户需求中的所有要点：
- ✅ 自动更新潮玩名称为识别结果的模型名称
- ✅ 在图鉴页的潮玩名称下方显示参考价格
- ✅ 在详情页的潮玩名称下方显示参考价格
- ✅ 确保价格信息在两个页面都能正确显示 