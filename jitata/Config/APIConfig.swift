import Foundation

/// API配置管理
struct APIConfig {
    // MARK: - API Configuration
    /// TUZI API密钥 - 优先使用的API密钥
    static var tuziAPIKey: String? {
        // 首先尝试从环境变量读取 TUZI_API_KEY
        if let envKey = ProcessInfo.processInfo.environment["TUZI_API_KEY"], 
           !envKey.isEmpty,
           envKey != "your_actual_api_key_here" {
            return envKey
        }
        
        // 尝试从.env文件读取
        if let envFileKey = loadValueFromEnvFile(key: "TUZI_API_KEY"), 
           !envFileKey.isEmpty,
           envFileKey != "your_actual_api_key_here" {
            return envFileKey
        }
        
        return nil
    }
    
    /// TUZI API基础URL - 优先使用的API基础URL
    static var tuziAPIBase: String? {
        // 首先尝试从环境变量读取
        if let envBaseURL = ProcessInfo.processInfo.environment["TUZI_API_BASE"], 
           !envBaseURL.isEmpty {
            return envBaseURL
        }
        
        // 尝试从.env文件读取
        if let envFileBaseURL = loadValueFromEnvFile(key: "TUZI_API_BASE"), 
           !envFileBaseURL.isEmpty {
            return envFileBaseURL
        }
        
        return nil
    }
    
    /// API基础URL - 从环境变量或默认值读取
    static var openAIBaseURL: String {
        // 首先尝试从环境变量读取
        if let envBaseURL = ProcessInfo.processInfo.environment["TUZI_API_BASE"], 
           !envBaseURL.isEmpty {
            return envBaseURL
        }
        
        // 尝试从.env文件读取
        if let envFileBaseURL = loadBaseURLFromEnvFile(), 
           !envFileBaseURL.isEmpty {
            return envFileBaseURL
        }
        
        // 默认值
        return "https://api.tu-zi.com/v1"
    }
    
    static let openAIModel = "gpt-image-1"
    static let maxRetryAttempts = 3
    static let enhancementTimeout: TimeInterval = 120 // 增加到2分钟，因为复杂提示可能需要更长时间
    
    // MARK: - API Key Management
    /// API密钥 - 从多个来源读取，优先使用.env文件配置
    static var openAIAPIKey: String {
        // 首先尝试从环境变量读取 TUZI_API_KEY
        if let envKey = ProcessInfo.processInfo.environment["TUZI_API_KEY"], 
           !envKey.isEmpty,
           envKey != "your_actual_api_key_here" {
            return envKey
        }
        
        // 尝试从环境变量读取 OPENAI_API_KEY（向后兼容）
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], 
           !envKey.isEmpty,
           envKey != "your_actual_api_key_here" {
            return envKey
        }
        
        // 尝试从.env文件读取（开发环境）
        if let envFileKey = loadAPIKeyFromEnvFile(), 
           !envFileKey.isEmpty,
           envFileKey != "your_actual_api_key_here" {
            return envFileKey
        }
        
        // 如果环境变量不存在，尝试从Info.plist读取（用于开发环境）
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let key = plist["OPENAI_API_KEY"] as? String, 
           !key.isEmpty,
           key != "your_actual_api_key_here" {
            return key
        }
        
        // 🚀 临时硬编码API密钥用于测试（最后备选）
        let hardcodedKey = "sk-MVQo6gVtHAo79RUVDSAY9V390XsfdvWO3BA136v2iAM79CY1"
        if !hardcodedKey.isEmpty {
            return hardcodedKey
        }
        
        return ""
    }
    
    /// 从.env文件加载API密钥
    private static func loadAPIKeyFromEnvFile() -> String? {
        return loadValueFromEnvFile(key: "TUZI_API_KEY") ?? loadValueFromEnvFile(key: "OPENAI_API_KEY")
    }
    
    /// 从.env文件加载API基础URL
    private static func loadBaseURLFromEnvFile() -> String? {
        return loadValueFromEnvFile(key: "TUZI_API_BASE")
    }
    
    /// 从.env文件加载指定键的值
    private static func loadValueFromEnvFile(key: String) -> String? {
        // 获取应用Bundle路径
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let envPath = bundlePath + "/.env"
        
        // 如果Bundle中没有.env文件，尝试项目根目录
        let projectEnvPath = bundlePath + "/../../.env"
        
        for path in [envPath, projectEnvPath] {
            if FileManager.default.fileExists(atPath: path) {
                do {
                    let content = try String(contentsOfFile: path, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedLine.hasPrefix("\(key)=") {
                            let value = String(trimmedLine.dropFirst("\(key)=".count))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if !value.isEmpty && value != "your_actual_api_key_here" {
                                print("📁 从 \(path) 读取到\(key)")
                                return value
                            }
                        }
                    }
                } catch {
                    print("❌ 读取.env文件失败: \(error)")
                }
            }
        }
        
        return nil
    }
    
    /// 验证API密钥是否已设置
    static var isAPIKeyConfigured: Bool {
        return !openAIAPIKey.isEmpty
    }
    
    // MARK: - Supabase Configuration
    static var supabaseURL: String? {
        // 首先尝试从环境变量读取
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
            return envURL
        }
        
        // 尝试从.env文件读取
        return loadValueFromEnvFile(key: "SUPABASE_URL")
    }
    
    static var supabaseAnonKey: String? {
        // 首先尝试从环境变量读取
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 尝试从.env文件读取
        return loadValueFromEnvFile(key: "SUPABASE_ANON_KEY")
    }
    
    static var supabaseServiceRoleKey: String? {
        // 首先尝试从环境变量读取
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 尝试从.env文件读取
        return loadValueFromEnvFile(key: "SUPABASE_SERVICE_ROLE_KEY")
    }
    
    static var supabaseStorageBucket: String {
        // 首先尝试从环境变量读取
        if let envBucket = ProcessInfo.processInfo.environment["SUPABASE_STORAGE_BUCKET"], !envBucket.isEmpty {
            return envBucket
        }
        
        // 尝试从.env文件读取
        if let envFileBucket = loadValueFromEnvFile(key: "SUPABASE_STORAGE_BUCKET"), !envFileBucket.isEmpty {
            return envFileBucket
        }
        
        // 默认值
        return "jitata-images"
    }
}

/// API错误类型
enum APIError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case enhancementFailed(String)
    case timeout
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API密钥未配置"
        case .invalidURL:
            return "无效的API地址"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的API响应"
        case .enhancementFailed(let message):
            return "图片增强失败: \(message)"
        case .timeout:
            return "请求超时"
        case .compressionFailed:
            return "图片压缩失败"
        }
    }
} 