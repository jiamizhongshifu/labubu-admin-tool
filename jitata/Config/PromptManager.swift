import Foundation

/// 提示词管理器
class PromptManager {
    static let shared = PromptManager()
    
    private init() {
        // 私有初始化器，确保单例模式
    }
    
    // MARK: - 提示词模板
    
    /// 基础增强提示词
    private let baseEnhancementPrompt = """
    Enhance this object while preserving all original details, features, and characteristics. Keep the exact shape, proportions, and design elements. Improve color saturation, contrast, and material texture. Add appropriate lighting effects. Maintain transparent background. Output as high-quality PNG with 1:1 aspect ratio.
    """
    
    /// 默认提示词模板（用户可以参考）
    private let defaultPromptTemplates: [String] = [
        "Enhance this object while preserving all original details and features. Improve color vibrancy and material texture. Add subtle lighting effects. Maintain transparent background.",
        "Transform this into a high-quality artistic version while keeping all original characteristics. Enhance colors and add professional lighting.",
        "Create a premium enhanced version of this item. Improve material quality and add appropriate visual effects while preserving the original design.",
        """
请分析这张图片中的主体物品，并为其创建一个精美的艺术化版本。要求：

1. 保持物品的基本形状和特征
2. 增强色彩饱和度和对比度
3. 添加精美的光影效果
4. 提升整体的艺术感和收藏价值
5. 将其放置在模型展示盒里
6. 保持背景透明
7. 风格要适合作为收藏品展示

请生成一个高质量的艺术化版本，适合作为数字收藏品。
"""
    ]
    
    // MARK: - 公共方法
    
    /// 获取默认提示词模板
    /// - Returns: 默认提示词
    func getDefaultPrompt() -> String {
        return baseEnhancementPrompt
    }
    
    /// 获取提示词模板列表
    /// - Returns: 提示词模板数组
    func getPromptTemplates() -> [String] {
        return defaultPromptTemplates
    }
    
    /// 添加自定义提示词
    /// - Parameters:
    ///   - category: 分类名称
    ///   - prompt: 提示词内容
    func addCustomPrompt(for category: String, prompt: String) {
        // 注意：这里只是示例，实际应用中可能需要持久化存储
        // categoryPrompts[category] = prompt
        print("自定义提示词已添加：\(category)")
    }
    
    /// 验证提示词是否有效
    /// - Parameter prompt: 提示词
    /// - Returns: 是否有效
    func validatePrompt(_ prompt: String) -> Bool {
        return !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - 提示词模板结构

/// 提示词模板
struct PromptTemplate {
    let id: UUID
    let name: String
    let category: String
    let content: String
    let createdAt: Date
    let isCustom: Bool
    
    init(name: String, category: String, content: String, isCustom: Bool = false) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.content = content
        self.createdAt = Date()
        self.isCustom = isCustom
    }
} 