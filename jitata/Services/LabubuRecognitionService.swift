//
//  LabubuRecognitionService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import SwiftUI
import Vision
import CoreImage

/// 真正的Labubu识别服务
/// 基于图像特征提取和数据库比对的识别方案
class LabubuRecognitionService: ObservableObject {
    
    static let shared = LabubuRecognitionService()
    
    // MARK: - 依赖服务
    private let databaseManager = LabubuDatabaseManager.shared
    private let featureExtractor = LabubuFeatureExtractor.shared
    private let similarityMatcher = LabubuSimilarityMatcher.shared
    
    // MARK: - 状态管理
    @Published var isRecognizing = false
    @Published var recognitionProgress: Double = 0.0
    @Published var lastRecognitionResult: LabubuRecognitionResult?
    
    private init() {}
    
    // MARK: - 主要识别方法
    
    /// 识别Labubu（真实版本）
    /// - Parameter image: 用户拍摄的图片
    /// - Returns: 识别结果
    func recognizeLabubu(_ image: UIImage) async throws -> LabubuRecognitionResult {
        print("🔍 开始真实Labubu识别...")
        
        await MainActor.run {
            isRecognizing = true
            recognitionProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isRecognizing = false
                recognitionProgress = 1.0
            }
        }
        
        let startTime = Date()
        
        do {
            // 第一步：预处理图像 (10%)
            await updateProgress(0.1)
            let preprocessedImage = try await preprocessImage(image)
            
            // 第二步：快速检测是否为Labubu (20%)
            await updateProgress(0.2)
            let isLabubu = try await quickLabubuDetection(preprocessedImage)
            
            if !isLabubu {
                throw LabubuRecognitionError.imageProcessingFailed
            }
            
            // 第三步：提取图片特征 (60%)
            await updateProgress(0.6)
            let features = try await extractImageFeatures(preprocessedImage)
            
            // 第四步：数据库匹配 (90%)
            await updateProgress(0.9)
            let matchResults = try await findBestMatches(features: features)
            
            // 第五步：构建结果 (100%)
            await updateProgress(1.0)
            let result = try await buildRecognitionResult(
                image: image,
                matchResults: matchResults,
                features: features,
                processingTime: Date().timeIntervalSince(startTime)
            )
            
            await MainActor.run {
                lastRecognitionResult = result
            }
            
            print("✅ 识别完成: \(result.bestMatch?.model.name ?? "未识别")")
            return result
            
        } catch {
            print("❌ 识别失败: \(error)")
            throw error
        }
    }
    
    // MARK: - 识别步骤实现
    
    /// 预处理图像
    private func preprocessImage(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let ciImage = CIImage(image: image) else {
                    continuation.resume(throwing: LabubuRecognitionError.imageProcessingFailed)
                    return
                }
                
                let context = CIContext()
                
                // 1. 调整亮度和对比度
                let adjustedImage = ciImage
                    .applyingFilter("CIColorControls", parameters: [
                        "inputBrightness": 0.1,
                        "inputContrast": 1.2,
                        "inputSaturation": 1.1
                    ])
                
                // 2. 降噪
                let denoisedImage = adjustedImage
                    .applyingFilter("CINoiseReduction", parameters: [
                        "inputNoiseLevel": 0.02,
                        "inputSharpness": 0.4
                    ])
                
                // 3. 转换回UIImage
                guard let cgImage = context.createCGImage(denoisedImage, from: denoisedImage.extent) else {
                    continuation.resume(throwing: LabubuRecognitionError.imageProcessingFailed)
                    return
                }
                
                let processedImage = UIImage(cgImage: cgImage)
                continuation.resume(returning: processedImage)
            }
        }
    }
    
    /// 快速检测是否为Labubu
    private func quickLabubuDetection(_ image: UIImage) async throws -> Bool {
        // 使用Vision框架进行物体检测
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: LabubuRecognitionError.imageProcessingFailed)
                return
            }
            
            // 创建物体检测请求
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // 检查是否检测到矩形物体（Labubu的基本形状）
                let hasRectangularObject = request.results?.isEmpty == false
                
                // 简化版本：如果检测到物体，假设是Labubu
                // 在实际应用中，这里可以使用更复杂的分类器
                continuation.resume(returning: hasRectangularObject)
            }
            
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 2.0
            request.minimumSize = 0.1
            request.maximumObservations = 10
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 提取图片特征
    private func extractImageFeatures(_ image: UIImage) async throws -> VisualFeatures {
        return try await featureExtractor.extractFeatures(from: image)
    }
    
    /// 在数据库中查找最佳匹配
    private func findBestMatches(features: VisualFeatures) async throws -> [MatchResult] {
        let allModels = databaseManager.getAllModels()
        
        guard !allModels.isEmpty else {
            throw LabubuRecognitionError.serviceUnavailable
        }
        
        // 使用相似度匹配器进行匹配
        let matches = try await similarityMatcher.findSimilarModels(
            userFeatures: features,
            candidateModels: allModels,
            maxResults: 5
        )
        
        return matches
    }
    
    /// 构建识别结果
    private func buildRecognitionResult(
        image: UIImage,
        matchResults: [MatchResult],
        features: VisualFeatures,
        processingTime: TimeInterval
    ) async throws -> LabubuRecognitionResult {
        
        guard let bestMatch = matchResults.first else {
            return LabubuRecognitionResult(
                originalImage: image,
                bestMatch: nil,
                alternatives: [],
                confidence: 0.0,
                processingTime: processingTime,
                features: features,
                timestamp: Date()
            )
        }
        
        // 获取系列信息
        let series = databaseManager.getSeries(id: bestMatch.model.seriesId)
        
        // 构建最佳匹配
        let labubuMatch = LabubuMatch(
            model: bestMatch.model,
            series: series,
            confidence: bestMatch.confidence,
            matchedFeatures: bestMatch.matchedFeatures.map { $0.featureType.rawValue }
        )
        
        // 构建备选项
        let alternatives = Array(matchResults.dropFirst().prefix(3)).map { $0.model }
        
        return LabubuRecognitionResult(
            originalImage: image,
            bestMatch: labubuMatch,
            alternatives: alternatives,
            confidence: bestMatch.confidence,
            processingTime: processingTime,
            features: features,
            timestamp: Date()
        )
    }
    
    // MARK: - 辅助方法
    
    @MainActor
    private func updateProgress(_ progress: Double) {
        recognitionProgress = progress
    }
}

 