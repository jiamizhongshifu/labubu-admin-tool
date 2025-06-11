import SwiftUI
import AVKit
import AVFoundation

/// 全屏无控件的视频播放器视图（用于预设动态壁纸）
struct FullScreenVideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    
    var body: some View {
        FullScreenAVPlayerView(player: player)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
            }
            .allowsHitTesting(false) // 完全禁用点击交互
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.player = queuePlayer
        
        // 设置循环播放
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // 静音播放
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerLooper = nil
    }
}

/// 使用AVPlayerLayer的全屏视频播放器
struct FullScreenAVPlayerView: UIViewRepresentable {
    let player: AVQueuePlayer?
    
    func makeUIView(context: Context) -> FullScreenPlayerUIView {
        let view = FullScreenPlayerUIView()
        return view
    }
    
    func updateUIView(_ uiView: FullScreenPlayerUIView, context: Context) {
        uiView.setPlayer(player)
    }
    
    static func dismantleUIView(_ uiView: FullScreenPlayerUIView, coordinator: ()) {
        uiView.cleanup()
    }
}

/// 自定义UIView，专门用于全屏视频播放
class FullScreenPlayerUIView: UIView {
    private var playerLayer: AVPlayerLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPlayer(_ player: AVQueuePlayer?) {
        // 清除之前的layer
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        guard let player = player else { return }
        
        let newPlayerLayer = AVPlayerLayer(player: player)
        newPlayerLayer.videoGravity = .resizeAspectFill // 填充整个视图，保持宽高比
        newPlayerLayer.backgroundColor = UIColor.black.cgColor
        newPlayerLayer.frame = bounds
        
        layer.addSublayer(newPlayerLayer)
        self.playerLayer = newPlayerLayer
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 确保playerLayer始终填满整个视图
        playerLayer?.frame = bounds
    }
    
    func cleanup() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
}

/// 循环播放的视频播放器视图
struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVQueuePlayer?
    @State private var playerLooper: AVPlayerLooper?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                cleanupPlayer()
            }
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.player = queuePlayer
        
        // 设置循环播放
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // 静音播放（避免多个视频同时播放的声音混乱）
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        playerLooper = nil
    }
}

/// 带有覆盖层的视频卡片视图
struct VideoCardView: View {
    let videoURL: URL
    let title: String
    let date: Date
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // 视频播放器背景 - 适配9:16竖屏比例
            VideoPlayerView(videoURL: videoURL)
                .aspectRatio(9/16, contentMode: .fill)
                .clipped()
            
            // 渐变遮罩
            VStack {
                Spacer()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0),
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
            }
            
            // 信息覆盖层
            VStack {
                Spacer()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(date, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// 视频墙网格视图
struct VideoWallView: View {
    let videos: [VideoItem]
    let onVideoTap: (VideoItem) -> Void
    
    // 竖屏视频使用单列布局，更适合展示
    let columns = [
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(videos) { video in
                    VideoCardView(
                        videoURL: video.url,
                        title: video.title,
                        date: video.createdAt,
                        onTap: {
                            onVideoTap(video)
                        }
                    )
                    .frame(height: 400) // 增加高度以适配9:16竖屏比例
                }
            }
            .padding()
        }
    }
}

/// 视频数据模型
struct VideoItem: Identifiable {
    let id = UUID()
    let url: URL
    let title: String
    let createdAt: Date
    let stickerID: String
    
    // 用于存储Live Photo相关信息
    var livePhotoVideoURL: URL? {
        return url
    }
}

/// 壁纸选择视图
struct WallpaperSelectionView: View {
    let videos: [VideoItem]
    let currentWallpaperURL: URL?
    let onWallpaperSelected: (URL) -> Void
    let onResetToDefault: () -> Void
    let onDeleteVideo: (URL) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前壁纸预览
                if let currentWallpaperURL = currentWallpaperURL {
                    VStack(spacing: 12) {
                        Text("当前动态壁纸")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VideoPlayerView(videoURL: currentWallpaperURL)
                            .aspectRatio(9/16, contentMode: .fit)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Text("当前壁纸: \(currentWallpaperURL.lastPathComponent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                } else {
                    VStack(spacing: 12) {
                        Text("当前使用默认壁纸")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("未设置自定义动态壁纸")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                
                // 视频选择列表
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(videos) { video in
                            WallpaperOptionCard(
                                video: video,
                                isSelected: isVideoSelected(video),
                                onTap: {
                                    print("🎯 ForEach onTap 被触发")
                                    print("🎯 用户选择壁纸: \(video.title)")
                                    print("📱 壁纸URL: \(video.url.absoluteString)")
                                    print("📱 当前壁纸URL: \(currentWallpaperURL?.absoluteString ?? "无")")
                                    print("🔄 即将调用 onWallpaperSelected")
                                    onWallpaperSelected(video.url)
                                    print("✅ onWallpaperSelected 调用完成")
                                    print("🚪 即将关闭页面")
                                    dismiss()
                                },
                                onDelete: {
                                    print("🗑️ 用户删除壁纸: \(video.title)")
                                    onDeleteVideo(video.url)
                                    // 如果删除的是当前壁纸，重置为默认
                                    if video.url == currentWallpaperURL {
                                        onResetToDefault()
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                if videos.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("暂无可用的动态视频")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("请先生成一些动态视频")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                }
            }
            .navigationTitle("选择动态壁纸")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        print("🚫 用户取消壁纸选择")
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("恢复默认") {
                        print("🔄 用户点击恢复默认壁纸")
                        onResetToDefault()
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .onAppear {
            print("🎬 壁纸选择页面出现")
            print("📊 可选视频数量: \(videos.count)")
            print("📱 当前壁纸URL: \(currentWallpaperURL?.absoluteString ?? "无")")
        }
    }
    
    private func isVideoSelected(_ video: VideoItem) -> Bool {
        guard let currentURL = currentWallpaperURL else {
            return false
        }
        
        // 直接URL比较
        if video.url == currentURL {
            return true
        }
        
        // 字符串比较（处理可能的URL编码差异）
        if video.url.absoluteString == currentURL.absoluteString {
            return true
        }
        
        // 标准化URL比较（移除查询参数和片段）
        let videoBaseURL = video.url.baseURL ?? video.url
        let currentBaseURL = currentURL.baseURL ?? currentURL
        
        if videoBaseURL.absoluteString == currentBaseURL.absoluteString {
            return true
        }
        
        print("🔍 URL比较详情:")
        print("   视频URL: \(video.url.absoluteString)")
        print("   当前URL: \(currentURL.absoluteString)")
        print("   是否相等: false")
        
        return false
    }
}

/// 壁纸选项卡片
struct WallpaperOptionCard: View {
    let video: VideoItem
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // 视频预览
                VideoPlayerView(videoURL: video.url)
                    .aspectRatio(9/16, contentMode: .fill)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(true) // 禁用视频播放器交互
                
                // 选中状态覆盖层
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(height: 120)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .background(Color.white, in: Circle())
                                .padding(8)
                        }
                    }
                    .frame(height: 120)
                }
                
                // 删除按钮
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.red)
                                .background(Color.white, in: Circle())
                        }
                        .padding(8)
                    }
                    Spacer()
                }
                .frame(height: 120)
                
                // 点击区域
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 120)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("🎯 WallpaperOptionCard 点击区域被触发")
                        print("🎯 视频标题: \(video.title)")
                        onTap()
                    }
            }
            
            Text(video.title)
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .alert("删除壁纸", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("确定要删除这个动态壁纸吗？删除后无法恢复。")
        }
    }
}

/// 智能视频播放器 - 优先本地，备用云端
struct SmartVideoPlayerView: View {
    let sticker: ToySticker
    @State private var videoURL: URL?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let videoURL = videoURL {
                VideoPlayerView(videoURL: videoURL)
            } else if isLoading {
                ProgressView("加载视频...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            } else if let errorMessage = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                    
                    Text("暂无视频")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            }
        }
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        guard sticker.hasVideo else {
            isLoading = false
            return
        }
        
        let stickerID = sticker.id.uuidString
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosPath = documentsPath.appendingPathComponent("Videos")
        let localURL = videosPath.appendingPathComponent("video_\(stickerID).mp4")
        
        // 优先检查本地文件
        if FileManager.default.fileExists(atPath: localURL.path) {
            print("✅ 使用本地视频: \(localURL.path)")
            videoURL = localURL
            isLoading = false
            return
        }
        
        // 使用云端URL
        guard let cloudURLString = sticker.videoURL,
              let cloudURL = URL(string: cloudURLString) else {
            errorMessage = "无效的视频URL"
            isLoading = false
            return
        }
        
        print("🌐 使用云端视频: \(cloudURLString)")
        videoURL = cloudURL
        isLoading = false
        
        // 后台下载到本地（不阻塞播放）
        downloadVideoInBackground(cloudURL: cloudURLString, stickerID: stickerID)
    }
    
    private func downloadVideoInBackground(cloudURL: String, stickerID: String) {
        guard let url = URL(string: cloudURL) else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosPath = documentsPath.appendingPathComponent("Videos")
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: videosPath.path) {
            try? FileManager.default.createDirectory(at: videosPath, withIntermediateDirectories: true)
        }
        
        let localURL = videosPath.appendingPathComponent("video_\(stickerID).mp4")
        
        // 如果本地文件已存在，跳过下载
        if FileManager.default.fileExists(atPath: localURL.path) {
            return
        }
        
        print("⬇️ 后台下载视频到本地: \(cloudURL)")
        
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                print("❌ 后台下载失败: \(error.localizedDescription)")
                return
            }
            
            guard let tempURL = tempURL else {
                print("❌ 后台下载失败：无数据")
                return
            }
            
            do {
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                
                print("✅ 视频后台下载完成: \(localURL.path)")
                
                // 下次播放时将使用本地文件
            } catch {
                print("❌ 视频文件移动失败: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}
