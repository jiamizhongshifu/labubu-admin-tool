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
                _ = await ImageEnhancementService.shared.enhanceImage(for: sticker, aspectRatio: sticker.preferredAspectRatio)
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
        // 根据用户偏好，不再显示增强提示
        EmptyView()
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

/// 图片比例选择视图
struct AspectRatioSelectionView: View {
    @Binding var selectedAspectRatio: String
    let onConfirm: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // 常见图片比例选项
    private let aspectRatios = [
        AspectRatioOption(ratio: "1:1", name: "正方形", description: "社交媒体头像"),
        AspectRatioOption(ratio: "4:3", name: "标准屏幕", description: "传统显示器"),
        AspectRatioOption(ratio: "3:4", name: "竖屏", description: "手机竖屏"),
        AspectRatioOption(ratio: "16:9", name: "宽屏", description: "电脑屏幕"),
        AspectRatioOption(ratio: "9:16", name: "手机竖屏", description: "手机壁纸"),
        AspectRatioOption(ratio: "3:2", name: "摄影比例", description: "相机照片"),
        AspectRatioOption(ratio: "2:3", name: "竖版摄影", description: "人像照片"),
        AspectRatioOption(ratio: "21:9", name: "超宽屏", description: "电影比例")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 标题说明
                VStack(spacing: 12) {
                    Text("选择图片比例")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("选择AI增强后的图片比例，不同比例适用于不同场景")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                
                // 比例选择列表
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(aspectRatios, id: \.ratio) { option in
                            AspectRatioCard(
                                option: option,
                                isSelected: selectedAspectRatio == option.ratio,
                                onTap: {
                                    selectedAspectRatio = option.ratio
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // 底部确认按钮
                VStack(spacing: 12) {
                    Button(action: {
                        onConfirm()
                        dismiss()
                    }) {
                        Text("确认选择")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    
                    Text("当前选择：\(aspectRatios.first(where: { $0.ratio == selectedAspectRatio })?.name ?? "未知")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 比例选项数据模型
struct AspectRatioOption {
    let ratio: String
    let name: String
    let description: String
}

/// 比例选择卡片
struct AspectRatioCard: View {
    let option: AspectRatioOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 比例预览框
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(height: 80)
                    
                    // 根据比例显示预览框
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.blue : Color(.systemGray3))
                        .frame(width: previewWidth, height: previewHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                        )
                }
                
                // 比例信息
                VStack(spacing: 4) {
                    Text(option.ratio)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? .blue : .primary)
                    
                    Text(option.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(option.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 计算预览框尺寸
    private var previewWidth: CGFloat {
        let components = option.ratio.split(separator: ":").compactMap { Double($0) }
        guard components.count == 2 else { return 40 }
        
        let ratio = components[0] / components[1]
        let maxSize: CGFloat = 50
        
        if ratio > 1 {
            return maxSize
        } else {
            return maxSize * ratio
        }
    }
    
    private var previewHeight: CGFloat {
        let components = option.ratio.split(separator: ":").compactMap { Double($0) }
        guard components.count == 2 else { return 40 }
        
        let ratio = components[0] / components[1]
        let maxSize: CGFloat = 50
        
        if ratio > 1 {
            return maxSize / ratio
        } else {
            return maxSize
        }
    }
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