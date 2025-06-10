import SwiftUI

/// AI增强进度监控视图
struct AIEnhancementProgressView: View {
    @ObservedObject private var enhancementService = ImageEnhancementService.shared
    @State private var isVisible = false
    @Binding var isPresented: Bool
    let sticker: ToySticker // 直接传入贴纸对象
    
    @State private var compressedImage: UIImage?
    @State private var showImageComparison = false
    
    init(isPresented: Binding<Bool>, sticker: ToySticker) {
        self._isPresented = isPresented
        self.sticker = sticker
    }
    
    var body: some View {
        if isPresented {
            progressOverlay
        }
    }
    
    private var progressOverlay: some View {
        VStack(spacing: 0) {
            Spacer()
            progressCard
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
        .onReceive(NotificationCenter.default.publisher(for: .compressedImageReady)) { notification in
            handleCompressedImageNotification(notification)
        }
        .sheet(isPresented: $showImageComparison) {
            CompressionComparisonView(
                originalImage: UIImage(data: sticker.processedImageData),
                compressedImage: compressedImage
            )
        }
    }
    
    private var progressCard: some View {
        VStack(spacing: 16) {
            headerSection
            progressSection
            statusSection
            
            if compressedImage != nil {
                compressedImageButton
            }
            
            actionSection
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(sticker.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                isPresented = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: sticker.aiEnhancementProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                .scaleEffect(y: 2.0)
            
            HStack {
                Text(sticker.aiEnhancementMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(sticker.aiEnhancementProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor)
            }
        }
    }
    
    private var statusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(progressColor)
                .scaleEffect(isVisible && sticker.aiEnhancementStatus == .processing ? 1.2 : 1.0)
                .animation(sticker.aiEnhancementStatus == .processing ? 
                         .easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                         .default, value: isVisible)
            
            Text(statusDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var compressedImageButton: some View {
        Button("查看压缩后图像") {
            showImageComparison = true
        }
        .buttonStyle(.bordered)
        .foregroundColor(.blue)
    }
    
    private var actionSection: some View {
        Group {
            if sticker.aiEnhancementStatus == .processing {
                processingActions
            } else if sticker.aiEnhancementStatus == .failed {
                failedActions
            }
        }
    }
    
    private var processingActions: some View {
        VStack(spacing: 8) {
            Text("您可以关闭此窗口，增强将在后台继续进行")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button(action: {
                ImageEnhancementService.shared.cancelCurrentEnhancement()
                isPresented = false
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "stop.circle")
                    Text("终止增强")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red)
                .cornerRadius(8)
            }
        }
        .padding(.top, 8)
    }
    
    private var failedActions: some View {
        Button(action: {
            Task {
                _ = await ImageEnhancementService.shared.enhanceImage(for: sticker)
            }
            isPresented = false
        }) {
            Text("重试增强")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
        }
        .padding(.top, 8)
    }
    
    private func handleCompressedImageNotification(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let stickerId = userInfo["stickerId"] as? String,
           let imageData = userInfo["imageData"] as? Data,
           stickerId == sticker.id.uuidString {
            self.compressedImage = UIImage(data: imageData)
        }
    }
    
    // 计算属性
    private var titleText: String {
        switch sticker.aiEnhancementStatus {
        case .pending:
            return "等待AI增强"
        case .processing:
            return "AI增强处理中"
        case .completed:
            return "AI增强完成"
        case .failed:
            return "AI增强失败"
        }
    }
    
    private var statusIcon: String {
        switch sticker.aiEnhancementStatus {
        case .pending:
            return "clock"
        case .processing:
            return "brain.head.profile"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusDescription: String {
        switch sticker.aiEnhancementStatus {
        case .pending:
            return "等待开始AI增强处理..."
        case .processing:
            return "AI正在分析和增强您的图片..."
        case .completed:
            return "AI增强已完成，图片质量得到提升！"
        case .failed:
            return "AI增强处理失败，请检查网络连接后重试"
        }
    }
    
    private var progressColor: Color {
        switch sticker.aiEnhancementStatus {
        case .pending:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

/// 简化版AI增强状态指示器（用于卡片上）
struct AIEnhancementStatusIndicator: View {
    let sticker: ToySticker
    @ObservedObject private var enhancementService = ImageEnhancementService.shared
    @State private var showProgressView = false
    
    var body: some View {
        let status = sticker.aiEnhancementStatus
        let isCurrentlyProcessing = enhancementService.currentSticker?.id == sticker.id
        
        if status != .completed {
            Button(action: {
                // 点击徽章显示进度窗口（所有状态都可以点击）
                showProgressView = true
            }) {
                HStack(spacing: 4) {
                // 图标
                if isCurrentlyProcessing && status == .processing {
                    // 当前正在处理的贴纸显示进度环
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            .frame(width: 12, height: 12)
                        
                        Circle()
                            .trim(from: 0, to: sticker.aiEnhancementProgress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 12, height: 12)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: sticker.aiEnhancementProgress)
                    }
                } else {
                    Image(systemName: status.icon)
                        .font(.system(size: 10, weight: .medium))
                }
                
                // 状态文字
                Text(isCurrentlyProcessing && status == .processing ? 
                     "\(Int(sticker.aiEnhancementProgress * 100))%" : 
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
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showProgressView) {
                AIEnhancementProgressView(isPresented: $showProgressView, sticker: sticker)
            }
        }
    }
    
    // 徽章背景颜色
    private func badgeBackgroundColor(for status: AIEnhancementStatus) -> Color {
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
    private func badgeTextColor(for status: AIEnhancementStatus) -> Color {
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

// 新增：压缩图像对比视图
struct CompressionComparisonView: View {
    let originalImage: UIImage?
    let compressedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("图像压缩对比")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 原始图像
                    VStack {
                        Text("原始图像")
                            .font(.headline)
                        if let originalImage = originalImage {
                            Image(uiImage: originalImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .border(Color.gray, width: 1)
                            
                            Text("尺寸: \(Int(originalImage.size.width)) × \(Int(originalImage.size.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 压缩后图像
                    VStack {
                        Text("压缩后图像")
                            .font(.headline)
                        if let compressedImage = compressedImage {
                            Image(uiImage: compressedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .border(Color.blue, width: 1)
                            
                            Text("尺寸: \(Int(compressedImage.size.width)) × \(Int(compressedImage.size.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 压缩信息
                    if let originalImage = originalImage,
                       let compressedImage = compressedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("压缩详情")
                                .font(.headline)
                            
                            HStack {
                                Text("尺寸变化:")
                                Spacer()
                                Text("\(Int(originalImage.size.width))×\(Int(originalImage.size.height)) → \(Int(compressedImage.size.width))×\(Int(compressedImage.size.height))")
                            }
                            
                            let originalData = originalImage.jpegData(compressionQuality: 1.0) ?? Data()
                            let compressedData = compressedImage.jpegData(compressionQuality: 0.8) ?? Data()
                            let compressionRatio = originalData.count > 0 ? Double(compressedData.count) / Double(originalData.count) : 1.0
                            
                            HStack {
                                Text("压缩比:")
                                Spacer()
                                Text("\(String(format: "%.1f", compressionRatio * 100))% (\(formatFileSize(compressedData.count)) / \(formatFileSize(originalData.count)))")
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// 新增：通知扩展
extension Notification.Name {
    static let compressedImageReady = Notification.Name("compressedImageReady")
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        // 创建一个示例贴纸用于预览
        let sampleSticker = ToySticker(
            name: "示例潮玩",
            categoryName: "手办",
            originalImage: UIImage(systemName: "photo") ?? UIImage(),
            processedImage: UIImage(systemName: "photo") ?? UIImage()
        )
        
        AIEnhancementProgressView(isPresented: .constant(true), sticker: sampleSticker)
    }
} 