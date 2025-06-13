//
//  LabubuDatabaseManager.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit

/// Labubu数据库管理器 - 管理Supabase云端数据库的Labubu合集数据
class LabubuDatabaseManager: ObservableObject {
    
    static let shared = LabubuDatabaseManager()
    
    // MARK: - 属性
    
    private let bundleModelsFile: String = "labubu_models"
    private let bundleSeriesFile: String = "labubu_series"
    
    @Published private(set) var models: [LabubuModel] = []
    @Published private(set) var series: [LabubuSeries] = []
    @Published var isLoading = false
    @Published var lastSyncTime: Date?
    @Published var errorMessage: String?
    
    private let queue = DispatchQueue(label: "com.jitata.labubu.database", attributes: .concurrent)
    private let supabaseService = LabubuSupabaseDatabaseService.shared
    
    // MARK: - 初始化
    
    private init() {
        loadDatabase()
    }
    
    // MARK: - 只读查询接口
    
    /// 获取所有模型
    func getAllModels() -> [LabubuModel] {
        queue.sync {
            return models
        }
    }
    
    /// 根据系列ID获取模型
    func getModels(for seriesId: String) -> [LabubuModel] {
        queue.sync {
            return models.filter { $0.seriesId == seriesId }
        }
    }
    
    /// 根据ID获取模型
    func getModel(id: String) -> LabubuModel? {
        queue.sync {
            return models.first { $0.id == id }
        }
    }
    
    /// 获取所有系列
    func getAllSeries() -> [LabubuSeries] {
        queue.sync {
            return series
        }
    }
    
    /// 根据ID获取系列
    func getSeries(id: String) -> LabubuSeries? {
        queue.sync {
            return series.first { $0.id == id }
        }
    }
    
    /// 简单文本搜索模型
    func searchModels(query: String) -> [LabubuModel] {
        guard !query.isEmpty else { return models }
        
        return queue.sync {
            return models.filter { model in
                model.name.localizedCaseInsensitiveContains(query) ||
                model.nameCN.localizedCaseInsensitiveContains(query) ||
                model.tags.contains { $0.localizedCaseInsensitiveContains(query) }
            }
        }
    }
    
    /// 高级搜索模型
    func searchModels(with filter: LabubuSearchFilter) -> [LabubuModel] {
        queue.sync {
            var results = models
            
            // 应用过滤器
            if !filter.seriesIds.isEmpty {
                results = results.filter { filter.seriesIds.contains($0.seriesId) }
            }
            
            if !filter.rarities.isEmpty {
                results = results.filter { filter.rarities.contains($0.rarity) }
            }
            
            if !filter.variants.isEmpty {
                results = results.filter { filter.variants.contains($0.variant) }
            }
            
            if let priceRange = filter.priceRange {
                results = results.filter { model in
                    if let price = model.currentMarketPrice?.average ?? model.originalPrice {
                        return priceRange.contains(price)
                    }
                    return false
                }
            }
            
            if !filter.tags.isEmpty {
                results = results.filter { model in
                    !Set(model.tags).intersection(filter.tags).isEmpty
                }
            }
            
            // 排序
            results.sort { lhs, rhs in
                switch filter.sortBy {
                case .name:
                    return filter.ascending ? lhs.name < rhs.name : lhs.name > rhs.name
                case .releaseDate:
                    let lhsDate = lhs.releaseDate ?? Date.distantPast
                    let rhsDate = rhs.releaseDate ?? Date.distantPast
                    return filter.ascending ? lhsDate < rhsDate : lhsDate > rhsDate
                case .price:
                    let lhsPrice = lhs.currentMarketPrice?.average ?? lhs.originalPrice ?? 0
                    let rhsPrice = rhs.currentMarketPrice?.average ?? rhs.originalPrice ?? 0
                    return filter.ascending ? lhsPrice < rhsPrice : lhsPrice > rhsPrice
                case .rarity:
                    return filter.ascending ? lhs.rarity.rawValue < rhs.rarity.rawValue : lhs.rarity.rawValue > rhs.rarity.rawValue
                case .createdAt:
                    return filter.ascending ? lhs.createdAt < rhs.createdAt : lhs.createdAt > rhs.createdAt
                }
            }
            
            return results
        }
    }
    
    /// 获取数据库统计信息
    func getStatistics() -> DatabaseStats {
        queue.sync {
            let totalImages = models.reduce(0) { $0 + $1.referenceImages.count }
            
            return DatabaseStats(
                totalModels: models.count,
                totalSeries: series.count,
                totalImages: totalImages,
                lastUpdated: Date(),
                storageSize: 0 // 预置数据不计算存储大小
            )
        }
    }
    
    /// 获取模型的参考图片URL列表
    func getModelReferenceImages(modelId: String) async -> [String] {
        // 尝试从云端获取图片
        do {
            let images = try await supabaseService.fetchModelImages(modelId: modelId)
            return images
        } catch {
            print("⚠️ [数据库管理器] 获取模型图片失败: \(error)")
            
            // 如果云端获取失败，返回本地模型的参考图片
            return queue.sync {
                if let model = models.first(where: { $0.id == modelId }) {
                    return model.referenceImages.map { $0.imageURL }
                }
                return []
            }
        }
    }
    
    /// 刷新数据库（优先从云端加载，失败时使用预置数据）
    func loadDatabase() {
        Task {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
            
            do {
                // 尝试从云端加载数据
                let cloudModels = try await supabaseService.fetchAllActiveModels()
                let cloudSeries = try await supabaseService.fetchAllSeries()
                
                // 转换数据格式
                let convertedModels = convertSupabaseModelsToLabubuModels(cloudModels)
                let convertedSeries = convertSupabaseSeriesToLabubuSeries(cloudSeries)
                
                await MainActor.run {
                    self.models = convertedModels
                    self.series = convertedSeries
                    self.lastSyncTime = Date()
                    self.isLoading = false
                }
                
                print("✅ [数据库管理器] 成功从云端加载 \(convertedModels.count) 个模型和 \(convertedSeries.count) 个系列")
                
            } catch {
                print("⚠️ [数据库管理器] 云端加载失败，使用预置数据: \(error)")
                
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                
                // 降级到预置数据
                loadPresetDatabase()
            }
        }
    }
    
    /// 同步云端数据
    func syncWithCloud() {
        Task {
            do {
                try await supabaseService.syncAllData()
                loadDatabase()
            } catch {
                await MainActor.run {
                    self.errorMessage = "同步失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func loadPresetDatabase() {
        loadPresetModels()
        loadPresetSeries()
    }
    
    /// 转换Supabase模型数据为本地模型格式
    private func convertSupabaseModelsToLabubuModels(_ supabaseModels: [LabubuModelData]) -> [LabubuModel] {
        return supabaseModels.map { supabaseModel in
            LabubuModel(
                id: supabaseModel.id,
                name: supabaseModel.nameEn ?? supabaseModel.name,
                nameCN: supabaseModel.name,
                seriesId: supabaseModel.seriesId ?? "",
                variant: convertRarityToVariant(supabaseModel.rarityLevel),
                rarity: convertStringToRarity(supabaseModel.rarityLevel),
                releaseDate: nil, // LabubuModelData中没有releaseYear字段
                originalPrice: supabaseModel.estimatedPriceMin,
                visualFeatures: createDefaultVisualFeatures(), // 暂时使用默认值
                tags: [], // 数据库中没有tags字段，使用空数组
                description: supabaseModel.description
            )
        }
    }
    
    /// 转换Supabase系列数据为本地系列格式
    private func convertSupabaseSeriesToLabubuSeries(_ supabaseSeries: [LabubuSeriesModel]) -> [LabubuSeries] {
        return supabaseSeries.map { supabaseSeries in
            LabubuSeries(
                id: supabaseSeries.id,
                name: supabaseSeries.nameEn ?? supabaseSeries.name,
                nameCN: supabaseSeries.name,
                description: supabaseSeries.description ?? "",
                releaseDate: Date(), // 使用当前日期作为默认值
                theme: "经典", // 默认主题
                totalVariants: supabaseSeries.totalModels,
                imageURL: nil,
                isLimited: false, // 默认非限定
                averagePrice: 199.0 // 默认价格
            )
        }
    }
    
    /// 辅助转换方法
    private func convertRarityToVariant(_ rarity: String) -> LabubuVariant {
        switch rarity.lowercased() {
        case "common": return .standard
        case "uncommon": return .standard
        case "rare": return .limited
        case "ultra_rare": return .limited
        case "secret": return .anniversary
        default: return .standard
        }
    }
    
    private func convertStringToRarity(_ rarity: String) -> RarityLevel {
        switch rarity.lowercased() {
        case "common": return .common
        case "uncommon": return .uncommon
        case "rare": return .rare
        case "ultra_rare": return .epic
        case "secret": return .secret
        default: return .common
        }
    }
    
    private func convertYearToDate(_ year: Int?) -> Date? {
        guard let year = year else { return nil }
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = 1
        components.day = 1
        return calendar.date(from: components)
    }
    
    private func convertSupabaseVisualFeatures(_ features: [String: Any]?) -> VisualFeatures {
        guard let features = features else {
            return createDefaultVisualFeatures()
        }
        
        // 转换颜色特征
        let dominantColors: [ColorFeature] = (features["dominantColors"] as? [[String: Any]])?.compactMap { colorData in
            guard let colorHex = colorData["color"] as? String,
                  let percentage = colorData["percentage"] as? Double else {
                return nil
            }
            return ColorFeature(color: colorHex, percentage: percentage, region: .body)
        } ?? []
        
        return VisualFeatures(
            primaryColors: dominantColors,
            colorDistribution: [:],
            shapeDescriptor: ShapeDescriptor(
                aspectRatio: 0.8,
                roundness: 0.85,
                symmetry: 0.9,
                complexity: 0.4,
                keyPoints: []
            ),
            contourPoints: nil,
            textureFeatures: LabubuTextureFeatures(
                smoothness: 0.7,
                roughness: 0.3,
                patterns: ["dots"],
                materialType: .plush
            ),
            specialMarks: [],
            featureVector: []
        )
    }
    
    private func convertSupabaseReferenceImages(_ images: [LabubuReferenceImage]) -> [ReferenceImage] {
        return images.map { image in
            ReferenceImage(
                id: image.id,
                imageURL: image.imageUrl,
                angle: convertImageType(image.imageType),
                features: nil
            )
        }
    }
    
    private func convertImageType(_ type: String?) -> ReferenceImage.ImageAngle {
        switch type?.lowercased() {
        case "front": return .front
        case "back": return .back
        case "left", "side": return .left
        case "right": return .right
        case "top": return .top
        case "detail": return .detail
        default: return .front
        }
    }
    
    private func loadPresetModels() {
        // 尝试从Data目录加载预置数据
        if let url = Bundle.main.url(forResource: "labubu_models", withExtension: "json", subdirectory: "Data"),
           let data = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let jsonModels = try decoder.decode([LabubuModelJSON].self, from: data)
                models = jsonModels.map { convertJSONToModel($0) }
                print("✅ 从Data目录加载了 \(models.count) 个预置Labubu模型")
                return
            } catch {
                print("❌ 解析预置模型数据失败: \(error)")
            }
        }
        
        // 尝试从根目录加载
        if let url = Bundle.main.url(forResource: "labubu_models", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let jsonModels = try decoder.decode([LabubuModelJSON].self, from: data)
                models = jsonModels.map { convertJSONToModel($0) }
                print("✅ 从根目录加载了 \(models.count) 个预置Labubu模型")
                return
            } catch {
                print("❌ 解析预置模型数据失败: \(error)")
            }
        }
        
        // 尝试从Bundle加载预置数据（原有逻辑）
        if let path = Bundle.main.path(forResource: bundleModelsFile, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                models = try decoder.decode([LabubuModel].self, from: data)
                print("✅ 成功加载 \(models.count) 个预置Labubu模型")
                return
            } catch {
                print("❌ 加载预置模型数据失败: \(error)")
            }
        }
        
        print("⚠️ 未找到预置模型数据文件，使用默认数据")
        loadDefaultModels()
    }
    
    private func loadPresetSeries() {
        // 尝试从Data目录加载预置数据
        if let url = Bundle.main.url(forResource: "labubu_series", withExtension: "json", subdirectory: "Data"),
           let data = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let jsonSeries = try decoder.decode([LabubuSeriesJSON].self, from: data)
                series = jsonSeries.map { convertJSONToSeries($0) }
                print("✅ 从Data目录加载了 \(series.count) 个预置Labubu系列")
                return
            } catch {
                print("❌ 解析预置系列数据失败: \(error)")
            }
        }
        
        // 尝试从根目录加载
        if let url = Bundle.main.url(forResource: "labubu_series", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let jsonSeries = try decoder.decode([LabubuSeriesJSON].self, from: data)
                series = jsonSeries.map { convertJSONToSeries($0) }
                print("✅ 从根目录加载了 \(series.count) 个预置Labubu系列")
                return
            } catch {
                print("❌ 解析预置系列数据失败: \(error)")
            }
        }
        
        // 尝试从Bundle加载预置数据（原有逻辑）
        if let path = Bundle.main.path(forResource: bundleSeriesFile, ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                series = try decoder.decode([LabubuSeries].self, from: data)
                print("✅ 成功加载 \(series.count) 个预置Labubu系列")
                return
            } catch {
                print("❌ 加载预置系列数据失败: \(error)")
            }
        }
        
        print("⚠️ 未找到预置系列数据文件，使用默认数据")
        loadDefaultSeries()
    }
    
    // MARK: - JSON转换数据结构
    
    /// JSON模型数据结构
    private struct LabubuModelJSON: Codable {
        let id: String
        let name: String
        let nameEn: String
        let modelNumber: String
        let seriesId: String
        let description: String
        let rarity: String
        let estimatedPriceMin: Double
        let estimatedPriceMax: Double
        let releaseDate: Date
        let isActive: Bool
        let visualFeatures: VisualFeaturesJSON
    }
    
    private struct VisualFeaturesJSON: Codable {
        let dominantColors: [String]
        let bodyShape: String
        let headShape: String
        let earType: String
        let surfaceTexture: String
        let patternType: String
        let heightCm: Double
        let widthCm: Double
        let depthCm: Double
        let specialMarks: String
    }
    
    /// JSON系列数据结构
    private struct LabubuSeriesJSON: Codable {
        let id: String
        let name: String
        let nameEn: String
        let description: String
        let releaseYear: Int
        let totalModels: Int
        let isActive: Bool
        let createdAt: Date
        let updatedAt: Date
    }
    
    /// 转换JSON模型到内部模型
    private func convertJSONToModel(_ json: LabubuModelJSON) -> LabubuModel {
        let colorFeatures = json.visualFeatures.dominantColors.map { colorHex in
            ColorFeature(
                color: colorHex,
                percentage: 1.0 / Double(json.visualFeatures.dominantColors.count),
                region: .body
            )
        }
        
        let visualFeatures = VisualFeatures(
            primaryColors: colorFeatures,
            colorDistribution: [:],
            shapeDescriptor: ShapeDescriptor(
                aspectRatio: 0.8,
                roundness: 0.85,
                symmetry: 0.9,
                complexity: 0.4,
                keyPoints: []
            ),
            contourPoints: nil,
            textureFeatures: LabubuTextureFeatures(
                smoothness: 0.7,
                roughness: 0.3,
                patterns: ["dots"],
                materialType: .plush
            ),
            specialMarks: [],
            featureVector: []
        )
        
        return LabubuModel(
            id: json.id,
            name: json.nameEn,
            nameCN: json.name,
            seriesId: json.seriesId,
            variant: convertRarityToVariant(json.rarity),
            rarity: convertStringToRarity(json.rarity),
            releaseDate: json.releaseDate,
            originalPrice: (json.estimatedPriceMin + json.estimatedPriceMax) / 2.0,
            visualFeatures: visualFeatures,
            tags: [json.rarity, json.visualFeatures.patternType],
            description: json.description
        )
    }
    
    /// 转换JSON系列到内部系列
    private func convertJSONToSeries(_ json: LabubuSeriesJSON) -> LabubuSeries {
        return LabubuSeries(
            id: json.id,
            name: json.nameEn,
            nameCN: json.name,
            description: json.description,
            releaseDate: json.createdAt,
            theme: "经典",
            totalVariants: json.totalModels,
            imageURL: nil,
            isLimited: json.releaseYear >= 2022,
            averagePrice: 199.0
        )
    }
    

    
    // MARK: - 默认数据（用于演示）
    
    private func loadDefaultModels() {
        models = [
            LabubuModel(
                name: "Classic Pink Labubu",
                nameCN: "经典粉色Labubu",
                seriesId: "series_001",
                variant: .standard,
                rarity: .common,
                releaseDate: Date(timeIntervalSinceNow: -365 * 24 * 60 * 60),
                originalPrice: 199.0,
                visualFeatures: createDefaultVisualFeatures(),
                tags: ["经典", "粉色", "入门款"],
                description: "最经典的粉色Labubu，是很多收藏家的第一个Labubu"
            ),
            LabubuModel(
                name: "Limited White Labubu",
                nameCN: "限定白色Labubu",
                seriesId: "series_001",
                variant: .limited,
                rarity: .rare,
                releaseDate: Date(timeIntervalSinceNow: -180 * 24 * 60 * 60),
                originalPrice: 399.0,
                visualFeatures: createDefaultVisualFeatures(),
                tags: ["限定", "白色", "稀有"],
                description: "限量发售的白色款式，全球限量1000只"
            ),
            LabubuModel(
                name: "Golden Anniversary Labubu",
                nameCN: "金色周年纪念Labubu",
                seriesId: "series_002",
                variant: .anniversary,
                rarity: .secret,
                releaseDate: Date(timeIntervalSinceNow: -90 * 24 * 60 * 60),
                originalPrice: 999.0,
                visualFeatures: createDefaultVisualFeatures(),
                tags: ["周年", "金色", "传说"],
                description: "品牌周年纪念特别款，全球限量100只"
            )
        ]
        
        print("加载了 \(models.count) 个默认Labubu模型")
    }
    
    private func loadDefaultSeries() {
        series = [
            LabubuSeries(
                id: "series_001",
                name: "Classic Series",
                nameCN: "经典系列",
                description: "Labubu的经典系列，包含最受欢迎的基础款式",
                releaseDate: Date(timeIntervalSinceNow: -365 * 24 * 60 * 60),
                theme: "经典",
                totalVariants: 12,
                imageURL: nil,
                isLimited: false,
                averagePrice: 299.0
            ),
            LabubuSeries(
                id: "series_002",
                name: "Anniversary Collection",
                nameCN: "周年纪念合集",
                description: "品牌周年纪念特别系列，限量发售",
                releaseDate: Date(timeIntervalSinceNow: -90 * 24 * 60 * 60),
                theme: "纪念",
                totalVariants: 5,
                imageURL: nil,
                isLimited: true,
                averagePrice: 799.0
            )
        ]
        
        print("加载了 \(series.count) 个默认Labubu系列")
    }
    
    private func createDefaultVisualFeatures() -> VisualFeatures {
        return VisualFeatures(
            primaryColors: [
                ColorFeature(color: "#FFB6C1", percentage: 40.0, region: .body),
                ColorFeature(color: "#FFFFFF", percentage: 30.0, region: .face),
                ColorFeature(color: "#000000", percentage: 20.0, region: .accessory)
            ],
            colorDistribution: ["#FFB6C1": 40.0, "#FFFFFF": 30.0, "#000000": 20.0],
            shapeDescriptor: ShapeDescriptor(
                aspectRatio: 0.8,
                roundness: 0.85,
                symmetry: 0.9,
                complexity: 0.4,
                keyPoints: []
            ),
            contourPoints: nil,
            textureFeatures: LabubuTextureFeatures(
                smoothness: 0.7,
                roughness: 0.3,
                patterns: ["dots"],
                materialType: .plush
            ),
            specialMarks: [],
            featureVector: Array(repeating: 0.5, count: 20)
        )
    }
}

// MARK: - 错误类型

enum DatabaseError: LocalizedError {
    case modelNotFound
    case seriesNotFound
    case dataLoadingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "找不到指定的模型"
        case .seriesNotFound:
            return "找不到指定的系列"
        case .dataLoadingFailed(let reason):
            return "数据加载失败: \(reason)"
        }
    }
} 