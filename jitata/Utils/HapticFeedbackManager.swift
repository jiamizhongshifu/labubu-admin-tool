//
//  HapticFeedbackManager.swift
//  jitata
//
//  Created by AI Assistant on 2025/1/20.
//

import UIKit
import SwiftUI

/// 震动反馈管理器 - 统一使用轻微震动
class HapticFeedbackManager {
    static let shared = HapticFeedbackManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    
    private init() {
        // 预热生成器以减少延迟
        lightImpact.prepare()
    }
    
    /// 轻微点击震动反馈 - 用于所有点击事件
    func lightTap() {
        lightImpact.impactOccurred()
        // 重新预热以保持响应性
        lightImpact.prepare()
    }
}

/// SwiftUI View 扩展 - 便捷添加震动反馈
extension View {
    /// 为任何View添加轻微震动反馈
    func withHapticFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticFeedbackManager.shared.lightTap()
                }
        )
    }
} 