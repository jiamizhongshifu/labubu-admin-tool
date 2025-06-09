#!/usr/bin/env swift

import Foundation

// 读取.env文件的函数
func loadEnvironmentVariables() {
    guard let envPath = FileManager.default.currentDirectoryPath.appending("/.env") as String?,
          FileManager.default.fileExists(atPath: envPath) else {
        print("⚠️  未找到.env文件")
        return
    }
    
    do {
        let envContent = try String(contentsOfFile: envPath)
        let lines = envContent.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty && !trimmedLine.hasPrefix("#") {
                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count == 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    setenv(key, value, 1)
                    print("📝 加载环境变量: \(key)")
                }
            }
        }
    } catch {
        print("❌ 读取.env文件失败: \(error)")
    }
}

// API测试函数
func testAPIEndpoint() {
    let baseURL = "https://api.tu-zi.com/v1"
    
    // 检查API密钥
    guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], 
          !apiKey.isEmpty,
          apiKey != "your_actual_api_key_here" else {
        print("❌ 错误: API密钥未正确配置")
        print("💡 请编辑.env文件，将 your_actual_api_key_here 替换为您的实际API密钥")
        return
    }
    
    print("🔍 测试API连接...")
    print("📍 API地址: \(baseURL)")
    print("🔑 API密钥: \(apiKey.prefix(10))...")
    
    // 测试图像编辑端点（POST请求需要认证）
    guard let url = URL(string: "\(baseURL)/images/edits") else {
        print("❌ 无效的API地址")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // 创建一个简单的测试请求体（这会失败，但能测试认证）
    let testBody = ["prompt": "test"]
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: testBody)
    } catch {
        print("❌ 创建请求体失败")
        return
    }
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 网络错误: \(error.localizedDescription)")
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的响应")
            return
        }
        
        print("📡 HTTP状态码: \(httpResponse.statusCode)")
        
        if let data = data {
            print("📦 响应数据大小: \(data.count) bytes")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 响应内容: \(responseString)")
            }
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            print("✅ API认证成功！服务正常")
        case 400:
            print("✅ API认证成功！(400错误是因为测试请求格式不完整，这是正常的)")
        case 401:
            print("❌ 认证失败：API密钥可能无效")
        case 403:
            print("❌ 访问被拒绝：权限不足")
        case 404:
            print("❌ 端点不存在：API地址可能错误")
        case 429:
            print("❌ 请求过于频繁：已达到速率限制")
        case 500...599:
            print("❌ 服务器错误：API服务可能暂时不可用")
        default:
            print("⚠️  未知状态码: \(httpResponse.statusCode)")
        }
    }
    
    task.resume()
    semaphore.wait()
}

// 主程序
print("=== OpenAI API 测试（使用.env文件）===")
print("🔄 加载.env文件...")
loadEnvironmentVariables()
print("")
testAPIEndpoint()
print("=== 测试完成 ===") 