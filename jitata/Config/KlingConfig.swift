import Foundation

/// 可灵API配置
struct KlingConfig {
    /// 开发者预配置的API Token（用户无需配置）
    private static let apiToken = "sk-MVQo6gVtHAo79RUVDSAY9V390XsfdvWO3BA136v2iAM79CY1"
    
    /// 默认模型名称
    static let defaultModelName = "kling-v1"
    
    /// 默认生成模式
    static let defaultMode = "pro"
    
    /// 默认视频时长（秒）
    static let defaultDuration = 5
    
    /// 默认CFG强度
    static let defaultCFGScale = 0.5
    
    /// 默认宽高比 - 适合动态壁纸的竖屏比例
    static let defaultAspectRatio = "9:16"
    
    /// 默认负面提示词
    static let defaultNegativePrompt = "模糊, 低质量, 变形, 失真, 抖动, 噪点"
    
    /// 轮询间隔（秒）
    static let pollingInterval: TimeInterval = 5
    
    /// 最大重试次数
    static let maxRetries = 60
    
    /// 获取API Token（开发者预配置）
    static func getAPIToken() -> String? {
        return apiToken.isEmpty ? nil : apiToken
    }
    
    /// 检查API Token是否已配置
    static var isAPITokenConfigured: Bool {
        return !apiToken.isEmpty
    }
    
    /// 默认视频生成提示词模板 - 适合竖屏动态壁纸
    static let videoPromptTemplates = [
        "潮玩在竖直画面中央缓缓旋转360度，背景简洁，适合手机壁纸",
        "潮玩在竖屏构图中轻微摇摆，营造生动的动态壁纸效果",
        "镜头从上到下展示潮玩全貌，竖屏构图，背景虚化",
        "潮玩在竖直画面中闪烁发光，营造梦幻的手机壁纸氛围",
        "潮玩在竖屏中做出点头或摆手动作，适合动态锁屏",
        "竖屏展示潮玩特色部件动作，如关节活动或发光效果，背景纯净",
        "潮玩在竖直构图中上下轻微浮动，营造悬浮效果",
        "竖屏画面中潮玩缓慢呼吸般的缩放动作，适合息屏显示"
    ]
} 