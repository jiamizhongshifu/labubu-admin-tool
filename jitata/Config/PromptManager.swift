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
        5. 风格要适合作为收藏品展示
        
        请生成一个高质量的艺术化版本，适合作为数字收藏品。
        """,
        
        // MARK: - 潮玩展示场景模板
        
        """
        🏪 潮玩店铺展示场景：
        将这个潮玩放置在精美的潮玩专卖店展示柜中，营造专业的零售展示氛围。要求：
        - 透明玻璃展示柜，带有柔和的LED灯光
        - 现代简约的店铺背景，略微虚化
        - 专业的产品展示灯光，突出潮玩细节
        - 保持潮玩原有特征和色彩
        - 添加高端零售店的质感
        - 背景保持透明或纯色
        """,
        
        """
        🎨 艺术画廊展示场景：
        将这个潮玩作为艺术品在现代画廊中展示。要求：
        - 简洁的白色展示台座
        - 专业的美术馆级别打光
        - 营造高雅的艺术氛围
        - 突出潮玩的艺术价值和设计美感
        - 增强材质质感和色彩层次
        - 保持背景简洁，突出主体
        - 适合作为艺术收藏品展示
        """,
        
        """
        🏠 家居收藏展示场景：
        将这个潮玩融入温馨的家居收藏展示环境。要求：
        - 木质或现代材质的收藏展示架
        - 温暖舒适的家居灯光氛围
        - 营造个人收藏空间的感觉
        - 保持潮玩的可爱和亲和力
        - 添加生活化的温馨质感
        - 背景可以有轻微的家居元素虚化
        - 适合日常欣赏和展示
        """,
        
        """
        🌟 未来科技展示场景：
        将这个潮玩置于充满科技感的未来展示环境中。要求：
        - 全息投影式的展示效果
        - 蓝色或紫色的科技光效
        - 几何形状的未来感展示台
        - 增强潮玩的科技质感
        - 添加微妙的发光边缘效果
        - 营造未来博物馆的氛围
        - 保持背景的科技感但不抢夺主体
        """,
        
        """
        🎪 主题乐园展示场景：
        将这个潮玩放置在梦幻的主题乐园商店展示区。要求：
        - 彩虹色彩的梦幻背景氛围
        - 游乐园式的欢快展示环境
        - 增强潮玩的趣味性和可爱感
        - 添加轻微的魔法光效
        - 营造童话般的展示氛围
        - 保持色彩鲜艳但和谐
        - 适合儿童和成人共同欣赏
        """,
        
        """
        🏆 限定收藏展示场景：
        将这个潮玩作为珍贵的限定版收藏品展示。要求：
        - 豪华的收藏展示盒或底座
        - 金色或银色的高端装饰元素
        - 专业的收藏品级别打光
        - 突出其稀有性和收藏价值
        - 增强材质的高级质感
        - 添加微妙的光泽和反射效果
        - 营造奢华的收藏品氛围
        """,
        
        """
        🌸 日式和风展示场景：
        将这个潮玩融入优雅的日式和风展示环境。要求：
        - 简约的日式木质展示台
        - 柔和的自然光线氛围
        - 营造禅意和宁静的感觉
        - 保持潮玩的精致和细腻
        - 添加温润的材质质感
        - 背景可有轻微的和风元素
        - 体现日式美学的简约与精致
        """,
        
        """
        🎮 电竞游戏展示场景：
        将这个潮玩置于炫酷的电竞游戏主题展示环境。要求：
        - RGB灯光效果的游戏氛围
        - 现代电竞风格的展示台
        - 增强潮玩的动感和活力
        - 添加轻微的电子光效
        - 营造年轻时尚的游戏文化氛围
        - 保持色彩鲜明但不过度
        - 适合游戏爱好者收藏展示
        """,
        
        """
        🌙 夜景氛围展示场景：
        将这个潮玩置于浪漫的夜景氛围中展示。要求：
        - 柔和的月光或星光效果
        - 深蓝色或紫色的夜空背景
        - 营造宁静神秘的夜晚氛围
        - 增强潮玩的轮廓和细节
        - 添加微妙的夜光效果
        - 保持梦幻而不失真实感
        - 适合营造浪漫收藏氛围
        """,
        
        """
        🌈 彩虹梦幻展示场景：
        将这个潮玩放置在充满彩虹色彩的梦幻世界中。要求：
        - 柔和的彩虹光谱背景
        - 云朵般的梦幻展示台
        - 增强潮玩的童趣和想象力
        - 添加闪烁的星星点点效果
        - 营造如梦如幻的童话氛围
        - 保持色彩丰富但不杂乱
        - 适合激发创意和想象
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