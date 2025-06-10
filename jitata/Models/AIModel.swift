import Foundation

/// AI增强模型枚举
enum AIModel: String, CaseIterable, Identifiable {
    case fluxKontext = "flux-kontext-pro"
    case gpt4Vision = "gpt-4o-image-vip"
    
    var id: String { rawValue }
    
    /// 模型显示名称
    var displayName: String {
        switch self {
        case .fluxKontext:
            return "Flux-Kontext Pro"
        case .gpt4Vision:
            return "GPT-4 Vision"
        }
    }
    
    /// 模型描述
    var description: String {
        switch self {
        case .fluxKontext:
            return "专业图像增强模型，擅长保持原图细节"
        case .gpt4Vision:
            return "OpenAI视觉模型，擅长理解和增强图像"
        }
    }
    
    /// 模型图标
    var iconName: String {
        switch self {
        case .fluxKontext:
            return "wand.and.stars"
        case .gpt4Vision:
            return "brain.head.profile"
        }
    }
    
    /// 是否支持自定义参数
    var supportsCustomParameters: Bool {
        switch self {
        case .fluxKontext:
            return true
        case .gpt4Vision:
            return false
        }
    }
} 