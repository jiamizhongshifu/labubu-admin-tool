#!/usr/bin/env swift

import Foundation

print("🔍 AI增强功能调试检查")
print("====================")

// 1. 检查API配置
print("\n1️⃣ 检查API配置...")

let envPath = ".env"
if FileManager.default.fileExists(atPath: envPath) {
    do {
        let envContent = try String(contentsOfFile: envPath, encoding: .utf8)
        let lines = envContent.components(separatedBy: .newlines)
        
        var apiKeyFound = false
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.hasPrefix("OPENAI_API_KEY=") {
                let keyPart = String(trimmedLine.dropFirst("OPENAI_API_KEY=".count))
                if !keyPart.isEmpty && keyPart != "your_actual_api_key_here" {
                    print("✅ API密钥已配置: \(keyPart.prefix(10))...")
                    apiKeyFound = true
                } else {
                    print("❌ API密钥未正确设置")
                }
                break
            }
        }
        
        if !apiKeyFound {
            print("❌ 在.env文件中未找到OPENAI_API_KEY")
        }
    } catch {
        print("❌ 读取.env文件失败: \(error)")
    }
} else {
    print("❌ .env文件不存在")
}

// 2. 检查环境变量
print("\n2️⃣ 检查环境变量...")
if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
    if !envKey.isEmpty {
        print("✅ 环境变量OPENAI_API_KEY已设置: \(envKey.prefix(10))...")
    } else {
        print("❌ 环境变量OPENAI_API_KEY为空")
    }
} else {
    print("❌ 环境变量OPENAI_API_KEY未设置")
}

// 3. 测试API连接
print("\n3️⃣ 测试API连接...")

func getAPIKey() -> String? {
    // 先检查环境变量
    if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
        return envKey
    }
    
    // 再检查.env文件
    guard let envContent = try? String(contentsOfFile: ".env", encoding: .utf8) else { return nil }
    
    let lines = envContent.components(separatedBy: .newlines)
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.hasPrefix("OPENAI_API_KEY=") {
            let keyPart = String(trimmedLine.dropFirst("OPENAI_API_KEY=".count))
            return keyPart.isEmpty ? nil : keyPart
        }
    }
    return nil
}

if let apiKey = getAPIKey() {
    let testURL = URL(string: "https://api.tu-zi.com/v1/models")!
    var request = URLRequest(url: testURL)
    request.httpMethod = "GET"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 网络错误: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📄 响应内容: \(responseString.prefix(100))...")
                
                if httpResponse.statusCode == 200 {
                    print("✅ API连接成功")
                } else if httpResponse.statusCode == 401 {
                    print("❌ API密钥认证失败")
                } else {
                    print("⚠️ API响应异常，状态码: \(httpResponse.statusCode)")
                }
            }
        }
    }.resume()
    
    semaphore.wait()
} else {
    print("❌ 无法获取API密钥")
}

// 4. 检查应用编译状态
print("\n4️⃣ 检查应用编译状态...")

let buildProcess = Process()
buildProcess.launchPath = "/usr/bin/xcodebuild"
buildProcess.arguments = [
    "-project", "jitata.xcodeproj",
    "-scheme", "jitata",
    "-destination", "platform=iOS Simulator,name=iPhone 16",
    "-dry-run"
]

let pipe = Pipe()
buildProcess.standardOutput = pipe
buildProcess.standardError = pipe

do {
    try buildProcess.run()
    buildProcess.waitUntilExit()
    
    if buildProcess.terminationStatus == 0 {
        print("✅ 应用配置正确")
    } else {
        print("❌ 应用配置有问题")
    }
} catch {
    print("❌ 无法检查应用配置: \(error)")
}

// 5. 总结和建议
print("\n📋 调试建议")
print("============")
print("如果AI增强没有显示进度，可能的原因：")
print("1. API密钥配置问题 - 检查.env文件或环境变量")
print("2. 网络连接问题 - 检查网络和API服务器状态")
print("3. 应用状态问题 - 重新启动应用或清理缓存")
print("4. 日志输出问题 - 检查Xcode控制台是否显示AI增强相关日志")

print("\n🔧 解决步骤：")
print("1. 确保API密钥正确配置")
print("2. 重新启动iOS模拟器")
print("3. 重新编译并运行应用")
print("4. 拍摄新照片并观察控制台日志")
print("5. 检查图鉴页面是否显示状态徽章")

print("\n调试完成！") 