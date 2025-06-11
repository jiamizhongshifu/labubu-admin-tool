import Foundation
import UIKit

/// 可灵API服务类 - 用于处理图片到视频的转换
class KlingAPIService: NSObject {
    static let shared = KlingAPIService()
    
    private let baseURL = "https://api.tu-zi.com/kling/v1"
    private var apiToken: String? {
        return KlingConfig.getAPIToken()
    }
    
    // 存储待处理的请求回调
    private var pendingCompletions: [String: (Result<String, Error>) -> Void] = [:]
    private var pendingStatusCompletions: [String: (Result<TaskStatusResponse, Error>) -> Void] = [:]
    private var pendingData: [String: Data] = [:]
    private let completionQueue = DispatchQueue(label: "com.jitata.kling.completion", attributes: .concurrent)
    
    // 🔧 后台URLSession配置 - 支持应用切换到后台时继续处理
    private lazy var backgroundSession: URLSession = {
        let config = createBackgroundSessionConfiguration()
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    override init() {
        super.init()
    }
    
    // MARK: - 数据模型
    
    /// 图生视频请求参数
    struct Image2VideoRequest: Codable {
        let modelName: String
        let mode: String
        let duration: Int
        let image: String
        let prompt: String
        let cfgScale: Double
        let aspectRatio: String
        let negativePrompt: String
        let staticMask: String?
        let dynamicMasks: [DynamicMask]?
        
        enum CodingKeys: String, CodingKey {
            case modelName = "model_name"
            case mode
            case duration
            case image
            case prompt
            case cfgScale = "cfg_scale"
            case aspectRatio = "aspect_ratio"
            case negativePrompt = "negative_prompt"
            case staticMask = "static_mask"
            case dynamicMasks = "dynamic_masks"
        }
    }
    
    /// 动态蒙版
    struct DynamicMask: Codable {
        let mask: String
        let trajectories: [Trajectory]
    }
    
    /// 轨迹点
    struct Trajectory: Codable {
        let x: Int
        let y: Int
    }
    
    /// API响应包装结构
    struct APIResponse<T: Codable>: Codable {
        let code: Int
        let message: String
        let requestId: String
        let data: T?
        
        enum CodingKeys: String, CodingKey {
            case code
            case message
            case requestId = "request_id"
            case data
        }
    }
    
    /// 图片生成视频响应数据
    struct Image2VideoData: Codable {
        let taskId: String
        let taskStatus: String
        let createdAt: Int64
        let updatedAt: Int64
        
        enum CodingKeys: String, CodingKey {
            case taskId = "task_id"
            case taskStatus = "task_status"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }
    
    /// API响应
    struct Image2VideoResponse: Codable {
        let taskId: String?
        let error: String?
        
        enum CodingKeys: String, CodingKey {
            case taskId = "task_id"
            case error
        }
    }
    
    /// 视频信息
    struct VideoInfo: Codable {
        let id: String
        let url: String
        let duration: String
    }
    
    /// 任务结果
    struct TaskResult: Codable {
        let videos: [VideoInfo]?
    }
    
    /// 任务状态响应数据
    struct TaskStatusData: Codable {
        let taskId: String
        let taskStatus: String
        let createdAt: Int64
        let updatedAt: Int64
        let taskResult: TaskResult?
        let error: String?
        
        // 计算属性：从task_result中提取第一个视频的URL
        var videoUrl: String? {
            return taskResult?.videos?.first?.url
        }
        
        enum CodingKeys: String, CodingKey {
            case taskId = "task_id"
            case taskStatus = "task_status"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case taskResult = "task_result"
            case error
        }
    }
    
    /// 任务状态响应
    struct TaskStatusResponse: Codable {
        let status: String
        let videoUrl: String?
        let error: String?
        
        enum CodingKeys: String, CodingKey {
            case status
            case videoUrl = "video_url"
            case error
        }
    }
    
    // MARK: - API方法
    
    /// 图片生成视频（完整流程）
    /// - Parameters:
    ///   - imageURL: 输入图片的URL
    ///   - prompt: 视频内容的描述性提示词
    ///   - aspectRatio: 视频宽高比 (例如 "16:9", "1:1")
    ///   - completion: 完成回调，返回视频URL或错误
    func generateVideoFromImage(
        imageURL: String,
        prompt: String,
        aspectRatio: String = KlingConfig.defaultAspectRatio,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 第一步：创建视频生成任务
        createVideoTask(imageURL: imageURL, prompt: prompt, aspectRatio: aspectRatio) { result in
            switch result {
            case .success(let taskId):
                print("✅ 视频任务创建成功，任务ID: \(taskId)")
                // 第二步：轮询任务状态直到完成
                self.pollTaskUntilComplete(taskId: taskId, completion: completion)
            case .failure(let error):
                print("❌ 视频任务创建失败: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// 创建视频生成任务
    /// - Parameters:
    ///   - imageURL: 输入图片的URL
    ///   - prompt: 视频内容的描述性提示词
    ///   - aspectRatio: 视频宽高比
    ///   - completion: 完成回调，返回任务ID或错误
    private func createVideoTask(
        imageURL: String,
        prompt: String,
        aspectRatio: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiToken = apiToken, !apiToken.isEmpty else {
            completion(.failure(KlingAPIError.missingAPIToken))
            return
        }
        
        print("🎬 开始生成视频 - 图片URL: \(imageURL)")
        print("🎬 提示词: \(prompt)")
        print("🎬 宽高比: \(aspectRatio)")
        
        let request = Image2VideoRequest(
            modelName: KlingConfig.defaultModelName,
            mode: KlingConfig.defaultMode,
            duration: KlingConfig.defaultDuration,
            image: imageURL,
            prompt: prompt,
            cfgScale: KlingConfig.defaultCFGScale,
            aspectRatio: aspectRatio,
            negativePrompt: KlingConfig.defaultNegativePrompt,
            staticMask: nil,
            dynamicMasks: nil
        )
        
        guard let url = URL(string: "\(baseURL)/videos/image2video") else {
            completion(.failure(KlingAPIError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let requestData = try encoder.encode(request)
            urlRequest.httpBody = requestData
            
            // 打印请求信息用于调试
            if let requestString = String(data: requestData, encoding: .utf8) {
                print("🎬 API请求体: \(requestString)")
            }
        } catch {
            print("❌ 编码请求失败: \(error)")
            completion(.failure(error))
            return
        }
        
        print("🎬 发送API请求到: \(url)")
        
        // 🔧 使用后台URLSession和delegate模式
        let task = backgroundSession.dataTask(with: urlRequest)
        let taskIdentifier = "\(task.taskIdentifier)"
        
        // 存储completion回调
        completionQueue.async(flags: .barrier) {
            self.pendingCompletions[taskIdentifier] = completion
        }
        
        // 🔧 添加超时保护机制
        DispatchQueue.global().asyncAfter(deadline: .now() + 300) { // 5分钟超时
            self.completionQueue.async(flags: .barrier) {
                if let timeoutCompletion = self.pendingCompletions.removeValue(forKey: taskIdentifier) {
                    print("⏰ 请求超时 - 任务ID: \(taskIdentifier)")
                    task.cancel()
                    DispatchQueue.main.async {
                        timeoutCompletion(.failure(KlingAPIError.timeout))
                    }
                }
            }
        }
        
        task.resume()
        print("🚀 任务已启动 - 任务ID: \(taskIdentifier)")
    }
    
    /// 获取视频生成任务状态
    /// - Parameters:
    ///   - taskId: 任务ID
    ///   - completion: 完成回调，返回任务状态或错误
    func getTaskStatus(
        taskId: String,
        completion: @escaping (Result<TaskStatusResponse, Error>) -> Void
    ) {
        guard let apiToken = apiToken, !apiToken.isEmpty else {
            completion(.failure(KlingAPIError.missingAPIToken))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/videos/image2video/\(taskId)") else {
            completion(.failure(KlingAPIError.invalidURL))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        
        print("🔍 查询任务状态: \(taskId)")
        
        // 🔧 使用后台URLSession和delegate模式
        let task = backgroundSession.dataTask(with: urlRequest)
        let taskIdentifier = "\(task.taskIdentifier)"
        
        // 存储completion回调
        completionQueue.async(flags: .barrier) {
            self.pendingStatusCompletions[taskIdentifier] = completion
        }
        
        // 🔧 添加超时保护机制
        DispatchQueue.global().asyncAfter(deadline: .now() + 120) { // 2分钟超时
            self.completionQueue.async(flags: .barrier) {
                if let timeoutCompletion = self.pendingStatusCompletions.removeValue(forKey: taskIdentifier) {
                    print("⏰ 状态查询超时 - 任务ID: \(taskIdentifier)")
                    task.cancel()
                    DispatchQueue.main.async {
                        timeoutCompletion(.failure(KlingAPIError.timeout))
                    }
                }
            }
        }
        
        task.resume()
        print("🚀 状态查询已启动 - 任务ID: \(taskIdentifier)")
    }
    
    /// 轮询任务状态直到完成
    /// - Parameters:
    ///   - taskId: 任务ID
    ///   - maxRetries: 最大重试次数
    ///   - interval: 轮询间隔（秒）
    ///   - completion: 完成回调，返回视频URL或错误
    func pollTaskUntilComplete(
        taskId: String,
        maxRetries: Int = KlingConfig.maxRetries,
        interval: TimeInterval = KlingConfig.pollingInterval,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var retryCount = 0
        
        func checkStatus() {
            getTaskStatus(taskId: taskId) { [weak self] result in
                switch result {
                case .success(let response):
                    switch response.status.lowercased() {
                    case "completed", "success", "succeed":
                        if let videoUrl = response.videoUrl {
                            print("✅ 视频生成完成: \(videoUrl)")
                            completion(.success(videoUrl))
                        } else {
                            print("❌ 任务完成但没有视频URL")
                            completion(.failure(KlingAPIError.noVideoURL))
                        }
                    case "failed", "error":
                        let error = response.error ?? "视频生成失败"
                        print("❌ 视频生成失败: \(error)")
                        completion(.failure(KlingAPIError.apiError(error)))
                    case "processing", "pending", "submitted":
                        retryCount += 1
                        print("⏳ 视频生成中... (\(retryCount)/\(maxRetries)) - 状态: \(response.status)")
                        if retryCount >= maxRetries {
                            print("❌ 视频生成超时")
                            completion(.failure(KlingAPIError.timeout))
                        } else {
                            DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                                checkStatus()
                            }
                        }
                    default:
                        print("❌ 未知任务状态: \(response.status)")
                        completion(.failure(KlingAPIError.unexpectedResponse))
                    }
                case .failure(let error):
                    retryCount += 1
                    print("❌ 查询任务状态失败 (\(retryCount)/\(maxRetries)): \(error)")
                    if retryCount >= maxRetries {
                        completion(.failure(error))
                    } else {
                        DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                            checkStatus()
                        }
                    }
                }
            }
        }
        
        checkStatus()
    }
    
    /// 取消任务
    /// - Parameter taskId: 要取消的任务ID
    func cancelTask(taskId: String) {
        print("🚫 尝试取消任务: \(taskId)")
        
        // 从回调存储中移除
        completionQueue.async {
            self.pendingCompletions.removeValue(forKey: taskId)
            self.pendingStatusCompletions.removeValue(forKey: taskId)
        }
        
        // 这里可以添加实际的API取消请求，如果Kling API支持的话
        // 目前只是本地清理
    }
    
    /// 创建后台URLSession配置
    private func createBackgroundSessionConfiguration() -> URLSessionConfiguration {
        // 🔧 使用默认配置而不是后台配置，避免SO_NOWAKEFROMSLEEP错误
        let config = URLSessionConfiguration.default
        
        // 基本超时设置
        config.timeoutIntervalForRequest = 180  // 3分钟请求超时
        config.timeoutIntervalForResource = 900 // 15分钟资源超时
        
        // 网络连接设置
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        
        // 优化网络设置
        config.httpMaximumConnectionsPerHost = 6
        config.networkServiceType = .responsiveData
        
        // 缓存策略
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        return config
    }
}

// MARK: - URLSessionDelegate

extension KlingAPIService: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let taskIdentifier = "\(dataTask.taskIdentifier)"
        print("📡 收到响应 - 任务ID: \(taskIdentifier)")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 HTTP状态码: \(httpResponse.statusCode)")
            print("📊 响应头: \(httpResponse.allHeaderFields)")
            print("📊 内容长度: \(httpResponse.expectedContentLength)")
        }
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let taskIdentifier = "\(dataTask.taskIdentifier)"
        print("📥 收到数据 - 任务ID: \(taskIdentifier), 数据大小: \(data.count) bytes")
        
        completionQueue.async(flags: .barrier) {
            if var existingData = self.pendingData[taskIdentifier] {
                existingData.append(data)
                self.pendingData[taskIdentifier] = existingData
                print("📥 累积数据 - 任务ID: \(taskIdentifier), 总大小: \(existingData.count) bytes")
            } else {
                self.pendingData[taskIdentifier] = data
                print("📥 首次数据 - 任务ID: \(taskIdentifier), 大小: \(data.count) bytes")
            }
            
            // 🔧 检查是否收到完整响应（基于Content-Length或JSON完整性）
            if let currentData = self.pendingData[taskIdentifier] {
                self.checkAndProcessCompleteResponse(taskIdentifier: taskIdentifier, data: currentData, task: dataTask)
            }
        }
    }
    
    // 🔧 新增：检查并处理完整响应
    private func checkAndProcessCompleteResponse(taskIdentifier: String, data: Data, task: URLSessionDataTask) {
        // 检查是否是完整的JSON响应
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 当前响应内容: \(responseString)")
            
            // 检查JSON是否完整（简单检查：以}结尾且括号匹配）
            let trimmed = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
                // 尝试解析JSON以确认完整性
                do {
                    _ = try JSONSerialization.jsonObject(with: data, options: [])
                    print("✅ JSON响应完整 - 任务ID: \(taskIdentifier)")
                    
                    // 强制触发完成处理
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.forceCompleteTask(taskIdentifier: taskIdentifier, task: task)
                    }
                } catch {
                    print("⚠️ JSON不完整，继续等待 - 任务ID: \(taskIdentifier)")
                }
            }
        }
    }
    
    // 🔧 新增：强制完成任务处理
    private func forceCompleteTask(taskIdentifier: String, task: URLSessionDataTask) {
        completionQueue.async(flags: .barrier) {
            // 检查是否还有待处理的回调
            if self.pendingCompletions[taskIdentifier] != nil || self.pendingStatusCompletions[taskIdentifier] != nil {
                print("🔄 强制完成任务 - 任务ID: \(taskIdentifier)")
                
                let data = self.pendingData[taskIdentifier]
                
                if let completion = self.pendingCompletions.removeValue(forKey: taskIdentifier) {
                    print("🎬 强制处理视频生成响应 - 任务ID: \(taskIdentifier)")
                    self.handleVideoGenerationResponse(data: data, error: nil, completion: completion)
                } else if let completion = self.pendingStatusCompletions.removeValue(forKey: taskIdentifier) {
                    print("🔍 强制处理状态查询响应 - 任务ID: \(taskIdentifier)")
                    self.handleStatusResponse(data: data, error: nil, completion: completion)
                }
                
                // 清理数据
                self.pendingData.removeValue(forKey: taskIdentifier)
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
        let taskIdentifier = "\(dataTask.taskIdentifier)"
        print("🏁 请求完成 - 任务ID: \(taskIdentifier)")
        
        if let error = error {
            print("❌ 请求错误 - 任务ID: \(taskIdentifier), 错误: \(error)")
        }
        
        if let httpResponse = dataTask.response as? HTTPURLResponse {
            print("📊 最终HTTP状态码: \(httpResponse.statusCode)")
        }
        
        completionQueue.async(flags: .barrier) {
            let data = self.pendingData.removeValue(forKey: taskIdentifier)
            print("📦 处理响应数据 - 任务ID: \(taskIdentifier), 数据大小: \(data?.count ?? 0) bytes")
            
            if let completion = self.pendingCompletions.removeValue(forKey: taskIdentifier) {
                print("🎬 处理视频生成响应 - 任务ID: \(taskIdentifier)")
                // 处理图片生成视频请求
                self.handleVideoGenerationResponse(data: data, error: error, completion: completion)
            } else if let completion = self.pendingStatusCompletions.removeValue(forKey: taskIdentifier) {
                print("🔍 处理状态查询响应 - 任务ID: \(taskIdentifier)")
                // 处理任务状态查询请求
                self.handleStatusResponse(data: data, error: error, completion: completion)
            } else {
                print("⚠️ 未找到对应的回调 - 任务ID: \(taskIdentifier)")
            }
        }
    }
    
    private func handleVideoGenerationResponse(
        data: Data?,
        error: Error?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            if let error = error {
                print("❌ 图片生成视频失败: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ 图片生成视频没有数据")
                completion(.failure(KlingAPIError.noData))
                return
            }
            
            // 打印API响应用于调试
            if let responseString = String(data: data, encoding: .utf8) {
                print("🎬 API响应: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                // 首先尝试解析为包装响应格式
                let apiResponse = try decoder.decode(APIResponse<Image2VideoData>.self, from: data)
                
                if apiResponse.code == 0, let data = apiResponse.data {
                    print("✅ 视频生成任务创建成功，任务ID: \(data.taskId)")
                    completion(.success(data.taskId))
                } else {
                    let errorMessage = apiResponse.message
                    print("❌ API返回错误: \(errorMessage)")
                    completion(.failure(KlingAPIError.apiError(errorMessage)))
                }
            } catch {
                print("❌ 解析响应失败: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    private func handleStatusResponse(
        data: Data?,
        error: Error?,
        completion: @escaping (Result<TaskStatusResponse, Error>) -> Void
    ) {
        DispatchQueue.main.async {
            if let error = error {
                print("❌ 查询任务状态失败: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                print("❌ 查询任务状态没有数据")
                completion(.failure(KlingAPIError.noData))
                return
            }
            
            // 打印状态查询响应
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 任务状态响应: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                // 尝试解析为包装响应格式
                do {
                    let apiResponse = try decoder.decode(APIResponse<TaskStatusData>.self, from: data)
                    if apiResponse.code == 0, let data = apiResponse.data {
                        let response = TaskStatusResponse(
                            status: data.taskStatus,
                            videoUrl: data.videoUrl,
                            error: data.error
                        )
                        print("📊 任务状态: \(response.status)")
                        completion(.success(response))
                    } else {
                        let errorMessage = apiResponse.message
                        print("❌ 查询任务状态API错误: \(errorMessage)")
                        completion(.failure(KlingAPIError.apiError(errorMessage)))
                    }
                } catch {
                    // 如果包装格式解析失败，尝试直接解析
                    let response = try decoder.decode(TaskStatusResponse.self, from: data)
                    print("📊 任务状态: \(response.status)")
                    completion(.success(response))
                }
            } catch {
                print("❌ 解析任务状态失败: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            print("❌ URLSession失效: \(error)")
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        print("✅ 后台URLSession任务完成")
        DispatchQueue.main.async {
            // 通知SwiftUI应用后台任务完成
            NotificationCenter.default.post(name: NSNotification.Name("BackgroundURLSessionCompleted"), object: nil)
        }
    }
}

// MARK: - 错误定义

enum KlingAPIError: Error, LocalizedError {
    case missingAPIToken
    case invalidURL
    case noData
    case apiError(String)
    case timeout
    case unexpectedResponse
    case noVideoURL
    
    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "缺少API令牌"
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有数据"
        case .apiError(let message):
            return "API错误: \(message)"
        case .timeout:
            return "请求超时"
        case .unexpectedResponse:
            return "意外的响应格式"
        case .noVideoURL:
            return "没有视频URL"
        }
    }
} 