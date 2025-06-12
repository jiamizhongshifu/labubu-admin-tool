//
//  LabubuDatabaseModels.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit

// MARK: - 数据库存储的Labubu模型

/// Labubu数据库模型 - 存储每个Labubu的详细信息
struct LabubuModel: Codable, Identifiable {
    let id: String
    let name: String
    let nameCN: String
    let seriesId: String
    let variant: LabubuVariant
    let rarity: RarityLevel
    let releaseDate: Date?
    let originalPrice: Double?
    let currentMarketPrice: MarketPrice?
    var referenceImages: [ReferenceImage]
    var visualFeatures: VisualFeatures
    let tags: [String]
    let description: String?
    
    /// 创建时间
    let createdAt: Date
    /// 更新时间
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        nameCN: String,
        seriesId: String,
        variant: LabubuVariant = .standard,
        rarity: RarityLevel = .common,
        releaseDate: Date? = nil,
        originalPrice: Double? = nil,
        currentMarketPrice: MarketPrice? = nil,
        referenceImages: [ReferenceImage] = [],
        visualFeatures: VisualFeatures,
        tags: [String] = [],
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameCN = nameCN
        self.seriesId = seriesId
        self.variant = variant
        self.rarity = rarity
        self.releaseDate = releaseDate
        self.originalPrice = originalPrice
        self.currentMarketPrice = currentMarketPrice
        self.referenceImages = referenceImages
        self.visualFeatures = visualFeatures
        self.tags = tags
        self.description = description
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 参考图像

/// 参考图像信息
struct ReferenceImage: Codable, Identifiable {
    let id: String
    let imageURL: String
    let angle: ImageAngle
    let features: ImageFeatures?
    let uploadDate: Date
    
    enum ImageAngle: String, Codable, CaseIterable {
        case front = "front"
        case back = "back"
        case left = "left"
        case right = "right"
        case top = "top"
        case detail = "detail"
        
        var displayName: String {
            switch self {
            case .front: return "正面"
            case .back: return "背面"
            case .left: return "左侧"
            case .right: return "右侧"
            case .top: return "顶部"
            case .detail: return "细节"
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        imageURL: String,
        angle: ImageAngle = .front,
        features: ImageFeatures? = nil
    ) {
        self.id = id
        self.imageURL = imageURL
        self.angle = angle
        self.features = features
        self.uploadDate = Date()
    }
}

// MARK: - 视觉特征

/// 视觉特征 - 用于识别的核心特征
struct VisualFeatures: Codable {
    // 颜色特征
    let primaryColors: [ColorFeature]
    let colorDistribution: [String: Double]
    
    // 形状特征
    let shapeDescriptor: ShapeDescriptor
    let contourPoints: [[Double]]?
    
    // 纹理特征
    let textureFeatures: LabubuTextureFeatures
    
    // 特殊标记
    let specialMarks: [SpecialMark]
    
    // 整体特征向量（用于快速匹配）
    let featureVector: [Float]
}

/// 颜色特征
struct ColorFeature: Codable {
    let color: String // Hex颜色值
    let percentage: Double
    let region: ColorRegion
    
    enum ColorRegion: String, Codable {
        case body = "body"
        case face = "face"
        case accessory = "accessory"
        case background = "background"
    }
}

/// 形状描述符
struct ShapeDescriptor: Codable {
    let aspectRatio: Double
    let roundness: Double
    let symmetry: Double
    let complexity: Double
    let keyPoints: [[Double]]
}

/// 纹理特征
struct LabubuTextureFeatures: Codable {
    let smoothness: Double
    let roughness: Double
    let patterns: [String]
    let materialType: MaterialType
    
    enum MaterialType: String, Codable {
        case plush = "plush"
        case vinyl = "vinyl"
        case plastic = "plastic"
        case fabric = "fabric"
        case mixed = "mixed"
    }
}

/// 特殊标记
struct SpecialMark: Codable {
    let type: MarkType
    let location: CGPoint
    let size: CGSize
    let description: String
    
    enum MarkType: String, Codable {
        case logo = "logo"
        case pattern = "pattern"
        case accessory = "accessory"
        case defect = "defect"
    }
}

// MARK: - 图像特征

/// 图像特征 - 从单张图像提取的特征
struct ImageFeatures: Codable {
    let colorHistogram: [Float]
    let edgeHistogram: [Float]
    let textureDescriptor: [Float]
    let shapeFeatures: [Float]
    let deepFeatures: [Float]? // 深度学习特征（如果可用）
    
    /// 合并所有特征为单一向量
    var combinedFeatures: [Float] {
        var features: [Float] = []
        features.append(contentsOf: colorHistogram)
        features.append(contentsOf: edgeHistogram)
        features.append(contentsOf: textureDescriptor)
        features.append(contentsOf: shapeFeatures)
        if let deep = deepFeatures {
            features.append(contentsOf: deep)
        }
        return features
    }
}

// MARK: - 匹配结果

/// 匹配结果
struct MatchResult: Identifiable {
    let id = UUID()
    let model: LabubuModel
    let confidence: Double
    let matchedFeatures: [MatchedFeature]
    let overallScore: Double
    let processingTime: TimeInterval
    
    /// 匹配的特征详情
    struct MatchedFeature {
        let featureType: FeatureType
        let similarity: Double
        let weight: Double
        
        enum FeatureType: String {
            case color = "颜色"
            case shape = "形状"
            case texture = "纹理"
            case pattern = "图案"
            case overall = "整体"
        }
    }
}

// MARK: - 市场价格

/// 市场价格信息
struct MarketPrice: Codable {
    let average: Double
    let min: Double
    let max: Double
    let lastUpdated: Date
    let source: String
}

// MARK: - Labubu变体类型

/// Labubu变体类型
enum LabubuVariant: String, Codable, CaseIterable {
    case standard = "标准版"
    case limited = "限定版"
    case special = "特别版"
    case collaboration = "联名版"
    case anniversary = "周年版"
    case seasonal = "季节版"
    case exclusive = "独占版"
}

// MARK: - 数据库统计

/// 数据库统计信息
struct DatabaseStats: Codable {
    let totalModels: Int
    let totalSeries: Int
    let totalImages: Int
    let lastUpdated: Date
    let storageSize: Int64
    
    var formattedStorageSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: storageSize)
    }
}

// MARK: - 搜索过滤器

/// 搜索过滤器
struct LabubuSearchFilter {
    var seriesIds: Set<String> = []
    var rarities: Set<RarityLevel> = []
    var variants: Set<LabubuVariant> = []
    var priceRange: ClosedRange<Double>?
    var tags: Set<String> = []
    var sortBy: SortOption = .name
    var ascending: Bool = true
    
    enum SortOption: String, CaseIterable {
        case name = "名称"
        case releaseDate = "发布日期"
        case price = "价格"
        case rarity = "稀有度"
        case createdAt = "添加时间"
    }
}

// MARK: - 批量导入结果

/// 批量导入结果
struct BatchImportResult {
    let successful: Int
    let failed: Int
    let errors: [ImportError]
    let duration: TimeInterval
    
    struct ImportError {
        let modelName: String
        let reason: String
    }
}

// MARK: - Supabase数据库模型

/// Supabase数据库中的Labubu模型数据
struct LabubuModelData: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String?
    let nameCN: String
    let seriesId: String
    let seriesName: String
    let modelNumber: String?
    let variant: String
    let rarity: String
    let releaseDate: String?
    let originalPrice: Double?
    let currentPrice: Double?
    let description: String?
    let tags: [String]
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, tags
        case nameEn = "name_en"
        case nameCN = "name_cn"
        case seriesId = "series_id"
        case seriesName = "series_name"
        case modelNumber = "model_number"
        case variant, rarity
        case releaseDate = "release_date"
        case originalPrice = "original_price"
        case currentPrice = "current_price"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// 转换为本地LabubuModel
    func toLabubuModel() -> LabubuModel {
        let dateFormatter = ISO8601DateFormatter()
        
        return LabubuModel(
            id: id,
            name: name,
            nameCN: nameCN,
            seriesId: seriesId,
            variant: LabubuVariant(rawValue: variant) ?? .standard,
            rarity: RarityLevel(rawValue: rarity) ?? .common,
            releaseDate: releaseDate.flatMap { dateFormatter.date(from: $0) },
            originalPrice: originalPrice,
            currentMarketPrice: currentPrice.map { price in
                MarketPrice(
                    average: price,
                    min: price * 0.8,
                    max: price * 1.2,
                    lastUpdated: Date(),
                    source: "Supabase"
                )
            },
            referenceImages: [],
            visualFeatures: VisualFeatures(
                primaryColors: [],
                colorDistribution: [:],
                shapeDescriptor: ShapeDescriptor(
                    aspectRatio: 1.0,
                    roundness: 0.8,
                    symmetry: 0.9,
                    complexity: 0.5,
                    keyPoints: []
                ),
                contourPoints: nil,
                textureFeatures: LabubuTextureFeatures(
                    smoothness: 0.8,
                    roughness: 0.2,
                    patterns: [],
                    materialType: .plush
                ),
                specialMarks: [],
                featureVector: []
            ),
            tags: tags,
            description: description
        )
    }
} 