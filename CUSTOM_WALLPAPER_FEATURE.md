# 自定义动态壁纸功能实现

## 功能概述

实现了用户可以手动选择生成的视频作为动态壁纸的功能，当用户设置了自定义动态壁纸时，会替换掉预设的动态壁纸。

## 核心功能

### 1. 动态壁纸优先级系统
- **自定义壁纸优先**：用户设置的自定义壁纸优先于预设壁纸显示
- **预设壁纸备用**：当没有自定义壁纸时，显示预设的 `7084_raw.MP4`
- **黑色背景兜底**：当所有视频都无法加载时，显示黑色背景

### 2. 壁纸设置入口
- **智能显示**：仅在用户有生成视频时显示壁纸设置按钮
- **位置设计**：壁纸设置按钮位于顶部导航栏右侧，"我的图鉴"按钮左边
- **图标设计**：使用 `photo.on.rectangle.angled` 系统图标，配合半透明圆形背景

### 3. 壁纸选择界面
- **当前壁纸预览**：顶部显示当前使用的动态壁纸
- **视频网格选择**：2列网格布局展示所有用户生成的视频
- **选中状态指示**：蓝色边框 + 勾选图标标识当前选中的壁纸
- **操作按钮**：
  - "取消"：关闭选择界面
  - "恢复默认"：重置为预设壁纸

### 4. 数据持久化
- **UserDefaults存储**：使用 `custom_wallpaper_url` 键保存用户选择
- **文件存在验证**：启动时验证保存的视频文件是否仍然存在
- **自动恢复**：应用重启后自动恢复用户的壁纸设置

## 技术实现

### 核心状态管理
```swift
@State private var customWallpaperURL: URL? // 用户自定义的动态壁纸URL
@State private var showingWallpaperOptions = false // 显示壁纸选择选项
```

### 壁纸显示逻辑
```swift
if let customWallpaperURL = customWallpaperURL {
    // 🎯 优先显示用户自定义的动态壁纸
    FullScreenVideoPlayerView(videoURL: customWallpaperURL)
} else if let presetVideoURL = presetVideoURL {
    // 🎯 备用显示预设动态壁纸
    FullScreenVideoPlayerView(videoURL: presetVideoURL)
} else {
    // 备用黑色背景
    Color.black
}
```

### 关键方法

#### 设置自定义壁纸
```swift
private func setCustomWallpaper(_ videoURL: URL) {
    customWallpaperURL = videoURL
    UserDefaults.standard.set(videoURL.absoluteString, forKey: "custom_wallpaper_url")
}
```

#### 重置为默认壁纸
```swift
private func resetToDefaultWallpaper() {
    customWallpaperURL = nil
    UserDefaults.standard.removeObject(forKey: "custom_wallpaper_url")
}
```

#### 加载保存的设置
```swift
private func loadCustomWallpaperSetting() {
    if let savedURLString = UserDefaults.standard.string(forKey: "custom_wallpaper_url"),
       let savedURL = URL(string: savedURLString),
       FileManager.default.fileExists(atPath: savedURL.path) {
        customWallpaperURL = savedURL
    }
}
```

## 用户体验流程

### 设置自定义壁纸
1. 用户生成视频后，顶部导航栏出现壁纸设置按钮
2. 点击壁纸设置按钮，弹出壁纸选择界面
3. 界面顶部显示当前使用的壁纸预览
4. 用户从网格中选择想要的视频作为壁纸
5. 选择后自动关闭界面，新壁纸立即生效
6. 设置会自动保存，下次启动应用时恢复

### 恢复默认壁纸
1. 在壁纸选择界面点击"恢复默认"按钮
2. 自动重置为预设的 `7084_raw.MP4` 壁纸
3. 清除保存的自定义设置

## 界面设计特点

### 壁纸设置按钮
- **材质设计**：半透明黑色背景 + 超薄材质效果
- **阴影效果**：增强视觉层次感
- **响应式显示**：仅在有用户视频时显示

### 壁纸选择界面
- **导航栏设计**：标准iOS导航栏，标题"选择动态壁纸"
- **当前壁纸区域**：灰色背景区域，突出显示当前壁纸
- **视频网格**：2列布局，9:16比例预览，圆角设计
- **选中指示**：蓝色边框 + 白色背景勾选图标

### 视觉一致性
- **与现有设计融合**：按钮样式与"我的图鉴"按钮保持一致
- **透明导航栏**：保持全屏沉浸式体验
- **阴影文字**：确保在动态背景上的可读性

## 技术优势

### 性能优化
- **按需加载**：仅在有用户视频时创建壁纸设置功能
- **文件验证**：启动时验证文件存在性，避免无效引用
- **内存管理**：使用 SwiftUI 的状态管理，自动处理内存

### 用户体验
- **即时反馈**：选择壁纸后立即生效，无需等待
- **持久化设置**：应用重启后保持用户选择
- **智能降级**：文件不存在时自动回退到预设壁纸

### 代码质量
- **模块化设计**：壁纸选择功能独立组件化
- **状态管理**：清晰的状态流转和数据绑定
- **错误处理**：完善的文件存在性检查和异常处理

## 未来扩展可能

1. **壁纸分类**：支持按类型、时间等分类管理壁纸
2. **预览功能**：长按预览壁纸效果
3. **批量管理**：支持删除、重命名等壁纸管理功能
4. **云端同步**：支持壁纸设置的云端同步
5. **定时切换**：支持定时自动切换壁纸功能

## 总结

自定义动态壁纸功能为用户提供了个性化的应用体验，让用户可以将自己生成的精美视频设置为应用的动态背景。功能设计简洁直观，技术实现稳定可靠，完美融入了现有的应用架构和设计语言。 