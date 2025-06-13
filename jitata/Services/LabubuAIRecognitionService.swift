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
    private let apiTimeout: TimeInterval = 180.0  // 3分钟超时，确保AI有足够处理时间
    private let maxImageSize: CGFloat = 1024      // 提高图像尺寸，保证识别精度
    private let compressionQuality: CGFloat = 0.8  // 提高压缩质量，保证图像细节
    private let maxRetryAttempts = 3              // 最大重试次数
    private let retryDelay: TimeInterval = 2.0    // 重试延迟
    
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
            
            print("✅ AI识别完成: \(result.bestMatch?.name ?? "未识别")")
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
            DispatchQueue.main.async {
                // 调整图像尺寸（需要在主线程执行）
                let resizedImage = self.resizeImage(image, maxSize: self.maxImageSize)
                
                DispatchQueue.global(qos: .userInitiated).async {
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
    
    /// 调用TUZI Vision API（带重试机制）
    private func callTuziVisionAPI(_ image: UIImage) async throws -> LabubuAIAnalysis {
        print("📁 LabubuAI从 \(Bundle.main.bundlePath)/.env 读取到TUZI_API_KEY")
        print("📁 LabubuAI从 \(Bundle.main.bundlePath)/.env 读取到TUZI_API_BASE")
        
        // 获取API配置
        guard let apiKey = getAPIKey(),
              let baseURL = getAPIBaseURL() else {
            print("❌ API配置缺失")
            throw LabubuAIError.apiConfigurationMissing
        }
        
        print("🔑 API密钥已获取: \(apiKey.prefix(10))...")
        print("🌐 API基础URL: \(baseURL)")
        
        // 转换图像为base64
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            print("❌ 图像压缩失败")
            throw LabubuAIError.imageProcessingFailed
        }
        
        print("📷 图像数据大小: \(imageData.count) 字节")
        print("📷 压缩质量: \(compressionQuality)")
        
        let base64Image = "data:image/jpeg;base64," + imageData.base64EncodedString()
        print("📝 Base64编码完成，长度: \(base64Image.count) 字符")
        
        // 带重试机制的API调用
        var lastError: Error?
        
        for attempt in 1...maxRetryAttempts {
            print("🔄 第\(attempt)次尝试API调用...")
            
            do {
                let result = try await performSingleAPICall(apiKey: apiKey, baseURL: baseURL, base64Image: base64Image)
                print("✅ 第\(attempt)次尝试成功")
                return result
            } catch {
                lastError = error
                print("❌ 第\(attempt)次尝试失败: \(error)")
                
                // 如果不是最后一次尝试，等待后重试
                if attempt < maxRetryAttempts {
                    print("⏳ 等待\(retryDelay)秒后重试...")
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        // 所有重试都失败了
        print("❌ 所有\(maxRetryAttempts)次尝试都失败")
        throw lastError ?? LabubuAIError.networkError("API调用失败")
    }
    
    /// 执行单次API调用
    private func performSingleAPICall(apiKey: String, baseURL: String, base64Image: String) async throws -> LabubuAIAnalysis {
        // 构建请求
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = apiTimeout
        
        print("🌐 请求URL: \(url.absoluteString)")
        print("⏱️ 超时设置: \(apiTimeout) 秒")
        
        let requestBody = [
            "model": "gemini-2.5-flash-all",
            "stream": false,  // 明确禁用流式模式，确保完整响应
            "temperature": 0.1,  // 降低随机性，提高一致性
            "max_tokens": 2000,  // 确保有足够的token返回完整分析
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
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📦 请求体大小: \(request.httpBody?.count ?? 0) 字节")
        } catch {
            print("❌ 请求体序列化失败: \(error)")
            throw LabubuAIError.jsonParsingFailed
        }
        
        print("🚀 发送API请求...")
        
        // 发送请求
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("📥 收到响应，数据大小: \(data.count) 字节")
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的HTTP响应类型")
            throw LabubuAIError.networkError("无效的响应")
        }
        
        print("📊 HTTP状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "无法解析错误信息"
            print("❌ API请求失败: \(httpResponse.statusCode)")
            print("❌ 错误详情: \(errorBody)")
            
            // 根据HTTP状态码提供更具体的错误信息
            switch httpResponse.statusCode {
            case 401:
                throw LabubuAIError.apiConfigurationMissing
            case 429:
                throw LabubuAIError.apiRateLimited
            case 402, 403:
                throw LabubuAIError.apiQuotaExceeded
            case 408, 504:
                throw LabubuAIError.apiTimeout
            case 500...599:
                throw LabubuAIError.invalidResponse
            default:
                throw LabubuAIError.networkError("API请求失败: \(httpResponse.statusCode) - \(errorBody)")
            }
        }
        
        // 解析响应
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            print("✅ JSON响应解析成功")
            
            guard let choices = jsonResponse?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                print("❌ 响应格式无效")
                print("📝 响应内容: \(String(data: data, encoding: .utf8) ?? "无法解析")")
                throw LabubuAIError.invalidResponse
            }
            
            print("📝 AI分析内容长度: \(content.count) 字符")
            print("📝 AI分析内容预览: \(content.prefix(200))...")
            print("📝 AI分析完整内容: \(content)")
            
            // 解析AI分析结果
            let result = try parseAIAnalysisResult(content)
            print("✅ AI分析结果解析完成")
            print("🎯 识别结果: isLabubu=\(result.isLabubu), confidence=\(result.confidence)")
            print("📄 详细描述: \(result.detailedDescription.prefix(100))...")
            
            return result
            
        } catch {
            print("❌ JSON解析失败: \(error)")
            print("📝 原始响应: \(String(data: data, encoding: .utf8) ?? "无法解析")")
            throw LabubuAIError.jsonParsingFailed
        }
    }
    
    /// 构建Labubu识别提示词
    private func buildLabubuRecognitionPrompt() -> String {
        return """
        你是一个专业的Labubu玩具识别专家。请仔细分析这张用户拍摄的图片，判断是否为Labubu玩具，并提供详细的特征描述。

        Labubu是一个知名的潮玩品牌，通常具有以下特征：
        - 可爱的卡通形象，通常有大眼睛
        - 多种颜色和主题系列
        - 常见材质包括毛绒、塑料、搪胶等
        - 尺寸从小型到大型不等
        - 经常有特殊的服装、配饰或主题装扮

        请按照以下JSON格式返回分析结果，确保JSON格式完全正确：

        ```json
        {
            "isLabubu": true,
            "confidence": 0.85,
            "detailedDescription": "详细的特征描述文案，包括颜色、形状、材质、图案、风格、服装、配饰等所有可见特征，这段文案将用于与数据库中的Labubu模型进行智能匹配。请尽可能详细描述，包括具体的颜色名称、材质质感、图案细节、整体风格等",
            "visualFeatures": {
                "dominantColors": ["#FF6B6B", "#4ECDC4", "#45B7D1"],
                "bodyShape": "圆润",
                "headShape": "圆形",
                "earType": "尖耳",
                "surfaceTexture": "绒毛",
                "patternType": "纯色",
                "estimatedSize": "中型"
            },
            "keyFeatures": [
                "具体特征1（如：蓝色渔夫帽）",
                "具体特征2（如：白色毛绒身体）", 
                "具体特征3（如：大眼睛表情）"
            ],
            "seriesHints": "可能的系列名称或主题提示（如：Fall in Wild、The Monsters等）",
            "materialAnalysis": "材质分析（如：毛绒质地、塑料配件、金属装饰等）",
            "styleAnalysis": "风格分析（如：户外探险风格、可爱萌系、酷炫街头等）",
            "conditionAssessment": "状态评估（如：全新、良好、轻微磨损等）",
            "rarityHints": "稀有度提示（如：常见款、稀有款、限定款、隐藏款等）"
        }
        ```

        重要说明：
        1. 如果图片中不是Labubu玩具，请将isLabubu设为false，confidence设为0.0-0.3
        2. 如果图片中是Labubu玩具，请将isLabubu设为true，confidence设为0.6-0.95之间的数值
        3. confidence字段必须是数字，不能是字符串，范围0.0-1.0
        4. detailedDescription字段非常重要，请提供丰富详细的特征描述，包含所有可见的细节
        5. keyFeatures要具体明确，避免模糊描述
        6. 请确保返回的是有效的JSON格式，使用```json```包围
        7. 即使不确定是否为Labubu，也要尽可能详细描述图片中玩具的特征
        """
    }
    
    /// 解析AI分析结果（增强版）
    private func parseAIAnalysisResult(_ content: String) throws -> LabubuAIAnalysis {
        print("🔍 开始解析AI分析结果...")
        
        // 多种方式提取JSON内容
        let jsonText: String
        
        // 方式1: 提取```json```块
        if let jsonMatch = content.range(of: "```json\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
            let fullMatch = String(content[jsonMatch])
            jsonText = fullMatch
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("📋 从```json```块中提取JSON")
        }
        // 方式2: 提取普通```代码块
        else if let codeMatch = content.range(of: "```\\s*([\\s\\S]*?)\\s*```", options: .regularExpression) {
            let fullMatch = String(content[codeMatch])
            jsonText = fullMatch
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("📋 从```代码块中提取JSON")
        }
        // 方式3: 查找{...}JSON对象
        else if let jsonStart = content.firstIndex(of: "{"),
                let jsonEnd = content.lastIndex(of: "}") {
            jsonText = String(content[jsonStart...jsonEnd])
            print("📋 从{}对象中提取JSON")
        }
        // 方式4: 直接使用原始内容
        else {
            jsonText = content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📋 直接使用原始内容作为JSON")
        }
        
        print("📝 提取的JSON文本: \(jsonText)")
        
        // 尝试修复常见的JSON格式问题
        let cleanedJsonText = cleanupJsonText(jsonText)
        print("🧹 清理后的JSON文本: \(cleanedJsonText)")
        
        // 解析JSON
        guard let data = cleanedJsonText.data(using: .utf8) else {
            print("❌ JSON文本转换为Data失败")
            throw LabubuAIError.jsonParsingFailed
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ JSON反序列化失败 - 不是字典类型")
                throw LabubuAIError.jsonParsingFailed
            }
            
            print("✅ JSON解析成功，字段: \(json.keys.sorted())")
            
            // 构建分析结果（增强容错性）
            let isLabubu = json["isLabubu"] as? Bool ?? false
            
            // 处理confidence字段的多种类型
            let confidence: Double
            if let confDouble = json["confidence"] as? Double {
                confidence = max(0.0, min(1.0, confDouble))  // 确保在0-1范围内
            } else if let confString = json["confidence"] as? String,
                      let confValue = Double(confString) {
                confidence = max(0.0, min(1.0, confValue))
            } else {
                confidence = isLabubu ? 0.5 : 0.0  // 默认值
            }
            
            let detailedDescription = json["detailedDescription"] as? String ?? ""
            let keyFeatures = json["keyFeatures"] as? [String] ?? []
            let seriesHints = json["seriesHints"] as? String ?? ""
            let materialAnalysis = json["materialAnalysis"] as? String ?? ""
            let styleAnalysis = json["styleAnalysis"] as? String ?? ""
            let conditionAssessment = json["conditionAssessment"] as? String ?? ""
            let rarityHints = json["rarityHints"] as? String ?? ""
            
            print("🔍 解析字段值:")
            print("  - isLabubu: \(isLabubu)")
            print("  - confidence: \(confidence)")
            print("  - detailedDescription长度: \(detailedDescription.count)")
            print("  - keyFeatures数量: \(keyFeatures.count)")
            
            // 解析视觉特征（增强容错性）
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
                print("✅ 视觉特征解析成功")
            } else {
                print("⚠️ 未找到visualFeatures字段，使用默认值")
                visualFeatures = LabubuVisualFeatures(
                    dominantColors: [],
                    bodyShape: "",
                    headShape: "",
                    earType: "",
                    surfaceTexture: "",
                    patternType: "",
                    estimatedSize: ""
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
            
        } catch {
            print("❌ JSON解析失败: \(error)")
            print("📝 原始内容: \(content)")
            print("📝 清理后内容: \(cleanedJsonText)")
            
            // 如果JSON解析失败，尝试从文本中提取基本信息
            return extractBasicInfoFromText(content)
        }
    }
    
    /// 清理JSON文本，修复常见格式问题
    private func cleanupJsonText(_ text: String) -> String {
        var cleaned = text
        
        // 移除多余的换行和空格
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 修复常见的引号问题
        cleaned = cleaned.replacingOccurrences(of: "\u{201C}", with: "\"") // 左双引号
        cleaned = cleaned.replacingOccurrences(of: "\u{201D}", with: "\"") // 右双引号
        cleaned = cleaned.replacingOccurrences(of: "\u{2018}", with: "\"") // 左单引号
        cleaned = cleaned.replacingOccurrences(of: "\u{2019}", with: "\"") // 右单引号
        
        // 修复布尔值
        cleaned = cleaned.replacingOccurrences(of: ": true", with: ": true")
        cleaned = cleaned.replacingOccurrences(of: ": false", with: ": false")
        
        return cleaned
    }
    
    /// 从文本中提取基本信息（备用方案）
    private func extractBasicInfoFromText(_ content: String) -> LabubuAIAnalysis {
        print("🔧 使用备用方案从文本中提取信息...")
        
        let lowercaseContent = content.lowercased()
        
        // 判断是否为Labubu
        let isLabubu = lowercaseContent.contains("labubu") || 
                      lowercaseContent.contains("是") ||
                      lowercaseContent.contains("true")
        
        // 提取置信度
        let confidence: Double
        if let confMatch = content.range(of: "\\d+\\.\\d+", options: .regularExpression) {
            confidence = Double(String(content[confMatch])) ?? (isLabubu ? 0.7 : 0.1)
        } else {
            confidence = isLabubu ? 0.7 : 0.1
        }
        
        print("🔧 备用方案结果: isLabubu=\(isLabubu), confidence=\(confidence)")
        
        return LabubuAIAnalysis(
            isLabubu: isLabubu,
            confidence: confidence,
            detailedDescription: content,
            visualFeatures: nil,
            keyFeatures: [],
            seriesHints: "",
            materialAnalysis: "",
            styleAnalysis: "",
            conditionAssessment: "",
            rarityHints: ""
        )
    }
    
    /// 与数据库进行匹配
    private func matchWithDatabase(_ aiAnalysis: LabubuAIAnalysis) async throws -> [LabubuDatabaseMatch] {
        print("🔍 开始与数据库进行智能匹配...")
        
        // 如果AI判断不是Labubu，直接返回空结果
        guard aiAnalysis.isLabubu else {
            print("❌ AI判断不是Labubu，跳过匹配")
            return []
        }
        
        // 获取所有数据库中的模型
        let allModelData = try await databaseService.fetchAllActiveModels()
        print("📊 获取到 \(allModelData.count) 个数据库模型进行匹配")
        
        // 使用AI描述进行智能相似度匹配
        var matches: [LabubuDatabaseMatch] = []
        
        for (index, modelData) in allModelData.enumerated() {
            print("🔍 正在匹配模型 \(index + 1)/\(allModelData.count): \(modelData.name)")
            
            // 解析数据库模型的特征描述
            let modelFeatureText = extractFeatureText(from: modelData)
            print("📝 模型特征文本长度: \(modelFeatureText.count) 字符")
            
            // 计算相似度
            let similarity = calculateAdvancedTextSimilarity(
                userDescription: aiAnalysis.detailedDescription,
                modelFeatureText: modelFeatureText,
                userKeyFeatures: aiAnalysis.keyFeatures
            )
            
            print("📊 相似度得分: \(String(format: "%.3f", similarity))")
            
            // 只保留相似度高于阈值的匹配结果
            let threshold = 0.08 // 进一步降低阈值，提高匹配成功率
            if similarity >= threshold {
                let matchedFeatures = extractMatchedFeatures(aiAnalysis, modelFeatureText)
                
                matches.append(LabubuDatabaseMatch(
                    model: modelData,
                    similarity: similarity,
                    matchedFeatures: matchedFeatures
                ))
                
                print("✅ 添加匹配结果: \(modelData.name) (相似度: \(String(format: "%.3f", similarity)))")
            } else {
                print("❌ 相似度过低，跳过")
            }
        }
        
        // 按相似度排序
        matches.sort { $0.similarity > $1.similarity }
        print("🏆 匹配完成，找到 \(matches.count) 个候选结果")
        
        // 打印前3个最佳匹配
        for (index, match) in matches.prefix(3).enumerated() {
            print("🥇 第\(index + 1)名: \(match.model.name) (相似度: \(String(format: "%.3f", match.similarity)))")
        }
        
        // 返回前5个最佳匹配
        return Array(matches.prefix(5))
    }
    
    /// 从LabubuModelData中提取特征文本
    private func extractFeatureText(from modelData: LabubuModelData) -> String {
        var featureTexts: [String] = []
        
        // 添加基本信息
        featureTexts.append(modelData.name)
        if let nameEn = modelData.nameEn, nameEn != modelData.name {
            featureTexts.append(nameEn)
        }
        
        // 解析feature_description JSON
        if let featureDescription = modelData.featureDescription,
           let data = featureDescription.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 提取详细描述
                    if let detailedDesc = json["detailedDescription"] as? String {
                        featureTexts.append(detailedDesc)
                    }
                    
                    // 提取关键特征
                    if let keyFeatures = json["keyFeatures"] as? [String] {
                        featureTexts.append(contentsOf: keyFeatures)
                    }
                    
                    // 提取材质分析
                    if let materialAnalysis = json["materialAnalysis"] as? String {
                        featureTexts.append(materialAnalysis)
                    }
                    
                    // 提取风格分析
                    if let styleAnalysis = json["styleAnalysis"] as? String {
                        featureTexts.append(styleAnalysis)
                    }
                    
                    // 提取视觉特征
                    if let visualFeatures = json["visualFeatures"] as? [String: Any] {
                        for (_, value) in visualFeatures {
                            if let stringValue = value as? String {
                                featureTexts.append(stringValue)
                            } else if let arrayValue = value as? [String] {
                                featureTexts.append(contentsOf: arrayValue)
                            }
                        }
                    }
                }
            } catch {
                print("⚠️ 解析feature_description JSON失败: \(error)")
            }
        }
        
        // 添加稀有度信息
        featureTexts.append(modelData.rarityLevel)
        
        return featureTexts.joined(separator: " ")
    }
    
    /// 计算高级文本相似度
    private func calculateAdvancedTextSimilarity(
        userDescription: String,
        modelFeatureText: String,
        userKeyFeatures: [String]
    ) -> Double {
        print("🔍 开始计算相似度...")
        print("👤 用户描述: \(userDescription.prefix(100))...")
        print("🏷️ 用户关键特征: \(userKeyFeatures)")
        print("🗄️ 模型特征文本: \(modelFeatureText.prefix(100))...")
        
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        
        // 处理用户描述
        let userWords = Set(userDescription.lowercased()
            .components(separatedBy: separators)
            .filter { $0.count > 2 })
        
        // 处理模型特征文本
        let modelWords = Set(modelFeatureText.lowercased()
            .components(separatedBy: separators)
            .filter { $0.count > 2 })
        
        // 1. 基础词汇相似度
        let intersection = userWords.intersection(modelWords)
        let union = userWords.union(modelWords)
        let basicSimilarity = union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
        print("📊 基础词汇相似度: \(String(format: "%.3f", basicSimilarity)) (匹配词数: \(intersection.count)/\(union.count))")
        
        // 2. 关键特征匹配度（改进版）
        var keyFeatureScore = 0.0
        var matchedFeatures: [String] = []
        
        for feature in userKeyFeatures {
            let featureScore = calculateFeatureMatch(feature: feature, modelText: modelFeatureText)
            keyFeatureScore += featureScore
            if featureScore > 0.3 {
                matchedFeatures.append(feature)
            }
            print("🔍 特征匹配: '\(feature)' -> \(String(format: "%.3f", featureScore))")
        }
        
        let keyFeatureSimilarity = userKeyFeatures.isEmpty ? 0.0 : keyFeatureScore / Double(userKeyFeatures.count)
        print("📊 关键特征相似度: \(String(format: "%.3f", keyFeatureSimilarity)) (匹配特征: \(matchedFeatures))")
        
        // 3. 系列名称匹配度
        let seriesScore = calculateSeriesMatch(userDescription: userDescription, modelText: modelFeatureText)
        print("📊 系列匹配度: \(String(format: "%.3f", seriesScore))")
        
        // 4. 颜色匹配度
        let colorScore = calculateColorMatch(userDescription: userDescription, modelText: modelFeatureText)
        print("📊 颜色匹配度: \(String(format: "%.3f", colorScore))")
        
        // 综合相似度计算 (调整权重)
        let finalSimilarity = basicSimilarity * 0.3 + 
                             keyFeatureSimilarity * 0.4 + 
                             seriesScore * 0.2 + 
                             colorScore * 0.1
        
        print("🎯 最终相似度: \(String(format: "%.3f", finalSimilarity))")
        print("📈 权重分布: 基础(\(String(format: "%.3f", basicSimilarity * 0.3))) + 特征(\(String(format: "%.3f", keyFeatureSimilarity * 0.4))) + 系列(\(String(format: "%.3f", seriesScore * 0.2))) + 颜色(\(String(format: "%.3f", colorScore * 0.1)))")
        
        return finalSimilarity
    }
    
    /// 计算单个特征的匹配度
    private func calculateFeatureMatch(feature: String, modelText: String) -> Double {
        let featureLower = feature.lowercased()
        let modelLower = modelText.lowercased()
        
        // 直接匹配
        if modelLower.contains(featureLower) {
            return 1.0
        }
        
        // 语义匹配映射
        let semanticMappings: [String: [String]] = [
            "渔夫帽": ["渔夫帽", "户外帽", "帽子", "hat"],
            "毛绒": ["毛绒", "绒毛", "长绒", "plush", "绒布"],
            "背心": ["背心", "衬衣", "上衣", "vest", "shirt"],
            "花朵": ["花朵", "雏菊", "花", "flower", "daisy"],
            "蓝色": ["蓝色", "深蓝", "靛蓝", "blue"],
            "白色": ["白色", "米白", "淡白", "white"],
            "卡其": ["卡其", "卡其色", "khaki"],
            "眼睛": ["眼睛", "瞳孔", "大眼", "eye"],
            "耳朵": ["耳朵", "兔耳", "ear"]
        ]
        
        // 检查语义匹配
        for (key, synonyms) in semanticMappings {
            if featureLower.contains(key) {
                for synonym in synonyms {
                    if modelLower.contains(synonym) {
                        return 0.8 // 语义匹配得分
                    }
                }
            }
        }
        
        // 部分匹配
        let featureWords = featureLower.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { $0.count > 2 }
        
        var partialMatches = 0
        for word in featureWords {
            if modelLower.contains(word) {
                partialMatches += 1
            }
        }
        
        return featureWords.isEmpty ? 0.0 : Double(partialMatches) / Double(featureWords.count) * 0.6
    }
    
    /// 计算系列名称匹配度
    private func calculateSeriesMatch(userDescription: String, modelText: String) -> Double {
        let userLower = userDescription.lowercased()
        let modelLower = modelText.lowercased()
        
        let seriesKeywords = [
            "fall in wild", "春天在野", "monsters", "the monsters",
            "time to chill", "best of luck", "checkmate", "flip with me"
        ]
        
        var matchCount = 0
        for keyword in seriesKeywords {
            if userLower.contains(keyword) && modelLower.contains(keyword) {
                matchCount += 1
            }
        }
        
        return seriesKeywords.isEmpty ? 0.0 : Double(matchCount) / Double(seriesKeywords.count)
    }
    
    /// 计算颜色匹配度
    private func calculateColorMatch(userDescription: String, modelText: String) -> Double {
        let userLower = userDescription.lowercased()
        let modelLower = modelText.lowercased()
        
        let colorKeywords = [
            "卡其", "白色", "蓝色", "黄色", "棕色", "黑色", "粉色",
            "khaki", "white", "blue", "yellow", "brown", "black", "pink"
        ]
        
        var matchCount = 0
        for color in colorKeywords {
            if userLower.contains(color) && modelLower.contains(color) {
                matchCount += 1
            }
        }
        
        return colorKeywords.isEmpty ? 0.0 : Double(matchCount) / Double(colorKeywords.count)
    }
    
    /// 提取匹配的特征
    private func extractMatchedFeatures(_ aiAnalysis: LabubuAIAnalysis, _ modelFeatureText: String) -> [String] {
        var matchedFeatures: [String] = []
        
        // 比较关键特征
        for feature in aiAnalysis.keyFeatures {
            if modelFeatureText.lowercased().contains(feature.lowercased()) {
                matchedFeatures.append(feature)
            }
        }
        
        return matchedFeatures
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
    let model: LabubuModelData
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
    var bestMatch: LabubuModelData? {
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
    case apiTimeout
    case apiQuotaExceeded
    case apiRateLimited
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "图像处理失败，请检查图片格式和大小"
        case .apiConfigurationMissing:
            return "AI识别服务配置缺失，请检查网络设置"
        case .networkError(let message):
            return "网络连接失败: \(message)"
        case .invalidResponse:
            return "AI服务响应异常，请稍后重试"
        case .jsonParsingFailed:
            return "AI分析结果解析失败，但已尝试备用方案"
        case .noMatchFound:
            return "未找到匹配的Labubu模型，可能是新款或非Labubu玩具"
        case .apiTimeout:
            return "AI分析超时，请检查网络连接后重试"
        case .apiQuotaExceeded:
            return "AI服务使用量已达上限，请稍后重试"
        case .apiRateLimited:
            return "请求过于频繁，请稍后重试"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageProcessingFailed:
            return "请尝试使用清晰度更高的图片，确保图片大小在合理范围内"
        case .apiConfigurationMissing:
            return "请检查网络连接，或联系技术支持"
        case .networkError:
            return "请检查网络连接，确保网络稳定后重试"
        case .invalidResponse, .jsonParsingFailed:
            return "这可能是临时问题，请稍后重试"
        case .noMatchFound:
            return "您可以尝试从不同角度拍摄，或手动添加到收藏"
        case .apiTimeout:
            return "请确保网络连接稳定，或稍后重试"
        case .apiQuotaExceeded, .apiRateLimited:
            return "请稍等片刻后再次尝试识别"
        }
    }
} 