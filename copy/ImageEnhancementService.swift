import Foundation
import SwiftUI
import SwiftData

/// 图片增强服务
/// 负责调用OpenAI API对图片进行AI增强处理
@MainActor
class ImageEnhancementService: ObservableObject {
    static let shared = ImageEnhancementService()
    
    private let openAIService = OpenAIService.shared
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var currentProcessingSticker: ToySticker?
    @Published var processingStatusMessage: String = ""
    @Published var isShowingProgress = false
    @Published var currentSticker: ToySticker?
    
    private init() {}
    
    // MARK: - 主要方法
    
    /// 增强贴纸图片
    /// - Parameters:
    ///   - sticker: 要增强的贴纸
    ///   - showProgress: 是否显示进度窗口，默认为true
    /// - Returns: 增强是否成功
    @MainActor
    func enhanceSticker(_ sticker: ToySticker, showProgress: Bool = true) async -> Bool {
        print("🚀 开始AI增强处理: \(sticker.name)")
        print("📝 使用分类: \(sticker.categoryName)")
        
        // 更新状态为处理中
        sticker.aiEnhancementStatus = .processing
        sticker.aiEnhancementProgress = 0.0
        sticker.aiEnhancementMessage = "准备开始增强..."
        
        // 只有在showProgress为true时才显示进度窗口
        if showProgress {
            self.isShowingProgress = true
            self.currentSticker = sticker
        }
        
        // 检查是否有处理后的图片
        guard let processedImage = sticker.processedImage else {
            print("❌ 没有找到处理后的图片")
            await updateEnhancementStatus(for: sticker, status: .failed, message: "没有找到处理后的图片")
            if showProgress {
                self.isShowingProgress = false
            }
            return false
        }
        
        // 重试逻辑
        var lastError: Error?
        for attempt in 1...APIConfig.maxRetryAttempts {
            do {
                // 压缩图片以减少传输大小
                let compressedImageData = try compressImageForAPI(processedImage, format: "jpeg")
                
                await updateProgress(for: sticker, progress: 0.1, message: "准备上传图片...")
                
                // 调用API进行增强
                await updateProgress(for: sticker, progress: 0.3, message: "正在上传图片...")
                
                print("📡 发送API请求，尝试次数: \(attempt)/\(APIConfig.maxRetryAttempts)")
                print("📊 请求详细信息:")
                print("   - URL: \(APIConfig.openAIBaseURL)/chat/completions")
                print("   - 方法: POST")
                print("   - 请求体大小: \(compressedImageData.count) bytes")
                print("   - 超时设置: 60.0秒")
                
                do {
                    // 直接调用新的API方法
                    let enhancedImageData = try await enhanceImageWithAPI(compressedImageData, category: sticker.categoryName ?? "未知", format: "jpeg")
                    
                    await updateProgress(for: sticker, progress: 0.9, message: "保存增强图片...")
                    
                    // 保存增强后的图片
                    sticker.enhancedImageData = enhancedImageData
                    
                    await updateEnhancementStatus(for: sticker, status: .completed, message: "增强完成")
                    await updateProgress(for: sticker, progress: 1.0, message: "AI增强完成！")
                    
                    print("✅ AI增强成功完成")
                    
                    // 发送成功通知
                    sendEnhancementNotification(for: sticker, success: true)
                    
                    return true
                    
                } catch {
                    print("❌ AI增强失败 (尝试 \(attempt)/\(APIConfig.maxRetryAttempts)): \(error)")
                    
                    if attempt < APIConfig.maxRetryAttempts {
                        if error.localizedDescription.contains("1005") || error.localizedDescription.contains("network connection") {
                            print("🔄 网络连接丢失，准备重试 (\(attempt)/\(APIConfig.maxRetryAttempts))...")
                            await updateProgress(for: sticker, progress: 0.2, message: "网络连接丢失，正在重试...")
                        } else {
                            print("⚠️ 服务器错误，准备重试: \(error.localizedDescription)")
                            await updateProgress(for: sticker, progress: 0.2, message: "服务器错误，正在重试...")
                        }
                        
                        // 等待一段时间再重试
                        try? await Task.sleep(nanoseconds: UInt64(attempt * 2_000_000_000)) // 递增延迟
                        continue
                    } else {
                        lastError = error
                        break
                    }
                }
                
            } catch {
                print("❌ 图片压缩失败: \(error)")
                await updateEnhancementStatus(for: sticker, status: .failed, message: "图片处理失败")
                return false
            }
        }
        
        // 如果所有重试都失败了
        let finalError = lastError?.localizedDescription ?? "未知错误"
        print("❌ 重试次数已用完，最后错误: \(finalError)")
        await updateEnhancementStatus(for: sticker, status: .failed, message: "增强失败: \(finalError)")
        return false
    }
    
    /// 压缩图片到指定大小，并返回数据和格式
    private func compressImage(_ image: UIImage, maxSizeBytes: Int) -> (data: Data, format: String)? {
        // 极激进的尺寸压缩策略 - 专为网络传输优化
        let maxDimension: CGFloat = 256 // 进一步减小到256像素
        let resizedImage: UIImage
        
        if max(image.size.width, image.size.height) > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            // 使用更高效的图片处理方式
            let renderer = UIGraphicsImageRenderer(size: newSize)
            resizedImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        } else {
            resizedImage = image
        }
        
        // 极激进的压缩质量策略，优先网络传输成功率
        let compressionQualities: [CGFloat] = [0.3, 0.2, 0.15, 0.1, 0.08, 0.05, 0.03]
        
        for quality in compressionQualities {
            if let data = resizedImage.jpegData(compressionQuality: quality),
               data.count <= maxSizeBytes {
                print("📊 图片压缩成功，格式: JPEG, 质量: \(quality), 大小: \(data.count) bytes")
                return (data, "jpeg")
            }
        }
        
        // 如果JPEG压缩还是太大，尝试进一步缩小尺寸
        if maxDimension > 128 {
            let smallerMaxDimension: CGFloat = 128 // 极小尺寸
            let scale = smallerMaxDimension / max(resizedImage.size.width, resizedImage.size.height)
            let smallerSize = CGSize(width: resizedImage.size.width * scale, height: resizedImage.size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: smallerSize)
            let smallerImage = renderer.image { _ in
                resizedImage.draw(in: CGRect(origin: .zero, size: smallerSize))
            }
            
            // 再次尝试压缩，使用极低质量
            let extremeQualities: [CGFloat] = [0.1, 0.05, 0.03, 0.02, 0.01]
            for quality in extremeQualities {
                if let data = smallerImage.jpegData(compressionQuality: quality),
                   data.count <= maxSizeBytes {
                    print("📊 图片极度压缩成功，格式: JPEG, 尺寸: \(smallerSize), 质量: \(quality), 大小: \(data.count) bytes")
                    return (data, "jpeg")
                }
            }
        }
        
        // 如果所有压缩都失败，尝试使用无损的PNG格式
        if let pngData = resizedImage.pngData(), pngData.count <= maxSizeBytes {
            print("📊 图片压缩成功，格式: PNG, 大小: \(pngData.count) bytes")
            return (pngData, "png")
        }
        
        print("❌ 无法将图片压缩到指定大小")
        return nil
    }
    
    /// 重置处理状态
    private func resetProcessingState() {
        isProcessing = false
        processingProgress = 0.0
        currentProcessingSticker = nil
        processingStatusMessage = ""
    }
    
    /// 重试增强
    /// - Parameters:
    ///   - sticker: 要重试的贴纸
    ///   - modelContext: SwiftData模型上下文
    /// - Returns: 是否成功
    @MainActor
    func retryEnhancement(_ sticker: ToySticker, modelContext: ModelContext) async -> Bool {
        print("🔄 重试AI增强: \(sticker.name)")
        
        // 重置状态为pending
        sticker.updateEnhancementStatus(.pending)
        try? modelContext.save()
        
        // 调用增强方法
        return await enhanceSticker(sticker, showProgress: false)
    }
    
    /// 批量增强多个贴纸
    /// - Parameters:
    ///   - stickers: 要增强的贴纸数组
    ///   - modelContext: SwiftData模型上下文
    /// - Returns: 成功增强的数量
    @MainActor
    func enhanceMultipleStickers(_ stickers: [ToySticker], modelContext: ModelContext) async -> Int {
        var successCount = 0
        let totalCount = stickers.count
        
        print("🚀 开始批量AI增强，共 \(totalCount) 个贴纸")
        
        for (index, sticker) in stickers.enumerated() {
            // 更新进度
            processingProgress = Double(index) / Double(totalCount)
            processingStatusMessage = "正在处理第 \(index + 1)/\(totalCount) 个贴纸..."
            
            // 只处理待增强或失败的贴纸
            if sticker.currentEnhancementStatus == .pending || sticker.canRetryEnhancement {
                let success = await enhanceSticker(sticker, showProgress: false)
                if success {
                    successCount += 1
                }
                
                // 添加延迟避免API限制
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
            }
        }
        
        processingProgress = 1.0
        processingStatusMessage = "批量增强完成！成功 \(successCount)/\(totalCount)"
        
        print("✅ 批量AI增强完成，成功 \(successCount)/\(totalCount)")
        
        // 延迟重置状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.resetProcessingState()
        }
        
        return successCount
    }
    
    // MARK: - 辅助方法
    
    /// 检查API是否已配置
    var isAPIConfigured: Bool {
        return APIConfig.isAPIKeyConfigured
    }
    
    /// 检查网络连接状态
    private func checkNetworkConnection() async -> Bool {
        do {
            // 尝试连接到API服务器
            guard let url = URL(string: APIConfig.openAIBaseURL) else { return false }
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            config.waitsForConnectivity = false
            let session = URLSession(configuration: config)
            
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 网络连接检查: 状态码 \(httpResponse.statusCode)")
                return httpResponse.statusCode < 500 // 只要不是服务器错误就认为网络可用
            }
            
            return false
        } catch {
            print("🌐 网络连接检查失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 检查API服务器连通性
    private func checkAPIServerReachability() async -> Bool {
        do {
            // 尝试连接到具体的API端点
            guard let url = URL(string: "\(APIConfig.openAIBaseURL)/images/edits") else { return false }
            
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 15.0
            config.waitsForConnectivity = false
            config.allowsCellularAccess = true
            config.allowsExpensiveNetworkAccess = true
            let session = URLSession(configuration: config)
            
            var request = URLRequest(url: url)
            request.httpMethod = "OPTIONS" // 使用OPTIONS方法检查端点可用性
            request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("🌐 API服务器连通性检查: 状态码 \(httpResponse.statusCode)")
                // 405 Method Not Allowed 也表示服务器可达，只是不支持OPTIONS方法
                return httpResponse.statusCode < 500 || httpResponse.statusCode == 405
            }
            
            return false
        } catch {
            print("🌐 API服务器连通性检查失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 获取处理状态描述
    var processingStatusDescription: String {
        if isProcessing {
            return processingStatusMessage.isEmpty ? 
                "正在处理中... \(Int(processingProgress * 100))%" : 
                processingStatusMessage
        } else {
            return "就绪"
        }
    }
    
    /// 取消当前处理
    func cancelProcessing() {
        print("🛑 取消AI增强处理")
        resetProcessingState()
    }
    
    /// 获取当前处理的贴纸名称
    var currentProcessingStickerName: String? {
        return currentProcessingSticker?.name
    }
    
    /// 更新增强进度
    @MainActor
    private func updateProgress(for sticker: ToySticker, progress: Double, message: String) async {
        sticker.aiEnhancementProgress = progress
        sticker.aiEnhancementMessage = message
        print("📊 AI增强进度: \(Int(progress * 100))% - \(message)")
    }
    
    /// 更新增强状态
    @MainActor
    private func updateEnhancementStatus(for sticker: ToySticker, status: AIEnhancementStatus, message: String) async {
        sticker.aiEnhancementStatus = status
        sticker.aiEnhancementMessage = message
        print("🔄 AI增强状态更新: \(status) - \(message)")
    }
    

    
    /// 为API压缩图片
    private func compressImageForAPI(_ image: UIImage, format: String) throws -> Data {
        // 调整图片尺寸到合理大小，但不要过度压缩
        let maxDimension: CGFloat = 1024
        let resizedImage: UIImage
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // 使用更合理的压缩质量，优先保证图片质量
        let compressionQuality: CGFloat = 0.8  // 提高压缩质量到0.8
        guard let imageData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw APIError.compressionFailed
        }
        
        print("📊 图片压缩成功，格式: JPEG, 质量: \(compressionQuality), 大小: \(imageData.count) bytes")
        return imageData
    }
}

// MARK: - 通知扩展

extension ImageEnhancementService {
    /// 发送增强完成通知
    private func sendEnhancementNotification(for sticker: ToySticker, success: Bool) {
        let notificationCenter = NotificationCenter.default
        let userInfo: [String: Any] = [
            "stickerId": sticker.id.uuidString,
            "success": success,
            "stickerName": sticker.name
        ]
        
        notificationCenter.post(
            name: NSNotification.Name("ImageEnhancementCompleted"),
            object: nil,
            userInfo: userInfo
        )
        
        print("📢 发送AI增强通知: \(sticker.name) - \(success ? "成功" : "失败")")
    }
}

enum ImageEnhancementError: Error {
    case invalidImage
    case networkError
    case serverError(Int, String)
    case invalidResponse
    case compressionFailed
    case noImageInResponse
    case invalidImageURL
    case imageDownloadFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidImage:
            return "无效的图片数据"
        case .networkError:
            return "网络连接错误"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .compressionFailed:
            return "图片压缩失败"
        case .noImageInResponse:
            return "响应中未包含图片"
        case .invalidImageURL:
            return "无效的图片URL"
        case .imageDownloadFailed:
            return "图片下载失败"
        }
    }
}



private func enhanceImageWithAPI(_ imageData: Data, category: String, format: String) async throws -> Data {
    print("🌐 API配置信息:")
    print("   - 基础URL: \(APIConfig.openAIBaseURL)")
    print("   - API密钥前缀: \(APIConfig.openAIAPIKey.prefix(10))...")
    print("   - 模型: \(APIConfig.openAIModel)")
    
    // 根据Tu-Zi API文档，使用图片生成接口
    let url = URL(string: "\(APIConfig.openAIBaseURL)/images/generate")!
    print("🌐 创建API请求: \(url)")
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    print("📊 图片数据大小: \(imageData.count) bytes")
    
    // 将图片转换为base64编码，不再进一步压缩
    let base64Image = imageData.base64EncodedString()
    print("📝 图片已转换为base64，长度: \(base64Image.count) 字符")
    
    // 使用完整的分类特定提示词
    let fullPrompt = PromptManager.shared.getEnhancementPrompt(for: category)
    print("📝 使用完整提示词，分类: \(category)")
    print("📝 提示词内容: \(fullPrompt.prefix(100))...")
    
    // 根据Tu-Zi API文档构造JSON请求体，使用图片生成API
    let requestBody: [String: Any] = [
        "model": "gpt-image-1",  // 使用正确的模型
        "prompt": fullPrompt,
        "size": "1024x1024",
        "quality": "high",
        "format": "png",
        "background": "transparent",
        "n": 1
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
    
    print("📤 请求体大小: \(jsonData.count) bytes")
    print("🔑 使用API密钥前缀: \(APIConfig.openAIAPIKey.prefix(10))...")
    
    // 优化URLSession配置，解决网络连接问题
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60.0   // 设置为60秒
    config.timeoutIntervalForResource = 120.0  // 设置为2分钟
    config.waitsForConnectivity = true
    config.allowsCellularAccess = true
    config.allowsExpensiveNetworkAccess = true
    config.allowsConstrainedNetworkAccess = true
    
    // 优化网络参数，避免连接问题
    config.httpMaximumConnectionsPerHost = 2
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.httpShouldUsePipelining = false
    config.httpShouldSetCookies = false
    
    // 添加Connection: close头，避免连接复用问题
    request.setValue("close", forHTTPHeaderField: "Connection")
    request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    
    let session = URLSession(configuration: config)
    
    // 使用标准的data任务
    request.httpBody = jsonData
    
    let (data, response) = try await session.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        throw APIError.invalidResponse
    }
    
    print("📥 收到响应，状态码: \(httpResponse.statusCode)")
    print("📊 响应数据大小: \(data.count) bytes")
    
    // 局部函数：解析增强响应
    func parseEnhancementResponse(_ data: Data) async throws -> Data {
        // 解析Tu-Zi API的图片生成响应格式
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("📥 收到JSON响应，键: \(Array(jsonResponse.keys))")
                
                // 检查是否有错误信息
                if let error = jsonResponse["error"] as? [String: Any] {
                    let errorMessage = error["message"] as? String ?? "未知错误"
                    let errorType = error["type"] as? String ?? "unknown"
                    let errorCode = error["code"] as? String ?? "unknown"
                    
                    print("❌ API返回错误: \(errorType) - \(errorCode) - \(errorMessage)")
                    throw APIError.enhancementFailed("[\(errorType)] \(errorMessage)")
                }
                
                // 解析图片生成响应格式
                if let dataArray = jsonResponse["data"] as? [[String: Any]],
                   let firstImage = dataArray.first {
                    
                    // 优先使用base64数据
                    if let base64String = firstImage["b64_json"] as? String {
                        print("🖼️ 找到base64图片数据，长度: \(base64String.count)")
                        
                        guard let imageData = Data(base64Encoded: base64String) else {
                            throw APIError.enhancementFailed("无法解码base64图片数据")
                        }
                        
                        print("✅ 图片解码成功，大小: \(imageData.count) bytes")
                        return imageData
                    }
                    
                    // 如果没有base64数据，尝试从URL下载
                    if let imageURL = firstImage["url"] as? String {
                        print("🖼️ 找到图片URL: \(imageURL)")
                        
                        // 下载增强后的图片
                        let imageData = try await downloadImage(from: imageURL)
                        print("✅ 图片下载成功，大小: \(imageData.count) bytes")
                        return imageData
                    }
                    
                    print("⚠️ 响应中既没有base64数据也没有URL")
                    throw APIError.enhancementFailed("响应中未包含图片数据")
                } else {
                    print("❌ 响应格式不正确，缺少data数组")
                    throw APIError.invalidResponse
                }
            } else {
                print("❌ JSON响应格式不正确")
                throw APIError.invalidResponse
            }
        } catch let jsonError {
            print("❌ JSON解析失败: \(jsonError)")
            
            // 尝试作为字符串解析错误信息
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ 响应错误文本: \(errorString)")
                throw APIError.enhancementFailed(errorString)
            }
            
            throw APIError.invalidResponse
        }
    }
    
    // 局部函数：从AI响应中提取图片URL
    func extractImageURL(from content: String) -> String? {
        // Tu-Zi API通常返回Markdown格式的图片链接，如: ![description](https://example.com/image.jpg)
        let pattern = #"!\[.*?\]\((https://[^)]+)\)"#
        
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let urlRange = Range(match.range(at: 1), in: content) {
            return String(content[urlRange])
        }
        
        // 如果没有找到Markdown格式，尝试直接查找URL
        let urlPattern = #"https://[^\s)]+\.(jpg|jpeg|png|gif|webp)"#
        if let urlRegex = try? NSRegularExpression(pattern: urlPattern),
           let urlMatch = urlRegex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let urlRange = Range(urlMatch.range, in: content) {
            return String(content[urlRange])
        }
        
        return nil
    }
    
    // 局部函数：下载图片
    func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidResponse
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.enhancementFailed("图片下载失败")
        }
        
        return data
    }
    
    // 局部函数：解析错误响应
    func parseErrorResponse(_ data: Data) -> String {
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = jsonResponse["error"] as? [String: Any] {
                
                let message = error["message"] as? String ?? "未知错误"
                let type = error["type"] as? String ?? "unknown"
                let code = error["code"] as? String ?? "unknown"
                
                return "[\(type)] \(message) (代码: \(code))"
            }
        } catch {
            print("❌ 错误响应JSON解析失败: \(error)")
        }
        
        if let errorString = String(data: data, encoding: .utf8) {
            return errorString
        }
        
        return "未知错误"
    }
    
    if httpResponse.statusCode == 200 {
        return try await parseEnhancementResponse(data)
    } else {
        let errorMessage = parseErrorResponse(data)
        print("❌ API错误 (\(httpResponse.statusCode)): \(errorMessage)")
        throw APIError.enhancementFailed("HTTP \(httpResponse.statusCode): \(errorMessage)")
    }
} 