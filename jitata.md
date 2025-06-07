
> **iPhone 拍照 ➝ 自动扣除背景 ➝ 导出透明 PNG ➝ 保存/展示/用于场景生成**

这类功能背后依赖的是 **iOS 的 VisionKit + RemoveBackgroundRequest API（iOS 17+）**，而不是通用的 `expo-camera`。这对技术栈的选型有重要影响，下面是我为你梳理的整体方案。

---

## ✅ 总体开发架构：原生 iOS 抠图 + RN 展示

```
iPhone 拍照
   ↓
VisionKit 实时拍摄 + RemoveBackground API（iOS 17+）
   ↓
得到透明背景 PNG + 原图
   ↓
展示、编辑或送给 Flux Kontext 生成场景
```

---

## 🧱 技术栈总览（原生 + React Native）

| 模块        | 技术                                          | 说明                            |
| --------- | ------------------------------------------- | ----------------------------- |
| 📸 拍照+抠图  | **iOS VisionKit + RemoveBackgroundRequest** | iOS 原生 API（支持透明 PNG 输出）       |
| 📱 App UI | React Native + Native Module Bridge         | 使用 RN 做 UI，但拍照部分走 Native      |
| 🔁 原生通信   | Swift ↔ JS Bridge (`RCTBridgeModule`)       | 自定义模块，把 Swift 抠图结果传给 RN       |
| 🖼 图像展示   | React Native Image + FlatList               | 展示已生成的 PNG 图像                 |
| ☁️ 后端上传   | Supabase / S3 / 后端 API                      | 可选，用于 CDN 存图和供 Kontext 使用     |
| 🎨 场景生成   | Flux Kontext API                            | 输入 reference 图 + prompt，返回场景图 |
| 开发环境      | Cursor + Dev Container + Xcode              | 前端 + Swift 混合开发调试             |

---

## ✂️ iOS 原生抠图核心代码（iOS 17+）

你需要创建一个 Swift 文件 `RemoveBackgroundManager.swift` 并注册为 React Native 模块：

```swift
import Foundation
import VisionKit
import UIKit
import Photos

@objc(RemoveBackgroundManager)
class RemoveBackgroundManager: NSObject {
  @objc
  func captureAndRemoveBackground(_ callback: @escaping RCTResponseSenderBlock) {
    let photoPicker = VNDocumentCameraViewController()
    photoPicker.delegate = self
    DispatchQueue.main.async {
      UIApplication.shared.windows.first?.rootViewController?.present(photoPicker, animated: true)
    }

    // 回调在 delegate 方法里完成
  }
}

extension RemoveBackgroundManager: VNDocumentCameraViewControllerDelegate {
  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    let image = scan.imageOfPage(at: 0)
    
    // 使用 iOS 17 RemoveBackgroundRequest 进行抠图
    let request = VNGenerateForegroundInstanceMaskRequest()
    request.revision = VNGenerateForegroundInstanceMaskRequestRevision1

    let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
    try? handler.perform([request])
    
    if let result = request.results?.first as? VNPixelBufferObservation {
      let mask = result.pixelBuffer
      // 处理 mask 与原图组合为透明 PNG
      let cutoutImage = applyMask(image: image, mask: mask)
      
      // 保存 cutoutImage 为 PNG 到本地，返回路径给 JS
      if let data = cutoutImage.pngData() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cutout.png")
        try? data.write(to: url)
        callback([url.absoluteString])
      }
    }
  }

  func applyMask(image: UIImage, mask: CVPixelBuffer) -> UIImage {
    // 自定义函数：将 pixel mask 应用于原图，输出透明背景 PNG
    // 实现可以参考 CoreImage 或 GPUImage 框架
  }
}
```

然后用 React Native 调用这个模块：

```ts
import { NativeModules } from 'react-native';

const { RemoveBackgroundManager } = NativeModules;

const captureAndCutout = async () => {
  const result = await RemoveBackgroundManager.captureAndRemoveBackground();
  setImageUri(result[0]); // PNG 本地路径
};
```

---

## 🧪 快速验证建议（开发环境）

1. **先在 Xcode 单独测试 Swift Module**
2. **再将其用 `RCTBridgeModule` 方式暴露给 React Native**
3. **用 Expo DevClient + Custom Dev Build** 启动带原生模块的 RN app
4. **上传生成图给 Flux Kontext → 场景图**

---

## 🔮 示例 Flux Kontext Prompt 配合（贴合拍摄潮玩）

```txt
"<reference image::0.9> of a designer toy, isolated cutout, on a fantasy shelf background, cinematic lighting, 35mm lens"
```

你可以把被拍物体放入虚拟展示空间，比如：

* toy in a **neon-lit street**
* toy on a **futuristic desk**
* toy on a **wooden bookshelf**

---

## 📦 可选功能（进阶建议）

| 功能          | 做法                               |
| ----------- | -------------------------------- |
| ✏️ 裁剪/调整背景  | 加一个 RN-canvas 编辑界面（预览前调整位置）      |
| 🧠 多个场景一键生成 | 同时发多个不同 Prompt 给 Kontext（最多 3 个） |
| 💾 保存到相册    | 使用 `expo-media-library` 保存 PNG   |

---

## 📆 项目周期建议（拍照 + 场景图）

| 时间    | 模块                      | 成果                 |
| ----- | ----------------------- | ------------------ |
| 第 1 周 | VisionKit 集成 + 拍照输出 PNG | 完成 Swift 模块，输出透明图  |
| 第 2 周 | React Native 调用 + 展示图像  | 完成图片浏览、选择 UI       |
| 第 3 周 | Kontext 场景生成功能          | 完成生成 → 展示流程        |
| 第 4 周 | 分享 / 优化 / 上架准备          | 打包 TestFlight、优化体验 |