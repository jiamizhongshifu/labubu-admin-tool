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
    
    private init() {}
    
    // MARK: - 主要方法
    
    /// 增强ToySticker的图片
    /// - Parameters:
    ///   - sticker: 要增强的贴纸
    ///   - modelContext: SwiftData模型上下文
    /// - Returns: 是否成功
    @MainActor
    func enhanceSticker(_ sticker: ToySticker, modelContext: ModelContext) async -> Bool {
        // 检查是否已经在处理中
        guard !isProcessing else {
            print("⚠️ AI增强服务忙碌中，跳过增强请求")
            return false
        }
        
        // 检查是否可以重试
        guard sticker.currentEnhancementStatus == .pending || sticker.canRetryEnhancement else {
            print("⚠️ 贴纸状态不允许增强: \(sticker.currentEnhancementStatus)")
            return false
        }
        
        // 获取要增强的图片
        guard let imageToEnhance = sticker.processedImage else {
            print("❌ 无法获取要增强的图片")
            sticker.markEnhancementFailed()
            try? modelContext.save()
            return false
        }
        
        print("🚀 开始AI增强处理: \(sticker.name)")
        
        // 更新状态为处理中
        sticker.updateEnhancementStatus(.processing)
        try? modelContext.save()
        
        // 更新服务状态
        isProcessing = true
        processingProgress = 0.0
        currentProcessingSticker = sticker
        processingStatusMessage = "正在连接AI服务..."
        
        do {
            // 步骤1: 准备请求 (20%)
            processingProgress = 0.2
            processingStatusMessage = "正在准备图片数据..."
            
            // 步骤2: 发送API请求 (40%)
            processingProgress = 0.4
            processingStatusMessage = "正在发送到AI服务器..."
            
            // 调用OpenAI API进行增强
            let enhancedImage = try await openAIService.enhanceImage(imageToEnhance, category: sticker.categoryName)
            
            // 步骤3: 处理响应 (80%)
            processingProgress = 0.8
            processingStatusMessage = "正在处理增强结果..."
            
            // 保存增强后的图片
            sticker.setEnhancedImage(enhancedImage)
            sticker.enhancementPrompt = PromptManager.shared.getEnhancementPrompt(for: sticker.categoryName)
            
            try? modelContext.save()
            
            // 步骤4: 完成 (100%)
            processingProgress = 1.0
            processingStatusMessage = "AI增强完成！"
            
            print("✅ AI增强成功完成: \(sticker.name)")
            
            // 发送成功通知
            sendEnhancementNotification(for: sticker, success: true)
            
            // 延迟重置状态，让用户看到完成状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetProcessingState()
            }
            
            return true
            
        } catch {
            print("❌ AI增强失败: \(error.localizedDescription)")
            print("   - 错误详情: \(error)")
            
            // 增强失败
            sticker.markEnhancementFailed()
            try? modelContext.save()
            
            processingStatusMessage = "增强失败: \(error.localizedDescription)"
            
            // 发送失败通知
            sendEnhancementNotification(for: sticker, success: false)
            
            // 延迟重置状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.resetProcessingState()
            }
            
            return false
        }
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
        return await enhanceSticker(sticker, modelContext: modelContext)
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
                let success = await enhanceSticker(sticker, modelContext: modelContext)
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