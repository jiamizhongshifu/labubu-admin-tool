import SwiftUI
import Combine
import UIKit
import Foundation
import SwiftData

// 🔧 添加图像增强错误类型
enum ImageEnhancementError: Error, LocalizedError {
    case invalidImageData(String)
    case networkError(String)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData(let message):
            return "图像数据错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .apiError(let message):
            return "API错误: \(message)"
        }
    }
}

// MARK: - ImageEnhancementService
class ImageEnhancementService: NSObject, ObservableObject {
    
    // Singleton instance
    static let shared = ImageEnhancementService()
    
    // Published properties to be observed by the UI
    @Published var currentSticker: ToySticker?
    
    private var urlSession: URLSession
    private var keepAliveTimer: Timer?
    
    private override init() {
        // 🔧 优化网络配置 - 先初始化属性再调用super.init()
        urlSession = ImageEnhancementService.createOptimizedURLSessionStatic()
        super.init()
    }
    
    // 静态方法创建URLSession，避免在init中调用实例方法
    private static func createOptimizedURLSessionStatic() -> URLSession {
        let config = URLSessionConfiguration.default
        
        // 🔧 激进的超时配置 - 突破60秒限制
        config.timeoutIntervalForRequest = 600.0     // 10分钟请求超时
        config.timeoutIntervalForResource = 900.0    // 15分钟资源超时
        
        // 🚀 网络优化设置 - 最大化连接稳定性
        config.allowsCellularAccess = true
        config.allowsConstrainedNetworkAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.waitsForConnectivity = true           // 🔧 等待网络连接
        config.shouldUseExtendedBackgroundIdleMode = true  // 🔧 扩展后台模式
        
        // 🔧 HTTP连接优化 - 突破系统限制
        config.httpMaximumConnectionsPerHost = 6     // 增加并发连接数
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        
        // 🔧 缓存策略 - 避免缓存以确保每次都是新请求
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        
        // 🔧 关键：设置HTTP/2和Keep-Alive以避免60秒连接超时
        config.httpAdditionalHeaders = [
            "Connection": "keep-alive",
            "Keep-Alive": "timeout=600, max=10000",   // 🔧 延长keep-alive时间
            "User-Agent": "jitata-iOS/1.0 (iPhone; iOS 17.0)",
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Cache-Control": "no-cache",
            "Pragma": "no-cache"
        ]
        
        // 🔧 网络服务类型 - 设置为后台任务
        config.networkServiceType = .background
        
        return URLSession(configuration: config)
    }

    private func logProgress(for sticker: ToySticker, _ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        print("[图像增强服务] [\(timestamp)] [贴纸: \(sticker.id)]: \(message)")
    }

    func enhanceImage(for sticker: ToySticker, customPrompt: String? = nil, model: AIModel? = nil, aspectRatio: String = "1:1") async -> Data? {
        // 取消之前的任务（如果有）
        currentTask?.cancel()
        
        // 创建新的增强任务
        currentTask = Task<Data?, Never> {
            return await performEnhancement(for: sticker, customPrompt: customPrompt, model: model, aspectRatio: aspectRatio)
        }
        return await currentTask?.value
    }
    
    private func performEnhancement(for sticker: ToySticker, customPrompt: String? = nil, model: AIModel? = nil, aspectRatio: String = "1:1", attempt: Int = 1) async -> Data? {
        let maxAttempts = 3
        
        // 检查任务是否已被取消
        if Task.isCancelled {
            logProgress(for: sticker, "🚫 任务已被取消")
            return nil
        }
        
        logProgress(for: sticker, "尝试 \(attempt)/\(maxAttempts): 开始图像增强处理。")
        
        await MainActor.run {
            self.currentSticker = sticker
            sticker.aiEnhancementStatus = .processing
            sticker.aiEnhancementProgress = 0.05
            sticker.aiEnhancementMessage = "初始化增强任务..."
            
            // 🔄 重新增强时，清除之前的增强图片并重置显示状态
            if sticker.hasEnhancedImage {
                sticker.enhancedImageData = nil
                sticker.isShowingEnhancedImage = true  // 重置为显示增强图
            }
        }
        
        do {
            let enhancedData = try await enhanceImageInternal(for: sticker, customPrompt: customPrompt, model: model, aspectRatio: aspectRatio)
            await MainActor.run {
                sticker.aiEnhancementStatus = .completed
                sticker.aiEnhancementProgress = 1.0
                self.currentSticker = nil
            }
            return enhancedData
        } catch {
            logProgress(for: sticker, "网络错误: \(error.localizedDescription)")
            
            // 详细的网络错误诊断
            if let urlError = error as? URLError {
                logProgress(for: sticker, "URL错误代码: \(urlError.code.rawValue)")
                logProgress(for: sticker, "URL错误描述: \(urlError.localizedDescription)")
                
                switch urlError.code {
                case .networkConnectionLost:
                    logProgress(for: sticker, "诊断: 上传/下载过程中网络连接丢失 - 可能是60秒超时限制")
                case .timedOut:
                    logProgress(for: sticker, "诊断: 请求超时 - 可能是网络基础设施60秒限制")
                case .cannotConnectToHost:
                    logProgress(for: sticker, "诊断: 无法连接到主机")
                case .notConnectedToInternet:
                    logProgress(for: sticker, "诊断: 未连接到互联网")
                default:
                    logProgress(for: sticker, "诊断: 其他网络错误")
                }
            }
            
            logProgress(for: sticker, "尝试 \(attempt)/\(maxAttempts) 失败: \(error.localizedDescription)")
            
            if attempt < maxAttempts {
                let delay = Double(attempt * 2) // 2秒, 4秒
                logProgress(for: sticker, "等待 \(delay) 秒后重试...")
                
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return await performEnhancement(for: sticker, customPrompt: customPrompt, model: model, aspectRatio: aspectRatio, attempt: attempt + 1)
            } else {
                logProgress(for: sticker, "所有尝试均失败。最终错误: \(error.localizedDescription)")
                
                await MainActor.run {
                    sticker.aiEnhancementStatus = .failed
                    sticker.aiEnhancementMessage = "增强失败: \(error.localizedDescription)"
                    self.currentSticker = nil
                }
                return nil
            }
        }
    }
    
    // 新增：Keep-Alive心跳机制
    private func startKeepAlive(for url: URL, with headers: [String: String]) {
        stopKeepAlive() // 先停止之前的心跳
        
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 90.0, repeats: true) { [weak self] _ in
            Task {
                await self?.sendKeepAliveRequest(to: url, headers: headers)
            }
        }
    }
    
    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    private func sendKeepAliveRequest(to url: URL, headers: [String: String]) async {
        do {
            // 发送一个轻量级的HEAD请求来保持连接
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 10.0 // 短超时
            
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("[Keep-Alive] 心跳请求成功，状态码: \(httpResponse.statusCode)")
            }
                } catch {
            print("[Keep-Alive] 心跳请求失败: \(error.localizedDescription)")
        }
    }
    
    private func enhanceImageInternal(for sticker: ToySticker, customPrompt: String? = nil, model: AIModel? = nil, aspectRatio: String = "1:1") async throws -> Data {
        // 检查任务是否已被取消
        if Task.isCancelled {
            logProgress(for: sticker, "🚫 增强任务已被取消")
            throw CancellationError()
        }
        
        logProgress(for: sticker, "步骤 1/8: 开始增强处理。")
        await MainActor.run {
            sticker.aiEnhancementProgress = 0.1
            sticker.aiEnhancementMessage = "准备图像数据..."
        }
        
        // 优先使用TUZI_API_KEY和TUZI_API_BASE，保持向后兼容
        let apiKey: String
        let apiBase: String
        
        if let tuziKey = APIConfig.tuziAPIKey, !tuziKey.isEmpty {
            apiKey = tuziKey
                        } else {
            let openaiKey = APIConfig.openAIAPIKey
            if !openaiKey.isEmpty {
                apiKey = openaiKey
            } else {
                logProgress(for: sticker, "错误: 未配置API密钥 (TUZI_API_KEY 或 OPENAI_API_KEY)。")
                await MainActor.run {
                    sticker.aiEnhancementStatus = .failed
                }
                return Data()
            }
        }
        
        if let tuziBase = APIConfig.tuziAPIBase, !tuziBase.isEmpty {
            apiBase = tuziBase
                    } else {
            let openaiBase = APIConfig.openAIBaseURL
            if !openaiBase.isEmpty {
                apiBase = openaiBase
            } else {
                logProgress(for: sticker, "错误: 未配置API基础URL (TUZI_API_BASE 或 OPENAI_BASE_URL)。")
                await MainActor.run {
                    sticker.aiEnhancementStatus = .failed
                }
                return Data()
            }
        }
        
        guard !sticker.processedImageData.isEmpty else {
            logProgress(for: sticker, "错误: 没有可用的处理图像数据。")
            await MainActor.run {
                sticker.aiEnhancementStatus = .failed
            }
            return Data()
        }
        
        let imageData = sticker.processedImageData
        
        // 步骤2：压缩图像（仅在需要时）
        let selectedModel = model ?? .fluxKontext
        let compressedImageData: Data
        
        if selectedModel == .fluxKontext {
            // Flux-Kontext需要压缩图像用于上传到图床
            logProgress(for: sticker, "步骤 2/8: 开始图像压缩...")
            await MainActor.run {
                sticker.aiEnhancementProgress = 0.15
                sticker.aiEnhancementMessage = "压缩图像数据..."
            }
            
            // 🔧 使用新的PNG压缩策略
            guard let compressed = compressImage(UIImage(data: imageData)!, targetSize: CGSize(width: 1024, height: 1024), for: sticker) else {
                throw ImageEnhancementError.invalidImageData("图像压缩失败")
            }
            compressedImageData = compressed
            
            logProgress(for: sticker, "步骤 2/8: PNG压缩完成，从 \(imageData.count) 字节减少到 \(compressedImageData.count) 字节")
            await MainActor.run {
                sticker.aiEnhancementProgress = 0.2
                sticker.aiEnhancementMessage = "图像压缩完成"
            }
        } else {
            // GPT-4 Vision将在后续步骤中处理图像压缩
            logProgress(for: sticker, "步骤 2/8: GPT-4 Vision将使用本地图像数据")
            await MainActor.run {
                sticker.aiEnhancementProgress = 0.15
                sticker.aiEnhancementMessage = "准备本地图像数据..."
            }
            compressedImageData = imageData // 使用原始数据，后续会重新压缩
        }
        
        // 🚀 根据模型选择API端点
        let apiEndpoint: String
        
        switch selectedModel {
        case .fluxKontext:
            apiEndpoint = "/images/generations"
        case .gpt4Vision:
            apiEndpoint = "/chat/completions"
        }
        
        let apiURL = URL(string: "\(apiBase)\(apiEndpoint)")!
        logProgress(for: sticker, "步骤 3/8: 准备API请求到 \(apiURL) (模型: \(selectedModel.displayName))")
        await MainActor.run {
            sticker.aiEnhancementProgress = 0.25
            sticker.aiEnhancementMessage = "准备API请求..."
        }
        
        // 获取提示词（优先使用自定义提示词）
        let finalPrompt: String
        if let customPrompt = customPrompt, !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // 🔧 根据模型类型优化提示词
            if selectedModel == .gpt4Vision {
                // 为GPT-4 Vision优化提示词，强制生成图片
                finalPrompt = """
Based on the uploaded image, create a new artistic image with these requirements: \(customPrompt)

CRITICAL INSTRUCTIONS:
- Use the uploaded image as reference for generating a new image
- Apply the requirements above to create an artistic version
- MUST generate and return an image URL, do NOT ask questions or provide text explanations
- Focus on image generation, not conversation

Output format required:
{
  "prompt": "[detailed prompt based on image and requirements]",
  "size": "1024x1024"
}

Generate the image immediately.
"""
        } else {
                finalPrompt = customPrompt
            }
            logProgress(for: sticker, "步骤 4/8: 使用自定义提示词")
        } else {
            finalPrompt = PromptManager.shared.getDefaultPrompt()
            logProgress(for: sticker, "步骤 4/8: 使用默认提示词")
        }
        
        // 🔧 准备图像URL - 仅为Flux-Kontext模型上传到图床
        var imageUrl: String = ""
        
        if selectedModel == .fluxKontext {
            // 只有Flux-Kontext需要图床URL
            do {
                imageUrl = try await uploadImageToFreeHost(compressedImageData, for: sticker)
                logProgress(for: sticker, "✅ 图像已上传到图床: \(imageUrl)")
            } catch {
                logProgress(for: sticker, "⚠️ 图像上传失败，使用备用方案")
                // 备用方案：使用示例URL，提醒用户配置图床服务
                imageUrl = "https://tuziai.oss-cn-shenzhen.aliyuncs.com/style/default_style_small.png"
                logProgress(for: sticker, "📌 使用示例图像URL，请配置您自己的图床服务")
            }
        }
        
        // 🚀 构建API请求
        logProgress(for: sticker, "步骤 5/8: 准备API请求体")
        if selectedModel == .fluxKontext {
            logProgress(for: sticker, "📝 图像URL: \(imageUrl)")
        }
        logProgress(for: sticker, "📝 提示词: \(finalPrompt)")
        
        await MainActor.run {
            sticker.aiEnhancementProgress = 0.35
            sticker.aiEnhancementMessage = "构建请求参数..."
        }
        
        // 🚀 构造API请求体（根据模型类型）
        var requestBody: [String: Any]
        
        switch selectedModel {
        case .fluxKontext:
            // 🔧 检测原图比例并构建智能提示词
            let originalAspectRatio = detectOriginalImageAspectRatio(from: sticker)
            let aspectRatioPrompt = buildAspectRatioPrompt(original: originalAspectRatio, target: aspectRatio)
            
            // Flux-Kontext Pro API格式 - 需要将图片URL和提示词合并，并明确要求比例
            let enhancedPrompt: String
            if originalAspectRatio != aspectRatio {
                // 当比例不同时，在开头强调比例要求，减弱对原图比例的依赖
                enhancedPrompt = "严格要求：生成\(aspectRatioPrompt.trimmingCharacters(in: .whitespaces))的图像。参考图像：\(imageUrl) 基于参考图像的内容：\(finalPrompt)"
            } else {
                // 比例相同时，正常处理
                enhancedPrompt = "\(imageUrl) \(finalPrompt)\(aspectRatioPrompt)"
            }
            
            logProgress(for: sticker, "📐 检测到原图比例: \(originalAspectRatio), 目标比例: \(aspectRatio)")
            if !aspectRatioPrompt.isEmpty {
                logProgress(for: sticker, "📝 添加比例调整提示: \(aspectRatioPrompt)")
            }
            
            // 🔧 根据kontext.md文档：当需要改变比例时，不传递aspect_ratio参数
            requestBody = [
                "model": selectedModel.rawValue,
                "prompt": enhancedPrompt,
                "output_format": "png",          // PNG格式
                "output_quality": 95,            // 高质量输出
                "safety_tolerance": 2,           // 安全容忍度
                "prompt_upsampling": false,      // 不进行提示上采样
                "num_inference_steps": 28,       // 推理步数（提高质量）
                "guidance_scale": 3.5,           // 引导比例（保持细节）
                "seed": -1,                      // 随机种子
                "n": 1,                          // 生成图片数量
                "response_format": "url"         // 响应格式
            ]
            
            // 🎯 智能决定是否传递aspect_ratio参数
            if originalAspectRatio == aspectRatio {
                // 比例相同，不传递aspect_ratio参数（保持原图比例）
                logProgress(for: sticker, "📐 比例相同，不传递aspect_ratio参数，保持原图比例")
            } else {
                // 比例不同，传递aspect_ratio参数指定新比例
                requestBody["aspect_ratio"] = aspectRatio
                logProgress(for: sticker, "📐 比例不同，传递aspect_ratio参数: \(aspectRatio)")
                
                // 🔧 同时添加size参数来强制指定尺寸
                let sizeString = aspectRatioToSize(aspectRatio)
                requestBody["size"] = sizeString
                logProgress(for: sticker, "📐 同时设置size参数: \(sizeString)")
            }
            
        case .gpt4Vision:
            // GPT-4 Vision API格式（根据 gpt.md 文档）- 使用本地图片转base64
            
            logProgress(for: sticker, "📝 使用模型: gpt-4o-all")
            logProgress(for: sticker, "📝 用户自定义提示词: \(finalPrompt)")
            logProgress(for: sticker, "🔄 使用本地图片数据转换为base64")
            
            // 🔧 使用本地图片数据，避免网络下载和质量损失
            do {
                logProgress(for: sticker, "步骤 4.5/8: 处理本地图片数据并压缩到500KB以内...")
                
                // 使用本地图片数据（已经在前面准备好）
                let imageData = compressedImageData
                logProgress(for: sticker, "✅ 使用本地图片数据，大小: \(imageData.count) 字节")
                
                // 🔧 检测原始图片格式
                let originalFormat = detectImageFormat(from: imageData)
                logProgress(for: sticker, "📷 检测到图片格式: \(originalFormat)")
                
                // 🔧 压缩图片到200KB以内（按gpt.md文档要求）
                var processedImageData = imageData
                var finalFormat = originalFormat
                let maxSize = 500_000 // 500KB - 提高压缩限制，保留更多细节
                
                if imageData.count > maxSize {
                    logProgress(for: sticker, "⚠️ 图片过大(\(imageData.count)字节)，压缩到500KB以内...")
                    
                    guard let image = UIImage(data: imageData) else {
                        throw ImageEnhancementError.invalidImageData("无法创建UIImage")
                    }
                    
                                        // 🔧 优化压缩策略：优先保持PNG格式和透明背景
                    var compressionQuality: CGFloat = 0.9  // 提高初始质量
                    var attempts = 0
                    let maxAttempts = 8
                    
                    while attempts < maxAttempts {
                        let compressedData: Data?
                        
                        if originalFormat == "png" && attempts < 6 {
                            // PNG格式：前6次尝试保持PNG格式，保留透明背景
                            if attempts == 0 {
                                // 第一次尝试：不压缩，直接使用原图
                                compressedData = imageData
                            } else {
                                // 后续尝试：通过调整图片尺寸来减小文件大小
                                let scale = 1.0 - (Double(attempts) * 0.1)  // 逐步缩小
                                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                                let resizedImage = image.resized(to: newSize)
                                compressedData = resizedImage.pngData()
                            }
                            finalFormat = "png"
                        } else {
                            // 其他格式或PNG压缩失败：使用JPEG压缩
                            compressedData = image.jpegData(compressionQuality: compressionQuality)
                            finalFormat = "jpeg"
                        }
                        
                        guard let data = compressedData else {
                            throw ImageEnhancementError.invalidImageData("图片压缩失败")
                        }
                        
                        if data.count <= maxSize {
                            processedImageData = data
                            break
                        }
                        
                        compressionQuality -= 0.1
                        attempts += 1
                        
                        if compressionQuality <= 0.1 {
                            compressionQuality = 0.1
                        }
                    }
                    
                    logProgress(for: sticker, "✅ 图片已压缩，格式: \(finalFormat)，大小: \(processedImageData.count) 字节")
                } else {
                    logProgress(for: sticker, "✅ 图片大小合适(\(imageData.count)字节)，无需压缩")
                }
                
                // 🔧 转换为base64格式（按gpt.md文档格式）
                let base64String = processedImageData.base64EncodedString()
                let mimeType = finalFormat == "png" ? "image/png" : "image/jpeg"
                
                logProgress(for: sticker, "📝 Base64长度: \(base64String.count) 字符")
                
                // 🎯 按照gpt.md文档格式构建请求体（启用流模式避免60秒超时）
                requestBody = [
                    "model": "gpt-4o-all",  // 使用gpt-4o-all模型
                    "stream": true,  // 🔧 启用流模式，支持长时间处理和心跳
                    "max_tokens": 4096,  // 🔧 限制token数量，避免过长文本回复
                    "temperature": 0.7,  // 🔧 适度的创造性
                    "messages": [
                        [
                            "role": "system",
                            "content": "You are an AI image generator. When given an image and requirements, you must generate a new image based on the reference image and return the image URL. Do not engage in conversation or ask questions. Always generate images directly."
                        ],
                        [
                            "role": "user",
                            "content": [
                                [
                                    "type": "text",
                                    "text": finalPrompt  // 用户自定义提示词
                                ],
                                [
                                    "type": "image_url",
                                    "image_url": [
                                        "url": "data:\(mimeType);base64,\(base64String)"
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
                
            } catch {
                logProgress(for: sticker, "❌ 图片下载或处理失败: \(error.localizedDescription)")
                throw error
            }
        }
        
        logProgress(for: sticker, "📝 使用模型: \(selectedModel.displayName)")
        
        // 🔍 调试信息：记录发送的提示词（根据模型类型）
        switch selectedModel {
        case .fluxKontext:
            if let enhancedPrompt = (requestBody["prompt"] as? String) {
                logProgress(for: sticker, "📝 发送的完整提示词长度: \(enhancedPrompt.count) 字符")
                logProgress(for: sticker, "📝 完整提示词内容: \(enhancedPrompt)")
            }
            // 🔍 调试aspect_ratio参数
            if let aspectRatioValue = requestBody["aspect_ratio"] as? String {
                logProgress(for: sticker, "📐 发送的aspect_ratio参数: \(aspectRatioValue)")
            } else {
                logProgress(for: sticker, "❌ aspect_ratio参数缺失或类型错误")
            }
            // 🔍 调试完整请求体参数
            logProgress(for: sticker, "📋 完整请求体参数:")
            for (key, value) in requestBody {
                logProgress(for: sticker, "  - \(key): \(value)")
            }
        case .gpt4Vision:
            // 🔧 详细调试GPT-4 Vision请求体结构
            logProgress(for: sticker, "🔍 开始调试GPT-4 Vision请求体结构...")
            
            if let messages = requestBody["messages"] as? [[String: Any]] {
                logProgress(for: sticker, "✅ 找到messages数组，包含 \(messages.count) 条消息")
                
                for (index, message) in messages.enumerated() {
                    logProgress(for: sticker, "📋 消息 \(index + 1): role = \(message["role"] as? String ?? "unknown")")
                    
                    if let content = message["content"] as? String {
                        // 系统消息
                        logProgress(for: sticker, "📝 系统消息内容: \(content.prefix(100))...")
                    } else if let content = message["content"] as? [[String: Any]] {
                        // 用户消息（包含文本和图像）
                        logProgress(for: sticker, "📋 用户消息包含 \(content.count) 个内容项")
                        
                        for (itemIndex, item) in content.enumerated() {
                            if let type = item["type"] as? String {
                                logProgress(for: sticker, "📋 内容项 \(itemIndex + 1): type = \(type)")
                                
                                if type == "text", let text = item["text"] as? String {
                                    logProgress(for: sticker, "📝 文本内容长度: \(text.count) 字符")
                                    logProgress(for: sticker, "📝 文本内容预览: \(text.prefix(100))...")
                                } else if type == "image_url", let imageUrl = item["image_url"] as? [String: Any] {
                                    if let url = imageUrl["url"] as? String {
                                        if url.hasPrefix("data:") {
                                            let mimeTypeEnd = url.firstIndex(of: ";") ?? url.startIndex
                                            let mimeType = String(url[url.startIndex..<mimeTypeEnd])
                                            logProgress(for: sticker, "📝 ✅ 找到base64图像数据!")
                                            logProgress(for: sticker, "📝 图像MIME类型: \(mimeType)")
                                            logProgress(for: sticker, "📝 base64数据长度: \(url.count) 字符")
                                            logProgress(for: sticker, "📝 base64前缀: \(url.prefix(50))...")
                                        } else {
                                            logProgress(for: sticker, "📝 使用图像URL: \(url)")
                                        }
                                    } else {
                                        logProgress(for: sticker, "❌ image_url中没有找到url字段")
                                    }
                                } else {
                                    logProgress(for: sticker, "❌ 未知的内容类型: \(type)")
                                }
                            } else {
                                logProgress(for: sticker, "❌ 内容项缺少type字段")
                            }
                        }
                    } else {
                        logProgress(for: sticker, "❌ 消息内容格式未知")
                    }
                }
            } else {
                logProgress(for: sticker, "❌ 请求体中没有找到messages字段")
            }
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        logProgress(for: sticker, "📊 JSON请求体大小: \(jsonData.count) 字节")
        
        // 🔧 输出完整的JSON请求体用于调试（仅限GPT-4 Vision）
        if selectedModel == .gpt4Vision {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // 截取前1000字符避免日志过长
                let preview = jsonString.count > 1000 ? String(jsonString.prefix(1000)) + "..." : jsonString
                logProgress(for: sticker, "📋 完整JSON请求体预览: \(preview)")
            }
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        // 准备请求头
        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json; charset=utf-8",
            "Connection": "keep-alive",
            "Keep-Alive": "timeout=600, max=10000"
        ]
        
        // 设置请求头
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // 🔧 流式模式自带心跳，无需额外Keep-Alive机制
        if selectedModel != .gpt4Vision {
            // 只为非流式请求启动Keep-Alive心跳机制
            startKeepAlive(for: apiURL, with: headers)
        }
        
        // 使用专门的长连接策略
        switch selectedModel {
        case .fluxKontext:
            logProgress(for: sticker, "步骤 6/8: 开始Flux-Kontext API调用...")
        case .gpt4Vision:
            logProgress(for: sticker, "步骤 6/8: 开始GPT-4 Vision API调用...")
            logProgress(for: sticker, "⏳ GPT-4 Vision图像生成通常需要1-3分钟，请耐心等待...")
        }
        
        // 检查任务是否已被取消
        if Task.isCancelled {
            stopKeepAlive()
            logProgress(for: sticker, "🚫 API调用前任务已被取消")
            throw CancellationError()
        }
        
        do {
            // 🔧 流式请求策略：使用stream模式避免60秒超时
            let (data, response) = try await performStreamRequest(request: request, for: sticker, model: selectedModel)
            
            // 停止Keep-Alive心跳（如果有的话）
            if selectedModel != .gpt4Vision {
                stopKeepAlive()
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logProgress(for: sticker, "错误: 无效的HTTP响应")
                throw NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])
            }
            
            logProgress(for: sticker, "步骤 6.3/8: 收到HTTP响应，状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                logProgress(for: sticker, "API错误 (\(httpResponse.statusCode)): \(errorMessage)")
                throw NSError(domain: "ImageEnhancementService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API错误: \(errorMessage)"])
            }
            
            await MainActor.run {
                sticker.aiEnhancementProgress = 0.65
                sticker.aiEnhancementMessage = "处理API响应..."
            }
            
            // 🔍 调试信息：记录完整的API响应
            let responseString = String(data: data, encoding: .utf8) ?? "无法解析响应"
            logProgress(for: sticker, "📥 API完整响应: \(responseString)")
            
            // 🚀 解析API响应（根据模型类型）
            let resultImageUrl: URL
            
            switch selectedModel {
            case .fluxKontext:
                // 解析Flux-Kontext API响应
                if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let dataArray = jsonResponse["data"] as? [[String: Any]],
                   let firstResult = dataArray.first,
                   let imageUrlString = firstResult["url"] as? String,
                   let url = URL(string: imageUrlString) {
                    resultImageUrl = url
                    logProgress(for: sticker, "步骤 7/8: 成功获取Flux-Kontext图像URL: \(imageUrlString)")
                } else {
                    logProgress(for: sticker, "❌ 无法解析Flux-Kontext API响应")
                    throw NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法从Flux-Kontext响应中提取图像URL"])
                }
                
            case .gpt4Vision:
                // GPT-4 Vision 直接返回生成的图片
                logProgress(for: sticker, "步骤 7/8: GPT-4 Vision 图片生成完成，提取图片URL...")
                
                if let imageUrl = extractImageUrlFromGPTResponse(from: data) {
                    resultImageUrl = imageUrl
                    logProgress(for: sticker, "✅ 成功获取GPT-4 Vision生成的图片URL: \(imageUrl.absoluteString)")
                } else {
                    // 🔧 检查是否是对话回复，如果是则抛出特定错误
                    if let responseString = String(data: data, encoding: .utf8),
                       let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        let lowerContent = content.lowercased()
                        let conversationKeywords = ["你想要", "你偏好", "请告诉我", "还是", "风格", "指引", "？", "需要", "帮你", "为了", "比如"]
                        let hasConversationIndicators = conversationKeywords.contains { lowerContent.contains($0) }
                        
                        if hasConversationIndicators {
                            logProgress(for: sticker, "❌ API返回了对话回复而非图片生成")
                            throw NSError(domain: "ImageEnhancementService", code: -2001, userInfo: [NSLocalizedDescriptionKey: "API请求了澄清信息而非直接生成图片。请尝试使用更具体的提示词。"])
                        }
                    }
                    
                    logProgress(for: sticker, "❌ 无法从GPT-4 Vision响应中提取图片URL")
                    throw NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法从GPT-4 Vision响应中提取图片URL"])
                }
            }
            
            // 检查任务是否已被取消
            if Task.isCancelled {
                logProgress(for: sticker, "🚫 图像下载前任务已被取消")
                throw CancellationError()
            }
            
            // 下载增强后的图像
            await MainActor.run {
                sticker.aiEnhancementProgress = 0.8
                sticker.aiEnhancementMessage = "下载增强图像..."
            }
            
            let enhancedImageData = try await downloadImage(from: resultImageUrl, for: sticker)
            
            logProgress(for: sticker, "步骤 8/8: 图像下载完成，大小: \(enhancedImageData.count) 字节")
            
            // 更新UI
            await MainActor.run {
                sticker.enhancedImageData = enhancedImageData
                sticker.aiEnhancementStatus = .completed
                sticker.aiEnhancementProgress = 0.95
                
                // 🎯 增强完成后自动切换到显示增强图片
                sticker.isShowingEnhancedImage = true
                
                // 强制触发UI更新
                sticker.aiEnhancementMessage = "正在上传增强图片..."
            }
            
            // 🎯 上传AI增强图片到Supabase
            do {
                let enhancedFileName = "enhanced_\(sticker.id.uuidString)_\(Date().timeIntervalSince1970).png"
                let enhancedURL = try await uploadEnhancedImageToSupabase(enhancedImageData, fileName: enhancedFileName, for: sticker)
                
                await MainActor.run {
                    sticker.enhancedSupabaseImageURL = enhancedURL
                    sticker.aiEnhancementProgress = 1.0
                    sticker.aiEnhancementMessage = "AI增强完成！"
                    self.currentSticker = nil
                }
                
                logProgress(for: sticker, "✅ AI增强图片已上传到Supabase: \(enhancedURL)")
            } catch {
                await MainActor.run {
                    sticker.aiEnhancementProgress = 1.0
                    sticker.aiEnhancementMessage = "AI增强完成！(上传失败: \(error.localizedDescription))"
                    self.currentSticker = nil
                }
                
                logProgress(for: sticker, "⚠️ AI增强图片上传失败: \(error.localizedDescription)")
            }
            
            logProgress(for: sticker, "增强完成成功！图像已保存并更新UI")
            return enhancedImageData
            
        } catch {
            // 确保停止Keep-Alive心跳（如果有的话）
            if selectedModel != .gpt4Vision {
                stopKeepAlive()
            }
            
            logProgress(for: sticker, "网络错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 🔧 压缩图像并确保格式和大小符合要求
    private func compressImage(_ image: UIImage, targetSize: CGSize, for sticker: ToySticker) -> Data? {
        // 调整图像尺寸
        let resizedImage = image.resized(to: targetSize)
        
        // 🔧 直接生成PNG格式，并控制文件大小在200KB以内
        guard let pngData = resizedImage.pngData() else {
            logProgress(for: sticker, "❌ PNG数据生成失败")
            return nil
        }
        
        // 检查PNG数据大小
        if pngData.count <= 200_000 { // 200KB
            logProgress(for: sticker, "✅ PNG压缩完成，大小: \(pngData.count) 字节")
            return pngData
        }
        
        // 如果PNG过大，尝试进一步压缩尺寸
        logProgress(for: sticker, "⚠️ PNG数据过大(\(pngData.count)字节)，进一步压缩尺寸...")
        
        // 计算新的压缩尺寸
        let compressionRatio = sqrt(200_000.0 / Double(pngData.count))
        let newSize = CGSize(
            width: targetSize.width * compressionRatio,
            height: targetSize.height * compressionRatio
        )
        
        let furtherResizedImage = image.resized(to: newSize)
        guard let compressedPngData = furtherResizedImage.pngData() else {
            logProgress(for: sticker, "❌ 进一步PNG压缩失败")
            return pngData // 返回原始PNG数据
        }
        
        logProgress(for: sticker, "✅ PNG进一步压缩完成: \(compressedPngData.count) 字节，尺寸: \(newSize)")
        return compressedPngData
    }
    
    // 🔧 从GPT-4 Vision响应中提取图片URL（根据 gpt.md 文档）
    private func extractImageUrlFromGPTResponse(from data: Data) -> URL? {
        guard let responseString = String(data: data, encoding: .utf8) else { 
            print("❌ 无法将响应数据转换为字符串")
            return nil 
        }
        
        print("📥 GPT-4 Vision 完整响应: \(responseString)")
        
        // 解析JSON响应
        guard let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ 无法解析JSON响应")
            return nil
        }
        
        // 检查是否有错误
        if let error = jsonResponse["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("❌ API返回错误: \(message)")
            return nil
        }
        
        // 检查响应结构
        print("📊 响应结构检查:")
        if let choices = jsonResponse["choices"] as? [[String: Any]] {
            print("✅ 找到 choices 数组，包含 \(choices.count) 个选择")
            
            if let firstChoice = choices.first {
                print("✅ 获取第一个选择")
                
                if let message = firstChoice["message"] as? [String: Any] {
                    print("✅ 找到 message 对象")
                    
                    if let content = message["content"] as? String {
                        print("✅ 成功提取内容，长度: \(content.count) 字符")
                        print("📝 GPT-4 Vision 响应内容: \(content)")
                        
                        // 🔧 检查是否是对话回复而非图片生成
                        let lowerContent = content.lowercased()
                        let conversationKeywords = ["你想要", "你偏好", "请告诉我", "还是", "风格", "指引", "？", "需要", "帮你", "为了", "比如"]
                        let hasConversationIndicators = conversationKeywords.contains { lowerContent.contains($0) }
                        
                        if hasConversationIndicators && !content.contains("filesystem.site") && !content.contains("http") {
                            print("⚠️ 检测到对话回复而非图片生成，内容包含对话关键词")
                            return nil
                        }
                        
                        // 🔧 基于测试结果优化：支持多种图片URL格式
                        // 格式1：![description](https://example.com/image.png)
                        // 格式2：sediment://file_xxx](https://filesystem.site/cdn/...)
                        let patterns = [
                            #"!\[.*?\]\((https?://[^\s\)]+)\)"#,  // 标准markdown格式
                            #"sediment://[^\]]+\]\((https?://[^\s\)]+)"#,  // sediment格式（测试中发现）
                            #"(https?://filesystem\.site/[^\s\)]+\.(?:jpg|jpeg|png|gif|webp))"#,  // filesystem.site 图片URL
                            #"(https?://[^\s\)]*\.(jpg|jpeg|png|gif|webp))"#  // 其他图片文件URL
                        ]
                        
                        // 尝试所有模式
                        for (index, pattern) in patterns.enumerated() {
                            do {
                                let regex = try NSRegularExpression(pattern: pattern, options: [])
                                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                                
                                if let match = regex.firstMatch(in: content, options: [], range: range) {
                                    let captureIndex = pattern.contains("sediment://") || pattern.contains("filesystem\\.site") ? 1 : 1
                                    if let urlRange = Range(match.range(at: captureIndex), in: content) {
                                        let urlString = String(content[urlRange])
                                        print("✅ 使用模式\(index+1)提取到图片URL: \(urlString)")
                                        return URL(string: urlString)
                                    }
                                }
                            } catch {
                                print("❌ 模式\(index+1)正则表达式错误: \(error)")
                            }
                        }
                        
                        print("❌ 所有模式都未找到符合格式的图片URL")
                        print("📝 响应内容: \(content.prefix(500))...")  // 只显示前500字符
        } else {
                        print("❌ message 中没有找到 content 字段")
                        print("📊 message 结构: \(message)")
                    }
                } else {
                    print("❌ choice 中没有找到 message 字段")
                    print("📊 choice 结构: \(firstChoice)")
                }
            } else {
                print("❌ choices 数组为空")
            }
        } else {
            print("❌ 响应中没有找到 choices 字段")
            print("📊 响应顶级字段: \(Array(jsonResponse.keys))")
        }
        
        return nil
    }
    
    // 🔧 下载图像的方法
    private func downloadImage(from url: URL, for sticker: ToySticker) async throws -> Data {
        logProgress(for: sticker, "步骤 7.5/8: 提取到图像URL，开始下载...")
        logProgress(for: sticker, "图像URL: \(url.absoluteString)")
        
        await MainActor.run {
            sticker.aiEnhancementProgress = 0.85
            sticker.aiEnhancementMessage = "连接图像服务器..."
        }
        
        // 下载增强后的图像
        let (enhancedImageData, response) = try await urlSession.data(from: url)
        
        // 检查HTTP响应
        if let httpResponse = response as? HTTPURLResponse {
            logProgress(for: sticker, "下载响应状态码: \(httpResponse.statusCode)")
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                logProgress(for: sticker, "下载内容类型: \(contentType)")
            }
        }
        
        // 检查下载的数据前几个字节（用于调试）
        let prefix = enhancedImageData.prefix(20)
        let hexString = prefix.map { String(format: "%02x", $0) }.joined(separator: " ")
        logProgress(for: sticker, "图像数据前20字节: \(hexString)")
        
        // 检查是否是HTML错误页面
        if let dataString = String(data: enhancedImageData.prefix(200), encoding: .utf8) {
            if dataString.lowercased().contains("<html") || dataString.lowercased().contains("<!doctype") {
                logProgress(for: sticker, "❌ 下载的是HTML页面，不是图像文件")
                logProgress(for: sticker, "HTML内容前200字符: \(dataString)")
                throw NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载的是HTML错误页面，不是图像文件"])
            }
        }
        
        await MainActor.run {
            sticker.aiEnhancementProgress = 0.95
            sticker.aiEnhancementMessage = "验证图像数据..."
        }
        
        // 验证下载的图像数据是否有效
        if let testImage = UIImage(data: enhancedImageData) {
            logProgress(for: sticker, "✅ 增强图像数据验证成功，尺寸: \(testImage.size)")
            logProgress(for: sticker, "📊 图像文件大小: \(enhancedImageData.count) 字节")
        } else {
            logProgress(for: sticker, "❌ 增强图像数据验证失败，数据可能损坏")
            throw NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载的图像数据无效"])
        }
        
        // 更新UI
        await MainActor.run {
            sticker.enhancedImageData = enhancedImageData
            sticker.aiEnhancementStatus = .completed
            sticker.aiEnhancementProgress = 1.0
            
            // 🎯 增强完成后自动切换到显示增强图片
            sticker.isShowingEnhancedImage = true
            
            self.currentSticker = nil
            
            // 强制触发UI更新
            sticker.aiEnhancementMessage = "AI增强完成！"
        }
        
        logProgress(for: sticker, "增强完成成功！图像已保存并更新UI")
        return enhancedImageData
    }
    
    // 取消当前的增强任务
    func cancelCurrentEnhancement() {
        currentTask?.cancel()
        currentTask = nil
        stopKeepAlive() // 停止心跳
        
        if let sticker = currentSticker {
            logProgress(for: sticker, "用户取消了增强任务")
            Task { @MainActor in
                sticker.aiEnhancementStatus = .failed
                sticker.aiEnhancementMessage = "用户取消了增强任务"
                self.currentSticker = nil
            }
        }
    }
    
    // 🚀 获取图像URL（优先使用预上传的URL）
    private func uploadImageToFreeHost(_ imageData: Data, for sticker: ToySticker) async throws -> String {
        // 🎯 优先使用预上传的URL
        if let storedURL = sticker.supabaseImageURL, !storedURL.isEmpty {
            // 检查是否是本地文件URL
            if storedURL.hasPrefix("file://") {
                logProgress(for: sticker, "✅ 使用预存储的本地文件")
                logProgress(for: sticker, "📝 本地文件路径: \(storedURL)")
                
                // 从本地文件读取数据并上传
                do {
                    let fileURL = URL(string: storedURL)!
                    let localImageData = try Data(contentsOf: fileURL)
                    logProgress(for: sticker, "📦 从本地文件读取数据: \(localImageData.count) 字节")
                    
                    // 尝试上传到Supabase
                    if let supabaseURL = APIConfig.supabaseURL,
                       let supabaseKey = APIConfig.supabaseServiceRoleKey,
                       !supabaseURL.isEmpty && !supabaseKey.isEmpty,
                       !supabaseURL.contains("your_supabase_project_url_here"),
                       !supabaseKey.contains("your_supabase_service_role_key_here") {
                        
                        do {
                            let uploadedURL = try await uploadToSupabase(localImageData, for: sticker)
                            logProgress(for: sticker, "✅ 本地文件已上传到Supabase: \(uploadedURL)")
                            
                            // 更新为Supabase URL
                            await MainActor.run {
                                sticker.supabaseImageURL = uploadedURL
                            }
                            
                            return uploadedURL
                        } catch {
                            logProgress(for: sticker, "⚠️ 本地文件上传到Supabase失败，使用本地数据: \(error.localizedDescription)")
                            // 继续使用本地数据进行base64编码
                        }
                    }
                    
                    // 如果Supabase不可用，使用base64编码本地数据
                    let base64String = localImageData.base64EncodedString()
                    let dataURL = "data:image/png;base64,\(base64String)"
                    logProgress(for: sticker, "📝 使用本地文件的base64编码 (大小: \(base64String.count) 字符)")
                    return dataURL
                    
                } catch {
                    logProgress(for: sticker, "❌ 读取本地文件失败: \(error.localizedDescription)")
                    // 继续到下面的实时上传逻辑
                }
            } else {
                // 是Supabase URL或其他网络URL
                logProgress(for: sticker, "✅ 使用预上传的网络URL")
                logProgress(for: sticker, "📝 预上传URL: \(storedURL)")
                return storedURL
            }
        }
        
        // 如果没有预上传URL，尝试实时上传
        logProgress(for: sticker, "⚠️ 未找到预上传URL，尝试实时上传...")
        
        // 优先使用Supabase存储
        if let supabaseURL = APIConfig.supabaseURL,
           let supabaseKey = APIConfig.supabaseServiceRoleKey,
           !supabaseURL.isEmpty && !supabaseKey.isEmpty {
            
            do {
                let uploadedURL = try await uploadToSupabase(imageData, for: sticker)
                
                // 保存URL到贴纸以供下次使用
                await MainActor.run {
                    sticker.supabaseImageURL = uploadedURL
                }
                
                return uploadedURL
            } catch {
                logProgress(for: sticker, "❌ Supabase实时上传失败: \(error.localizedDescription)")
            }
        }
        
        // 备用方案：使用示例URL
        logProgress(for: sticker, "⚠️ 图像上传失败，使用备用方案")
        logProgress(for: sticker, "📌 使用示例图像URL，请配置您自己的图床服务")
        return "https://tuziai.oss-cn-shenzhen.aliyuncs.com/style/default_style_small.png"
    }
    
    // 🚀 上传图像到Supabase存储
    private func uploadToSupabase(_ imageData: Data, for sticker: ToySticker) async throws -> String {
        guard let supabaseURL = APIConfig.supabaseURL,
              let supabaseKey = APIConfig.supabaseServiceRoleKey else {
            logProgress(for: sticker, "❌ Supabase配置缺失")
            logProgress(for: sticker, "📝 SUPABASE_URL: \(APIConfig.supabaseURL ?? "未设置")")
            logProgress(for: sticker, "📝 SUPABASE_SERVICE_ROLE_KEY: \(APIConfig.supabaseServiceRoleKey?.prefix(20) ?? "未设置")...")
            throw NSError(domain: "SupabaseUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase配置缺失"])
        }
        
        let bucket = APIConfig.supabaseStorageBucket
        let fileName = "sticker_\(sticker.id.uuidString)_\(Date().timeIntervalSince1970).png"
        let uploadURL = URL(string: "\(supabaseURL)/storage/v1/object/\(bucket)/\(fileName)")!
        
        logProgress(for: sticker, "🔄 开始上传图像到Supabase")
        logProgress(for: sticker, "📝 存储桶: \(bucket)")
        logProgress(for: sticker, "📝 文件名: \(fileName)")
        logProgress(for: sticker, "📝 上传URL: \(uploadURL.absoluteString)")
        logProgress(for: sticker, "📝 图像数据大小: \(imageData.count) 字节")
        
        var request = URLRequest(url: uploadURL)
    request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.httpBody = imageData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logProgress(for: sticker, "❌ 无效的HTTP响应")
                throw NSError(domain: "SupabaseUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])
            }
            
            logProgress(for: sticker, "📥 Supabase响应状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // 构建公开访问URL
                let publicURL = "\(supabaseURL)/storage/v1/object/public/\(bucket)/\(fileName)"
                logProgress(for: sticker, "✅ 图像上传成功: \(publicURL)")
                return publicURL
    } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                logProgress(for: sticker, "❌ Supabase上传失败 (\(httpResponse.statusCode)): \(errorMessage)")
                
                // 提供具体的错误建议
                if httpResponse.statusCode == 404 {
                    logProgress(for: sticker, "💡 建议：请检查存储桶 '\(bucket)' 是否存在")
                } else if httpResponse.statusCode == 403 {
                    logProgress(for: sticker, "💡 建议：请检查API密钥权限和存储桶访问策略")
                } else if httpResponse.statusCode == 401 {
                    logProgress(for: sticker, "💡 建议：请检查SUPABASE_SERVICE_ROLE_KEY是否正确")
                }
                
                throw NSError(domain: "SupabaseUpload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "上传失败: \(errorMessage)"])
            }
        } catch {
            logProgress(for: sticker, "❌ Supabase上传网络错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 🎯 上传AI增强图像到Supabase存储
    private func uploadEnhancedImageToSupabase(_ imageData: Data, fileName: String, for sticker: ToySticker) async throws -> String {
        guard let supabaseURL = APIConfig.supabaseURL,
              let supabaseKey = APIConfig.supabaseServiceRoleKey else {
            logProgress(for: sticker, "❌ Supabase配置缺失")
            throw NSError(domain: "SupabaseUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Supabase配置缺失"])
        }
        
        let bucket = APIConfig.supabaseStorageBucket
        let uploadURL = URL(string: "\(supabaseURL)/storage/v1/object/\(bucket)/\(fileName)")!
        
        logProgress(for: sticker, "🔄 开始上传AI增强图片到Supabase")
        logProgress(for: sticker, "📝 文件名: \(fileName)")
        logProgress(for: sticker, "📝 图像数据大小: \(imageData.count) 字节")
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.httpBody = imageData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logProgress(for: sticker, "❌ 无效的HTTP响应")
                throw NSError(domain: "SupabaseUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])
            }
            
            logProgress(for: sticker, "📥 Supabase响应状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // 构建公开访问URL
                let publicURL = "\(supabaseURL)/storage/v1/object/public/\(bucket)/\(fileName)"
                logProgress(for: sticker, "✅ AI增强图片上传成功: \(publicURL)")
                return publicURL
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                logProgress(for: sticker, "❌ AI增强图片上传失败 (\(httpResponse.statusCode)): \(errorMessage)")
                throw NSError(domain: "SupabaseUpload", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "上传失败: \(errorMessage)"])
            }
        } catch {
            logProgress(for: sticker, "❌ AI增强图片上传网络错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 取消增强功能
    private var currentTask: Task<Data?, Never>?
    
    // 🔍 检测图片格式
    private func detectImageFormat(from data: Data) -> String {
        guard data.count >= 8 else { return "unknown" }
        
        // PNG格式检测：前8字节为 89 50 4E 47 0D 0A 1A 0A
        if data.count >= 8 {
            let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
            let dataHeader = Array(data.prefix(8))
            if dataHeader == pngHeader {
                return "png"
            }
        }
        
        // JPEG格式检测：前2字节为 FF D8
        if data.count >= 2 {
            let jpegHeader: [UInt8] = [0xFF, 0xD8]
            let dataHeader = Array(data.prefix(2))
            if dataHeader == jpegHeader {
                return "jpeg"
            }
        }
        
        // WebP格式检测：前4字节为 RIFF，第8-11字节为 WEBP
        if data.count >= 12 {
            let riffHeader = Array(data.prefix(4))
            let webpHeader = Array(data[8..<12])
            if riffHeader == [0x52, 0x49, 0x46, 0x46] && // RIFF
               webpHeader == [0x57, 0x45, 0x42, 0x50] {  // WEBP
                return "webp"
            }
        }
        
        // GIF格式检测：前6字节为 GIF87a 或 GIF89a
        if data.count >= 6 {
            let gif87Header: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x37, 0x61] // GIF87a
            let gif89Header: [UInt8] = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61] // GIF89a
            let dataHeader = Array(data.prefix(6))
            if dataHeader == gif87Header || dataHeader == gif89Header {
                return "gif"
            }
        }
        
        // 默认返回jpeg（最常见的格式）
        return "jpeg"
    }
    
    // 🚫 取消当前增强任务
    func cancelEnhancement(for sticker: ToySticker) {
        logProgress(for: sticker, "🚫 用户取消了AI增强任务")
        
        // 取消当前任务
        currentTask?.cancel()
        currentTask = nil
        
        // 重置状态
        DispatchQueue.main.async {
            sticker.aiEnhancementStatus = .pending
            sticker.aiEnhancementProgress = 0.0
            self.currentSticker = nil
        }
    }
    
    // 🚀 增强图像（更新版本，支持取消）
    
    // 🔧 流式请求处理 - 支持GPT chat模式的长连接
    private func performStreamRequest(request: URLRequest, for sticker: ToySticker, model: AIModel) async throws -> (Data, URLResponse) {
        // 对于非GPT模型，仍使用原有的重试机制
        if model != .gpt4Vision {
            return try await performRequestWithRetries(request: request, for: sticker, model: model)
        }
        
        // GPT-4 Vision 使用流式处理
        logProgress(for: sticker, "🔄 启动GPT-4 Vision流式请求...")
        
        // 🔧 添加请求调试信息
        logProgress(for: sticker, "📋 请求URL: \(request.url?.absoluteString ?? "未知")")
        logProgress(for: sticker, "📋 请求方法: \(request.httpMethod ?? "未知")")
        if let headers = request.allHTTPHeaderFields {
            logProgress(for: sticker, "📋 请求头: \(headers)")
        }
        if let bodyData = request.httpBody {
            logProgress(for: sticker, "📋 请求体大小: \(bodyData.count) 字节")
        }
        
        let customConfig = URLSessionConfiguration.default
        customConfig.timeoutIntervalForRequest = 300.0  // 5分钟超时
        customConfig.timeoutIntervalForResource = 900.0 // 15分钟资源超时
        customConfig.waitsForConnectivity = true
        customConfig.allowsCellularAccess = true
        customConfig.allowsExpensiveNetworkAccess = true
        
        let customSession = URLSession(configuration: customConfig)
        
        // 🔧 真正的流式处理：逐步接收数据
        var accumulatedData = Data()
        var finalResponse: URLResponse?
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false  // 🔧 防止重复resume
            
            let task = customSession.dataTask(with: request) { data, response, error in
                // 🔧 确保只resume一次
                guard !hasResumed else { 
                    self.logProgress(for: sticker, "⚠️ 重复调用dataTask completion handler，忽略")
                    return 
                }
                
                if let error = error {
                    hasResumed = true
                    self.logProgress(for: sticker, "❌ 流式请求错误: \(error.localizedDescription)")
                    
                    // 🔧 详细错误信息
                    if let urlError = error as? URLError {
                        self.logProgress(for: sticker, "❌ URLError代码: \(urlError.code.rawValue)")
                        self.logProgress(for: sticker, "❌ URLError描述: \(urlError.localizedDescription)")
                        if let failingURL = urlError.failingURL {
                            self.logProgress(for: sticker, "❌ 失败URL: \(failingURL.absoluteString)")
                        }
                    }
                    
                    continuation.resume(throwing: error)
                    return
                }
                
                if let response = response {
                    finalResponse = response
                    if let httpResponse = response as? HTTPURLResponse {
                        self.logProgress(for: sticker, "📡 流式响应状态码: \(httpResponse.statusCode)")
                    }
                }
                
                if let data = data {
                    accumulatedData.append(data)
                    self.logProgress(for: sticker, "📥 接收流式数据: \(data.count) 字节，累计: \(accumulatedData.count) 字节")
                    
                    // 检查是否收到完整响应
                    if let responseString = String(data: accumulatedData, encoding: .utf8),
                       responseString.contains("data: [DONE]") {
                        hasResumed = true
                        self.logProgress(for: sticker, "✅ 流式响应完成，开始处理数据...")
                        let processedData = self.processStreamResponse(accumulatedData, for: sticker)
                        continuation.resume(returning: (processedData, finalResponse!))
                        return
                    }
                    
                    // 🔧 检查是否是非流式响应（普通JSON响应）
                    if let responseString = String(data: accumulatedData, encoding: .utf8),
                       !responseString.hasPrefix("data: ") && responseString.contains("\"choices\"") {
                        hasResumed = true
                        self.logProgress(for: sticker, "✅ 检测到非流式响应，直接处理...")
                        continuation.resume(returning: (accumulatedData, finalResponse!))
                        return
                    }
                } else {
                    // 🔧 如果没有更多数据，说明响应完成
                    hasResumed = true
                    self.logProgress(for: sticker, "✅ 响应接收完成，处理累积数据...")
                    let processedData = self.processStreamResponse(accumulatedData, for: sticker)
                    continuation.resume(returning: (processedData, finalResponse ?? URLResponse()))
                }
            }
            
            // 🔧 添加超时保护，防止无限等待
            DispatchQueue.global().asyncAfter(deadline: .now() + 300) { // 5分钟超时
                guard !hasResumed else { return }
                hasResumed = true
                self.logProgress(for: sticker, "⏰ 流式请求超时，处理已接收的数据...")
                let processedData = self.processStreamResponse(accumulatedData, for: sticker)
                continuation.resume(returning: (processedData, finalResponse ?? URLResponse()))
            }
            
            // 🔧 添加任务状态检测
            self.logProgress(for: sticker, "🔄 准备启动dataTask...")
            task.resume()
            self.logProgress(for: sticker, "🚀 流式请求已启动，任务状态: \(task.state.rawValue)")
            
            // 🔧 添加短暂延迟后的状态检查
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                self.logProgress(for: sticker, "📊 2秒后任务状态: \(task.state.rawValue)")
                if task.state == .suspended {
                    self.logProgress(for: sticker, "⚠️ 任务仍处于暂停状态，可能存在问题")
                }
            }
        }
    }
    
    // 🔧 处理流式响应数据
    private func processStreamResponse(_ data: Data, for sticker: ToySticker) -> Data {
        guard let responseString = String(data: data, encoding: .utf8) else {
            logProgress(for: sticker, "❌ 无法解析流式响应数据")
            return data
        }
        
        logProgress(for: sticker, "📥 收到流式响应数据: \(data.count) 字节")
        
        // 流式响应格式：每行一个JSON对象，以"data: "开头
        let lines = responseString.components(separatedBy: .newlines)
        var finalContent = ""
        var isComplete = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 检查是否是数据行
            if trimmedLine.hasPrefix("data: ") {
                let jsonString = String(trimmedLine.dropFirst(6)) // 移除"data: "前缀
                
                // 检查是否是结束标记
                if jsonString == "[DONE]" {
                    isComplete = true
                    logProgress(for: sticker, "✅ 流式响应完成")
                    break
                }
                
                // 解析JSON数据
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    
                    finalContent += content
                    logProgress(for: sticker, "📝 累积内容长度: \(finalContent.count) 字符")
                }
            }
        }
        
        if isComplete && !finalContent.isEmpty {
            // 构建完整的响应JSON
            let completeResponse: [String: Any] = [
                "id": "stream-\(Int(Date().timeIntervalSince1970))",
                "object": "chat.completion",
                "created": Int(Date().timeIntervalSince1970),
                "model": "gpt-4o-all",
                "choices": [
                    [
                        "index": 0,
                        "message": [
                            "role": "assistant",
                            "content": finalContent
                        ],
                        "finish_reason": "stop"
                    ]
                ]
            ]
            
            if let completeData = try? JSONSerialization.data(withJSONObject: completeResponse) {
                logProgress(for: sticker, "✅ 流式响应处理完成，最终内容长度: \(finalContent.count) 字符")
                return completeData
            }
        }
        
        // 如果处理失败，返回原始数据
        return data
    }
    
    // 🔧 激进的分段请求策略 - 突破60秒限制（用于非流式请求）
    private func performRequestWithRetries(request: URLRequest, for sticker: ToySticker, model: AIModel) async throws -> (Data, URLResponse) {
        let maxRetries = 3  // 🔧 改回3次重试
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                logProgress(for: sticker, "🔄 网络请求尝试 \(attempt)/\(maxRetries)")
                
                // 🔧 策略1：使用自定义超时的URLSession（针对GPT-4 Vision优化）
                let customConfig = URLSessionConfiguration.default
                customConfig.timeoutIntervalForRequest = 180.0  // 3分钟（基于测试结果优化）
                customConfig.timeoutIntervalForResource = 900.0 // 15分钟
                customConfig.waitsForConnectivity = true
                customConfig.allowsCellularAccess = true
                customConfig.allowsExpensiveNetworkAccess = true
                
                let customSession = URLSession(configuration: customConfig)
                
                // 🔧 策略2：分段发送 - 先发送小请求测试连接
                if attempt == 1 {
                    try await testConnection(to: request.url!, for: sticker)
                }
                
                // 🔧 策略3：使用Task.withTimeout包装请求（基于测试结果优化）
                let timeoutSeconds: TimeInterval = model == .gpt4Vision ? 240.0 : 180.0 // GPT-4 Vision需要更长时间
                let result = try await withTimeout(seconds: timeoutSeconds) {
                    try await customSession.data(for: request)
                }
                
                logProgress(for: sticker, "✅ 网络请求成功，尝试次数: \(attempt)")
                return result
                
        } catch {
                lastError = error
                logProgress(for: sticker, "❌ 网络请求失败 (尝试 \(attempt)/\(maxRetries)): \(error.localizedDescription)")
                
                // 如果是网络连接丢失，等待更长时间再重试
                if let urlError = error as? URLError, urlError.code == .networkConnectionLost {
                    let waitTime = Double(attempt * 5) // 5秒, 10秒, 15秒...
                    logProgress(for: sticker, "⏳ 网络连接丢失，等待 \(waitTime) 秒后重试...")
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                } else if attempt < maxRetries {
                    // 其他错误，短暂等待
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
                }
            }
        }
        
        throw lastError ?? NSError(domain: "ImageEnhancementService", code: -1, userInfo: [NSLocalizedDescriptionKey: "所有网络重试均失败"])
    }
    
    // 🔧 测试网络连接
    private func testConnection(to url: URL, for sticker: ToySticker) async throws {
        logProgress(for: sticker, "🔍 测试网络连接...")
        
        var testRequest = URLRequest(url: url)
        testRequest.httpMethod = "HEAD"
        testRequest.timeoutInterval = 30.0
        testRequest.setValue("Bearer \(APIConfig.tuziAPIKey ?? "")", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await urlSession.data(for: testRequest)
        
        if let httpResponse = response as? HTTPURLResponse {
            logProgress(for: sticker, "✅ 网络连接测试成功，状态码: \(httpResponse.statusCode)")
        }
    }
    
    // 🔧 自定义超时包装器
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            // 添加主要操作
            group.addTask {
                try await operation()
            }
            
            // 添加超时任务
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "ImageEnhancementService", code: -1001, userInfo: [NSLocalizedDescriptionKey: "请求超时"])
            }
            
            // 返回第一个完成的任务结果
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - 比例检测和提示词构建辅助方法
    
    /// 检测原图的宽高比
    private func detectOriginalImageAspectRatio(from sticker: ToySticker) -> String {
        guard let image = sticker.processedImage else { 
            logProgress(for: sticker, "⚠️ 无法获取原图，默认使用1:1比例")
            return "1:1" 
        }
        
        let width = image.size.width
        let height = image.size.height
        let ratio = width / height
        
        logProgress(for: sticker, "📐 原图尺寸: \(width) x \(height), 比例: \(ratio)")
        
        // 根据比例判断最接近的标准比例
        if abs(ratio - 1.0) < 0.1 { return "1:1" }
        if abs(ratio - 16.0/9.0) < 0.1 { return "16:9" }
        if abs(ratio - 9.0/16.0) < 0.1 { return "9:16" }
        if abs(ratio - 4.0/3.0) < 0.1 { return "4:3" }
        if abs(ratio - 3.0/4.0) < 0.1 { return "3:4" }
        if abs(ratio - 21.0/9.0) < 0.1 { return "21:9" }
        if abs(ratio - 9.0/21.0) < 0.1 { return "9:21" }
        if abs(ratio - 3.0/2.0) < 0.1 { return "3:2" }
        if abs(ratio - 2.0/3.0) < 0.1 { return "2:3" }
        
        // 默认返回1:1
        logProgress(for: sticker, "📐 未匹配到标准比例，默认使用1:1")
        return "1:1"
    }
    
    /// 构建比例调整提示词
    private func buildAspectRatioPrompt(original: String, target: String) -> String {
        if original == target {
            return "" // 比例相同，不需要额外提示
        }
        
        let aspectRatioInstructions: [String: String] = [
            "1:1": "正方形比例",
            "16:9": "宽屏横向比例",
            "9:16": "竖屏手机比例", 
            "4:3": "标准横向比例",
            "3:4": "标准竖向比例",
            "21:9": "超宽屏比例",
            "9:21": "超长竖屏比例",
            "3:2": "经典横向比例",
            "2:3": "经典竖向比例"
        ]
        
        let targetDescription = aspectRatioInstructions[target] ?? target
        return " 请将图像调整为\(targetDescription)(\(target))，确保内容完整且构图合理。重要：必须严格按照\(target)的宽高比例生成图像。"
    }
    
    // 🔧 将aspect_ratio转换为具体的size字符串
    private func aspectRatioToSize(_ aspectRatio: String) -> String {
        switch aspectRatio {
        case "1:1":
            return "1024x1024"
        case "16:9":
            return "1024x576"
        case "9:16":
            return "576x1024"
        case "4:3":
            return "1024x768"
        case "3:4":
            return "768x1024"
        case "21:9":
            return "1024x439"
        case "9:21":
            return "439x1024"
        default:
            return "1024x1024"
        }
    }
    
    // 🔧 检测原图比例
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
