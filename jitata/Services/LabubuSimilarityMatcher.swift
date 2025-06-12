//
//  LabubuSimilarityMatcher.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import Accelerate

/// Labubu相似度匹配器
/// 将用户图片特征与数据库中的模型进行比对
class LabubuSimilarityMatcher: ObservableObject {
    
    static let shared = LabubuSimilarityMatcher()
    
    // MARK: - 匹配权重配置
    private struct MatchingWeights {
        static let colorSimilarity: Double = 0.4      // 颜色相似度权重
        static let shapeSimilarity: Double = 0.3      // 形状相似度权重
        static let textureSimilarity: Double = 0.2    // 纹理相似度权重
        static let vectorSimilarity: Double = 0.1     // 特征向量相似度权重
    }
    
    private init() {}
    
    // MARK: - 主要匹配方法
    
    /// 查找相似的Labubu模型
    /// - Parameters:
    ///   - userFeatures: 用户图片的特征
    ///   - candidateModels: 候选模型列表
    ///   - maxResults: 最大返回结果数
    /// - Returns: 匹配结果列表，按相似度降序排列
    func findSimilarModels(
        userFeatures: VisualFeatures,
        candidateModels: [LabubuModel],
        maxResults: Int = 5
    ) async throws -> [MatchResult] {
        
        print("🔍 开始相似度匹配，候选模型数量: \(candidateModels.count)")
        
        var matchResults: [MatchResult] = []
        
        for model in candidateModels {
            let similarity = await calculateSimilarity(
                userFeatures: userFeatures,
                modelFeatures: model.visualFeatures
            )
            
            let matchResult = MatchResult(
                model: model,
                confidence: similarity.overallScore,
                matchedFeatures: similarity.matchedFeatures,
                overallScore: similarity.overallScore,
                processingTime: 0.1 // 简化的处理时间
            )
            
            matchResults.append(matchResult)
        }
        
        // 按相似度降序排列
        matchResults.sort { $0.confidence > $1.confidence }
        
        // 返回前N个结果
        let topResults = Array(matchResults.prefix(maxResults))
        
        print("✅ 匹配完成，找到 \(topResults.count) 个匹配结果")
        return topResults
    }
    
    // MARK: - 相似度计算
    
    /// 计算两个特征之间的相似度
    private func calculateSimilarity(
        userFeatures: VisualFeatures,
        modelFeatures: VisualFeatures
    ) async -> SimilarityResult {
        
        // 1. 颜色相似度
        let colorSimilarity = calculateColorSimilarity(
            userColors: userFeatures.primaryColors.map { $0.color },
            modelColors: modelFeatures.primaryColors.map { $0.color }
        )
        
        // 2. 形状相似度
        let shapeSimilarity = calculateShapeSimilarity(
            userShape: userFeatures.shapeDescriptor,
            modelShape: modelFeatures.shapeDescriptor
        )
        
        // 3. 纹理相似度
        let textureSimilarity = calculateTextureSimilarity(
            userTexture: userFeatures.textureFeatures,
            modelTexture: modelFeatures.textureFeatures
        )
        
        // 4. 特征向量相似度
        let vectorSimilarity = calculateVectorSimilarity(
            userVector: userFeatures.featureVector,
            modelVector: modelFeatures.featureVector
        )
        
        // 5. 加权综合评分
        let overallScore = 
            colorSimilarity * MatchingWeights.colorSimilarity +
            shapeSimilarity * MatchingWeights.shapeSimilarity +
            textureSimilarity * MatchingWeights.textureSimilarity +
            vectorSimilarity * MatchingWeights.vectorSimilarity
        
        // 6. 确定匹配的特征
        let matchedFeatures = determineMatchedFeatures(
            colorScore: colorSimilarity,
            shapeScore: shapeSimilarity,
            textureScore: textureSimilarity,
            vectorScore: vectorSimilarity
        )
        
        return SimilarityResult(
            overallScore: overallScore,
            colorScore: colorSimilarity,
            shapeScore: shapeSimilarity,
            textureScore: textureSimilarity,
            vectorScore: vectorSimilarity,
            matchedFeatures: matchedFeatures
        )
    }
    
    // MARK: - 颜色相似度计算
    
    private func calculateColorSimilarity(
        userColors: [String],
        modelColors: [String]
    ) -> Double {
        
        guard !userColors.isEmpty && !modelColors.isEmpty else {
            return 0.0
        }
        
        var totalSimilarity = 0.0
        var comparisons = 0
        
        for userColorHex in userColors {
            for modelColorHex in modelColors {
                if let userColor = UIColor(hex: userColorHex),
                   let modelColor = UIColor(hex: modelColorHex) {
                    let similarity = calculateColorDistance(userColor, modelColor)
                    totalSimilarity += similarity
                    comparisons += 1
                }
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Double(comparisons) : 0.0
    }
    
    private func calculateColorDistance(_ color1: UIColor, _ color2: UIColor) -> Double {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let distance = sqrt(pow(r1 - r2, 2) + pow(g1 - g2, 2) + pow(b1 - b2, 2))
        
        // 将距离转换为相似度（距离越小，相似度越高）
        return max(0.0, 1.0 - Double(distance))
    }
    
    // MARK: - 形状相似度计算
    
    private func calculateShapeSimilarity(
        userShape: ShapeDescriptor,
        modelShape: ShapeDescriptor
    ) -> Double {
        
        // 比较宽高比
        let aspectRatioSimilarity = 1.0 - abs(userShape.aspectRatio - modelShape.aspectRatio) / max(userShape.aspectRatio, modelShape.aspectRatio)
        
        // 比较圆润度
        let roundnessSimilarity = 1.0 - abs(userShape.roundness - modelShape.roundness)
        
        // 比较对称性
        let symmetrySimilarity = 1.0 - abs(userShape.symmetry - modelShape.symmetry)
        
        // 综合形状相似度
        return (aspectRatioSimilarity + roundnessSimilarity + symmetrySimilarity) / 3.0
    }
    
    // MARK: - 纹理相似度计算
    
    private func calculateTextureSimilarity(
        userTexture: LabubuTextureFeatures,
        modelTexture: LabubuTextureFeatures
    ) -> Double {
        
        // 比较表面纹理
        let smoothnessMatch = 1.0 - abs(userTexture.smoothness - modelTexture.smoothness)
        
        // 比较粗糙度
        let roughnessMatch = 1.0 - abs(userTexture.roughness - modelTexture.roughness)
        
        // 材质匹配
        let materialMatch = userTexture.materialType == modelTexture.materialType ? 1.0 : 0.0
        
        return (smoothnessMatch + roughnessMatch + materialMatch) / 3.0
    }
    
    // MARK: - 特征向量相似度计算
    
    private func calculateVectorSimilarity(
        userVector: [Float],
        modelVector: [Float]
    ) -> Double {
        
        guard userVector.count == modelVector.count && !userVector.isEmpty else {
            return 0.0
        }
        
        // 计算余弦相似度
        return cosineSimilarity(userVector, modelVector)
    }
    
    private func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Double {
        guard vector1.count == vector2.count else { return 0.0 }
        
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<vector1.count {
            dotProduct += vector1[i] * vector2[i]
            norm1 += vector1[i] * vector1[i]
            norm2 += vector2[i] * vector2[i]
        }
        
        let denominator = sqrt(norm1) * sqrt(norm2)
        return denominator > 0 ? Double(dotProduct / denominator) : 0.0
    }
    
    // MARK: - 匹配特征确定
    
    private func determineMatchedFeatures(
        colorScore: Double,
        shapeScore: Double,
        textureScore: Double,
        vectorScore: Double
    ) -> [MatchResult.MatchedFeature] {
        
        var features: [MatchResult.MatchedFeature] = []
        
        if colorScore > 0.7 {
            features.append(MatchResult.MatchedFeature(
                featureType: .color,
                similarity: colorScore,
                weight: MatchingWeights.colorSimilarity
            ))
        }
        
        if shapeScore > 0.7 {
            features.append(MatchResult.MatchedFeature(
                featureType: .shape,
                similarity: shapeScore,
                weight: MatchingWeights.shapeSimilarity
            ))
        }
        
        if textureScore > 0.7 {
            features.append(MatchResult.MatchedFeature(
                featureType: .texture,
                similarity: textureScore,
                weight: MatchingWeights.textureSimilarity
            ))
        }
        
        if vectorScore > 0.7 {
            features.append(MatchResult.MatchedFeature(
                featureType: .overall,
                similarity: vectorScore,
                weight: MatchingWeights.vectorSimilarity
            ))
        }
        
        // 如果没有强匹配特征，添加一些通用描述
        if features.isEmpty {
            if colorScore > 0.4 {
                features.append(MatchResult.MatchedFeature(
                    featureType: .color,
                    similarity: colorScore,
                    weight: MatchingWeights.colorSimilarity
                ))
            }
            if shapeScore > 0.4 {
                features.append(MatchResult.MatchedFeature(
                    featureType: .shape,
                    similarity: shapeScore,
                    weight: MatchingWeights.shapeSimilarity
                ))
            }
        }
        
        return features
    }
    
    /// 生成匹配报告
    func generateMatchReport(for result: MatchResult) -> String {
        var report = "🎯 识别结果报告\n\n"
        
        report += "📋 基本信息:\n"
        report += "• 模型名称: \(result.model.name)\n"
        report += "• 置信度: \(String(format: "%.1f%%", result.confidence * 100))\n"
        report += "• 处理时间: \(String(format: "%.2f秒", result.processingTime))\n\n"
        
        report += "🔍 匹配特征:\n"
        for feature in result.matchedFeatures {
            let percentage = String(format: "%.1f%%", feature.similarity * 100)
            report += "• \(feature.featureType.rawValue): \(percentage)\n"
        }
        
        report += "\n📊 综合评分: \(String(format: "%.1f%%", result.overallScore * 100))"
        
        return report
    }
    
    // MARK: - 快速匹配方法
    
    /// 快速匹配方法 - 使用特征向量进行快速筛选
    func quickMatch(
        featureVector: [Float],
        with models: [LabubuModel]
    ) -> [MatchResult] {
        
        var quickResults: [MatchResult] = []
        
        for model in models {
            // 计算特征向量相似度
            let vectorSimilarity = calculateVectorSimilarity(
                userVector: featureVector,
                modelVector: model.visualFeatures.featureVector
            )
            
            let matchResult = MatchResult(
                model: model,
                confidence: vectorSimilarity,
                matchedFeatures: [MatchResult.MatchedFeature(
                    featureType: .overall,
                    similarity: vectorSimilarity,
                    weight: 1.0
                )],
                overallScore: vectorSimilarity,
                processingTime: 0.01 // 快速匹配时间很短
            )
            
            quickResults.append(matchResult)
        }
        
        // 按相似度降序排列
        quickResults.sort { $0.confidence > $1.confidence }
        
        return quickResults
    }
    
    /// 详细匹配方法 - 对候选模型进行详细特征匹配
    func matchImage(
        _ image: UIImage,
        with candidateModels: [LabubuModel]
    ) async throws -> [MatchResult] {
        
        // 提取用户图片的完整特征
        let featureExtractor = LabubuFeatureExtractor()
        let userFeatures = try await featureExtractor.extractFeatures(from: image)
        
        // 使用完整特征进行详细匹配
        return try await findSimilarModels(
            userFeatures: userFeatures,
            candidateModels: candidateModels,
            maxResults: candidateModels.count
        )
    }
    
    /// 评估匹配质量
    func evaluateMatchQuality(_ confidence: Double) -> MatchQuality {
        switch confidence {
        case 0.9...1.0:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .fair
        case 0.4..<0.6:
            return .poor
        default:
            return .veryPoor
        }
    }
}

// MARK: - 辅助数据结构

/// 相似度计算结果
private struct SimilarityResult {
    let overallScore: Double
    let colorScore: Double
    let shapeScore: Double
    let textureScore: Double
    let vectorScore: Double
    let matchedFeatures: [MatchResult.MatchedFeature]
}

// MARK: - UIColor扩展

extension UIColor {
    convenience init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

// MARK: - 匹配质量枚举

enum MatchQuality {
    case excellent
    case good
    case fair
    case poor
    case veryPoor
    
    var description: String {
        switch self {
        case .excellent:
            return "极佳匹配"
        case .good:
            return "良好匹配"
        case .fair:
            return "一般匹配"
        case .poor:
            return "较差匹配"
        case .veryPoor:
            return "很差匹配"
        }
    }
}
