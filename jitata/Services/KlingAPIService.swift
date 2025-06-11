import Foundation
import UIKit

/// 可灵API服务类 - 用于处理图片到视频的转换
class KlingAPIService {
    static let shared = KlingAPIService()
    
    private let baseURL = "https://api.tu-zi.com/kling/v1"
    private var apiToken: String? {
        return KlingConfig.getAPIToken()
    }
    
    private init() {}
    
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
    
    /// API响应
    struct Image2VideoResponse: Codable {
        let taskId: String?
        let error: String?
        
        enum CodingKeys: String, CodingKey {
            case taskId = "task_id"
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
    
    /// 图片生成视频
    /// - Parameters:
    ///   - imageURL: 输入图片的URL
    ///   - prompt: 视频内容的描述性提示词
    ///   - aspectRatio: 视频宽高比 (例如 "16:9", "1:1")
    ///   - completion: 完成回调，返回任务ID或错误
    func generateVideoFromImage(
        imageURL: String,
        prompt: String,
        aspectRatio: String = "1:1",
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiToken = apiToken, !apiToken.isEmpty else {
            completion(.failure(KlingAPIError.missingAPIToken))
            return
        }
        
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
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(KlingAPIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(Image2VideoResponse.self, from: data)
                
                if let taskId = response.taskId {
                    completion(.success(taskId))
                } else if let error = response.error {
                    completion(.failure(KlingAPIError.apiError(error)))
                } else {
                    completion(.failure(KlingAPIError.unexpectedResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
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
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(KlingAPIError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TaskStatusResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
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
                    case "completed", "success":
                        if let videoUrl = response.videoUrl {
                            completion(.success(videoUrl))
                        } else {
                            completion(.failure(KlingAPIError.noVideoURL))
                        }
                    case "failed", "error":
                        let error = response.error ?? "视频生成失败"
                        completion(.failure(KlingAPIError.apiError(error)))
                    case "processing", "pending":
                        retryCount += 1
                        if retryCount >= maxRetries {
                            completion(.failure(KlingAPIError.timeout))
                        } else {
                            DispatchQueue.global().asyncAfter(deadline: .now() + interval) {
                                checkStatus()
                            }
                        }
                    default:
                        completion(.failure(KlingAPIError.unexpectedResponse))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        checkStatus()
    }
}

// MARK: - 错误定义

enum KlingAPIError: LocalizedError {
    case missingAPIToken
    case invalidURL
    case noData
    case noVideoURL
    case timeout
    case apiError(String)
    case unexpectedResponse
    
    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "缺少API Token"
        case .invalidURL:
            return "无效的URL"
        case .noData:
            return "没有接收到数据"
        case .noVideoURL:
            return "响应中没有视频URL"
        case .timeout:
            return "视频生成超时"
        case .apiError(let message):
            return "API错误: \(message)"
        case .unexpectedResponse:
            return "意外的响应格式"
        }
    }
} 