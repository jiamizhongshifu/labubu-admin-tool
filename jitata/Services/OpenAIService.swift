import Foundation
import UIKit

/// OpenAI服务类
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {
        // 配置JSON编码器
        encoder.outputFormatting = .prettyPrinted
    }
    
    // MARK: - 图片增强方法
    
    /// 增强图片
    /// - Parameters:
    ///   - image: 要增强的图片
    ///   - category: 图片分类
    /// - Returns: 增强后的图片
    func enhanceImage(_ image: UIImage, category: String?) async throws -> UIImage {
        // 验证API密钥
        guard APIConfig.isAPIKeyConfigured else {
            throw APIError.missingAPIKey
        }
        
        // 获取提示词
        let prompt = PromptManager.shared.getDefaultPrompt()
        
        // 使用图片编辑API
        return try await editImage(image, prompt: prompt)
    }
    
    /// 编辑图片
    /// - Parameters:
    ///   - image: 原始图片
    ///   - prompt: 编辑提示词
    /// - Returns: 编辑后的图片
    private func editImage(_ image: UIImage, prompt: String) async throws -> UIImage {
        // 创建URL
        guard let url = URL(string: "\(APIConfig.openAIBaseURL)/images/edits") else {
            throw APIError.invalidURL
        }
        
        // 准备图片数据
        guard let imageData = image.pngData() else {
            throw APIError.enhancementFailed("无法处理图片数据")
        }
        
        // 创建multipart/form-data请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = APIConfig.enhancementTimeout
        
        // 创建multipart数据
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加模型参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(APIConfig.openAIModel)\r\n".data(using: .utf8)!)
        
        // 添加提示词
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(prompt)\r\n".data(using: .utf8)!)
        
        // 添加图片文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 添加其他参数
        let parameters = [
            ("size", "1024x1024"),
            ("quality", "high"),
            ("format", "png"),
            ("background", "transparent")
        ]
        
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 结束boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // 发送请求
        do {
            let (data, response) = try await session.data(for: request)
            
            // 检查HTTP状态码
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                    throw APIError.enhancementFailed("HTTP错误 \(httpResponse.statusCode): \(errorMessage)")
                }
            }
            
            // 解析响应
            let imageResponse = try decoder.decode(OpenAIImageResponse.self, from: data)
            return try await processImageResponse(imageResponse)
            
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理图片API响应
    private func processImageResponse(_ response: OpenAIImageResponse) async throws -> UIImage {
        // 检查响应是否有效
        guard let imageData = response.data.first else {
            throw APIError.enhancementFailed("API响应中没有图片数据")
        }
        
        // 优先使用Base64数据
        if let base64String = imageData.b64Json {
            guard let data = Data(base64Encoded: base64String) else {
                throw APIError.enhancementFailed("无法解码Base64图片数据")
            }
            
            guard let image = UIImage(data: data) else {
                throw APIError.enhancementFailed("无法创建UIImage")
            }
            
            print("✅ 成功从Base64数据创建增强图片")
            return image
        }
        
        // 如果没有Base64数据，尝试从URL下载
        if let urlString = imageData.url, let url = URL(string: urlString) {
            do {
                let (data, _) = try await session.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw APIError.enhancementFailed("无法从URL创建UIImage")
                }
                
                print("✅ 成功从URL下载增强图片")
                return image
            } catch {
                throw APIError.enhancementFailed("下载图片失败: \(error.localizedDescription)")
            }
        }
        
        throw APIError.enhancementFailed("响应中既没有Base64数据也没有有效URL")
    }
}

// MARK: - 扩展方法

extension OpenAIService {
    /// 测试API连接
    func testConnection() async -> Bool {
        guard APIConfig.isAPIKeyConfigured else {
            return false
        }
        
        // 创建一个简单的测试请求
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        
        do {
            _ = try await enhanceImage(testImage, category: nil)
            return true
        } catch {
            print("API连接测试失败: \(error)")
            return false
        }
    }
    
    /// 获取API状态
    var apiStatus: String {
        if APIConfig.isAPIKeyConfigured {
            return "已配置"
        } else {
            return "未配置"
        }
    }
} 