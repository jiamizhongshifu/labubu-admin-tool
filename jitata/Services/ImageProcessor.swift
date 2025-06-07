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
    
    /// 创建缩略图
    func createThumbnail(from image: UIImage, size: CGSize = CGSize(width: 150, height: 150)) -> UIImage {
        return resizeImage(image, to: size)
    }
} 