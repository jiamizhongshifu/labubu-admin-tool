# 视频重新生成功能实现文档

## 功能概述
为Jitata iOS应用添加了视频重新生成功能，允许用户对已生成的视频进行重新生成，新视频会替换掉旧视频。

## 核心需求
用户生成好视频之后，可以再次进行新的视频生成，新的视频生成后会替换掉旧的视频。

## 技术实现

### 1. VideoManagementView 增强
在视频管理界面添加了"重新生成"按钮：

#### 界面布局调整
- **第一行**: 播放视频 + 重新生成视频
- **第二行**: 设为首页壁纸 + 导出Live Photo  
- **第三行**: 删除视频

#### 重新生成按钮设计
```swift
Button(action: {
    regenerateVideo()
}) {
    HStack {
        Image(systemName: "arrow.clockwise.circle.fill")
        Text("重新生成")
    }
    .font(.system(size: 14, weight: .medium))
    .foregroundColor(.white)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .background(Color.orange)
    .cornerRadius(8)
}
```

### 2. 重新生成逻辑实现

#### regenerateVideo() 方法
```swift
private func regenerateVideo() {
    // 清除当前视频相关数据
    if let localURL = sticker.localVideoURL {
        try? FileManager.default.removeItem(at: localURL)
    }
    
    // 重置视频生成状态
    sticker.videoURL = nil
    sticker.videoTaskId = nil
    sticker.videoGenerationStatus = .pending
    sticker.videoGenerationProgress = 0.0
    sticker.videoGenerationMessage = "准备重新生成视频..."
    
    // 保存更改
    try? modelContext.save()
    
    // 发送通知，让详情页重新显示视频生成按钮
    NotificationCenter.default.post(
        name: NSNotification.Name("VideoRegenerationRequested"),
        object: nil,
        userInfo: ["stickerID": sticker.id.uuidString]
    )
    
    // 显示提示
    exportMessage = "已重置视频状态，请使用上方的生成按钮重新生成视频"
    showingExportAlert = true
}
```

### 3. StickerDetailView 界面逻辑优化

#### 智能显示逻辑
修改了视频生成按钮和视频管理组件的显示条件：

```swift
// 🎯 视频生成按钮（AI增强完成后显示，或者视频状态为pending/processing/failed时显示）
if let enhancedURL = currentSticker.enhancedSupabaseImageURL, !enhancedURL.isEmpty {
    let videoStatus = currentSticker.videoGenerationStatus
    if videoStatus == .none || videoStatus == .pending || videoStatus == .processing || videoStatus == .failed {
        VideoGenerationButton(sticker: currentSticker)
            .padding(.horizontal, 20)
    }
}

// 🎬 视频管理组件（只有视频生成完成后才显示）
if currentSticker.videoGenerationStatus == .completed,
   let videoURL = currentSticker.videoURL, !videoURL.isEmpty {
    VideoManagementView(sticker: currentSticker)
        .padding(.horizontal, 20)
        .padding(.top, 8)
}
```

#### 通知监听机制
添加了视频重新生成的通知监听：

```swift
// 🎬 监听视频重新生成通知
NotificationCenter.default.addObserver(
    forName: NSNotification.Name("VideoRegenerationRequested"),
    object: nil,
    queue: .main
) { notification in
    if let userInfo = notification.userInfo,
       let stickerID = userInfo["stickerID"] as? String,
       stickerID == currentSticker.id.uuidString {
        // 当前贴纸的视频被重新生成，刷新界面
        print("🔄 收到视频重新生成通知，刷新界面")
    }
}
```

### 4. VideoGenerationButton 旧视频清理

在视频生成成功时添加了旧视频文件清理逻辑：

```swift
case .success(let videoURL):
    // 🔄 清理旧的本地视频文件（如果存在）
    if let oldLocalURL = sticker.localVideoURL {
        try? FileManager.default.removeItem(at: oldLocalURL)
        print("🗑️ 已清理旧的本地视频文件")
    }
    
    // 保存新的视频URL
    sticker.videoURL = videoURL
    sticker.videoGenerationStatus = .completed
    sticker.videoGenerationProgress = 1.0
    sticker.videoGenerationMessage = "视频生成完成"
    try? modelContext.save()
    
    print("✅ 视频生成完成，URL: \(videoURL)")
    print("📝 新视频已保存到云端，可在详情页进行管理")
```

## 用户交互流程

### 完整操作流程
1. **用户首次生成视频**: 在图片详情页点击"生成动态视频"按钮
2. **视频生成完成**: 界面自动切换到视频管理模式，显示VideoManagementView
3. **用户选择重新生成**: 点击"重新生成"按钮
4. **状态重置**: 系统清理旧视频文件，重置生成状态为pending
5. **界面切换**: 自动切换回视频生成按钮模式
6. **重新生成**: 用户再次点击"生成动态视频"按钮
7. **新视频替换**: 新视频生成完成后替换旧视频，界面再次切换到管理模式

### 状态管理
- **videoGenerationStatus**: 控制界面显示模式
  - `.none/.pending/.processing/.failed`: 显示VideoGenerationButton
  - `.completed`: 显示VideoManagementView
- **通知机制**: 使用NotificationCenter实现组件间通信
- **文件管理**: 自动清理旧视频文件，避免存储空间浪费

## 技术特点

### 1. 智能界面切换
- 根据视频生成状态自动切换显示组件
- 无需用户手动刷新或重新进入页面

### 2. 完整的数据清理
- 清理本地视频文件
- 重置所有相关状态字段
- 保持数据一致性

### 3. 用户友好的提示
- 明确的操作反馈
- 清晰的状态提示信息
- 直观的按钮设计

### 4. 无缝的用户体验
- 一键重新生成
- 自动状态管理
- 流畅的界面过渡

## 编译验证
✅ 所有修改均通过完整编译测试
✅ 使用命令: `xcodebuild -scheme jitata -destination 'platform=iOS Simulator,name=iPhone 16' build`
✅ 结果: BUILD SUCCEEDED

## 总结
成功实现了视频重新生成功能，用户现在可以：
- 对已生成的视频进行重新生成
- 新视频自动替换旧视频
- 享受流畅的操作体验
- 获得完整的状态反馈

这个功能完善了视频管理系统，为用户提供了更灵活的视频生成选项。 