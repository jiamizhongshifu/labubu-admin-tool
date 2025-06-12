//
//  LabubuAIRecognitionService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import SwiftUI

/// Labubu AI识别服务 - 方案3: 多模态AI识别
/// 使用TUZI API进行图像分析和特征文案生成，用于替换用户拍照后的自动识别环节
@MainActor
class LabubuAIRecognitionService: ObservableObject {
    
    static let shared = LabubuAIRecognitionService()
    
    // MARK: - 发布的属性
    @Published var isRecognizing = false
    @Published var recognitionProgress: Double = 0.0
    @Published var recognitionStatus = "准备识别"
    @Published var lastRecognitionResult: LabubuAIRecognitionResult?
    @Published var errorMessage: String?
    
    // MARK: - 配置
    private let apiTimeout: TimeInterval = 120.0  // 2分钟超时，适合AI图像处理
    private let maxImageSize: CGFloat = 1024      // 最大图像尺寸
    private let compressionQuality: CGFloat = 0.8  // 图像压缩质量
    
    // MARK: - 数据库服务
    private let databaseService = LabubuSupabaseDatabaseService.shared
    
    private init() {}
    
    // MARK: - 主要识别接口
    
    /// 识别用户拍摄的Labubu图片
    /// - Parameter image: 用户拍摄的图片
    /// - Returns: AI识别结果
    func recognizeUserPhoto(_ image: UIImage) async throws -> LabubuAIRecognitionResult {
        print("🤖 开始AI识别用户拍摄的Labubu...")
        
        isRecognizing = true
        recognitionProgress = 0.0
        recognitionStatus = "准备识别"
        errorMessage = nil
        
        defer {
            isRecognizing = false
        }
        
        do {
            // 第一步：预处理图像 (20%)
            recognitionStatus = "预处理图像..."
            recognitionProgress = 0.2
            let processedImage = try await preprocessImage(image)
            
            // 第二步：调用AI分析 (70%)
            recognitionStatus = "AI分析中..."
            recognitionProgress = 0.7
            let aiAnalysis = try await callTuziVisionAPI(processedImage)
            
            // 第三步：数据库匹配 (90%)
            recognitionStatus = "数据库匹配..."
            recognitionProgress = 0.9
            let matchResults = try await matchWithDatabase(aiAnalysis)
            
            // 第四步：构建结果 (100%)
            recognitionStatus = "识别完成"
            recognitionProgress = 1.0
            
            let result = LabubuAIRecognitionResult(
                originalImage: image,
                aiAnalysis: aiAnalysis,
                matchResults: matchResults,
                processingTime: Date().timeIntervalSince(Date()),
                timestamp: Date()
            )
            
            lastRecognitionResult = result
            
            print("✅ AI识别完成: \(result.bestMatch?.nameCN ?? "未识别")")
            return result
            
        } catch {
            print("❌ AI识别失败: \(error)")
            errorMessage = error.localizedDescription
            recognitionStatus = "识别失败"
            throw error
        }
    }
    
    // MARK: - 私有方法
    
    /// 预处理图像
    private func preprocessImage(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 调整图像尺寸
                let resizedImage = self.resizeImage(image, maxSize: self.maxImageSize)
                
                // 压缩图像
                guard let compressedData = resizedImage.jpegData(compressionQuality: self.compressionQuality),
                      let finalImage = UIImage(data: compressedData) else {
                    continuation.resume(throwing: LabubuAIError.imageProcessingFailed)
                    return
                }
                
                continuation.resume(returning: finalImage)
            }
        }
    }
    
    /// 调整图像尺寸
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)
        
        if ratio >= 1.0 {
            return image
        }
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    /// 调用TUZI Vision API
    private func callTuziVisionAPI(_ image: UIImage) async throws -> LabubuAIAnalysis {
        // 获取API配置
        guard let apiKey = getAPIKey(),
              let baseURL = getAPIBaseURL() else {
            throw LabubuAIError.apiConfigurationMissing
        }
        
        // 转换图像为base64
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw LabubuAIError.imageProcessingFailed
        }
        let base64Image = "data:image/jpeg;base64," + imageData.base64EncodedString()
        
        // 构建请求
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = apiTimeout
        
        let requestBody = [
            "model": "gemini-2.5-flash-all",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": buildLabubuRecognitionPrompt()
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabubuAIError.networkError("无效的响应")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabubuAIError.networkError("API请求失败: \(httpResponse.statusCode)")
        }
        
        // 解析响应
        let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = jsonResponse?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LabubuAIError.invalidResponse
        }
        
        // 解析AI分析结果
        return try parseAIAnalysisResult(content)
    }
    
    /// 构建Labubu识别提示词
    private func buildLabubuRecognitionPrompt() -> String {
        return """
        你是一个专业的Labubu玩具识别专家。请仔细分析这张用户拍摄的图片，判断是否为Labubu玩具，并提供详细的特征描述。

        请按照以下JSON格式返回分析结果：

        {
            "isLabubu": true/false,
            "confidence": 0.0-1.0,
            "detailedDescription": "详细的特征描述文案，包括颜色、形状、材质、图案、风格等特征，这段文案将用于与数据库中的Labubu模型进行智能匹配",
            "visualFeatures": {
                "dominantColors": ["#颜色1", "#颜色2", "#颜色3"],
                "bodyShape": "圆润/细长/方正",
                "headShape": "圆形/三角形/椭圆形",
                "earType": "尖耳/圆耳/垂耳",
                "surfaceTexture": "光滑/磨砂/粗糙/绒毛",
                "patternType": "纯色/渐变/图案/条纹",
                "estimatedSize": "小型/中型/大型"
            },
            "keyFeatures": [
                "特征1",
                "特征2", 
                "特征3"
            ],
            "seriesHints": "可能的系列名称或主题提示",
            "materialAnalysis": "材质分析（如毛绒、塑料、金属等）",
            "styleAnalysis": "风格分析（如可爱、酷炫、复古等）",
            "conditionAssessment": "状态评估（如全新、良好、一般等）",
            "rarityHints": "稀有度提示（如常见、稀有、限定等）"
        }

        重要说明：
        1. 如果图片中不是Labubu玩具，请将isLabubu设为false
        2. detailedDescription字段非常重要，请提供丰富详细的特征描述，这将用于后续的智能匹配
        3. 颜色请使用十六进制格式
        4. 请确保返回的是有效的JSON格式
        5. 特征描述要具体且准确，包含足够的细节用于识别匹配
        """
    }
    
    /// 解析AI分析结果
    private func parseAIAnalysisResult(_ content: String) throws -> LabubuAIAnalysis {
        // 提取JSON内容
        let jsonText: String
        if let jsonMatch = content.range(of: "```json\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
            jsonText = String(content[jsonMatch]).replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let codeMatch = content.range(of: "```\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
            jsonText = String(content[codeMatch]).replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            jsonText = content
        }
        
        // 解析JSON
        guard let data = jsonText.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LabubuAIError.jsonParsingFailed
        }
        
        // 构建分析结果
        let isLabubu = json["isLabubu"] as? Bool ?? false
        let confidence = json["confidence"] as? Double ?? 0.0
        let detailedDescription = json["detailedDescription"] as? String ?? ""
        let keyFeatures = json["keyFeatures"] as? [String] ?? []
        let seriesHints = json["seriesHints"] as? String ?? ""
        let materialAnalysis = json["materialAnalysis"] as? String ?? ""
        let styleAnalysis = json["styleAnalysis"] as? String ?? ""
        let conditionAssessment = json["conditionAssessment"] as? String ?? ""
        let rarityHints = json["rarityHints"] as? String ?? ""
        
        // 解析视觉特征
        var visualFeatures: LabubuVisualFeatures?
        if let featuresDict = json["visualFeatures"] as? [String: Any] {
            visualFeatures = LabubuVisualFeatures(
                dominantColors: featuresDict["dominantColors"] as? [String] ?? [],
                bodyShape: featuresDict["bodyShape"] as? String ?? "",
                headShape: featuresDict["headShape"] as? String ?? "",
                earType: featuresDict["earType"] as? String ?? "",
                surfaceTexture: featuresDict["surfaceTexture"] as? String ?? "",
                patternType: featuresDict["patternType"] as? String ?? "",
                estimatedSize: featuresDict["estimatedSize"] as? String ?? ""
            )
        }
        
        return LabubuAIAnalysis(
            isLabubu: isLabubu,
            confidence: confidence,
            detailedDescription: detailedDescription,
            visualFeatures: visualFeatures,
            keyFeatures: keyFeatures,
            seriesHints: seriesHints,
            materialAnalysis: materialAnalysis,
            styleAnalysis: styleAnalysis,
            conditionAssessment: conditionAssessment,
            rarityHints: rarityHints
        )
    }
    
    /// 与数据库进行匹配
    private func matchWithDatabase(_ aiAnalysis: LabubuAIAnalysis) async throws -> [LabubuDatabaseMatch] {
        // 如果AI判断不是Labubu，直接返回空结果
        guard aiAnalysis.isLabubu else {
            return []
        }
        
        // 获取所有数据库中的模型
        let allModelData = try await databaseService.fetchAllActiveModels()
        let allModels = convertToLabubuModels(allModelData)
        
        // 使用AI描述进行文本相似度匹配
        var matches: [LabubuDatabaseMatch] = []
        
        for model in allModels {
            let similarity = calculateTextSimilarity(
                userDescription: aiAnalysis.detailedDescription,
                modelDescription: model.description ?? "",
                modelFeatures: model.tags.joined(separator: " ")
            )
            
            if similarity > 0.3 { // 最低相似度阈值
                matches.append(LabubuDatabaseMatch(
                    model: model,
                    similarity: similarity,
                    matchedFeatures: extractMatchedFeatures(aiAnalysis, model)
                ))
            }
        }
        
        // 按相似度排序
        matches.sort { $0.similarity > $1.similarity }
        
        // 返回前5个最佳匹配
        return Array(matches.prefix(5))
    }
    
    /// 计算文本相似度（简化版本）
    private func calculateTextSimilarity(userDescription: String, modelDescription: String, modelFeatures: String) -> Double {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let userWords = Set(userDescription.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        let combinedModelText = "\(modelDescription) \(modelFeatures)"
        let modelWords = Set(combinedModelText.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        
        let intersection = userWords.intersection(modelWords)
        let union = userWords.union(modelWords)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    /// 提取匹配的特征
    private func extractMatchedFeatures(_ aiAnalysis: LabubuAIAnalysis, _ model: LabubuModel) -> [String] {
        var matchedFeatures: [String] = []
        
        // 比较关键特征
        for feature in aiAnalysis.keyFeatures {
            let modelTags = model.tags.joined(separator: " ").lowercased()
            if model.description?.lowercased().contains(feature.lowercased()) == true ||
               modelTags.contains(feature.lowercased()) {
                matchedFeatures.append(feature)
            }
        }
        
        return matchedFeatures
    }
    
    /// 转换LabubuModelData为LabubuModel
    private func convertToLabubuModels(_ modelData: [LabubuModelData]) -> [LabubuModel] {
        return modelData.map { data in
            LabubuModel(
                id: data.id,
                name: data.nameEn ?? data.name,
                nameCN: data.name,
                seriesId: data.seriesId,
                variant: .standard,
                rarity: convertStringToRarity(data.rarity),
                releaseDate: nil,
                originalPrice: data.originalPrice,
                visualFeatures: createDefaultVisualFeatures(),
                tags: data.tags,
                description: data.description
            )
        }
    }
    
    /// 转换稀有度字符串为RarityLevel
    private func convertStringToRarity(_ rarity: String) -> RarityLevel {
        switch rarity.lowercased() {
        case "common": return .common
        case "uncommon": return .uncommon
        case "rare": return .rare
        case "ultra_rare": return .epic
        case "secret": return .secret
        default: return .common
        }
    }
    
    /// 创建默认视觉特征
    private func createDefaultVisualFeatures() -> VisualFeatures {
        return VisualFeatures(
            primaryColors: [],
            colorDistribution: [:],
            shapeDescriptor: ShapeDescriptor(
                aspectRatio: 0.8,
                roundness: 0.85,
                symmetry: 0.9,
                complexity: 0.4,
                keyPoints: []
            ),
            contourPoints: nil,
            textureFeatures: LabubuTextureFeatures(
                smoothness: 0.7,
                roughness: 0.3,
                patterns: [],
                materialType: .plush
            ),
            specialMarks: [],
            featureVector: []
        )
    }
    
    /// 获取API密钥
    private func getAPIKey() -> String? {
        // 优先从环境变量获取
        if let envKey = ProcessInfo.processInfo.environment["TUZI_API_KEY"], 
           !envKey.isEmpty,
           envKey != "your_api_key_here" {
            return envKey
        }
        
        // 尝试从.env文件读取
        if let envFileKey = loadValueFromEnvFile(key: "TUZI_API_KEY"),
           !envFileKey.isEmpty,
           envFileKey != "your_api_key_here" {
            return envFileKey
        }
        
        // 向后兼容：从环境变量读取OPENAI_API_KEY
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"],
           !envKey.isEmpty,
           envKey != "your_api_key_here" {
            return envKey
        }
        
        // 向后兼容：从.env文件读取OPENAI_API_KEY
        if let envFileKey = loadValueFromEnvFile(key: "OPENAI_API_KEY"),
           !envFileKey.isEmpty,
           envFileKey != "your_api_key_here" {
            return envFileKey
        }
        
        // 备选从UserDefaults获取（用于测试）
        return UserDefaults.standard.string(forKey: "tuzi_api_key")
    }
    
    /// 获取API基础URL
    private func getAPIBaseURL() -> String? {
        // 优先从环境变量获取
        if let envURL = ProcessInfo.processInfo.environment["TUZI_API_BASE"],
           !envURL.isEmpty {
            return envURL
        }
        
        // 尝试从.env文件读取
        if let envFileURL = loadValueFromEnvFile(key: "TUZI_API_BASE"),
           !envFileURL.isEmpty {
            return envFileURL
        }
        
        // 备选从UserDefaults获取（用于测试）
        return UserDefaults.standard.string(forKey: "tuzi_api_base") ?? "https://api.tu-zi.com/v1"
    }
    
    /// 从.env文件加载指定键的值
    private func loadValueFromEnvFile(key: String) -> String? {
        // 获取应用Bundle路径
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let envPath = bundlePath + "/.env"
        
        // 如果Bundle中没有.env文件，尝试项目根目录
        let projectEnvPath = bundlePath + "/../../.env"
        
        for path in [envPath, projectEnvPath] {
            if FileManager.default.fileExists(atPath: path) {
                do {
                    let content = try String(contentsOfFile: path, encoding: .utf8)
                    let lines = content.components(separatedBy: .newlines)
                    
                    for line in lines {
                        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedLine.hasPrefix("\(key)=") {
                            let value = String(trimmedLine.dropFirst("\(key)=".count))
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            if !value.isEmpty && value != "your_api_key_here" {
                                print("📁 LabubuAI从 \(path) 读取到\(key)")
                                return value
                            }
                        }
                    }
                } catch {
                    print("❌ LabubuAI读取.env文件失败: \(error)")
                }
            }
        }
        
        return nil
    }
}

// MARK: - 数据模型

/// Labubu AI分析结果
struct LabubuAIAnalysis {
    let isLabubu: Bool
    let confidence: Double
    let detailedDescription: String
    let visualFeatures: LabubuVisualFeatures?
    let keyFeatures: [String]
    let seriesHints: String
    let materialAnalysis: String
    let styleAnalysis: String
    let conditionAssessment: String
    let rarityHints: String
}

/// 视觉特征
struct LabubuVisualFeatures {
    let dominantColors: [String]
    let bodyShape: String
    let headShape: String
    let earType: String
    let surfaceTexture: String
    let patternType: String
    let estimatedSize: String
}

/// 数据库匹配结果
struct LabubuDatabaseMatch {
    let model: LabubuModel
    let similarity: Double
    let matchedFeatures: [String]
}

/// AI识别结果
struct LabubuAIRecognitionResult {
    let originalImage: UIImage
    let aiAnalysis: LabubuAIAnalysis
    let matchResults: [LabubuDatabaseMatch]
    let processingTime: TimeInterval
    let timestamp: Date
    
    /// 最佳匹配
    var bestMatch: LabubuModel? {
        return matchResults.first?.model
    }
    
    /// 是否成功识别
    var isSuccessful: Bool {
        return aiAnalysis.isLabubu && !matchResults.isEmpty
    }
    
    /// 识别置信度
    var confidence: Double {
        if let bestMatch = matchResults.first {
            return aiAnalysis.confidence * bestMatch.similarity
        }
        return aiAnalysis.confidence
    }
}

// MARK: - 错误类型

enum LabubuAIError: LocalizedError {
    case imageProcessingFailed
    case apiConfigurationMissing
    case networkError(String)
    case invalidResponse
    case jsonParsingFailed
    case noMatchFound
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图像处理失败"
        case .apiConfigurationMissing:
            return "API配置缺失，请检查TUZI_API_KEY和TUZI_API_BASE"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .invalidResponse:
            return "API响应无效"
        case .jsonParsingFailed:
            return "JSON解析失败"
        case .noMatchFound:
            return "未找到匹配的Labubu"
        }
    }
} 