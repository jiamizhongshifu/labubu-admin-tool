import Foundation
import UIKit
import SwiftData

/// AI增强测试辅助工具
/// 用于开发和调试AI增强功能
class AIEnhancementTestHelper {
    
    /// 创建测试用的ToySticker
    static func createTestSticker(name: String = "测试玩具", category: String = CategoryConstants.defaultCategory) -> ToySticker {
        // 创建一个简单的测试图片
        let testImage = createTestImage()
        
        return ToySticker(
            name: name,
            categoryName: category,
            originalImage: testImage,
            processedImage: testImage,
            notes: "这是一个用于测试AI增强功能的示例贴纸"
        )
    }
    
    /// 创建测试图片
    private static func createTestImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 绘制一个简单的圆形作为测试图片
            context.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
            
            // 添加一些文字
            let text = "TEST"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// 测试API配置状态
    static func testAPIConfiguration() -> (isConfigured: Bool, message: String) {
        let isConfigured = APIConfig.isAPIKeyConfigured
        let message = isConfigured ? 
            "✅ API密钥已配置，AI增强功能可用" : 
            "❌ API密钥未配置，请设置环境变量 OPENAI_API_KEY"
        
        return (isConfigured, message)
    }
    
    /// 测试提示词管理器
    static func testPromptManager() -> [String: String] {
        let categories = CategoryConstants.allCategories
        var results: [String: String] = [:]
        
        // 获取 PromptManager 实例
        let promptManager = PromptManager.shared
        
        for category in categories {
            let prompt = promptManager.getDefaultPrompt()
            results[category] = prompt
        }
        
        return results
    }
    
    /// 模拟AI增强流程（不实际调用API）
    static func simulateEnhancementFlow(for sticker: ToySticker, success: Bool = true) {
        // 模拟处理中状态
        sticker.updateEnhancementStatus(.processing)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if success {
                // 模拟成功：创建一个稍微不同的图片作为"增强"结果
                let enhancedImage = createEnhancedTestImage()
                sticker.setEnhancedImage(enhancedImage)
                // 获取 PromptManager 实例
                let promptManager = PromptManager.shared
                sticker.enhancementPrompt = promptManager.getDefaultPrompt()
            } else {
                // 模拟失败
                sticker.markEnhancementFailed()
            }
        }
    }
    
    /// 创建"增强"后的测试图片
    private static func createEnhancedTestImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 绘制一个渐变圆形作为"增强"后的图片
            let colors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
            
            context.cgContext.drawRadialGradient(
                gradient,
                startCenter: CGPoint(x: size.width/2, y: size.height/2),
                startRadius: 0,
                endCenter: CGPoint(x: size.width/2, y: size.height/2),
                endRadius: size.width/2,
                options: []
            )
            
            // 添加"增强"标识
            let text = "AI+"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.white
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    /// 打印调试信息
    static func printDebugInfo() {
        print("=== AI增强功能调试信息 ===")
        
        // API配置状态
        let (_, message) = testAPIConfiguration()
        print("API配置: \(message)")
        
        // 提示词测试
        print("\n提示词测试:")
        let prompts = testPromptManager()
        for (category, prompt) in prompts {
            print("- \(category): \(prompt.prefix(50))...")
        }
        
        // 服务状态
        print("\n服务状态:")
        print("- ImageEnhancementService: \(APIConfig.isAPIKeyConfigured ? "可用" : "不可用")")
        print("- OpenAIService: 已初始化")
        print("- PromptManager: 已初始化")
        
        print("========================")
    }
}

#if DEBUG
extension AIEnhancementTestHelper {
    /// 开发环境专用：重置所有贴纸的增强状态
    static func resetAllEnhancementStatus(in context: ModelContext) {
        let descriptor = FetchDescriptor<ToySticker>()
        
        do {
            let stickers = try context.fetch(descriptor)
            for sticker in stickers {
                sticker.updateEnhancementStatus(.pending)
                sticker.enhancedImageData = nil
                sticker.enhancementRetryCount = 0
                sticker.lastEnhancementAttempt = nil
                sticker.enhancementPrompt = nil
            }
            try context.save()
            print("✅ 已重置 \(stickers.count) 个贴纸的增强状态")
        } catch {
            print("❌ 重置增强状态失败: \(error)")
        }
    }
    
    /// 开发环境专用：批量创建测试贴纸
    static func createTestStickers(count: Int = 5, in context: ModelContext) {
        let categories = CategoryConstants.allCategories
        
        for i in 1...count {
            let category = categories.randomElement() ?? CategoryConstants.defaultCategory
            let sticker = createTestSticker(
                name: "测试\(category)\(i)",
                category: category
            )
            context.insert(sticker)
        }
        
        do {
            try context.save()
            print("✅ 已创建 \(count) 个测试贴纸")
        } catch {
            print("❌ 创建测试贴纸失败: \(error)")
        }
    }
}
#endif 