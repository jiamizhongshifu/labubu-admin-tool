import Foundation
import SwiftUI

/// Supabase数据库服务
/// 负责从云端数据库读取Labubu合集数据
class LabubuSupabaseDatabaseService: ObservableObject {
    static let shared = LabubuSupabaseDatabaseService()
    
    @Published var isLoading = false
    @Published var lastSyncTime: Date?
    @Published var errorMessage: String?
    
    private let baseURL: String
    private let apiKey: String
    
    private init() {
        // 从配置中获取Supabase信息
        self.baseURL = APIConfig.supabaseURL ?? ""
        self.apiKey = APIConfig.supabaseAnonKey ?? ""
    }
    
    // MARK: - 配置验证
    
    /// 检查Supabase配置是否有效
    var isConfigured: Bool {
        return !baseURL.isEmpty && 
               !apiKey.isEmpty && 
               !baseURL.contains("your_supabase_project_url_here") &&
               !apiKey.contains("your_supabase_anon_key_here")
    }
    
    // MARK: - 数据获取方法
    
    /// 获取所有Labubu系列
    func fetchAllSeries() async throws -> [LabubuSeriesModel] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_series?is_active=eq.true&order=release_year.desc")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取系列数据失败")
        }
        
        let series = try JSONDecoder().decode([LabubuSeriesModel].self, from: data)
        print("📊 [Supabase数据库] 获取到 \(series.count) 个系列")
        return series
    }
    
    /// 获取指定系列的所有模型
    func fetchModelsForSeries(_ seriesId: String) async throws -> [LabubuModelData] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_models_with_series?series_id=eq.\(seriesId)&is_active=eq.true&order=name")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取模型数据失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: data)
        print("📊 [Supabase数据库] 获取到 \(models.count) 个模型")
        return models
    }
    
    /// 获取所有活跃的Labubu模型（用于识别）
    func fetchAllActiveModels() async throws -> [LabubuModelData] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_complete_info?order=series_name,name")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取完整模型数据失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: data)
        print("📊 [Supabase数据库] 获取到 \(models.count) 个完整模型数据")
        
        await MainActor.run {
            self.lastSyncTime = Date()
        }
        
        return models
    }
    
    /// 根据模型ID获取详细信息
    func fetchModelDetails(_ modelId: String) async throws -> LabubuModelData? {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_complete_info?id=eq.\(modelId)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取模型详情失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: data)
        return models.first
    }
    
    /// 获取模型的参考图片
    func fetchReferenceImages(for modelId: String) async throws -> [LabubuReferenceImage] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_reference_images?model_id=eq.\(modelId)&order=sort_order,is_primary.desc")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取参考图片失败")
        }
        
        let images = try JSONDecoder().decode([LabubuReferenceImage].self, from: data)
        print("📊 [Supabase数据库] 获取到 \(images.count) 张参考图片")
        return images
    }
    
    /// 获取模型的价格历史
    func fetchPriceHistory(for modelId: String, limit: Int = 10) async throws -> [LabubuPriceHistory] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_price_history?model_id=eq.\(modelId)&order=recorded_at.desc&limit=\(limit)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取价格历史失败")
        }
        
        let priceHistory = try JSONDecoder().decode([LabubuPriceHistory].self, from: data)
        print("📊 [Supabase数据库] 获取到 \(priceHistory.count) 条价格记录")
        return priceHistory
    }
    
    /// 搜索Labubu模型
    func searchModels(query: String) async throws -> [LabubuModelData] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        // 使用ilike进行模糊搜索
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/rest/v1/labubu_complete_info?or=(name.ilike.*\(encodedQuery)*,name_en.ilike.*\(encodedQuery)*,model_number.ilike.*\(encodedQuery)*,series_name.ilike.*\(encodedQuery)*)&order=name")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("搜索失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: data)
        print("📊 [Supabase数据库] 搜索 '\(query)' 找到 \(models.count) 个结果")
        return models
    }
    
    // MARK: - 缓存管理
    
    /// 同步所有数据到本地缓存
    func syncAllData() async throws {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // 获取所有数据
            let models = try await fetchAllActiveModels()
            
            // 保存到本地缓存
            await saveToLocalCache(models)
            
            await MainActor.run {
                self.isLoading = false
                self.lastSyncTime = Date()
            }
            
            print("✅ [Supabase数据库] 数据同步完成，共 \(models.count) 个模型")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    /// 保存数据到本地缓存
    private func saveToLocalCache(_ models: [LabubuModelData]) async {
        do {
            let data = try JSONEncoder().encode(models)
            let cacheURL = getCacheURL()
            try data.write(to: cacheURL)
            print("💾 [Supabase数据库] 数据已保存到本地缓存")
        } catch {
            print("❌ [Supabase数据库] 保存缓存失败: \(error)")
        }
    }
    
    /// 从本地缓存加载数据
    func loadFromLocalCache() async -> [LabubuModelData] {
        do {
            let cacheURL = getCacheURL()
            let data = try Data(contentsOf: cacheURL)
            let models = try JSONDecoder().decode([LabubuModelData].self, from: data)
            print("💾 [Supabase数据库] 从本地缓存加载 \(models.count) 个模型")
            return models
        } catch {
            print("⚠️ [Supabase数据库] 加载缓存失败: \(error)")
            return []
        }
    }
    
    /// 获取缓存文件URL
    private func getCacheURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("labubu_models_cache.json")
    }
    
    /// 检查缓存是否过期
    func isCacheExpired() -> Bool {
        guard let lastSync = lastSyncTime else { return true }
        let cacheValidDuration: TimeInterval = 24 * 60 * 60 // 24小时
        return Date().timeIntervalSince(lastSync) > cacheValidDuration
    }
}

// MARK: - 错误类型

enum LabubuDatabaseError: LocalizedError {
    case configurationMissing
    case networkError(String)
    case decodingError(String)
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Supabase数据库配置缺失，请检查环境变量"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        case .notFound:
            return "未找到相关数据"
        }
    }
}

// MARK: - 数据模型

/// Labubu系列模型
struct LabubuSeriesModel: Codable, Identifiable {
    let id: String
    let name: String
    let nameEn: String?
    let description: String?
    let releaseYear: Int?
    let totalModels: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case nameEn = "name_en"
        case releaseYear = "release_year"
        case totalModels = "total_models"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Labubu参考图片
struct LabubuReferenceImage: Codable, Identifiable {
    let id: String
    let modelId: String
    let imageUrl: String
    let imageType: String?
    let isPrimary: Bool
    let sortOrder: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case modelId = "model_id"
        case imageUrl = "image_url"
        case imageType = "image_type"
        case isPrimary = "is_primary"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }
}

/// Labubu价格历史
struct LabubuPriceHistory: Codable, Identifiable {
    let id: String
    let modelId: String
    let price: Double
    let currency: String
    let source: String?
    let condition: String?
    let recordedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case modelId = "model_id"
        case price, currency, source, condition
        case recordedAt = "recorded_at"
    }
} 