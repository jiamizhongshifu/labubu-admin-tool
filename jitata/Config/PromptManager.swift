import Foundation

/// 提示词管理器
class PromptManager {
    static let shared = PromptManager()
    
    private init() {}
    
    // MARK: - 提示词模板
    
    /// 基础增强提示词
    private let baseEnhancementPrompt = """
    请分析这张图片中的主体物品，并为其创建一个精美的艺术化版本。要求：
    
    1. 保持物品的基本形状和特征
    2. 增强色彩饱和度和对比度
    3. 添加精美的光影效果
    4. 提升整体的艺术感和收藏价值
    5. 保持背景透明
    6. 风格要适合作为收藏品展示
    7. 输出的图片格式为png，比例为：1:1
    8. 注意画面的完整性，不要裁剪
    
    请生成一个高质量的艺术化版本，适合作为数字收藏品。
    """
    
    /// 分类特定的提示词
    private let categoryPrompts: [String: String] = [
        "玩具": """
        这是一个玩具物品。请创建一个精美的艺术化版本：
        - 增强玩具的可爱和趣味性
        - 添加柔和的光泽效果
        - 保持玩具的童趣特色
        - 提升色彩的鲜艳度
        - 保持背景透明
        - 添加适合的阴影和高光
        - 注意画面的完整性，不要裁剪
        - 输出的图片格式为png，比例为：1:1
        """,
        
        "手办": """
        这是一个手办收藏品。请创建一个精美的艺术化版本：
        - 增强手办的精致细节
        - 添加专业的展示光效
        - 提升材质的质感表现
        - 保持角色的特征和魅力
        - 保持背景透明
        - 注意画面的完整性，不要裁剪
        - 添加收藏级的视觉效果
        - 输出的图片格式为png，比例为：1:1
        """,
        
        "模型": """
        这是一个模型物品。请创建一个精美的艺术化版本：
        - 增强模型的精密感
        - 添加金属或塑料的质感
        - 提升细节的清晰度
        - 保持背景透明
        - 保持比例和结构的准确性
        - 添加专业的产品展示效果
        - 注意画面的完整性，不要裁剪
        - 输出的图片格式为png，比例为：1:1
        """,
        
        "卡片": """
        这是一张卡片。请创建一个精美的艺术化版本：
        - 增强卡片的光泽和质感
        - 提升图案和文字的清晰度
        - 添加适合的反光效果
        - 保持卡片的平整感
        - 保持背景透明
        - 增强整体的收藏价值感
        - 注意画面的完整性，不要裁剪
        - 输出的图片格式为png，比例为：1:1
        """,
        
        "其他": """
        这是一个收藏品。请创建一个精美的艺术化版本：
        - 分析物品特征并增强其独特性
        - 添加适合的光影效果
        - 提升整体的艺术感
        - 保持背景透明
        - 保持物品的原始特色
        - 将其放置在模型展示盒里
        - 注意画面的完整性，不要裁剪
        - 增加收藏展示的吸引力
        - 输出的图片格式为png，比例为：1:1
        """
    ]
    
    // MARK: - 公共方法
    
    /// 获取增强提示词
    /// - Parameter category: 物品分类
    /// - Returns: 完整的提示词
    func getEnhancementPrompt(for category: String?) -> String {
        // 如果有特定分类的提示词，使用分类提示词
        if let category = category,
           let categoryPrompt = categoryPrompts[category] {
            return categoryPrompt
        }
        
        // 否则使用基础提示词
        return baseEnhancementPrompt
    }
    
    /// 获取所有可用的分类
    var availableCategories: [String] {
        return Array(categoryPrompts.keys).sorted()
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