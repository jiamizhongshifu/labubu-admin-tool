//
//  ToySticker.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import SwiftData
import UIKit

/// AI增强状态枚举
enum AIEnhancementStatus: String, CaseIterable {
    case pending = "pending"        // 等待增强
    case processing = "processing"  // 增强中
    case completed = "completed"    // 增强完成
    case failed = "failed"         // 增强失败
    
    var displayName: String {
        switch self {
        case .pending:
            return "等待增强"
        case .processing:
            return "增强中"
        case .completed:
            return "已增强"
        case .failed:
            return "增强失败"
        }
    }
    
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}

/// 视频生成状态枚举
enum VideoGenerationStatus: String, CaseIterable {
    case none = "none"              // 未生成
    case pending = "pending"        // 等待生成
    case processing = "processing"  // 生成中
    case completed = "completed"    // 生成完成
    case failed = "failed"         // 生成失败
    
    var displayName: String {
        switch self {
        case .none:
            return "未生成"
        case .pending:
            return "等待生成"
        case .processing:
            return "生成中"
        case .completed:
            return "已生成"
        case .failed:
            return "生成失败"
        }
    }
    
    var icon: String {
        switch self {
        case .none:
            return "video.slash"
        case .pending:
            return "clock"
        case .processing:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
}

@Model
final class ToySticker: Identifiable {
    var id: UUID
    var name: String
    var categoryName: String
    var originalImageData: Data
    var processedImageData: Data
    var createdDate: Date
    var notes: String
    var isFavorite: Bool
    
    // MARK: - AI Enhancement Properties (with default values for migration)
    var enhancementStatus: String = "pending"
    var enhancedImageData: Data? = nil
    var lastEnhancementAttempt: Date? = nil
    var enhancementRetryCount: Int = 0
    var enhancementPrompt: String? = nil
    var preferredAspectRatio: String = KlingConfig.defaultAspectRatio  // 用户选择的图片比例
    
    // MARK: - New AI Enhancement Properties
    var aiEnhancementStatusRaw: String = "pending"
    var aiEnhancementProgress: Double = 0.0
    var aiEnhancementMessage: String = ""
    
    // MARK: - Image Display Properties
    var isShowingEnhancedImage: Bool = true  // 默认显示增强图片（如果有的话）
    
    // MARK: - Supabase Storage Properties
    var supabaseImageURL: String?  // 预上传到Supabase的图片URL
    var enhancedSupabaseImageURL: String?  // 🎯 AI增强图片的Supabase URL
    
    // MARK: - Video Generation Properties
    var videoURL: String?  // 生成的视频URL
    var videoTaskId: String?  // 可灵API任务ID
    var videoGenerationStatusRaw: String = "none"
    var videoGenerationProgress: Double = 0.0
    var videoGenerationMessage: String = ""
    var videoGenerationPrompt: String?  // 视频生成使用的提示词
    
    // MARK: - Local Video Storage Properties
    var localVideoPath: String?  // 本地视频文件路径
    var videoDownloadStatus: String = "none"  // 下载状态：none, downloading, completed, failed
    var downloadProgress: Double = 0.0  // 下载进度
    
    // MARK: - Labubu Recognition Properties
    var labubuInfoData: Data?  // 存储序列化的Labubu信息
    var isLabubuVerified: Bool = false  // 是否已验证为Labubu
    var labubuSeriesId: String?  // 快速访问系列ID
    var labubuRecognitionConfidence: Double = 0.0  // 识别置信度
    var labubuRecognitionDate: Date?  // 识别时间
    
    // MARK: - AI Recognition Properties
    var aiRecognitionResultData: Data?  // 存储序列化的AI识别结果
    var hasAIRecognitionResult: Bool = false  // 是否有AI识别结果
    
    init(name: String, categoryName: String, originalImage: UIImage, processedImage: UIImage, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryName = categoryName
        // 🎯 保存高质量原图：使用0.95质量的JPEG，保持高清晰度
        self.originalImageData = originalImage.jpegData(compressionQuality: 0.95) ?? Data()
        // 🎯 修复：使用PNG格式保存抠图结果，保持透明背景和最高质量
        self.processedImageData = processedImage.pngData() ?? Data()
        self.createdDate = Date()
        self.notes = notes
        self.isFavorite = false
        
        // 初始化AI增强相关属性
        self.enhancementStatus = EnhancementStatus.pending.rawValue
        self.enhancedImageData = nil
        self.lastEnhancementAttempt = nil
        self.enhancementRetryCount = 0
        self.enhancementPrompt = nil
        self.preferredAspectRatio = KlingConfig.defaultAspectRatio
        
        // 初始化新的AI增强属性
        self.aiEnhancementStatusRaw = AIEnhancementStatus.pending.rawValue
        self.aiEnhancementProgress = 0.0
        self.aiEnhancementMessage = "等待增强"
        
        // 初始化视频生成属性
        self.videoGenerationStatusRaw = VideoGenerationStatus.none.rawValue
        self.videoGenerationProgress = 0.0
        self.videoGenerationMessage = ""
    }
    
    var originalImage: UIImage? {
        return UIImage(data: originalImageData)
    }
    
    var processedImage: UIImage? {
        return UIImage(data: processedImageData)
    }
    
    /// 获取最终显示的图片（根据用户选择显示原图或增强图）
    var displayImage: UIImage? {
        // 如果用户选择显示增强图且增强图存在
        if isShowingEnhancedImage, let enhancedData = enhancedImageData, !enhancedData.isEmpty {
            return UIImage(data: enhancedData)
        }
        // 否则显示处理后的原图
        return processedImage
    }
    
    /// 增强图片
    var enhancedImage: UIImage? {
        guard let data = enhancedImageData else { return nil }
        return UIImage(data: data)
    }
    
    /// 是否有增强图片
    var hasEnhancedImage: Bool {
        return enhancedImageData != nil && !enhancedImageData!.isEmpty
    }
    
    /// 切换显示的图片类型
    func toggleImageDisplay() {
        if hasEnhancedImage {
            isShowingEnhancedImage.toggle()
        }
    }
    
    /// 获取当前显示图片的类型描述
    var currentImageTypeDescription: String {
        if hasEnhancedImage {
            return isShowingEnhancedImage ? "AI增强版" : "原图"
        } else {
            return "原图"
        }
    }
    
    /// 新的AI增强状态
    var aiEnhancementStatus: AIEnhancementStatus {
        get {
            return AIEnhancementStatus(rawValue: aiEnhancementStatusRaw) ?? .pending
        }
        set {
            aiEnhancementStatusRaw = newValue.rawValue
        }
    }
    
    /// 视频生成状态
    var videoGenerationStatus: VideoGenerationStatus {
        get {
            return VideoGenerationStatus(rawValue: videoGenerationStatusRaw) ?? .none
        }
        set {
            videoGenerationStatusRaw = newValue.rawValue
        }
    }
    
    /// 是否有视频
    var hasVideo: Bool {
        // 检查是否有云端视频URL且状态为完成
        let hasCloudVideo = videoURL != nil && !videoURL!.isEmpty && videoGenerationStatus == .completed
        
        // 检查是否有本地视频文件
        let hasLocalVideo: Bool = {
            let stickerID = id.uuidString
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let videosPath = documentsPath.appendingPathComponent("Videos")
            let localURL = videosPath.appendingPathComponent("video_\(stickerID).mp4")
            return FileManager.default.fileExists(atPath: localURL.path)
        }()
        
        return hasCloudVideo || hasLocalVideo
    }
    
    /// 获取本地视频URL（如果存在）
    var localVideoURL: URL? {
        let stickerID = id.uuidString
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosPath = documentsPath.appendingPathComponent("Videos")
        let localURL = videosPath.appendingPathComponent("video_\(stickerID).mp4")
        
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    /// 获取最佳视频URL（优先本地，备用云端）
    var bestVideoURL: URL? {
        // 优先返回本地视频URL
        if let localURL = localVideoURL {
            return localURL
        }
        
        // 备用返回云端视频URL
        guard let cloudURLString = videoURL,
              let cloudURL = URL(string: cloudURLString) else {
            return nil
        }
        
        return cloudURL
    }
}

// MARK: - Enhancement Status Enum (保持向后兼容)

extension ToySticker {
    enum EnhancementStatus: String, CaseIterable {
        case pending = "pending"        // 等待增强
        case processing = "processing"  // 增强中
        case completed = "completed"    // 增强完成
        case failed = "failed"         // 增强失败
        
        var displayName: String {
            switch self {
            case .pending:
                return "等待增强"
            case .processing:
                return "增强中"
            case .completed:
                return "已增强"
            case .failed:
                return "增强失败"
            }
        }
        
        var icon: String {
            switch self {
            case .pending:
                return "clock"
            case .processing:
                return "arrow.triangle.2.circlepath"
            case .completed:
                return "checkmark.circle.fill"
            case .failed:
                return "exclamationmark.triangle.fill"
            }
        }
    }
    
    /// 当前增强状态
    var currentEnhancementStatus: EnhancementStatus {
        return EnhancementStatus(rawValue: enhancementStatus) ?? .pending
    }
    
    /// 是否可以重试增强
    var canRetryEnhancement: Bool {
        return currentEnhancementStatus == .failed && enhancementRetryCount < APIConfig.maxRetryAttempts
    }
    
    /// 更新增强状态
    func updateEnhancementStatus(_ status: EnhancementStatus) {
        self.enhancementStatus = status.rawValue
        if status == .processing {
            self.lastEnhancementAttempt = Date()
        }
    }
    
    /// 设置增强图片
    func setEnhancedImage(_ image: UIImage) {
        self.enhancedImageData = image.pngData()
        self.enhancementStatus = EnhancementStatus.completed.rawValue
    }
    
    /// 增强失败
    func markEnhancementFailed() {
        self.enhancementStatus = EnhancementStatus.failed.rawValue
        self.enhancementRetryCount += 1
    }
}

extension ToySticker {
    static let sampleData: [ToySticker] = []
}

// MARK: - Labubu Recognition Extension
extension ToySticker {
    /// Labubu识别信息（简化版本）
    var labubuInfo: LabubuRecognitionResult? {
        get {
            // 由于LabubuRecognitionResult不再支持Codable，我们暂时返回nil
            // 在简化的架构中，识别结果不需要持久化存储
            return nil
        }
        set {
            // 从识别结果中提取关键信息进行存储
            if let newValue = newValue {
                labubuSeriesId = newValue.bestMatch?.model.seriesId
                labubuRecognitionConfidence = newValue.confidence
                labubuRecognitionDate = Date()
                isLabubuVerified = newValue.confidence > 0.6
                // 清除旧的数据，因为新结构不支持序列化
                labubuInfoData = nil
            } else {
                labubuSeriesId = nil
                labubuRecognitionConfidence = 0.0
                labubuRecognitionDate = nil
                isLabubuVerified = false
                labubuInfoData = nil
            }
        }
    }
    
    /// AI识别结果（新版本，支持持久化）
    var aiRecognitionResult: LabubuAIRecognitionResult? {
        get {
            guard let data = aiRecognitionResultData else { return nil }
            do {
                return try JSONDecoder().decode(LabubuAIRecognitionResult.self, from: data)
            } catch {
                print("❌ AI识别结果反序列化失败: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    aiRecognitionResultData = try JSONEncoder().encode(newValue)
                    hasAIRecognitionResult = true
                    
                    // 同时更新基础识别信息
                    labubuSeriesId = newValue.bestMatch?.seriesId
                    labubuRecognitionConfidence = newValue.confidence
                    labubuRecognitionDate = newValue.timestamp
                    isLabubuVerified = newValue.isSuccessful
                    
                    print("✅ AI识别结果已保存到ToySticker")
                } catch {
                    print("❌ AI识别结果序列化失败: \(error)")
                    aiRecognitionResultData = nil
                    hasAIRecognitionResult = false
                }
            } else {
                aiRecognitionResultData = nil
                hasAIRecognitionResult = false
                
                // 清除相关信息
                labubuSeriesId = nil
                labubuRecognitionConfidence = 0.0
                labubuRecognitionDate = nil
                isLabubuVerified = false
            }
        }
    }
    
    /// 是否为Labubu系列
    var isLabubu: Bool {
        return isLabubuVerified && labubuSeriesId != nil
    }
    
    /// 识别状态描述
    var labubuRecognitionStatus: String {
        if !isLabubuVerified {
            return "未识别"
        }
        
        if labubuRecognitionConfidence > 0.85 {
            return "高置信度"
        } else if labubuRecognitionConfidence > 0.6 {
            return "中等置信度"
        } else {
            return "低置信度"
        }
    }
    
    /// 显示名称（优先使用识别结果的模型名称）
    var displayName: String {
        if let recognitionResult = aiRecognitionResult,
           let bestMatch = recognitionResult.bestMatch,
           recognitionResult.isSuccessful {
            return bestMatch.name
        }
        return name
    }
    
    /// 参考价格信息
    var referencePrice: String? {
        guard let recognitionResult = aiRecognitionResult,
              let bestMatch = recognitionResult.bestMatch,
              recognitionResult.isSuccessful else {
            return nil
        }
        
        // 构建价格显示字符串
        if let releasePrice = bestMatch.releasePrice,
           let referencePrice = bestMatch.referencePrice {
            return "发售价: ¥\(Int(releasePrice)) | 参考价: ¥\(Int(referencePrice))"
        } else if let releasePrice = bestMatch.releasePrice {
            return "发售价: ¥\(Int(releasePrice))"
        } else if let referencePrice = bestMatch.referencePrice {
            return "参考价: ¥\(Int(referencePrice))"
        }
        
        return nil
    }
} 