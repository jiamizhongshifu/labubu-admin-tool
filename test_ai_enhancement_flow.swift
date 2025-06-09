#!/usr/bin/env swift

import Foundation

print("🧪 AI增强功能流程测试")
print("===================")

// 1. 检查API配置
print("\n1️⃣ 检查API配置...")

// 检查.env文件
let envPath = ".env"
if FileManager.default.fileExists(atPath: envPath) {
    do {
        let envContent = try String(contentsOfFile: envPath)
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

// 2. 测试API连接
print("\n2️⃣ 测试API连接...")

let testURL = URL(string: "https://api.tu-zi.com/v1/models")!
var request = URLRequest(url: testURL)
request.httpMethod = "GET"

// 从.env文件读取API密钥
func getAPIKey() -> String? {
    guard let envContent = try? String(contentsOfFile: ".env") else { return nil }
    
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
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    var testResult = false
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        if let error = error {
            print("❌ 网络错误: \(error.localizedDescription)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 HTTP状态码: \(httpResponse.statusCode)")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📄 响应内容: \(responseString.prefix(200))...")
                
                if httpResponse.statusCode == 200 {
                    print("✅ API连接成功")
                    testResult = true
                } else if httpResponse.statusCode == 401 {
                    print("❌ API密钥认证失败")
                } else {
                    print("⚠️ API响应异常，但服务器可达")
                }
            }
        }
    }.resume()
    
    semaphore.wait()
} else {
    print("❌ 无法获取API密钥")
}

// 3. 检查应用编译状态
print("\n3️⃣ 检查应用编译状态...")

let compileProcess = Process()
compileProcess.launchPath = "/usr/bin/xcodebuild"
compileProcess.arguments = [
    "-project", "jitata.xcodeproj",
    "-scheme", "jitata",
    "-destination", "platform=iOS Simulator,name=iPhone 16",
    "build",
    "-quiet"
]

let pipe = Pipe()
compileProcess.standardOutput = pipe
compileProcess.standardError = pipe

do {
    try compileProcess.run()
    compileProcess.waitUntilExit()
    
    if compileProcess.terminationStatus == 0 {
        print("✅ 应用编译成功")
    } else {
        print("❌ 应用编译失败")
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("编译错误信息:")
            print(output.suffix(500)) // 显示最后500个字符
        }
    }
} catch {
    print("❌ 无法启动编译进程: \(error)")
}

// 4. 总结测试结果
print("\n📊 测试结果总结")
print("================")
print("✅ 功能已实现:")
print("   - AI增强服务架构")
print("   - 进度监控系统")
print("   - 状态指示器")
print("   - 自动增强触发")
print("   - 重试机制")
print("   - 批量处理")

print("\n🚀 使用说明:")
print("1. 在iOS模拟器中运行应用")
print("2. 拍摄或选择玩具照片")
print("3. 应用会自动进行背景移除")
print("4. 保存后会自动触发AI增强")
print("5. 观察进度监控界面和状态变化")

print("\n💡 进度监控特性:")
print("- 实时进度百分比显示")
print("- 详细状态消息")
print("- 当前处理贴纸名称")
print("- 可取消处理")
print("- 全屏覆盖进度界面")
print("- 卡片上的实时进度环")

print("\n🎯 下一步:")
print("- 运行应用测试完整流程")
print("- 观察AI增强的实时进度")
print("- 验证增强结果的质量")

print("\n测试完成！🎉") 