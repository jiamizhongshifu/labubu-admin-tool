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
        // 临时使用Service Role Key解决权限问题
        // TODO: 配置RLS策略后改回使用Anon Key
        self.apiKey = APIConfig.supabaseServiceRoleKey ?? APIConfig.supabaseAnonKey ?? ""
        
        if APIConfig.supabaseServiceRoleKey != nil {
            print("🔑 [Supabase数据库] 使用Service Role Key（临时解决方案）")
        } else {
            print("🔑 [Supabase数据库] 使用Anon Key")
        }
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
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
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
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
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
        // 详细的配置检查和调试信息
        print("🔍 [Supabase数据库] 开始配置检查...")
        print("📝 [Supabase数据库] baseURL: \(baseURL.isEmpty ? "空" : baseURL)")
        print("📝 [Supabase数据库] apiKey前缀: \(apiKey.isEmpty ? "空" : String(apiKey.prefix(20)))...")
        print("📝 [Supabase数据库] isConfigured: \(isConfigured)")
        
        guard isConfigured else {
            print("❌ [Supabase数据库] 配置检查失败")
            throw LabubuDatabaseError.configurationMissing
        }
        
        print("✅ [Supabase数据库] 配置检查通过")

        // 先获取模型数据
        let modelsUrl = URL(string: "\(baseURL)/rest/v1/labubu_models?is_active=eq.true&order=created_at.desc")!
        print("🌐 [Supabase数据库] 请求URL: \(modelsUrl.absoluteString)")
        
        var modelsRequest = URLRequest(url: modelsUrl)
        modelsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        modelsRequest.setValue(apiKey, forHTTPHeaderField: "apikey")
        modelsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        modelsRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("🔑 [Supabase数据库] Authorization头: Bearer \(String(apiKey.prefix(20)))...")
        print("🔑 [Supabase数据库] apikey头: \(String(apiKey.prefix(20)))...")
        print("🚀 [Supabase数据库] 发送请求...")

        let (modelsData, modelsResponse) = try await URLSession.shared.data(for: modelsRequest)
        
        guard let httpModelsResponse = modelsResponse as? HTTPURLResponse,
              httpModelsResponse.statusCode == 200 else {
            print("❌ [Supabase数据库] HTTP错误: \(modelsResponse)")
            if let httpResponse = modelsResponse as? HTTPURLResponse {
                print("❌ [Supabase数据库] 状态码: \(httpResponse.statusCode)")
                print("❌ [Supabase数据库] 响应头: \(httpResponse.allHeaderFields)")
                
                // 尝试解析错误响应内容
                if let errorString = String(data: modelsData, encoding: .utf8) {
                    print("❌ [Supabase数据库] 错误响应内容: \(errorString)")
                }
                
                // 根据状态码提供具体的错误信息
                switch httpResponse.statusCode {
                case 401:
                    print("💡 [Supabase数据库] 401错误通常表示:")
                    print("   - API密钥无效或过期")
                    print("   - API密钥权限不足")
                    print("   - 项目URL不正确")
                    print("💡 [Supabase数据库] 建议检查:")
                    print("   - .env文件中的SUPABASE_URL和SUPABASE_ANON_KEY是否正确")
                    print("   - Supabase项目是否处于活跃状态")
                    print("   - API密钥是否有读取权限")
                case 404:
                    print("💡 [Supabase数据库] 404错误表示表不存在或URL错误")
                case 403:
                    print("💡 [Supabase数据库] 403错误表示权限不足，可能需要RLS策略")
                default:
                    print("💡 [Supabase数据库] 其他HTTP错误: \(httpResponse.statusCode)")
                }
            }
            throw LabubuDatabaseError.networkError("获取模型数据失败")
        }

        do {
            let models = try JSONDecoder().decode([LabubuModelData].self, from: modelsData)
            print("📊 [Supabase数据库] 成功解码 \(models.count) 个模型")
            return try await enrichModelsWithSeries(models)
        } catch {
            print("❌ [Supabase数据库] JSON解码失败: \(error)")
            if let jsonString = String(data: modelsData, encoding: .utf8) {
                print("📄 [Supabase数据库] 响应内容: \(jsonString.prefix(500))")
            }
            throw LabubuDatabaseError.networkError("解析模型数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 为模型数据关联系列信息
    private func enrichModelsWithSeries(_ models: [LabubuModelData]) async throws -> [LabubuModelData] {
        // 获取系列数据
        let seriesUrl = URL(string: "\(baseURL)/rest/v1/labubu_series")!
        var seriesRequest = URLRequest(url: seriesUrl)
        seriesRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        seriesRequest.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
        seriesRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        seriesRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (seriesData, seriesResponse) = try await URLSession.shared.data(for: seriesRequest)
        
        var seriesDict: [String: LabubuSeriesModel] = [:]
        if let httpSeriesResponse = seriesResponse as? HTTPURLResponse,
           httpSeriesResponse.statusCode == 200 {
            do {
                let series = try JSONDecoder().decode([LabubuSeriesModel].self, from: seriesData)
                seriesDict = Dictionary(uniqueKeysWithValues: series.map { ($0.id, $0) })
                print("📊 [Supabase数据库] 获取到 \(series.count) 个系列")
            } catch {
                print("⚠️ [Supabase数据库] 系列数据解码失败: \(error)")
            }
        } else {
            print("⚠️ [Supabase数据库] 获取系列数据失败")
        }
        
        // 手动关联系列信息到模型数据
        let enrichedModels = models.map { model in
            var enrichedModel = model
            if let seriesId = model.seriesId, let series = seriesDict[seriesId] {
                enrichedModel.seriesName = series.name
                enrichedModel.seriesNameEn = series.nameEn
                enrichedModel.seriesDescription = series.description
            }
            return enrichedModel
        }
        
        print("📊 [Supabase数据库] 获取到 \(enrichedModels.count) 个完整模型数据")
        
        await MainActor.run {
            self.lastSyncTime = Date()
        }
        
        return enrichedModels
    }
    
    /// 根据模型ID获取详细信息
    func fetchModelDetails(_ modelId: String) async throws -> LabubuModelData? {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        // 获取模型数据
        let modelUrl = URL(string: "\(baseURL)/rest/v1/labubu_models?id=eq.\(modelId)")!
        var modelRequest = URLRequest(url: modelUrl)
        modelRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        modelRequest.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
        modelRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        modelRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (modelData, modelResponse) = try await URLSession.shared.data(for: modelRequest)
        
        guard let httpModelResponse = modelResponse as? HTTPURLResponse,
              httpModelResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("获取模型详情失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: modelData)
        guard let model = models.first else {
            return nil
        }
        
        // 获取系列信息
        if let seriesId = model.seriesId {
            let seriesUrl = URL(string: "\(baseURL)/rest/v1/labubu_series?id=eq.\(seriesId)")!
            var seriesRequest = URLRequest(url: seriesUrl)
            seriesRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            seriesRequest.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
            seriesRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            seriesRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (seriesData, seriesResponse) = try await URLSession.shared.data(for: seriesRequest)
            
            if let httpSeriesResponse = seriesResponse as? HTTPURLResponse,
               httpSeriesResponse.statusCode == 200 {
                let series = try JSONDecoder().decode([LabubuSeriesModel].self, from: seriesData)
                if let seriesInfo = series.first {
                    var enrichedModel = model
                    enrichedModel.seriesName = seriesInfo.name
                    enrichedModel.seriesNameEn = seriesInfo.nameEn
                    enrichedModel.seriesDescription = seriesInfo.description
                    return enrichedModel
                }
            }
        }
        
        return model
    }
    
    /// 获取模型的参考图片
    func fetchReferenceImages(for modelId: String) async throws -> [LabubuReferenceImage] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_reference_images?model_id=eq.\(modelId)&order=sort_order,is_primary.desc")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
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
        request.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
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
        
        // 使用ilike进行模糊搜索模型表
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let modelsUrl = URL(string: "\(baseURL)/rest/v1/labubu_models?or=(name.ilike.*\(encodedQuery)*,name_en.ilike.*\(encodedQuery)*,model_number.ilike.*\(encodedQuery)*)&is_active=eq.true&order=name")!
        
        var modelsRequest = URLRequest(url: modelsUrl)
        modelsRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        modelsRequest.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
        modelsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        modelsRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (modelsData, modelsResponse) = try await URLSession.shared.data(for: modelsRequest)
        
        guard let httpModelsResponse = modelsResponse as? HTTPURLResponse,
              httpModelsResponse.statusCode == 200 else {
            throw LabubuDatabaseError.networkError("搜索失败")
        }
        
        let models = try JSONDecoder().decode([LabubuModelData].self, from: modelsData)
        
        // 获取系列数据用于关联
        let seriesUrl = URL(string: "\(baseURL)/rest/v1/labubu_series")!
        var seriesRequest = URLRequest(url: seriesUrl)
        seriesRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        seriesRequest.setValue(apiKey, forHTTPHeaderField: "apikey")  // Supabase需要这个头部
        seriesRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        seriesRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (seriesData, seriesResponse) = try await URLSession.shared.data(for: seriesRequest)
        
        var seriesDict: [String: LabubuSeriesModel] = [:]
        if let httpSeriesResponse = seriesResponse as? HTTPURLResponse,
           httpSeriesResponse.statusCode == 200 {
            let series = try JSONDecoder().decode([LabubuSeriesModel].self, from: seriesData)
            seriesDict = Dictionary(uniqueKeysWithValues: series.map { ($0.id, $0) })
        }
        
        // 手动关联系列信息
        let enrichedModels = models.map { model in
            var enrichedModel = model
            if let series = seriesDict[model.seriesId ?? ""] {
                enrichedModel.seriesName = series.name
                enrichedModel.seriesNameEn = series.nameEn
                enrichedModel.seriesDescription = series.description
            }
            return enrichedModel
        }
        
        print("📊 [Supabase数据库] 搜索 '\(query)' 找到 \(enrichedModels.count) 个结果")
        return enrichedModels
    }
    
    /// 获取指定模型的参考图片
    func fetchModelImages(modelId: String) async throws -> [String] {
        guard isConfigured else {
            throw LabubuDatabaseError.configurationMissing
        }
        
        let url = URL(string: "\(baseURL)/rest/v1/labubu_reference_images?model_id=eq.\(modelId)&order=sort_order.asc")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("⚠️ [Supabase数据库] 获取模型图片失败，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            throw LabubuDatabaseError.networkError("获取模型图片失败")
        }
        
        do {
            let images = try JSONDecoder().decode([LabubuReferenceImage].self, from: data)
            let imageUrls = images.map { $0.imageUrl }
            print("📸 [Supabase数据库] 获取到模型 \(modelId) 的 \(imageUrls.count) 张图片")
            return imageUrls
        } catch {
            print("❌ [Supabase数据库] 解析图片数据失败: \(error)")
            throw LabubuDatabaseError.decodingError("解析图片数据失败: \(error.localizedDescription)")
        }
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