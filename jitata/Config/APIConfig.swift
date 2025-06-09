import Foundation

/// API配置管理
struct APIConfig {
    // MARK: - OpenAI Configuration
    static let openAIBaseURL = "https://api.tu-zi.com/v1"
    static let openAIModel = "gpt-image-1"
    static let maxRetryAttempts = 3
    static let enhancementTimeout: TimeInterval = 120 // 增加到2分钟，因为复杂提示可能需要更长时间
    
    // MARK: - API Key Management
    /// OpenAI API密钥 - 从多个来源读取
    static var openAIAPIKey: String {
        // 🚀 临时硬编码API密钥用于测试
        let hardcodedKey = "sk-MVQo6gVtHAo79RUVDSAY9V390XsfdvWO3BA136v2iAM79CY1"
        if !hardcodedKey.isEmpty {
            return hardcodedKey
        }
        
        // 首先尝试从环境变量读取
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], 
           !envKey.isEmpty,
           envKey != "your_actual_api_key_here" {
            return envKey
        }
        
        // 尝试从.env文件读取（开发环境）
        if let envFileKey = loadFromEnvFile(), 
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
        
        return ""
    }
    
    /// 从.env文件加载API密钥
    private static func loadFromEnvFile() -> String? {
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
                        if trimmedLine.hasPrefix("OPENAI_API_KEY=") {
                            let key = String(trimmedLine.dropFirst("OPENAI_API_KEY=".count))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if !key.isEmpty && key != "your_actual_api_key_here" {
                                return key
                            }
                        }
                    }
                } catch {
                    print("读取.env文件失败: \(error)")
                }
            }
        }
        
        return nil
    }
    
    /// 验证API密钥是否已设置
    static var isAPIKeyConfigured: Bool {
        return !openAIAPIKey.isEmpty
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
        }
    }
} 