//
//  ToySticker.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import SwiftData
import UIKit

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
    
    init(name: String, categoryName: String, originalImage: UIImage, processedImage: UIImage, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryName = categoryName
        self.originalImageData = originalImage.jpegData(compressionQuality: 0.8) ?? Data()
        // 🎯 修复：使用PNG格式保存抠图结果，保持透明背景
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
    }
    
    var originalImage: UIImage? {
        return UIImage(data: originalImageData)
    }
    
    var processedImage: UIImage? {
        return UIImage(data: processedImageData)
    }
    
    /// 获取最终显示的图片（优先显示增强图片）
    var displayImage: UIImage? {
        if let enhancedData = enhancedImageData, !enhancedData.isEmpty {
            return UIImage(data: enhancedData)
        }
        return processedImage
    }
    
    /// 增强图片
    var enhancedImage: UIImage? {
        guard let data = enhancedImageData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - Enhancement Status Enum

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