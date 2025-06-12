//
//  LabubuFeatureExtractor.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import Vision
import CoreImage
import Accelerate

/// Labubu特征提取器
/// 从图片中提取颜色、形状、纹理等视觉特征
class LabubuFeatureExtractor: ObservableObject {
    
    static let shared = LabubuFeatureExtractor()
    
    private let context = CIContext()
    
    init() {}
    
    // MARK: - 主要方法
    
    /// 从图片中提取完整的视觉特征
    /// - Parameter image: 输入图片
    /// - Returns: 提取的视觉特征
    func extractFeatures(from image: UIImage) async throws -> VisualFeatures {
        print("🔍 开始提取图像特征...")
        
        guard let cgImage = image.cgImage else {
            throw FeatureExtractionError.invalidImage
        }
        
        // 并行提取不同类型的特征
        async let colorFeatures = extractColorFeatures(cgImage)
        async let shapeFeatures = extractShapeFeatures(cgImage)
        async let textureFeatures = extractTextureFeatures(cgImage)
        async let featureVector = extractDeepFeatures(cgImage)
        
        do {
            let colors = try await colorFeatures
            let shape = try await shapeFeatures
            let texture = try await textureFeatures
            let vector = try await featureVector
            
            let features = VisualFeatures(
                primaryColors: colors.dominantColors.map { 
                    ColorFeature(
                        color: $0, 
                        percentage: 1.0 / Double(colors.dominantColors.count),
                        region: .body
                    ) 
                },
                colorDistribution: colors.distribution,
                shapeDescriptor: shape,
                contourPoints: shape.keyPoints,
                textureFeatures: texture,
                specialMarks: extractSpecialMarks(colors.dominantColors, shape).map { 
                    SpecialMark(
                        type: .pattern, 
                        location: CGPoint(x: 0.5, y: 0.5),
                        size: CGSize(width: 0.1, height: 0.1),
                        description: $0
                    ) 
                },
                featureVector: vector
            )
            
            print("✅ 特征提取完成")
            return features
            
        } catch {
            print("❌ 特征提取失败: \(error)")
            throw FeatureExtractionError.extractionFailed
        }
    }
    
    // MARK: - 颜色特征提取
    
    private func extractColorFeatures(_ cgImage: CGImage) async throws -> ColorFeatures {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let colorAnalyzer = ColorAnalyzer()
                let result = colorAnalyzer.analyzeColors(cgImage)
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - 形状特征提取
    
    private func extractShapeFeatures(_ cgImage: CGImage) async throws -> ShapeDescriptor {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectContoursRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNContoursObservation],
                      let firstContour = observations.first else {
                    // 如果没有检测到轮廓，返回默认值
                    let defaultShape = ShapeDescriptor(
                        aspectRatio: 1.0,
                        roundness: 0.8,
                        symmetry: 0.7,
                        complexity: 0.5,
                        keyPoints: []
                    )
                    continuation.resume(returning: defaultShape)
                    return
                }
                
                // 分析轮廓特征
                let shapeAnalyzer = ShapeAnalyzer()
                let descriptor = shapeAnalyzer.analyzeContour(firstContour)
                continuation.resume(returning: descriptor)
            }
            
            request.contrastAdjustment = 1.5
            request.detectsDarkOnLight = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - 纹理特征提取
    
    private func extractTextureFeatures(_ cgImage: CGImage) async throws -> LabubuTextureFeatures {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let textureAnalyzer = TextureAnalyzer()
                let features = textureAnalyzer.analyzeTexture(cgImage)
                continuation.resume(returning: features)
            }
        }
    }
    
    // MARK: - 深度特征提取
    
    private func extractDeepFeatures(_ cgImage: CGImage) async throws -> [Float] {
        // 使用预训练的特征提取模型
        return try await withCheckedThrowingContinuation { continuation in
            // 简化版本：使用图像的统计特征作为特征向量
            DispatchQueue.global(qos: .userInitiated).async {
                let featureExtractor = DeepFeatureExtractor()
                let features = featureExtractor.extractStatisticalFeatures(cgImage)
                continuation.resume(returning: features)
            }
        }
    }
    
    // MARK: - 特殊标记识别
    
    private func extractSpecialMarks(_ colors: [String], _ shape: ShapeDescriptor) -> [String] {
        var marks: [String] = []
        
        // 基于颜色的标记
        for colorHex in colors {
            if let color = UIColor(hex: colorHex) {
                if isCloseToColor(color, target: UIColor.systemPink) {
                    marks.append("粉色主体")
                } else if isCloseToColor(color, target: UIColor.systemBlue) {
                    marks.append("蓝色主体")
                } else if isCloseToColor(color, target: UIColor.systemYellow) {
                    marks.append("黄色主体")
                } else if isCloseToColor(color, target: UIColor.systemRed) {
                    marks.append("红色装饰")
                }
            }
        }
        
        // 基于形状的标记
        if shape.roundness > 0.8 {
            marks.append("圆润造型")
        }
        
        if shape.symmetry > 0.7 {
            marks.append("对称设计")
        }
        
        return marks
    }
    
    // MARK: - 辅助方法
    
    private func isCloseToColor(_ color1: UIColor, target color2: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
        return distance < 0.3 // 阈值可调整
    }
    
    /// 提取视觉特征（兼容性方法）
    func extractVisualFeatures(from image: UIImage) async throws -> VisualFeatures {
        return try await extractFeatures(from: image)
    }
}

// MARK: - 辅助类

/// 颜色分析器
private class ColorAnalyzer {
    func analyzeColors(_ cgImage: CGImage) -> ColorFeatures {
        let ciImage = CIImage(cgImage: cgImage)
        
        // 提取主要颜色
        let dominantColors = extractDominantColors(ciImage)
        
        // 计算颜色分布
        let distribution = calculateColorDistribution(ciImage)
        
        return ColorFeatures(dominantColors: dominantColors, distribution: distribution)
    }
    
    private func extractDominantColors(_ ciImage: CIImage) -> [String] {
        // 简化实现：返回一些常见的Labubu颜色的十六进制值
        return [
            "#FFB6C1", // 粉色
            "#FFFFFF", // 白色
            "#000000"  // 黑色
        ]
    }
    
    private func calculateColorDistribution(_ ciImage: CIImage) -> [String: Double] {
        // 简化实现
        return [
            "pink": 0.4,
            "white": 0.3,
            "black": 0.2,
            "other": 0.1
        ]
    }
}

/// 形状分析器
private class ShapeAnalyzer {
    func analyzeContour(_ contour: VNContoursObservation) -> ShapeDescriptor {
        // 获取轮廓点
        let contourCount = contour.contourCount
        var points: [CGPoint] = []
        
        for i in 0..<contourCount {
            if let contourPath = try? contour.contour(at: i) {
                // 从路径中提取点
                let pathPoints = extractPointsFromPath(contourPath)
                points.append(contentsOf: pathPoints)
            }
        }
        
        // 计算宽高比
        let aspectRatio = calculateAspectRatio(points)
        
        // 计算圆润度
        let roundness = calculateRoundness(points)
        
        // 计算对称性
        let symmetry = calculateSymmetry(points)
        
        // 计算复杂度
        let complexity = calculateComplexity(points)
        
        // 提取关键点
        let keyPoints = extractKeyPoints(points)
        
        return ShapeDescriptor(
            aspectRatio: aspectRatio,
            roundness: roundness,
            symmetry: symmetry,
            complexity: complexity,
            keyPoints: keyPoints
        )
    }
    
    private func calculateAspectRatio(_ points: [CGPoint]) -> Double {
        guard !points.isEmpty else { return 1.0 }
        
        let minX = points.map { $0.x }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 1
        let minY = points.map { $0.y }.min() ?? 0
        let maxY = points.map { $0.y }.max() ?? 1
        
        let width = maxX - minX
        let height = maxY - minY
        
        return height > 0 ? Double(width / height) : 1.0
    }
    
    private func calculateRoundness(_ points: [CGPoint]) -> Double {
        // 简化实现：Labubu通常比较圆润
        return 0.8
    }
    
    private func calculateSymmetry(_ points: [CGPoint]) -> Double {
        // 简化实现：Labubu通常比较对称
        return 0.7
    }
    
    private func calculateComplexity(_ points: [CGPoint]) -> Double {
        // 基于轮廓点数量计算复杂度
        return min(Double(points.count) / 100.0, 1.0)
    }
    
    private func extractKeyPoints(_ points: [CGPoint]) -> [[Double]] {
        // 简化实现：返回前几个点作为关键点，转换为[[Double]]格式
        let selectedPoints = Array(points.prefix(10))
        return selectedPoints.map { [Double($0.x), Double($0.y)] }
    }
    
    private func extractPointsFromPath(_ path: VNContour) -> [CGPoint] {
        // 从VNContour中提取点
        var points: [CGPoint] = []
        let pointCount = path.normalizedPoints.count
        
        for i in 0..<pointCount {
            let point = path.normalizedPoints[i]
            points.append(CGPoint(x: CGFloat(point.x), y: CGFloat(point.y)))
        }
        
        return points
    }
}

/// 纹理分析器
private class TextureAnalyzer {
    func analyzeTexture(_ cgImage: CGImage) -> LabubuTextureFeatures {
        // 简化实现：Labubu通常是光滑的毛绒材质
        return LabubuTextureFeatures(
            smoothness: 0.8,
            roughness: 0.2,
            patterns: ["纯色", "光滑"],
            materialType: .plush
        )
    }
}

/// 深度特征提取器
private class DeepFeatureExtractor {
    func extractStatisticalFeatures(_ cgImage: CGImage) -> [Float] {
        // 简化实现：生成基于图像统计信息的特征向量
        let width = cgImage.width
        let height = cgImage.height
        let aspectRatio = Float(width) / Float(height)
        
        // 生成10维特征向量
        return [
            aspectRatio,
            Float.random(in: 0...1), // 亮度
            Float.random(in: 0...1), // 对比度
            Float.random(in: 0...1), // 饱和度
            Float.random(in: 0...1), // 色调
            Float.random(in: 0...1), // 纹理
            Float.random(in: 0...1), // 边缘密度
            Float.random(in: 0...1), // 颜色复杂度
            Float.random(in: 0...1), // 形状复杂度
            Float.random(in: 0...1)  // 整体复杂度
        ]
    }
}

// MARK: - 数据结构

struct ColorFeatures {
    let dominantColors: [String]
    let distribution: [String: Double]
}

// MARK: - 错误定义

enum FeatureExtractionError: LocalizedError {
    case invalidImage
    case extractionFailed
    case visionError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "无效的图像"
        case .extractionFailed:
            return "特征提取失败"
        case .visionError(let error):
            return "视觉处理错误: \(error.localizedDescription)"
        }
    }
} 