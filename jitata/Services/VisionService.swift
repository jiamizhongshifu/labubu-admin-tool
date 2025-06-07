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
import ImageIO

@MainActor
class VisionService: ObservableObject {
    
    static let shared = VisionService()
    
    private init() {}
    
    /// 使用VisionKit移除背景
    func removeBackground(from image: UIImage) async throws -> UIImage {
        // 首先修正图像方向
        let orientedImage = fixImageOrientation(image)
        print("🚀 开始处理图像，原始尺寸: \(image.size)，修正后尺寸: \(orientedImage.size)")
        
        guard let inputImage = CIImage(image: orientedImage) else {
            print("❌ 图像转换失败")
            throw VisionError.invalidImage
        }
        
        print("📐 CIImage extent: \(inputImage.extent)")
        
        // 使用Vision框架的主体分离功能（iOS 17+推荐方法）
        if #available(iOS 17.0, *) {
            do {
                let result = try await performVisionSubjectLifting(image: orientedImage)
                print("✅ Vision主体分离成功，结果尺寸: \(result.size)")
                return result
            } catch {
                print("⚠️ Vision主体分离失败: \(error)，尝试降级方案")
                // 降级到其他方法
            }
        }
        
        // 降级方案：使用传统Vision技术
        do {
            let result = try await performAdvancedVisionProcessing(ciImage: inputImage)
            print("✅ 降级处理成功，结果尺寸: \(result.size)")
            return result
        } catch {
            print("❌ 所有处理方法都失败: \(error)")
            throw error
        }
    }
    
    /// 高级Vision处理（专为潮玩物品优化）
    private func performAdvancedVisionProcessing(ciImage: CIImage) async throws -> UIImage {
        print("🔄 开始高级Vision处理...")
        
        // 策略1: 首先尝试VisionKit主体分离（iOS 17+）
        if #available(iOS 17.0, *) {
            do {
                print("🎯 尝试VisionKit主体分离...")
                let originalImage = UIImage(ciImage: ciImage) ?? UIImage()
                let result = try await performVisionSubjectLifting(image: originalImage)
                print("✅ VisionKit主体分离成功")
                return result
            } catch {
                print("⚠️ VisionKit主体分离失败: \(error)")
            }
        }
        
        // 策略2: 尝试人像分割（适用于人形手办）
        do {
            print("👤 尝试人像分割...")
            let result = try await performPersonSegmentation(ciImage: ciImage)
            print("✅ 人像分割成功")
            return result
        } catch {
            print("⚠️ 人像分割失败: \(error)")
        }
        
        // 策略3: 尝试显著性检测（适用于大多数突出物体）
        do {
            print("🎯 尝试显著性检测...")
            let result = try await performEnhancedSaliencyDetection(ciImage: ciImage)
            print("✅ 显著性检测成功")
            return result
        } catch {
            print("⚠️ 显著性检测失败: \(error)")
        }
        
        // 策略4: 使用改进的边缘检测（最后的降级方案）
        print("🔧 使用改进的边缘检测...")
        do {
            let result = try await performEnhancedEdgeDetection(ciImage: ciImage)
            print("✅ 边缘检测成功")
            return result
        } catch {
            print("❌ 所有方法都失败了: \(error)")
            throw error
        }
    }
    

    
    /// 高级物体分割（支持各种物体类型）
    @available(iOS 17.0, *)
    private func performAdvancedObjectSegmentation(ciImage: CIImage, originalImage: UIImage) async throws -> UIImage {
        // 尝试多种分割方法，优先级从高到低
        
        // 1. 首先尝试人像分割（对人物最准确）
        do {
            return try await performPersonSegmentation(ciImage: ciImage)
        } catch {
            print("人像分割失败: \(error)")
        }
        
        // 2. 尝试物体检测和分割
        do {
            return try await performObjectDetectionSegmentation(ciImage: ciImage)
        } catch {
            print("物体检测分割失败: \(error)")
        }
        
        // 3. 使用显著性检测作为最后的降级方案
        return try await performEnhancedSaliencyDetection(ciImage: ciImage)
    }
    
    /// 使用物体检测进行分割
    @available(iOS 17.0, *)
    private func performObjectDetectionSegmentation(ciImage: CIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 使用矩形检测来识别主要物体区域
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation],
                      !observations.isEmpty else {
                    // 如果矩形检测失败，降级到显著性检测
                    Task {
                        do {
                            let result = try await self.performEnhancedSaliencyDetection(ciImage: ciImage)
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                    return
                }
                
                do {
                    // 找到置信度最高的矩形
                    let bestObservation = observations.max { $0.confidence < $1.confidence }
                    guard let mainRect = bestObservation else {
                        continuation.resume(throwing: VisionError.noResults)
                        return
                    }
                    
                    // 基于检测到的矩形区域创建蒙版
                    let maskedImage = try self.createMaskFromBoundingBox(
                        ciImage: ciImage,
                        boundingBox: mainRect.boundingBox
                    )
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // 设置矩形检测参数
            request.minimumAspectRatio = 0.1
            request.maximumAspectRatio = 10.0
            request.minimumSize = 0.1
            request.maximumObservations = 5
            
            // 执行矩形检测
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 基于边界框创建蒙版
    private func createMaskFromBoundingBox(ciImage: CIImage, boundingBox: CGRect) throws -> UIImage {
        let imageSize = ciImage.extent.size
        
        // 转换Vision坐标系到Core Image坐标系
        let convertedBox = CGRect(
            x: boundingBox.minX * imageSize.width,
            y: (1 - boundingBox.maxY) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        
        // 创建白色蒙版
        guard let maskFilter = CIFilter(name: "CIConstantColorGenerator") else {
            throw VisionError.filterCreationFailed
        }
        maskFilter.setValue(CIColor.white, forKey: kCIInputColorKey)
        
        guard let whiteMask = maskFilter.outputImage?.cropped(to: convertedBox) else {
            throw VisionError.filterProcessingFailed
        }
        
        // 创建黑色背景
        guard let blackFilter = CIFilter(name: "CIConstantColorGenerator") else {
            throw VisionError.filterCreationFailed
        }
        blackFilter.setValue(CIColor.black, forKey: kCIInputColorKey)
        
        guard let blackBackground = blackFilter.outputImage?.cropped(to: ciImage.extent) else {
            throw VisionError.filterProcessingFailed
        }
        
        // 合成最终蒙版
        guard let compositeFilter = CIFilter(name: "CISourceOverCompositing") else {
            throw VisionError.filterCreationFailed
        }
        compositeFilter.setValue(whiteMask, forKey: kCIInputImageKey)
        compositeFilter.setValue(blackBackground, forKey: kCIInputBackgroundImageKey)
        
        guard let finalMask = compositeFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 应用蒙版到原图
        guard let maskedFilter = CIFilter(name: "CIBlendWithMask") else {
            throw VisionError.filterCreationFailed
        }
        maskedFilter.setValue(ciImage, forKey: kCIInputImageKey)
        maskedFilter.setValue(finalMask, forKey: kCIInputMaskImageKey)
        maskedFilter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        
        guard let result = maskedFilter.outputImage,
              let cgImage = CIContext().createCGImage(result, from: result.extent) else {
            throw VisionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 使用Core Image提取主体（适用于各种物体）
    private func extractSubjectWithCoreImage(from image: CIImage) -> CIImage {
        // 多步骤处理来提取主体
        
        // 1. 首先增强对比度，突出主体
        guard let contrastFilter = CIFilter(name: "CIColorControls") else {
            return image
        }
        contrastFilter.setValue(image, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.2, forKey: kCIInputContrastKey) // 增加对比度
        contrastFilter.setValue(1.1, forKey: kCIInputSaturationKey) // 增加饱和度
        
        guard let enhancedImage = contrastFilter.outputImage else {
            return image
        }
        
        // 2. 使用边缘检测找到物体轮廓
        guard let edgeFilter = CIFilter(name: "CIEdges") else {
            return enhancedImage
        }
        edgeFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
        edgeFilter.setValue(2.0, forKey: kCIInputIntensityKey) // 增强边缘检测
        
        guard let edges = edgeFilter.outputImage else {
            return enhancedImage
        }
        
        // 3. 使用形态学操作填充边缘内部
        guard let morphologyFilter = CIFilter(name: "CIMorphologyGradient") else {
            return enhancedImage
        }
        morphologyFilter.setValue(edges, forKey: kCIInputImageKey)
        morphologyFilter.setValue(3.0, forKey: kCIInputRadiusKey)
        
        guard let morphed = morphologyFilter.outputImage else {
            return enhancedImage
        }
        
        // 4. 创建蒙版并应用到原图
        guard let maskFilter = CIFilter(name: "CIColorInvert") else {
            return enhancedImage
        }
        maskFilter.setValue(morphed, forKey: kCIInputImageKey)
        
        guard let mask = maskFilter.outputImage else {
            return enhancedImage
        }
        
        // 5. 使用蒙版混合原图和透明背景
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            return enhancedImage
        }
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        blendFilter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        
        return blendFilter.outputImage ?? enhancedImage
    }
    
    /// 通用物体分割（适用于iOS 15+）
    private func performGeneralObjectSegmentation(ciImage: CIImage) async throws -> UIImage {
        // 对于iOS 15+，尝试多种分割方法
        
        // 1. 首先尝试人像分割（对人物最准确）
        do {
            return try await performPersonSegmentation(ciImage: ciImage)
        } catch {
            print("人像分割失败: \(error)")
        }
        
        // 2. 尝试显著性检测（适用于各种突出物体）
        do {
            return try await performEnhancedSaliencyDetection(ciImage: ciImage)
        } catch {
            print("显著性检测失败: \(error)")
        }
        
        // 3. 最后使用基础的边缘检测方法
        return try await performBasicEdgeDetectionSegmentation(ciImage: ciImage)
    }
    
    /// 基础边缘检测分割（最后的降级方案）
    private func performBasicEdgeDetectionSegmentation(ciImage: CIImage) async throws -> UIImage {
        // 使用Core Image的边缘检测和形态学操作
        let processedImage = extractSubjectWithCoreImage(from: ciImage)
        
        guard let cgImage = CIContext().createCGImage(processedImage, from: processedImage.extent) else {
            throw VisionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 使用人像分割进行背景移除
    private func performPersonSegmentation(ciImage: CIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 使用人像分割请求
            let request = VNGeneratePersonSegmentationRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observation = request.results?.first as? VNPixelBufferObservation else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                do {
                    let maskedImage = try self.applyPersonSegmentationMask(
                        to: ciImage,
                        maskObservation: observation
                    )
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // 设置请求质量
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
            
            // 执行请求
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 增强的显著性检测（专为潮玩优化）
    private func performEnhancedSaliencyDetection(ciImage: CIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            // 使用显著性检测来识别前景对象
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observation = request.results?.first as? VNSaliencyImageObservation else {
                    continuation.resume(throwing: VisionError.noResults)
                    return
                }
                
                do {
                    let maskedImage = try self.applyEnhancedSaliencyMask(
                        to: ciImage,
                        saliencyObservation: observation
                    )
                    continuation.resume(returning: maskedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // 执行请求
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 增强的边缘检测（最后的降级方案）
    private func performEnhancedEdgeDetection(ciImage: CIImage) async throws -> UIImage {
        // 使用多种技术组合来提取主体
        let processedImage = extractSubjectWithAdvancedCoreImage(from: ciImage)
        
        guard let cgImage = CIContext().createCGImage(processedImage, from: processedImage.extent) else {
            throw VisionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 应用人像分割蒙版到图像
    private func applyPersonSegmentationMask(to image: CIImage, maskObservation: VNPixelBufferObservation) throws -> UIImage {
        let maskImage = CIImage(cvPixelBuffer: maskObservation.pixelBuffer)
        
        // 调整蒙版尺寸以匹配原图像
        let scaleX = image.extent.width / maskImage.extent.width
        let scaleY = image.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // 创建透明背景
        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: image.extent)
        
        // 使用蒙版混合
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            throw VisionError.filterCreationFailed
        }
        
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(transparentBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 转换为UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw VisionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 应用增强的显著性蒙版（专为潮玩优化）
    private func applyEnhancedSaliencyMask(to image: CIImage, saliencyObservation: VNSaliencyImageObservation) throws -> UIImage {
        let saliencyImage = CIImage(cvPixelBuffer: saliencyObservation.pixelBuffer)
        
        // 调整显著性图像的尺寸以匹配原图像
        let scaledSaliency = saliencyImage.transformed(by: CGAffineTransform(
            scaleX: image.extent.width / saliencyImage.extent.width,
            y: image.extent.height / saliencyImage.extent.height
        ))
        
        // 多步骤增强蒙版质量
        
        // 1. 增强对比度和亮度
        guard let contrastFilter = CIFilter(name: "CIColorControls") else {
            throw VisionError.filterCreationFailed
        }
        contrastFilter.setValue(scaledSaliency, forKey: kCIInputImageKey)
        contrastFilter.setValue(3.0, forKey: kCIInputContrastKey) // 大幅增加对比度
        contrastFilter.setValue(0.2, forKey: kCIInputBrightnessKey) // 调整亮度
        
        guard let enhancedMask = contrastFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 2. 使用形态学操作填充空洞
        guard let morphologyFilter = CIFilter(name: "CIMorphologyGradient") else {
            throw VisionError.filterCreationFailed
        }
        morphologyFilter.setValue(enhancedMask, forKey: kCIInputImageKey)
        morphologyFilter.setValue(2.0, forKey: kCIInputRadiusKey)
        
        guard let morphedMask = morphologyFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 3. 轻微模糊以平滑边缘
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else {
            throw VisionError.filterCreationFailed
        }
        blurFilter.setValue(morphedMask, forKey: kCIInputImageKey)
        blurFilter.setValue(1.0, forKey: kCIInputRadiusKey)
        
        guard let smoothMask = blurFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 4. 使用蒙版混合
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else {
            throw VisionError.filterCreationFailed
        }
        
        // 创建透明背景
        let transparentBackground = CIImage(color: CIColor.clear)
            .cropped(to: image.extent)
        
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(transparentBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(smoothMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage else {
            throw VisionError.filterProcessingFailed
        }
        
        // 转换为UIImage
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw VisionError.imageConversionFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    /// 使用高级Core Image技术提取主体（专为潮玩优化）
    private func extractSubjectWithAdvancedCoreImage(from image: CIImage) -> CIImage {
        print("使用高级Core Image处理...")
        
        // 1. 预处理：增强图像质量
        guard let enhancedImage = preprocessImageForSegmentation(image) else {
            return image
        }
        
        // 2. 多种边缘检测技术组合
        guard let combinedEdges = detectCombinedEdges(enhancedImage) else {
            return enhancedImage
        }
        
        // 3. 创建智能蒙版
        guard let smartMask = createSmartMask(from: combinedEdges, originalImage: image) else {
            return enhancedImage
        }
        
        // 4. 应用蒙版并优化结果
        return applyMaskWithOptimization(mask: smartMask, to: image)
    }
    
    /// 预处理图像以优化分割效果
    private func preprocessImageForSegmentation(_ image: CIImage) -> CIImage? {
        // 1. 增强对比度和饱和度
        guard let contrastFilter = CIFilter(name: "CIColorControls") else { return nil }
        contrastFilter.setValue(image, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.3, forKey: kCIInputContrastKey)
        contrastFilter.setValue(1.2, forKey: kCIInputSaturationKey)
        contrastFilter.setValue(0.05, forKey: kCIInputBrightnessKey)
        
        guard let enhanced = contrastFilter.outputImage else { return nil }
        
        // 2. 轻微锐化以突出细节
        guard let sharpenFilter = CIFilter(name: "CISharpenLuminance") else { return enhanced }
        sharpenFilter.setValue(enhanced, forKey: kCIInputImageKey)
        sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
        
        return sharpenFilter.outputImage ?? enhanced
    }
    
    /// 组合多种边缘检测技术
    private func detectCombinedEdges(_ image: CIImage) -> CIImage? {
        // 1. 标准边缘检测
        guard let edgeFilter = CIFilter(name: "CIEdges") else { return nil }
        edgeFilter.setValue(image, forKey: kCIInputImageKey)
        edgeFilter.setValue(1.5, forKey: kCIInputIntensityKey)
        
        guard let edges1 = edgeFilter.outputImage else { return nil }
        
        // 2. 线条检测
        guard let lineFilter = CIFilter(name: "CILineOverlay") else { return edges1 }
        lineFilter.setValue(image, forKey: kCIInputImageKey)
        lineFilter.setValue(0.1, forKey: "inputNRNoiseLevel")
        lineFilter.setValue(0.7, forKey: "inputNRSharpness")
        lineFilter.setValue(0.08, forKey: "inputEdgeIntensity")
        lineFilter.setValue(0.5, forKey: "inputThreshold")
        lineFilter.setValue(3.0, forKey: "inputContrast")
        
        guard let edges2 = lineFilter.outputImage else { return edges1 }
        
        // 3. 组合两种边缘检测结果
        guard let combineFilter = CIFilter(name: "CIAdditionCompositing") else { return edges1 }
        combineFilter.setValue(edges1, forKey: kCIInputImageKey)
        combineFilter.setValue(edges2, forKey: kCIInputBackgroundImageKey)
        
        return combineFilter.outputImage ?? edges1
    }
    
    /// 创建智能蒙版
    private func createSmartMask(from edges: CIImage, originalImage: CIImage) -> CIImage? {
        // 1. 形态学操作填充边缘
        guard let morphologyFilter = CIFilter(name: "CIMorphologyGradient") else { return nil }
        morphologyFilter.setValue(edges, forKey: kCIInputImageKey)
        morphologyFilter.setValue(4.0, forKey: kCIInputRadiusKey)
        
        guard let filled = morphologyFilter.outputImage else { return nil }
        
        // 2. 反转颜色创建蒙版
        guard let invertFilter = CIFilter(name: "CIColorInvert") else { return filled }
        invertFilter.setValue(filled, forKey: kCIInputImageKey)
        
        guard let inverted = invertFilter.outputImage else { return filled }
        
        // 3. 模糊蒙版边缘以获得更自然的效果
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return inverted }
        blurFilter.setValue(inverted, forKey: kCIInputImageKey)
        blurFilter.setValue(2.0, forKey: kCIInputRadiusKey)
        
        return blurFilter.outputImage ?? inverted
    }
    
    /// 应用蒙版并优化结果
    private func applyMaskWithOptimization(mask: CIImage, to image: CIImage) -> CIImage {
        // 1. 使用蒙版混合
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return image }
        
        let transparentBackground = CIImage(color: CIColor.clear).cropped(to: image.extent)
        blendFilter.setValue(image, forKey: kCIInputImageKey)
        blendFilter.setValue(transparentBackground, forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(mask, forKey: kCIInputMaskImageKey)
        
        guard let blended = blendFilter.outputImage else { return image }
        
        // 2. 轻微增强最终结果
        guard let finalFilter = CIFilter(name: "CIColorControls") else { return blended }
        finalFilter.setValue(blended, forKey: kCIInputImageKey)
        finalFilter.setValue(1.05, forKey: kCIInputContrastKey)
        finalFilter.setValue(1.02, forKey: kCIInputSaturationKey)
        
        return finalFilter.outputImage ?? blended
    }
    
    /// iOS 17+ 使用Vision框架的主体分离功能
    @available(iOS 17.0, *)
    private func performVisionSubjectLifting(image: UIImage) async throws -> UIImage {
        print("🔍 开始Vision主体分离分析...")
        
        // 添加超时保护
        return try await withThrowingTaskGroup(of: UIImage.self) { group in
            // 添加主要任务
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    var hasResumed = false
                    let lock = NSLock()
                    
                    // 确保图像有效
                    guard let cgImage = image.cgImage else {
                        continuation.resume(throwing: VisionError.invalidImage)
                        return
                    }
                    
                    // 创建主体分离请求
                    let request = VNGenerateForegroundInstanceMaskRequest { request, error in
                        lock.lock()
                        defer { lock.unlock() }
                        
                        guard !hasResumed else { return }
                        hasResumed = true
                        
                        if let error = error {
                            print("❌ Vision主体分离请求失败: \(error)")
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        guard let observations = request.results as? [VNInstanceMaskObservation],
                              let observation = observations.first else {
                            print("⚠️ 没有检测到主体")
                            continuation.resume(throwing: VisionError.noResults)
                            return
                        }
                        
                        do {
                            print("✅ 检测到主体，开始生成蒙版...")
                            let maskedImage = try self.createMaskedImage(
                                from: image,
                                observation: observation
                            )
                            print("✅ 主体分离完成")
                            continuation.resume(returning: maskedImage)
                        } catch {
                            print("❌ 蒙版生成失败: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                    
                    // 创建请求处理器，保持原始图像方向
                    let imageOrientation = CGImagePropertyOrientation(image.imageOrientation)
                    let handler = VNImageRequestHandler(
                        cgImage: cgImage,
                        orientation: imageOrientation,
                        options: [:]
                    )
                    
                    // 在后台队列执行请求
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try handler.perform([request])
                        } catch {
                            lock.lock()
                            defer { lock.unlock() }
                            
                            guard !hasResumed else { return }
                            hasResumed = true
                            
                            print("❌ Vision请求执行失败: \(error)")
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
            
            // 添加超时任务
            group.addTask {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30秒超时
                throw VisionError.processingTimeout
            }
            
            // 返回第一个完成的任务结果
            guard let result = try await group.next() else {
                throw VisionError.noResults
            }
            
            group.cancelAll()
            return result
        }
    }
    
    /// 使用Vision观察结果创建蒙版图像
    @available(iOS 17.0, *)
    nonisolated private func createMaskedImage(from image: UIImage, observation: VNInstanceMaskObservation) throws -> UIImage {
        // 获取所有前景实例
        let allInstances = observation.allInstances
        
        // 确保有检测到的实例
        guard !allInstances.isEmpty else {
            throw VisionError.noResults
        }
        
        // 直接生成带蒙版的图像
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }
        
        do {
            // 使用正确的方法生成蒙版图像
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let maskedPixelBuffer = try observation.generateMaskedImage(
                ofInstances: allInstances,
                from: requestHandler,
                croppedToInstancesExtent: false
            )
            
            // 将CVPixelBuffer转换为UIImage，保持原始方向
            let ciImage = CIImage(cvPixelBuffer: maskedPixelBuffer)
            
            // 使用专用的CIContext避免内存问题
            let context = CIContext(options: [
                .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            ])
            
            guard let outputCGImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                throw VisionError.imageConversionFailed
            }
            
            // 保持原始图像的方向信息
            return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
        } catch {
            print("❌ 生成蒙版图像失败: \(error)")
            throw VisionError.filterProcessingFailed
        }
    }
    
    /// 修正图像方向
    private func fixImageOrientation(_ image: UIImage) -> UIImage {
        // 如果图像方向已经是.up，直接返回
        if image.imageOrientation == .up {
            return image
        }
        
        // 创建正确方向的图像
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        guard let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return image
        }
        
        return normalizedImage
    }
}

// MARK: - 扩展
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

// MARK: - 错误定义
enum VisionError: LocalizedError {
    case invalidImage
    case noResults
    case filterCreationFailed
    case filterProcessingFailed
    case imageConversionFailed
    case processingTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像"
        case .noResults:
            return "未能检测到主体"
        case .filterCreationFailed:
            return "滤镜创建失败"
        case .filterProcessingFailed:
            return "图像处理失败"
        case .imageConversionFailed:
            return "图像转换失败"
        case .processingTimeout:
            return "处理超时"
        }
    }
} 