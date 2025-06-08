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
        guard let cgImage = image.cgImage else { return image }
        
        // 获取图片非透明区域的边界
        let bounds = getNonTransparentBounds(cgImage)
        
        // 如果无法检测到有效内容，返回原图
        guard bounds != .zero else { return image }
        
        // 计算正方形尺寸（取较大的边）
        let squareSize = max(bounds.width, bounds.height)
        
        // 计算居中位置
        let centerX = bounds.midX
        let centerY = bounds.midY
        let squareRect = CGRect(
            x: centerX - squareSize/2,
            y: centerY - squareSize/2,
            width: squareSize,
            height: squareSize
        )
        
        // 确保裁剪区域不超出原图边界，并适当扩展
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let padding: CGFloat = squareSize * 0.1 // 添加10%的边距
        let finalSquareSize = squareSize + padding * 2
        
        let finalRect = CGRect(
            x: max(0, centerX - finalSquareSize/2),
            y: max(0, centerY - finalSquareSize/2),
            width: min(finalSquareSize, imageSize.width),
            height: min(finalSquareSize, imageSize.height)
        )
        
        // 裁剪图片
        guard let croppedCGImage = cgImage.cropping(to: finalRect) else { return image }
        
        // 创建正方形画布
        let finalSize = CGSize(width: finalSquareSize, height: finalSquareSize)
        UIGraphicsBeginImageContextWithOptions(finalSize, false, image.scale)
        
        let drawRect = CGRect(
            x: (finalSize.width - CGFloat(croppedCGImage.width)) / 2,
            y: (finalSize.height - CGFloat(croppedCGImage.height)) / 2,
            width: CGFloat(croppedCGImage.width),
            height: CGFloat(croppedCGImage.height)
        )
        
        let croppedUIImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        croppedUIImage.draw(in: drawRect)
        
        let result = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return result
    }
    
    /// 检测图片中非透明像素的边界
    private func getNonTransparentBounds(_ cgImage: CGImage) -> CGRect {
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
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let data = context.data else {
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        
        var minX = width
        var maxX = 0
        var minY = height
        var maxY = 0
        
        // 扫描所有像素，找到非透明区域的边界
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = (y * width + x) * bytesPerPixel
                let alpha = pixels[pixelIndex + 3] // Alpha通道
                
                // 如果像素不是完全透明
                if alpha > 10 { // 允许一些容差
                    minX = min(minX, x)
                    maxX = max(maxX, x)
                    minY = min(minY, y)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // 如果没有找到非透明像素，返回全图
        if minX >= maxX || minY >= maxY {
            return CGRect(x: 0, y: 0, width: width, height: height)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
    
    /// 创建缩略图
    func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage {
        return resizeImage(image, to: size)
    }
} 