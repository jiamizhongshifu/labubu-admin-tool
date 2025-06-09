//
//  jitataApp.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import SwiftData

@main
struct jitataApp: App {
    
    init() {
        // 🚀 应用启动时加载API配置
        loadAPIConfiguration()
        
        print("🚀 应用启动，初始化数据库...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ToySticker.self, Category.self]) { result in
                    switch result {
                    case .success(let container):
                        print("✅ ModelContainer创建成功")
                        print("✅ 数据库初始化完成")
                        
                        // 配置DataManager
                        DataManager.shared.configure(with: container.mainContext)
                        print("✅ DataManager配置完成")
                        
                    case .failure(let error):
                        print("❌ ModelContainer创建失败: \(error)")
                    }
                }
        }
    }
    
    /// 加载API配置
    private func loadAPIConfiguration() {
        // 尝试从项目根目录的.env文件读取API密钥
        if let apiKey = loadAPIKeyFromEnvFile() {
            // 设置为环境变量，这样APIConfig就能读取到
            setenv("OPENAI_API_KEY", apiKey, 1)
            print("✅ API密钥已从.env文件加载并设置")
        } else {
            print("⚠️ 未找到API密钥配置")
        }
    }
    
    /// 从.env文件加载API密钥
    private func loadAPIKeyFromEnvFile() -> String? {
        // 获取应用Bundle路径
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        
        // 尝试多个可能的.env文件位置
        let possiblePaths = [
            bundlePath + "/.env",                    // Bundle内
            bundlePath + "/../../.env",              // 项目根目录
            bundlePath + "/../../../.env",           // 上级目录
            "/Users/zhongqingbiao/Downloads/jitata/.env"  // 绝对路径
        ]
        
        for envPath in possiblePaths {
            if FileManager.default.fileExists(atPath: envPath) {
                do {
                    let content = try String(contentsOfFile: envPath, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedLine.hasPrefix("OPENAI_API_KEY=") {
                            let key = String(trimmedLine.dropFirst("OPENAI_API_KEY=".count))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if !key.isEmpty && key != "your_actual_api_key_here" {
                                print("📁 从 \(envPath) 读取到API密钥")
                                return key
                            }
                        }
                    }
                } catch {
                    print("❌ 读取.env文件失败: \(envPath) - \(error)")
                }
            }
        }
        
        print("❌ 未找到有效的.env文件")
        return nil
    }
}
