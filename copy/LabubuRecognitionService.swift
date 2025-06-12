//
//  LabubuRecognitionService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import Vision
import CoreML

/// Labubu识别服务 - 渐进式识别架构
@MainActor
class LabubuRecognitionService: ObservableObject {
    
    static let shared = LabubuRecognitionService()
    
    @Published var isProcessing = false
    @Published var recognitionProgress: Double = 0.0
    @Published var recognitionMessage = ""
    
    // MARK: - 配置常量
    private let localConfidenceThreshold: Double = 0.75
    private let cloudConfidenceThreshold: Double = 0.6
    private let maxCacheSize = 1000
    
    // MARK: - 服务依赖
    private let cacheManager = LabubuCacheManager.shared
    private let coreMLService = LabubuCoreMLService.shared
    private let apiService = LabubuAPIService.shared
    
    private init() {
        // 初始化时预加载热门系列
        Task {
            await cacheManager.preloadPopularFeatures()
        }
    }
    
    // MARK: - 主要识别接口
    
    /// 识别Labubu系列 - 渐进式四层架构
    func recognizeLabubu(from image: UIImage) async throws -> LabubuRecognitionResult? {
        isProcessing = true
        recognitionProgress = 0.0
        recognitionMessage = "开始识别..."
        
        defer {
            isProcessing = false
            recognitionProgress = 1.0
        }
        
        do {
            // 第一层：快速预检（30ms）
            recognitionMessage = "快速预检中..."
            recognitionProgress = 0.1
            
            let preCheckResult = try await quickPreCheck(image: image)
            if !preCheckResult.isLabubu {
                recognitionMessage = "非Labubu玩具"
                return nil
            }
            
            // 第二层：本地特征匹配（200ms）
            recognitionMessage = "本地特征匹配中..."
            recognitionProgress = 0.4
            
            let localResult = try await localFeatureMatching(image: image)
            if localResult.confidence > localConfidenceThreshold {
                recognitionMessage = "本地识别完成"
                recognitionProgress = 0.8
                
                // 获取元数据
                let metadata = await getSeriesMetadata(seriesId: localResult.seriesId)
                return createRecognitionResult(
                    from: localResult,
                    metadata: metadata,
                    method: .local
                )
            }
            
            // 第三层：云端精确识别（800ms）
            recognitionMessage = "云端精确识别中..."
            recognitionProgress = 0.7
            
            let cloudResult = try await cloudPreciseRecognition(image: image)
            if cloudResult.confidence > cloudConfidenceThreshold {
                recognitionMessage = "云端识别完成"
                recognitionProgress = 0.9
                
                // 缓存云端结果到本地
                // 云端结果已通过 cacheManager 自动缓存
                
                let metadata = await getSeriesMetadata(seriesId: cloudResult.seriesId)
                return createRecognitionResult(
                    from: cloudResult,
                    metadata: metadata,
                    method: .cloud
                )
            }
            
            // 第四层：元数据获取和族谱构建
            recognitionMessage = "构建族谱信息..."
            recognitionProgress = 0.95
            
            // 即使置信度不高，也尝试返回最佳匹配
            let bestMatch = localResult.confidence > cloudResult.confidence ? localResult : cloudResult
            let metadata = await getSeriesMetadata(seriesId: bestMatch.seriesId)
            
            recognitionMessage = "识别完成"
            return createRecognitionResult(
                from: bestMatch,
                metadata: metadata,
                method: .hybrid
            )
            
        } catch {
            recognitionMessage = "识别失败: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - 第一层：快速预检
    
    private func quickPreCheck(image: UIImage) async throws -> LabubuDetectionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 使用CoreML服务进行快速分类
        let result = await LabubuCoreMLService.shared.quickLabubuDetection(image)
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        return LabubuDetectionResult(
            isLabubu: result.isLabubu,
            confidence: result.confidence,
            features: nil,
            processingTime: processingTime
        )
    }
    
    private func detectLabubuFeatures(image: UIImage) async -> Bool {
        // 简化的特征检测逻辑
        // 实际实现中会使用训练好的轻量级模型
        
        // 检查图像尺寸和质量
        guard image.size.width > 100 && image.size.height > 100 else {
            return false
        }
        
        // 检查主要颜色特征（Labubu通常有特定的颜色组合）
        let dominantColors = await extractDominantColors(from: image)
        let hasLabubuColors = dominantColors.contains { color in
            // Labubu常见颜色：粉色、白色、黑色等
            isLabubuColor(color)
        }
        
        return hasLabubuColors
    }
    
    private func extractDominantColors(from image: UIImage) async -> [UIColor] {
        // 简化的颜色提取逻辑
        // 实际实现中会使用更精确的颜色聚类算法
        return [UIColor.systemPink, UIColor.white, UIColor.black]
    }
    
    private func isLabubuColor(_ color: UIColor) -> Bool {
        // 检查是否为Labubu典型颜色
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 粉色系
        if red > 0.8 && green < 0.6 && blue > 0.6 {
            return true
        }
        
        // 白色系
        if red > 0.9 && green > 0.9 && blue > 0.9 {
            return true
        }
        
        return false
    }
    
    // MARK: - 第二层：本地特征匹配
    
    func localFeatureMatching(image: UIImage) async throws -> (seriesId: String, confidence: Double) {
        // 使用CoreML服务提取特征
        let features = await coreMLService.extractFeatures(image)
        
        // 在缓存中搜索最相似的特征
        var bestMatch: (seriesId: String, confidence: Double) = ("", 0.0)
        
        // 获取热门系列进行优先匹配
        let popularSeries = cacheManager.getPopularSeries(limit: 50)
        
        for seriesId in popularSeries {
            if let cachedFeatures = cacheManager.getCachedFeature(for: seriesId) {
                let similarity = calculateCosineSimilarity(features, cachedFeatures)
                if similarity > bestMatch.confidence {
                    bestMatch = (seriesId, similarity)
                    
                    // 更新命中次数
                    cacheManager.updateFeatureHitCount(for: seriesId)
                }
            }
        }
        
        return bestMatch
    }
    
    private func extractFeatures(from image: UIImage) async throws -> [Float] {
        // 使用CoreML服务提取特征
        return await LabubuCoreMLService.shared.extractFeatures(image)
    }
    
    private func calculateCosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map { Float($0.0) * Float($0.1) }.reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return Double(dotProduct / (magnitudeA * magnitudeB))
    }
    
    // MARK: - 第三层：云端精确识别
    
    func cloudPreciseRecognition(image: UIImage) async throws -> (seriesId: String, confidence: Double) {
        do {
            // 调用云端API进行精确识别
            let result = try await apiService.recognizeLabubu(image)
            
            if result.success && !result.results.isEmpty {
                let bestMatch = result.results[0]
                
                // 缓存识别结果的特征
                let features = await coreMLService.extractFeatures(image)
                cacheManager.cacheFeature(features, for: bestMatch.seriesId)
                
                return (bestMatch.seriesId, bestMatch.confidence)
            } else {
                // 如果云端识别失败，返回默认结果
                return ("unknown_series", 0.3)
            }
        } catch {
            print("云端识别失败: \(error)")
            // 降级到本地识别结果
            return ("unknown_series", 0.3)
        }
    }
    
    // MARK: - 第四层：元数据获取
    
    func getSeriesMetadata(seriesId: String) async -> LabubuSeries? {
        // 直接从缓存管理器获取（内部已处理缓存逻辑）
        return await fetchSeriesMetadataFromCloud(seriesId: seriesId)
    }
    
    private func fetchSeriesMetadataFromCloud(seriesId: String) async -> LabubuSeries? {
        // 先检查缓存
        if let cachedSeries = cacheManager.getCachedSeriesMetadata(for: seriesId) {
            return cachedSeries
        }
        
        do {
            // 从云端API获取系列元数据
            let metadata = try await apiService.fetchSeriesMetadata(seriesId: seriesId)
            
            // 转换为本地数据模型
            let series = LabubuSeries(
                id: metadata.id,
                name: metadata.name,
                description: metadata.description,
                releaseDate: ISO8601DateFormatter().date(from: metadata.releaseDate) ?? Date(),
                theme: metadata.theme,
                totalVariants: metadata.totalVariants,
                imageURL: metadata.imageURL.flatMap { URL(string: $0) },
                isLimited: metadata.isLimited,
                averagePrice: 299.0 // 默认价格，实际应从价格API获取
            )
            
            // 缓存元数据
            cacheManager.cacheSeriesMetadata(series)
            
            return series
        } catch {
            print("获取系列元数据失败: \(error)")
            // 返回默认元数据
            return LabubuSeries(
                id: seriesId,
                name: "未知系列",
                description: "暂无描述",
                releaseDate: Date(),
                theme: "未知",
                totalVariants: 1,
                imageURL: nil,
                isLimited: false,
                averagePrice: 0.0
            )
        }
    }
    
    // MARK: - 结果构建
    
    func createRecognitionResult(
        from match: (seriesId: String, confidence: Double),
        metadata: LabubuSeries?,
        method: LabubuRecognitionResult.RecognitionMethod
    ) -> LabubuRecognitionResult {
        
        let familyTree = generateFamilyTree(for: match.seriesId)
        
        return LabubuRecognitionResult(
            seriesId: match.seriesId,
            seriesName: metadata?.name ?? "未知系列",
            confidence: match.confidence,
            rarity: .rare, // 根据实际数据确定
            averagePrice: metadata?.averagePrice,
            priceChange7d: 0.05, // 模拟数据
            familyTree: familyTree,
            imageURL: metadata?.imageURL,
            recognitionMethod: method
        )
    }
    
    private func generateFamilyTree(for seriesId: String) -> [FamilyMember] {
        // 模拟族谱数据
        return [
            FamilyMember(
                id: "member_001",
                name: "经典粉色Labubu",
                rarity: .common,
                imageURL: nil,
                averagePrice: 199.0,
                isOwned: false,
                releaseDate: Date(),
                description: "最经典的粉色款式"
            ),
            FamilyMember(
                id: "member_002",
                name: "限定白色Labubu",
                rarity: .rare,
                imageURL: nil,
                averagePrice: 399.0,
                isOwned: false,
                releaseDate: Date(),
                description: "限定发售的白色款式"
            )
        ]
    }
    
    // MARK: - 价格信息获取
    
    private func fetchPriceInfo(for seriesId: String) async -> LabubuPriceInfo? {
        // 先检查缓存
        if let cachedPrice = cacheManager.getCachedPriceInfo(for: seriesId) {
            return cachedPrice
        }
        
        do {
            // 从云端API获取价格信息
            let priceInfo = try await apiService.fetchPriceInfo(seriesId: seriesId)
            
            // 缓存价格信息
            cacheManager.cachePriceInfo(priceInfo)
            
            return priceInfo
        } catch {
            print("获取价格信息失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 公共接口
    
    /// 检查是否为Labubu（快速检测）
    func isLabubu(image: UIImage) async -> Bool {
        do {
            let result = try await quickPreCheck(image: image)
            return result.isLabubu
        } catch {
            print("Labubu检测失败: \(error)")
            return false
        }
    }
    
    /// 获取缓存统计信息
    func getCacheStats() -> LabubuCacheStats {
        return cacheManager.getCacheStats()
    }
    
    /// 清理缓存
    func clearCache() {
        cacheManager.clearAllCaches()
    }
} 