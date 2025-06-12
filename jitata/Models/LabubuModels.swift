//
//  LabubuModels.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import SwiftUI

// MARK: - Labubu识别结果

/// Labubu识别结果
struct LabubuRecognitionResult {
    let originalImage: UIImage
    let bestMatch: LabubuMatch?
    let alternatives: [LabubuModel]
    let confidence: Double
    let processingTime: TimeInterval
    let features: VisualFeatures
    let timestamp: Date
    
    var isSuccessful: Bool {
        return bestMatch != nil && confidence > 0.3
    }
}

/// Labubu匹配结果
struct LabubuMatch {
    let model: LabubuModel
    let series: LabubuSeries?
    let confidence: Double
    let matchedFeatures: [String]
}

// MARK: - 族谱成员
struct FamilyMember: Codable, Identifiable {
    let id: String
    let name: String
    let rarity: RarityLevel
    let imageURL: URL?
    let averagePrice: Double?
    let isOwned: Bool  // 用户是否拥有
    let releaseDate: Date?
    let description: String?
}

// MARK: - 稀有度等级
enum RarityLevel: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case secret = "secret"
    
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .uncommon: return "不常见"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        case .secret: return "隐藏"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .secret: return .pink
        }
    }
    
    var priority: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 4
        case .legendary: return 5
        case .secret: return 6
        }
    }
}

// MARK: - Labubu检测结果
struct LabubuDetectionResult {
    let isLabubu: Bool
    let confidence: Double
    let features: [String: Any]?
    let processingTime: TimeInterval
    
    static let notLabubu = LabubuDetectionResult(
        isLabubu: false,
        confidence: 0.0,
        features: nil,
        processingTime: 0.0
    )
}

// MARK: - 价格信息
struct PriceInfo: Codable {
    let currentPrice: Double
    let averagePrice7d: Double
    let averagePrice30d: Double
    let priceChange7d: Double
    let priceChange30d: Double
    let currency: String
    let lastUpdated: Date
    let marketTrend: MarketTrend
    
    enum MarketTrend: String, Codable {
        case rising = "rising"
        case falling = "falling"
        case stable = "stable"
        
        var displayName: String {
            switch self {
            case .rising: return "上涨"
            case .falling: return "下跌"
            case .stable: return "稳定"
            }
        }
        
        var color: Color {
            switch self {
            case .rising: return .green
            case .falling: return .red
            case .stable: return .gray
            }
        }
    }
}

// MARK: - Labubu系列信息
struct LabubuSeries: Codable, Identifiable {
    let id: String
    let name: String
    let nameCN: String  // 添加中文名
    let description: String
    let releaseDate: Date
    let theme: String
    let totalVariants: Int
    let imageURL: URL?
    let isLimited: Bool
    let averagePrice: Double?
    let isActive: Bool  // 添加是否活跃
    
    init(id: String, name: String, nameCN: String? = nil, description: String, releaseDate: Date, theme: String, totalVariants: Int, imageURL: URL? = nil, isLimited: Bool = false, averagePrice: Double? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.nameCN = nameCN ?? name
        self.description = description
        self.releaseDate = releaseDate
        self.theme = theme
        self.totalVariants = totalVariants
        self.imageURL = imageURL
        self.isLimited = isLimited
        self.averagePrice = averagePrice
        self.isActive = isActive
    }
}

// MARK: - CoreML 相关模型

/// CoreML 快速分类结果
struct LabubuQuickClassificationResult {
    let isLabubu: Bool
    let confidence: Double
    let processingTime: TimeInterval
    let method: ClassificationMethod
    
    enum ClassificationMethod {
        case coreML
        case rules
    }
}

/// CoreML 特征提取结果
struct LabubuFeatureExtractionResult {
    let features: [Float]
    let processingTime: TimeInterval
}

// MARK: - 本地缓存的Labubu特征
struct CachedLabubuFeature: Codable {
    let seriesId: String
    let features: [Float]  // 特征向量
    let timestamp: Date
    var hitCount: Int
    
    func isExpired(days: Int) -> Bool {
        let expirationDate = Calendar.current.date(byAdding: .day, value: days, to: timestamp) ?? Date()
        return Date() > expirationDate
    }
}

// MARK: - CoreML相关模型

/// 快速检测结果（Phase 3版本）
struct LabubuQuickDetectionResult: Codable {
    let isLabubu: Bool
    let confidence: Double
    let processingTime: TimeInterval
    let timestamp: Date
    
    init(isLabubu: Bool, confidence: Double, processingTime: TimeInterval) {
        self.isLabubu = isLabubu
        self.confidence = confidence
        self.processingTime = processingTime
        self.timestamp = Date()
    }
}

/// 系列分类候选结果
struct LabubuSeriesCandidate: Codable, Identifiable {
    let id = UUID()
    let seriesId: String
    let seriesName: String
    let confidence: Double
    let features: [Float]?
    
    init(seriesId: String, seriesName: String, confidence: Double, features: [Float]? = nil) {
        self.seriesId = seriesId
        self.seriesName = seriesName
        self.confidence = confidence
        self.features = features
    }
}

/// 分类结果
struct LabubuClassificationResult: Codable {
    let candidates: [LabubuSeriesCandidate]
    let processingTime: TimeInterval
    let timestamp: Date
    let method: ClassificationMethod
    
    init(candidates: [LabubuSeriesCandidate], processingTime: TimeInterval, method: ClassificationMethod = .coreML) {
        self.candidates = candidates
        self.processingTime = processingTime
        self.timestamp = Date()
        self.method = method
    }
    
    var topCandidate: LabubuSeriesCandidate? {
        return candidates.first
    }
}

/// 分类方法
enum ClassificationMethod: String, Codable {
    case coreML = "coreml"
    case rules = "rules"
    case cloud = "cloud"
    case hybrid = "hybrid"
}

/// 性能监控数据
struct LabubuPerformanceMetrics: Codable {
    let sessionId: String
    let totalRecognitions: Int
    let averageProcessingTime: TimeInterval
    let successRate: Double
    let cacheHitRate: Double
    let cloudAPICallCount: Int
    let localProcessingCount: Int
    let errorCount: Int
    let timestamp: Date
    
    init() {
        self.sessionId = UUID().uuidString
        self.totalRecognitions = 0
        self.averageProcessingTime = 0
        self.successRate = 0
        self.cacheHitRate = 0
        self.cloudAPICallCount = 0
        self.localProcessingCount = 0
        self.errorCount = 0
        self.timestamp = Date()
    }
}

/// 模型版本信息
struct LabubuModelVersion: Codable {
    let version: String
    let releaseDate: Date
    let downloadURL: String
    let checksum: String
    let size: Int64
    let description: String
    let isRequired: Bool
    
    func isNewer(than other: LabubuModelVersion) -> Bool {
        return version.compare(other.version, options: .numeric) == .orderedDescending
    }
}

// MARK: - UI状态管理

/// 用户偏好设置
struct LabubuUserPreferences: Codable {
    var enableCloudRecognition: Bool = true
    var enableCaching: Bool = true
    var autoSaveResults: Bool = true
    var preferredConfidenceThreshold: Double = 0.7
    var enablePerformanceMonitoring: Bool = true
    var enableHapticFeedback: Bool = true
    var preferredRecognitionMode: RecognitionMode = .balanced
    
    enum RecognitionMode: String, Codable, CaseIterable {
        case fast = "fast"           // 优先速度
        case balanced = "balanced"   // 平衡模式
        case accurate = "accurate"   // 优先准确度
        
        var displayName: String {
            switch self {
            case .fast:
                return "快速模式"
            case .balanced:
                return "平衡模式"
            case .accurate:
                return "精确模式"
            }
        }
        
        var description: String {
            switch self {
            case .fast:
                return "优先本地识别，速度最快"
            case .balanced:
                return "本地和云端结合，平衡速度和准确度"
            case .accurate:
                return "优先云端识别，准确度最高"
            }
        }
    }
}

// MARK: - 错误处理

/// Labubu识别错误
enum LabubuRecognitionError: LocalizedError, Equatable {
    case imageProcessingFailed
    case modelNotLoaded
    case networkError(String)
    case invalidResponse
    case confidenceTooLow(Double)
    case quotaExceeded
    case serviceUnavailable
    case timeout
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图像处理失败"
        case .modelNotLoaded:
            return "识别模型未加载"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "服务器响应无效"
        case .confidenceTooLow(let confidence):
            return "识别置信度过低: \(Int(confidence * 100))%"
        case .quotaExceeded:
            return "今日识别次数已用完"
        case .serviceUnavailable:
            return "识别服务暂时不可用"
        case .timeout:
            return "识别超时"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageProcessingFailed:
            return "请尝试使用更清晰的图片"
        case .modelNotLoaded:
            return "请重启应用或检查网络连接"
        case .networkError:
            return "请检查网络连接后重试"
        case .invalidResponse:
            return "请稍后重试"
        case .confidenceTooLow:
            return "请尝试更清晰的角度拍摄"
        case .quotaExceeded:
            return "请明天再试或升级到专业版"
        case .serviceUnavailable:
            return "请稍后重试"
        case .timeout:
            return "请检查网络连接后重试"
        case .unknown:
            return "请重启应用后重试"
        }
    }
}

// MARK: - 分析和统计

/// 识别统计数据
struct LabubuRecognitionStats: Codable {
    let totalRecognitions: Int
    let successfulRecognitions: Int
    let averageConfidence: Double
    let mostRecognizedSeries: String?
    let averageProcessingTime: TimeInterval
    let cacheHitRate: Double
    let cloudAPIUsage: Int
    let lastUpdated: Date
    
    var successRate: Double {
        guard totalRecognitions > 0 else { return 0 }
        return Double(successfulRecognitions) / Double(totalRecognitions)
    }
    
    init() {
        self.totalRecognitions = 0
        self.successfulRecognitions = 0
        self.averageConfidence = 0
        self.mostRecognizedSeries = nil
        self.averageProcessingTime = 0
        self.cacheHitRate = 0
        self.cloudAPIUsage = 0
        self.lastUpdated = Date()
    }
}

/// 用户收藏进度
struct LabubuCollectionProgress: Codable {
    let totalSeries: Int
    let collectedSeries: Int
    let completedFamilies: [String]
    let rarityProgress: [RarityLevel: Int]
    let lastUpdated: Date
    
    var completionRate: Double {
        guard totalSeries > 0 else { return 0 }
        return Double(collectedSeries) / Double(totalSeries)
    }
    
    init() {
        self.totalSeries = 0
        self.collectedSeries = 0
        self.completedFamilies = []
        self.rarityProgress = [:]
        self.lastUpdated = Date()
    }
}

// MARK: - 扩展现有模型

// LabubuRecognitionResult 扩展已删除，因为该结构体已在 LabubuRecognitionService.swift 中重新定义

enum ConfidenceLevel: String, Codable, CaseIterable {
    case veryHigh = "very_high"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case veryLow = "very_low"
    
    var displayName: String {
        switch self {
        case .veryHigh:
            return "非常高"
        case .high:
            return "高"
        case .medium:
            return "中等"
        case .low:
            return "低"
        case .veryLow:
            return "很低"
        }
    }
    
    var color: Color {
        switch self {
        case .veryHigh:
            return .green
        case .high:
            return .blue
        case .medium:
            return .orange
        case .low:
            return .red
        case .veryLow:
            return .gray
        }
    }
}

extension RarityLevel {
    /// 获取稀有度权重（用于排序）
    var weight: Int {
        switch self {
        case .common:
            return 1
        case .uncommon:
            return 2
        case .rare:
            return 3
        case .epic:
            return 4
        case .legendary:
            return 5
        case .secret:
            return 6
        }
    }
    
    /// 获取稀有度图标
    var icon: String {
        switch self {
        case .common:
            return "circle"
        case .uncommon:
            return "circle.fill"
        case .rare:
            return "diamond"
        case .epic:
            return "diamond.fill"
        case .legendary:
            return "star"
        case .secret:
            return "star.fill"
        }
    }
}

// MARK: - 缓存相关

/// 缓存项
struct LabubuCacheItem: Codable {
    let key: String
    let data: Data
    let timestamp: Date
    let expirationDate: Date
    let hitCount: Int
    let size: Int64
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

/// 缓存统计（Phase 3版本）
struct LabubuCacheStatistics: Codable {
    let totalItems: Int
    let totalSize: Int64
    let hitCount: Int
    let missCount: Int
    let evictionCount: Int
    let lastCleanup: Date
    
    var hitRate: Double {
        let total = hitCount + missCount
        guard total > 0 else { return 0 }
        return Double(hitCount) / Double(total)
    }
    
    init() {
        self.totalItems = 0
        self.totalSize = 0
        self.hitCount = 0
        self.missCount = 0
        self.evictionCount = 0
        self.lastCleanup = Date()
    }
} 