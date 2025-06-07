//
//  VisionService.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import UIKit
import VisionKit
@preconcurrency import Vision
import CoreImage.CIFilterBuiltins

/// VisionKit错误类型
enum VisionError: Error, LocalizedError {
    case invalidImage
    case noSubjectsFound
    case imageConversionFailed
    case visionKitNotAvailable
    case processingFailed(String)
    case iOS17Required
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像"
        case .noSubjectsFound:
            return "未检测到主体"
        case .imageConversionFailed:
            return "图像转换失败"
        case .visionKitNotAvailable:
            return "VisionKit不可用"
        case .processingFailed(let message):
            return "处理失败: \(message)"
        case .iOS17Required:
            return "需要iOS 17+支持"
        }
    }
}

/// 符合开发文档的VisionKit主体提取服务（使用iOS 17+ RemoveBackgroundRequest API）
@MainActor
class VisionService: ObservableObject {
    
    static let shared = VisionService()
    
    private init() {}
    
    // MARK: - 主要API：背景移除（按文档要求使用RemoveBackgroundRequest）
    
    /// 使用iOS 17+ RemoveBackgroundRequest API移除背景，输出透明PNG
    func removeBackground(from image: UIImage) async throws -> UIImage {
        print("🚀 开始RemoveBackgroundRequest处理，图像尺寸: \(image.size)")
        
        // 检查iOS版本
        guard #available(iOS 17.0, *) else {
            print("❌ 需要iOS 17+支持RemoveBackgroundRequest")
            throw VisionError.iOS17Required
        }
        
        // 修正图像方向
        let orientedImage = fixImageOrientation(image)
        
        // 使用iOS 17+ RemoveBackgroundRequest API（文档推荐方法）
        return try await performRemoveBackgroundRequest(image: orientedImage)
    }
    
    // MARK: - iOS 17+ RemoveBackgroundRequest API实现（按文档规范）
    
    /// 使用RemoveBackgroundRequest进行背景移除（文档核心方法）
    @available(iOS 17.0, *)
    private func performRemoveBackgroundRequest(image: UIImage) async throws -> UIImage {
        print("📱 使用iOS 17+ RemoveBackgroundRequest API...")
        
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // 创建VNGenerateForegroundInstanceMaskRequest（按文档要求）
            let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                if let error = error {
                    print("❌ RemoveBackgroundRequest失败: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNInstanceMaskObservation],
                      let observation = observations.first else {
                    print("❌ 未检测到前景实例")
                    continuation.resume(throwing: VisionError.noSubjectsFound)
                    return
                }
                
                do {
                    print("✅ 检测到 \(observation.allInstances.count) 个前景实例")
                    
                    // 生成所有实例的蒙版（按文档方法）
                    let maskPixelBuffer = try observation.generateScaledMaskForImage(
                        forInstances: observation.allInstances,
                        from: VNImageRequestHandler(cgImage: cgImage, options: [:])
                    )
                    
                    // 应用蒙版创建透明背景PNG（按文档要求）
                    let cutoutImage = self.applyMask(image: image, mask: maskPixelBuffer)
                    
                    print("✅ RemoveBackgroundRequest成功，输出透明PNG")
                    continuation.resume(returning: cutoutImage)
                    
                } catch {
                    print("❌ 蒙版处理失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            
            // 设置请求版本（iOS 17+）
            request.revision = VNGenerateForegroundInstanceMaskRequestRevision1
            
            // 执行请求
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - 透明PNG生成（按文档要求的applyMask方法）
    
    /// 将pixel mask应用于原图，输出透明背景PNG（按文档规范实现）
    private func applyMask(image: UIImage, mask: CVPixelBuffer) -> UIImage {
        print("🎨 应用蒙版生成透明背景PNG...")
        
        guard let cgImage = image.cgImage else {
            print("❌ 无法获取CGImage")
            return image
        }
        
        // 方法1：使用CoreImage处理（推荐）
        if let transparentImage = applyMaskWithCoreImage(image: image, mask: mask) {
            print("✅ CoreImage方法成功")
            return transparentImage
        }
        
        // 方法2：手动像素处理（降级方案）
        print("🔧 使用手动像素处理降级方案...")
        return applyMaskManually(image: image, mask: mask)
    }
    
    /// 使用CoreImage应用蒙版（高效方法）
    private func applyMaskWithCoreImage(image: UIImage, mask: CVPixelBuffer) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let originalCIImage = CIImage(cgImage: cgImage)
        let maskCIImage = CIImage(cvPixelBuffer: mask)
        
        // 确保蒙版尺寸匹配
        let scaledMask: CIImage
        if maskCIImage.extent.size != originalCIImage.extent.size {
            let scaleX = originalCIImage.extent.width / maskCIImage.extent.width
            let scaleY = originalCIImage.extent.height / maskCIImage.extent.height
            let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            scaledMask = maskCIImage.transformed(by: scaleTransform)
            print("📏 蒙版已缩放: \(maskCIImage.extent.size) → \(scaledMask.extent.size)")
        } else {
            scaledMask = maskCIImage
        }
        
        // 使用CIBlendWithMask创建透明背景
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            print("❌ 无法创建CIBlendWithMask滤镜")
            return nil
        }
        
        // 创建一个精确尺寸的透明背景，而不是CIImage.empty()
        let transparentColor = CIColor.clear
        let transparentBackground = CIImage(color: transparentColor).cropped(to: originalCIImage.extent)
        
        blendFilter.setValue(originalCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(transparentBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage else {
            print("❌ CIBlendWithMask输出失败")
            return nil
        }
        
        // 转换为UIImage
        // 终极解决方案：强制使用CPU渲染并明确指定颜色空间，避免GPU渲染问题
        let contextOptions: [CIContextOption: Any] = [
            .useSoftwareRenderer: true, // 强制CPU渲染，保证结果可靠性
            .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        ]
        let context = CIContext(options: contextOptions)
        
        guard let resultCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            print("❌ 无法创建CGImage")
            return nil
        }
        
        // 验证Alpha通道是否存在
        print("✅ CGImage Alpha Info: \(resultCGImage.alphaInfo.rawValue)")
        
        // 🎯 终极修复：创建纯粹的UIImage，不传递任何方向元数据
        // 避免方向冲突导致的透明通道丢失问题
        return UIImage(cgImage: resultCGImage)
    }
    
    /// 手动像素处理应用蒙版（可靠的降级方案）
    private func applyMaskManually(image: UIImage, mask: CVPixelBuffer) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return image }
        
        // 创建可修改的位图上下文
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return image }
        
        // 绘制原图
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else { return image }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        // 处理蒙版
        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
        
        let maskData = CVPixelBufferGetBaseAddress(mask)
        let maskBytesPerRow = CVPixelBufferGetBytesPerRow(mask)
        let maskWidth = CVPixelBufferGetWidth(mask)
        let maskHeight = CVPixelBufferGetHeight(mask)
        
        guard let maskBytes = maskData?.bindMemory(to: UInt8.self, capacity: maskHeight * maskBytesPerRow) else {
            return image
        }
        
        // 应用蒙版到像素
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                
                // 计算蒙版坐标
                let maskX = min(x * maskWidth / width, maskWidth - 1)
                let maskY = min(y * maskHeight / height, maskHeight - 1)
                let maskIndex = maskY * maskBytesPerRow + maskX
                
                let maskValue = maskBytes[maskIndex]
                
                // 应用蒙版到alpha通道
                pixels[pixelIndex + 3] = UInt8((Float(pixels[pixelIndex + 3]) * Float(maskValue)) / 255.0)
            }
        }
        
        // 创建结果图像
        guard let resultCGImage = context.makeImage() else { return image }
        
        // 🎯 终极修复：创建纯粹的UIImage，不传递任何方向元数据
        // 避免方向冲突导致的透明通道丢失问题
        return UIImage(cgImage: resultCGImage)
    }
    
    // MARK: - 工具方法
    
    /// 修正图像方向
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    /// 保存透明PNG到本地（按文档要求功能）
    func saveTransparentPNG(_ image: UIImage, to fileName: String = "cutout.png") throws -> URL {
        guard let pngData = image.pngData() else {
            throw VisionError.imageConversionFailed
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try pngData.write(to: fileURL)
        print("💾 透明PNG已保存: \(fileURL.path)")
        
        return fileURL
    }
} 