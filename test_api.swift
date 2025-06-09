#!/usr/bin/env swift

import Foundation

// 简单的API测试脚本
func testAPIEndpoint() {
    let baseURL = "https://api.tu-zi.com/v1"
    
    // 检查环境变量
    guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !apiKey.isEmpty else {
        print("❌ 错误: 未找到环境变量 OPENAI_API_KEY")
        print("💡 请设置: export OPENAI_API_KEY='your_api_key_here'")
        return
    }
    
    print("🔍 测试API连接...")
    print("📍 API地址: \(baseURL)")
    print("🔑 API密钥: \(apiKey.prefix(10))...")
    
    // 创建URL请求测试连接性
    guard let url = URL(string: "\(baseURL)/models") else {
        print("❌ 无效的API地址")
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
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
                print("📄 响应内容: \(responseString.prefix(200))...")
            }
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            print("✅ API连接成功！")
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

// 运行测试
print("=== OpenAI API 连接测试 ===")
testAPIEndpoint()
print("=== 测试完成 ===") 