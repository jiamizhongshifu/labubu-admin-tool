//
//  ImageProcessor.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ImageProcessor {
    
    static let shared = ImageProcessor()
    private let context = CIContext()
    
    private init() {}
    
    /// 贴纸样式枚举
    enum StickerStyle {
        case basic          // 基础样式
        case withShadow     // 带阴影
        case withBorder     // 带边框
        case glossy         // 光泽效果
        case vintage        // 复古效果
        case transparent    // 纯透明无效果
    }
    
    /// 为图像添加贴纸效果
    func applyStickerEffect(to image: UIImage, style: StickerStyle = .withShadow) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        var processedImage = ciImage
        
        switch style {
        case .basic:
            // 基础样式：仅优化色彩
            processedImage = enhanceColors(processedImage)
            
        case .withShadow:
            // 添加白色描边和阴影效果
            processedImage = addWhiteBorder(processedImage)
            processedImage = addDropShadow(processedImage)
            processedImage = enhanceColors(processedImage)
            
        case .withBorder:
            // 添加边框
            processedImage = addBorder(processedImage)
            processedImage = enhanceColors(processedImage)
            
        case .glossy:
            // 光泽效果
            processedImage = addGlossyEffect(processedImage)
            processedImage = enhanceColors(processedImage)
            
        case .vintage:
            // 复古效果
            processedImage = addVintageEffect(processedImage)
            
        case .transparent:
            // 纯透明无任何效果，保持原始抠图结果
            break
        }
        
        return renderImage(processedImage) ?? image
    }
    
    /// 增强色彩
    private func enhanceColors(_ image: CIImage) -> CIImage {
        let filter = CIFilter.colorControls()
        filter.inputImage = image
        filter.saturation = 1.2  // 增加饱和度
        filter.brightness = 0.05 // 轻微增加亮度
        filter.contrast = 1.1    // 增加对比度
        
        return filter.outputImage ?? image
    }
    
    /// 添加阴影效果
    private func addDropShadow(_ image: CIImage) -> CIImage {
        // 创建阴影
        let shadowFilter = CIFilter.gaussianBlur()
        shadowFilter.inputImage = image
        shadowFilter.radius = 3.0
        
        guard let shadowImage = shadowFilter.outputImage else { return image }
        
        // 阴影偏移和透明度
        let shadowOffset = CGAffineTransform(translationX: 2, y: -2)
        let offsetShadow = shadowImage.transformed(by: shadowOffset)
        
        // 创建阴影颜色（半透明黑色）
        let shadowColor = CIFilter.colorMatrix()
        shadowColor.inputImage = offsetShadow
        shadowColor.rVector = CIVector(x: 0, y: 0, z: 0, w: 0.3) // 30% 透明度的黑色
        shadowColor.gVector = CIVector(x: 0, y: 0, z: 0, w: 0.3)
        shadowColor.bVector = CIVector(x: 0, y: 0, z: 0, w: 0.3)
        shadowColor.aVector = CIVector(x: 0, y: 0, z: 0, w: 0.3)
        
        guard let coloredShadow = shadowColor.outputImage else { return image }
        
        // 合成原图和阴影
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = image
        composite.backgroundImage = coloredShadow
        
        return composite.outputImage ?? image
    }
    
    /// 添加白色描边
    private func addWhiteBorder(_ image: CIImage) -> CIImage {
        let borderWidth: CGFloat = 4
        let borderColor = CIColor.white
        
        // 创建边框
        let borderRect = image.extent.insetBy(dx: -borderWidth, dy: -borderWidth)
        let borderBackground = CIImage(color: borderColor).cropped(to: borderRect)
        
        // 合成
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = image
        composite.backgroundImage = borderBackground
        
        return composite.outputImage ?? image
    }
    
    /// 添加边框
    private func addBorder(_ image: CIImage) -> CIImage {
        let borderWidth: CGFloat = 8
        let borderColor = CIColor.white
        
        // 创建边框
        let borderRect = image.extent.insetBy(dx: -borderWidth, dy: -borderWidth)
        let borderBackground = CIImage(color: borderColor).cropped(to: borderRect)
        
        // 合成
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = image
        composite.backgroundImage = borderBackground
        
        return composite.outputImage ?? image
    }
    
    /// 添加光泽效果
    private func addGlossyEffect(_ image: CIImage) -> CIImage {
        // 创建高光
        let highlight = CIFilter.colorMatrix()
        highlight.inputImage = image
        highlight.rVector = CIVector(x: 1.1, y: 0, z: 0, w: 0)
        highlight.gVector = CIVector(x: 0, y: 1.1, z: 0, w: 0)
        highlight.bVector = CIVector(x: 0, y: 0, z: 1.1, w: 0)
        highlight.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        
        guard let highlightImage = highlight.outputImage else { return image }
        
        // 添加轻微模糊创造光泽感
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = highlightImage
        blur.radius = 0.5
        
        return blur.outputImage ?? image
    }
    
    /// 添加复古效果
    private func addVintageEffect(_ image: CIImage) -> CIImage {
        // 降低饱和度
        let desaturate = CIFilter.colorControls()
        desaturate.inputImage = image
        desaturate.saturation = 0.7
        desaturate.brightness = -0.1
        desaturate.contrast = 1.2
        
        guard let desaturatedImage = desaturate.outputImage else { return image }
        
        // 添加褐色调
        let sepia = CIFilter.sepiaTone()
        sepia.inputImage = desaturatedImage
        sepia.intensity = 0.3
        
        return sepia.outputImage ?? image
    }
    
    /// 渲染最终图像
    private func renderImage(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
    
    /// 调整图像大小（保持宽高比）
    func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    /// 将抠图结果裁剪为1:1比例，最小化留白区域
    func cropToSquareAspectRatio(_ image: UIImage) -> UIImage {
        print("🔍 [cropToSquareAspectRatio] 开始处理图像，原始尺寸: \(image.size)")
        
        guard let cgImage = image.cgImage else { 
            print("❌ [cropToSquareAspectRatio] 无法获取CGImage")
            return image 
        }
        
        // 🎯 修复：使用更智能的主体检测
        let bounds = getMainSubjectBounds(cgImage)
        print("🎯 [cropToSquareAspectRatio] 检测到的主体边界: \(bounds)")
        
        // 如果无法检测到有效内容，返回原图
        guard bounds != .zero else { 
            print("⚠️ [cropToSquareAspectRatio] 未检测到有效主体，返回原图")
            return image 
        }
        
        // 计算正方形尺寸（取较大的边）
        let squareSize = max(bounds.width, bounds.height)
        print("📐 [cropToSquareAspectRatio] 计算的正方形尺寸: \(squareSize)")
        
        // 计算居中位置
        let centerX = bounds.midX
        let centerY = bounds.midY
        print("📍 [cropToSquareAspectRatio] 主体中心点: (\(centerX), \(centerY))")
        
        // 🎯 修复：减少边距，避免包含过多背景区域
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let padding: CGFloat = squareSize * 0.05 // 从10%减少到5%的边距
        let finalSquareSize = squareSize + padding * 2
        print("📏 [cropToSquareAspectRatio] 最终正方形尺寸（含边距）: \(finalSquareSize)")
        
        let finalRect = CGRect(
            x: max(0, centerX - finalSquareSize/2),
            y: max(0, centerY - finalSquareSize/2),
            width: min(finalSquareSize, imageSize.width),
            height: min(finalSquareSize, imageSize.height)
        )
        print("✂️ [cropToSquareAspectRatio] 最终裁剪区域: \(finalRect)")
        
        // 裁剪图片
        guard let croppedCGImage = cgImage.cropping(to: finalRect) else { 
            print("❌ [cropToSquareAspectRatio] 裁剪失败")
            return image 
        }
        
        // 创建正方形画布
        let finalSize = CGSize(width: finalSquareSize, height: finalSquareSize)
        UIGraphicsBeginImageContextWithOptions(finalSize, false, image.scale)
        
        let drawRect = CGRect(
            x: (finalSize.width - CGFloat(croppedCGImage.width)) / 2,
            y: (finalSize.height - CGFloat(croppedCGImage.height)) / 2,
            width: CGFloat(croppedCGImage.width),
            height: CGFloat(croppedCGImage.height)
        )
        print("🎨 [cropToSquareAspectRatio] 绘制区域: \(drawRect)")
        
        let croppedUIImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        croppedUIImage.draw(in: drawRect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        print("✅ [cropToSquareAspectRatio] 处理完成，结果尺寸: \(result.size)")
        return result
    }
    
    /// 🎯 新增：智能主体检测，使用双重阈值确保精确识别
    private func getMainSubjectBounds(_ cgImage: CGImage) -> CGRect {
        print("🔍 [getMainSubjectBounds] 开始主体检测，图像尺寸: \(cgImage.width)x\(cgImage.height)")
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            print("❌ [getMainSubjectBounds] 无法创建CGContext")
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else {
            print("❌ [getMainSubjectBounds] 无法获取像素数据")
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        
        // 🎯 使用高阈值进行主体检测
        let highAlphaThreshold: UInt8 = 200
        var bounds = detectBounds(pixelData: pixelData, width: width, height: height, alphaThreshold: highAlphaThreshold)
        print("🎯 [getMainSubjectBounds] 高阈值(\(highAlphaThreshold))检测结果: \(bounds)")
        
        // 如果高阈值检测失败，使用中等阈值作为降级方案
        if bounds == .zero {
            let mediumAlphaThreshold: UInt8 = 128
            bounds = detectBounds(pixelData: pixelData, width: width, height: height, alphaThreshold: mediumAlphaThreshold)
            print("🔄 [getMainSubjectBounds] 降级到中等阈值(\(mediumAlphaThreshold))检测结果: \(bounds)")
        }
        
        print("✅ [getMainSubjectBounds] 最终主体边界: \(bounds)")
        return bounds
    }
    
    /// 检测指定阈值下的边界
    private func detectBounds(pixelData: UnsafeMutablePointer<UInt8>, width: Int, height: Int, alphaThreshold: UInt8) -> CGRect {
        var minX = width, maxX = 0, minY = height, maxY = 0
        var pixelCount = 0
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * 4
                let alpha = pixelData[pixelIndex + 3]
                
                if alpha > alphaThreshold {
                    pixelCount += 1
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        print("📊 [detectBounds] 阈值\(alphaThreshold): 检测到\(pixelCount)个有效像素")
        
        // 如果没有检测到足够的像素，返回零矩形
        if pixelCount < 100 { // 至少需要100个像素才认为是有效主体
            print("⚠️ [detectBounds] 有效像素数量不足(\(pixelCount) < 100)")
            return .zero
        }
        
        let detectedBounds = CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
        
        print("📐 [detectBounds] 检测边界: \(detectedBounds)")
        return detectedBounds
    }
    
    /// 创建缩略图
    func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage {
        return resizeImage(image, to: size)
    }
} 