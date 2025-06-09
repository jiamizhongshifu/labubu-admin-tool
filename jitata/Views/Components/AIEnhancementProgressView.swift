import SwiftUI

/// AI增强进度监控视图
struct AIEnhancementProgressView: View {
    @ObservedObject private var enhancementService = ImageEnhancementService.shared
    @State private var isVisible = false
    
    var body: some View {
        if enhancementService.isProcessing {
            VStack(spacing: 0) {
                Spacer()
                
                // 进度卡片
                VStack(spacing: 16) {
                    // 标题和关闭按钮
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI增强处理中")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if let stickerName = enhancementService.currentProcessingStickerName {
                                Text(stickerName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            enhancementService.cancelProcessing()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 进度条
                    VStack(spacing: 8) {
                        ProgressView(value: enhancementService.processingProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 2.0) // 让进度条更粗
                        
                        HStack {
                            Text(enhancementService.processingStatusDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(enhancementService.processingProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // AI图标动画
                    HStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .scaleEffect(isVisible ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isVisible)
                        
                        Text("AI正在分析和增强您的图片...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // 避免被底部导航栏遮挡
                
                Spacer()
            }
            .background(Color.black.opacity(0.3))
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
        }
    }
}

/// 简化版AI增强状态指示器（用于卡片上）
struct AIEnhancementStatusIndicator: View {
    let sticker: ToySticker
    @ObservedObject private var enhancementService = ImageEnhancementService.shared
    
    var body: some View {
        let status = sticker.currentEnhancementStatus
        let isCurrentlyProcessing = enhancementService.currentProcessingSticker?.id == sticker.id
        
        if status != .completed {
            HStack(spacing: 4) {
                // 图标
                if isCurrentlyProcessing && status == .processing {
                    // 当前正在处理的贴纸显示进度环
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .frame(width: 12, height: 12)
                        
                        Circle()
                            .trim(from: 0, to: enhancementService.processingProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: enhancementService.processingProgress)
                    }
                } else {
                    Image(systemName: status.icon)
                        .font(.system(size: 10, weight: .medium))
                }
                
                // 状态文字
                Text(isCurrentlyProcessing && status == .processing ? 
                     "\(Int(enhancementService.processingProgress * 100))%" : 
                     status.displayName)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(badgeBackgroundColor(for: status))
            )
            .foregroundColor(badgeTextColor(for: status))
        }
    }
    
    // 徽章背景颜色
    private func badgeBackgroundColor(for status: ToySticker.EnhancementStatus) -> Color {
        switch status {
        case .pending:
            return Color.orange.opacity(0.2)
        case .processing:
            return Color.blue.opacity(0.2)
        case .completed:
            return Color.green.opacity(0.2)
        case .failed:
            return Color.red.opacity(0.2)
        }
    }
    
    // 徽章文字颜色
    private func badgeTextColor(for status: ToySticker.EnhancementStatus) -> Color {
        switch status {
        case .pending:
            return Color.orange
        case .processing:
            return Color.blue
        case .completed:
            return Color.green
        case .failed:
            return Color.red
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        AIEnhancementProgressView()
    }
} 