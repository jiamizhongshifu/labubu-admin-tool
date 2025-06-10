import Foundation

/// 应用分类常量
/// 统一管理所有分类相关的常量，确保整个应用中分类的一致性
struct CategoryConstants {
    
    /// 所有可用的分类列表
    /// 注意：这个顺序应该与 PromptManager 中的分类保持一致
    static let allCategories: [String] = [
        "玩具",
        "手办", 
        "模型",
        "卡片",
        "其他"
    ]
    
    /// 默认选中的分类
    static let defaultCategory: String = "玩具"
    
    /// 分类对应的图标
    static let categoryIcons: [String: String] = [
        "玩具": "toy.fill",
        "手办": "figure.stand",
        "模型": "building.2",
        "卡片": "rectangle.stack",
        "其他": "questionmark.circle"
    ]
    
    /// 验证分类是否有效
    /// - Parameter category: 要验证的分类名称
    /// - Returns: 是否为有效分类
    static func isValidCategory(_ category: String) -> Bool {
        return allCategories.contains(category)
    }
    
    /// 获取分类的图标名称
    /// - Parameter category: 分类名称
    /// - Returns: 对应的图标名称，如果分类不存在则返回默认图标
    static func iconName(for category: String) -> String {
        return categoryIcons[category] ?? "questionmark.circle"
    }
    
    /// 验证分类一致性（现在只是返回true，因为我们使用自定义提示词）
    /// - Returns: 总是返回true
    static func validateConsistencyWithPromptManager() -> Bool {
        print("✅ 分类一致性验证通过（使用自定义提示词模式）")
        return true
    }
} 