import SwiftUI
import AVKit

/// 视频管理视图 - 用于在图片详情页管理生成的视频
struct VideoManagementView: View {
    let sticker: ToySticker
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingDeleteAlert = false
    @State private var showingSetWallpaperAlert = false
    @State private var showingExportAlert = false
    @State private var showingRegenerateAlert = false
    @State private var isExportingLivePhoto = false
    @State private var exportMessage = ""
    @State private var showingVideoPlayer = false
    @State private var showingDetailedView = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 简洁的视频入口
            videoEntrySection
        }
        .alert("删除视频", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteVideo()
            }
        } message: {
            Text("确定要删除这个视频吗？删除后无法恢复。")
        }
        .alert("设为壁纸", isPresented: $showingSetWallpaperAlert) {
            Button("取消", role: .cancel) { }
            Button("确定") {
                setAsWallpaper()
            }
        } message: {
            Text("将此视频设为首页动态壁纸？")
        }
        .alert("重新生成视频", isPresented: $showingRegenerateAlert) {
            Button("取消", role: .cancel) { }
            Button("继续", role: .destructive) {
                regenerateVideo()
            }
        } message: {
            Text("重新生成将会替换当前视频，旧视频将被删除且无法恢复。确定要继续吗？")
        }
        .alert("导出结果", isPresented: $showingExportAlert) {
            Button("确定") { }
        } message: {
            Text(exportMessage)
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let videoURL = sticker.bestVideoURL {
                VideoPlayerDetailView(videoURL: videoURL, title: sticker.name)
            }
        }
        .sheet(isPresented: $showingDetailedView) {
            VideoManagementDetailView(
                sticker: sticker,
                showingDeleteAlert: $showingDeleteAlert,
                showingSetWallpaperAlert: $showingSetWallpaperAlert,
                showingExportAlert: $showingExportAlert,
                showingRegenerateAlert: $showingRegenerateAlert,
                isExportingLivePhoto: $isExportingLivePhoto,
                exportMessage: $exportMessage,
                showingVideoPlayer: $showingVideoPlayer,
                onDeleteVideo: deleteVideo,
                onSetAsWallpaper: setAsWallpaper,
                onExportLivePhoto: exportAsLivePhoto,
                onRegenerateVideo: { showingRegenerateAlert = true }
            )
        }
    }
    
    // MARK: - 简洁的视频入口区域
    private var videoEntrySection: some View {
        Button(action: {
            showingDetailedView = true
        }) {
            HStack(spacing: 12) {
                // 视频图标
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "video.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                }
                
                // 视频信息
                VStack(alignment: .leading, spacing: 2) {
                    Text("生成的动态视频")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        // 状态指示
                        HStack(spacing: 4) {
                            Image(systemName: sticker.videoGenerationStatus.icon)
                                .font(.system(size: 12))
                                .foregroundColor(statusColor)
                            Text(sticker.videoGenerationStatus.displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(statusColor)
                        }
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        // 存储位置
                        HStack(spacing: 4) {
                            Image(systemName: sticker.localVideoURL != nil ? "internaldrive.fill" : "cloud.fill")
                                .font(.system(size: 12))
                                .foregroundColor(sticker.localVideoURL != nil ? .blue : .green)
                            Text(sticker.localVideoURL != nil ? "本地" : "云端")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // 展开箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 计算属性
    private var statusColor: Color {
        switch sticker.videoGenerationStatus {
        case .none:
            return .secondary
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
    
    // MARK: - 私有方法
    
    /// 删除视频
    private func deleteVideo() {
        // 删除本地视频文件
        if let localURL = sticker.localVideoURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        // 清除数据库中的视频相关信息
        sticker.videoURL = nil
        sticker.videoTaskId = nil
        sticker.videoGenerationStatus = .none
        sticker.videoGenerationProgress = 0.0
        sticker.videoGenerationMessage = ""
        sticker.videoGenerationPrompt = nil
        
        // 保存更改
        try? modelContext.save()
        
        print("✅ 视频已删除: \(sticker.name)")
    }
    
    /// 设为首页壁纸
    private func setAsWallpaper() {
        guard let videoURL = sticker.bestVideoURL else { return }
        
        // 保存壁纸设置到UserDefaults
        UserDefaults.standard.set(videoURL.absoluteString, forKey: "custom_wallpaper_url")
        UserDefaults.standard.set(sticker.name, forKey: "custom_wallpaper_title")
        UserDefaults.standard.set(sticker.id.uuidString, forKey: "custom_wallpaper_sticker_id")
        
        // 发送通知更新首页壁纸
        NotificationCenter.default.post(name: NSNotification.Name("WallpaperChanged"), object: nil)
        
        print("✅ 已设为首页壁纸: \(sticker.name)")
    }
    
    /// 导出为Live Photo
    private func exportAsLivePhoto() {
        guard let videoURL = sticker.bestVideoURL else {
            exportMessage = "视频文件不存在"
            showingExportAlert = true
            return
        }
        
        isExportingLivePhoto = true
        
        LivePhotoExporter.shared.exportLivePhoto(from: videoURL) { result in
            DispatchQueue.main.async {
                isExportingLivePhoto = false
                
                switch result {
                case .success:
                    exportMessage = "Live Photo已成功保存到相册"
                case .failure(let error):
                    exportMessage = "导出失败: \(error.localizedDescription)"
                }
                
                showingExportAlert = true
            }
        }
    }
    
    /// 重新生成视频
    private func regenerateVideo() {
        // 清除当前视频相关数据
        if let localURL = sticker.localVideoURL {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        // 重置视频生成状态
        sticker.videoURL = nil
        sticker.videoTaskId = nil
        sticker.videoGenerationStatus = .pending
        sticker.videoGenerationProgress = 0.0
        sticker.videoGenerationMessage = "准备重新生成视频..."
        
        // 保存更改
        try? modelContext.save()
        
        print("🔄 开始重新生成视频: \(sticker.name)")
        
        // 发送通知，让详情页知道需要重新显示视频生成按钮
        NotificationCenter.default.post(
            name: NSNotification.Name("VideoRegenerationRequested"),
            object: nil,
            userInfo: ["stickerID": sticker.id.uuidString]
        )
        
        // 显示提示
        exportMessage = "已重置视频状态，请使用上方的生成按钮重新生成视频"
        showingExportAlert = true
    }
}

// MARK: - 详细视频管理视图
struct VideoManagementDetailView: View {
    let sticker: ToySticker
    @Binding var showingDeleteAlert: Bool
    @Binding var showingSetWallpaperAlert: Bool
    @Binding var showingExportAlert: Bool
    @Binding var showingRegenerateAlert: Bool
    @Binding var isExportingLivePhoto: Bool
    @Binding var exportMessage: String
    @Binding var showingVideoPlayer: Bool
    
    let onDeleteVideo: () -> Void
    let onSetAsWallpaper: () -> Void
    let onExportLivePhoto: () -> Void
    let onRegenerateVideo: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 视频预览区域
                videoPreviewSection
                
                // 视频信息
                videoInfoSection
                
                // 操作按钮区域
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("视频管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 视频预览区域
    private var videoPreviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundColor(.purple)
                Text("视频预览")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // 视频缩略图/播放按钮
            Button(action: {
                showingVideoPlayer = true
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                        .frame(height: 200)
                        .overlay(
                            // 如果有本地视频，显示视频预览
                            Group {
                                if let localURL = sticker.localVideoURL {
                                    VideoThumbnailView(videoURL: localURL)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    // 显示占位符
                                    VStack(spacing: 8) {
                                        Image(systemName: "video.circle")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("点击播放视频")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                        )
                    
                    // 播放按钮覆盖层
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    // MARK: - 视频信息区域
    private var videoInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("状态")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: sticker.videoGenerationStatus.icon)
                            .foregroundColor(statusColor)
                        Text(sticker.videoGenerationStatus.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("存储")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: sticker.localVideoURL != nil ? "internaldrive.fill" : "cloud.fill")
                            .foregroundColor(sticker.localVideoURL != nil ? .blue : .green)
                        Text(sticker.localVideoURL != nil ? "本地" : "云端")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            if let prompt = sticker.videoGenerationPrompt, !prompt.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("生成提示词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(prompt)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - 操作按钮区域
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // 第一行：播放和重新生成
            HStack(spacing: 12) {
                Button(action: {
                    showingVideoPlayer = true
                }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("播放视频")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    showingRegenerateAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("重新生成")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .cornerRadius(8)
                }
            }
            
            // 第二行：设为壁纸和导出Live Photo
            HStack(spacing: 12) {
                Button(action: {
                    showingSetWallpaperAlert = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("设为壁纸")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    onExportLivePhoto()
                }) {
                    HStack {
                        if isExportingLivePhoto {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "livephoto")
                        }
                        Text("导出Live Photo")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .disabled(isExportingLivePhoto)
            }
            
            // 第三行：删除视频
            HStack {
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("删除视频")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - 计算属性
    private var statusColor: Color {
        switch sticker.videoGenerationStatus {
        case .none:
            return .secondary
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

// MARK: - 视频缩略图视图
struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                await MainActor.run {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            } catch {
                print("❌ 生成视频缩略图失败: \(error)")
            }
        }
    }
}

// MARK: - 视频播放详情视图
struct VideoPlayerDetailView: View {
    let videoURL: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VideoPlayer(player: AVPlayer(url: videoURL))
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "figure.stand") ?? UIImage()
    let sampleSticker = ToySticker(
        name: "示例手办",
        categoryName: "手办",
        originalImage: sampleImage,
        processedImage: sampleImage
    )
    sampleSticker.videoGenerationStatus = .completed
    sampleSticker.videoURL = "https://example.com/video.mp4"
    
    return VideoManagementView(sticker: sampleSticker)
        .padding()
} 