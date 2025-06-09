#!/usr/bin/env swift

import Foundation

// 模拟APIConfig的逻辑
struct APIConfig {
    static var apiKey: String {
        // 1. 首先尝试从环境变量读取
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. 然后尝试从.env文件读取
        if let envKey = loadFromEnvFile(), !envKey.isEmpty {
            return envKey
        }
        
        // 3. 最后从Info.plist读取（这里简化为默认值）
        return "your_actual_api_key_here"
    }
    
    private static func loadFromEnvFile() -> String? {
        let envPath = ".env"
        
        guard let envContent = try? String(contentsOfFile: envPath) else {
            return nil
        }
        
        let lines = envContent.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("OPENAI_API_KEY=") {
                let key = String(trimmedLine.dropFirst("OPENAI_API_KEY=".count))
                return key.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }
}

print("=== 应用内API配置测试 ===")
print("🔍 测试APIConfig.apiKey读取...")

let apiKey = APIConfig.apiKey
print("🔑 读取到的API密钥: \(String(apiKey.prefix(12)))...")

if apiKey.hasPrefix("sk-") {
    print("✅ API密钥格式正确！")
    print("✅ 应用内API配置工作正常！")
} else {
    print("❌ API密钥格式不正确，请检查.env文件")
}

print("=== 测试完成 ===") 