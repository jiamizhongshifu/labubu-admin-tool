//
//  HomeView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import AVKit
import SwiftData

// 🎯 新增：定义应用的主要页面状态
enum AppState {
    case home
    case camera
    case collection(showSuccessToast: Bool = false) // 添加toast参数
}

struct HomeView: View {
    // 🎯 新增：使用 AppState 来管理当前页面
    @State private var appState: AppState = .home
    @State private var showingDatabaseResetAlert = false
    
    // 🎯 新增：Toast相关状态
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 🎯 新增：海盗对话气泡相关状态
    @State private var showPirateBubble = false
    @State private var bubbleTimer: Timer?
    
    // SwiftData环境
    @Environment(\.modelContext) private var modelContext
    
    // 视频相关状态
    @State private var videos: [VideoItem] = []
    @State private var selectedVideo: VideoItem?
    @State private var showingVideoDetail = false
    @State private var presetVideoURL: URL?
    @State private var customWallpaperURL: URL? // 🎯 新增：用户自定义的动态壁纸URL
    @State private var showingWallpaperOptions = false // 🎯 新增：显示壁纸选择选项
    
    var body: some View {
        ZStack {
            // 🎯 新增：根据 appState 切换页面
            Group {
                switch appState {
                case .home:
                    homeContentView
                case .camera:
                    CameraView(appState: $appState)
                case .collection(let showSuccessToast):
                    NavigationView {
                        CollectionView(showSuccessToast: showSuccessToast, appState: $appState)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationBarBackButtonHidden(true)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar(content: collectionToolbarContent)
                    }
                }
            }
            
            // 🎯 新增：Toast覆盖层
            if showToast {
                ToastView(message: toastMessage, isShowing: $showToast)
                    .zIndex(999)
            }
            
            // 🎯 新增：海盗对话气泡覆盖层
            if showPirateBubble {
                PirateBubbleView(isVisible: $showPirateBubble)
                    .zIndex(998)
            }
        }
        .onAppear {
            print("🏠 HomeView appeared, current appState: \(appState)")
            // 检查是否需要显示数据库重置提示
            checkForDatabaseReset()
        }
        .alert("数据库已更新", isPresented: $showingDatabaseResetAlert) {
            Button("确定") { }
        } message: {
            Text("为了支持新的AI增强功能，应用数据库已更新。之前的数据可能需要重新添加。")
        }
    }
    
    // 🎯 重构：全屏沉浸式首页内容
    private var homeContentView: some View {
        ZStack {
            // 全屏预设动态壁纸背景
            if let customWallpaperURL = customWallpaperURL {
                // 🎯 优先显示用户自定义的动态壁纸
                FullScreenVideoPlayerView(videoURL: customWallpaperURL)
                    .ignoresSafeArea(.all)
            } else if let presetVideoURL = presetVideoURL {
                // 🎯 备用显示预设动态壁纸
                FullScreenVideoPlayerView(videoURL: presetVideoURL)
                    .ignoresSafeArea(.all)
            } else {
                // 备用黑色背景
                Color.black
                    .ignoresSafeArea(.all)
            }
            
            // 主要内容区域
            VStack(spacing: 0) {
                // 顶部导航栏（透明背景）
                topNavigationBar
                
                // 中间内容区域
                if !videos.isEmpty {
                    // 视频墙内容
                    VideoWallView(
                        videos: videos,
                        onVideoTap: { video in
                            selectedVideo = video
                            showingVideoDetail = true
                        }
                    )
                    .background(Color.black.opacity(0.7))
                } else {
                    // 空白区域
                    Spacer()
                }
                
                // 🎯 新增：底部导航栏样式入口
                bottomActionButtons
            }
        }
        .onAppear {
            print("🎬 homeContentView appeared, loading videos...")
            loadVideos()
            startPirateBubbleTimer()
        }
        .onDisappear {
            stopPirateBubbleTimer()
        }
        .sheet(isPresented: $showingVideoDetail) {
            if let video = selectedVideo {
                VideoDetailView(
                    video: video,
                    onExportLivePhoto: {
                        exportVideoAsLivePhoto(video)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWallpaperOptions) {
            WallpaperSelectionView(
                videos: videos,
                currentWallpaperURL: customWallpaperURL ?? presetVideoURL,
                onWallpaperSelected: { videoURL in
                    setCustomWallpaper(videoURL)
                },
                onResetToDefault: {
                    resetToDefaultWallpaper()
                }
            )
        }
    }
    
    // 🎯 新增：简化的顶部导航栏（无背景色）
    private var topNavigationBar: some View {
        HStack {
            // 左上角：用户头像
            Button(action: {
                // 暂无点击事件
            }) {
                Image("UserAvatar")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
            }
            

            
            Spacer()
            
            // 右上角：功能图标组
            HStack(spacing: 16) {
                // 通知图标
                Button(action: {
                    // 暂无点击事件
                }) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                // 菜单图标
                Button(action: {
                    // 暂无点击事件
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                }
                
                // 🎯 壁纸设置按钮（仅在有用户视频时显示）
                if !videos.isEmpty {
                    Button(action: {
                        showingWallpaperOptions = true
                    }) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .background(.ultraThinMaterial, in: Circle())
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // 🎯 新增：底部导航栏样式入口
    private var bottomActionButtons: some View {
        HStack(spacing: 0) {
            // 我的图鉴
            NavigationBarItem(
                icon: "book.fill",
                title: "我的图鉴",
                action: {
                    appState = .collection()
                }
            )
            
            // 拍照收集
            NavigationBarItem(
                icon: "camera.fill",
                title: "拍照收集",
                action: {
                    appState = .camera
                }
            )
            
            // 即时通讯
            NavigationBarItem(
                icon: "message.fill",
                title: "即时通讯",
                action: {
                    showComingSoonToast("即时通讯功能")
                }
            )
            
            // 潮玩市场
            NavigationBarItem(
                icon: "storefront.fill",
                title: "潮玩市场",
                action: {
                    showComingSoonToast("潮玩市场功能")
                }
            )
        }
        .padding(.horizontal, 0)
        .padding(.bottom, 0) // 移除底部内边距，让导航栏更贴近底部
        .padding(.top, 20)
        .background(
            // 黑色透明度渐变背景 - 整体透明度70%
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.21),  // 0.3 * 0.7 = 0.21
                    Color.black.opacity(0.42),  // 0.6 * 0.7 = 0.42
                    Color.black.opacity(0.56)   // 0.8 * 0.7 = 0.56
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(.all, edges: .bottom)
        )
    }
    
    /// 加载视频列表
    private func loadVideos() {
        print("🔄 开始加载视频列表...")
        
        // 首先加载预设视频
        loadPresetVideo()
        
        // 🎯 加载保存的自定义壁纸设置
        loadCustomWallpaperSetting()
        
        // 从数据库加载所有有视频的贴纸
        let descriptor = FetchDescriptor<ToySticker>(
            predicate: #Predicate { sticker in
                sticker.videoGenerationStatusRaw == "completed" &&
                sticker.videoURL != nil
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        
        do {
            let stickers = try modelContext.fetch(descriptor)
            print("📊 找到 \(stickers.count) 个已完成的视频")
            
            // 转换为VideoItem
            let userVideos: [VideoItem] = stickers.compactMap { sticker in
                guard let bestURL = sticker.bestVideoURL else {
                    print("⚠️ 跳过无视频URL的贴纸: \(sticker.name)")
                    return nil
                }
                
                let isLocal = sticker.localVideoURL != nil
                print("\(isLocal ? "✅ 加载本地视频" : "🌐 加载云端视频"): \(sticker.name) - \(bestURL.absoluteString)")
                
                return VideoItem(
                    url: bestURL,
                    title: sticker.name,
                    createdAt: sticker.createdDate,
                    stickerID: sticker.id.uuidString
                )
            }
            
            videos = userVideos
            print("🎬 最终加载了 \(videos.count) 个用户视频")
        } catch {
            print("❌ 加载视频失败: \(error)")
            videos = []
        }
    }
    
    /// 加载预设的动态视频壁纸
    private func loadPresetVideo() {
        // 首先尝试从Bundle中获取
        if let bundleURL = Bundle.main.url(forResource: "7085_raw", withExtension: "MP4") {
            presetVideoURL = bundleURL
            print("✅ 从Bundle加载预设视频")
            return
        }
        
        // 如果Bundle中没有，尝试从Documents目录获取
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsPath.appendingPathComponent("7085_raw.MP4")
        
        if FileManager.default.fileExists(atPath: videoURL.path) {
            presetVideoURL = videoURL
            print("✅ 从Documents目录加载预设视频")
            return
        }
        
        // 最后尝试从项目根目录复制到Documents
        copyPresetVideoToDocuments()
    }
    
    /// 将预设视频复制到Documents目录
    private func copyPresetVideoToDocuments() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent("7085_raw.MP4")
        
        // 如果已经存在，直接使用
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            presetVideoURL = destinationURL
            print("✅ 使用Documents目录中的预设视频")
            return
        }
        
        // 尝试从项目根目录复制（开发环境）
        let projectRootPath = Bundle.main.bundlePath
        let sourceURL = URL(fileURLWithPath: projectRootPath)
            .deletingLastPathComponent()
            .appendingPathComponent("7085_raw.MP4")
        
        do {
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                presetVideoURL = destinationURL
                print("✅ 预设视频已复制到Documents目录")
            } else {
                print("⚠️ 未找到预设视频文件")
            }
        } catch {
            print("❌ 复制预设视频失败: \(error)")
        }
    }
    
    /// 导出视频为Live Photo
    private func exportVideoAsLivePhoto(_ video: VideoItem) {
        LivePhotoExporter.shared.exportLivePhoto(from: video.url) { result in
            switch result {
            case .success:
                // 显示成功提示
                print("Live Photo导出成功")
            case .failure(let error):
                // 显示错误提示
                print("Live Photo导出失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 检查数据库重置状态
    private func checkForDatabaseReset() {
        // 检查是否刚刚进行了数据库重置
        let userDefaults = UserDefaults.standard
        if userDefaults.bool(forKey: "database_was_reset") {
            showingDatabaseResetAlert = true
            userDefaults.set(false, forKey: "database_was_reset")
        }
    }
    
    /// 图鉴页面的工具栏内容
    @ToolbarContentBuilder
    private func collectionToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                appState = .home
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("首页")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.blue)
            }
        }
        
        ToolbarItem(placement: .principal) {
            Text("我的图鉴")
                .font(.headline)
                .fontWeight(.semibold)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                appState = .camera
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }
    
    /// 设置自定义动态壁纸
    private func setCustomWallpaper(_ videoURL: URL) {
        customWallpaperURL = videoURL
        
        // 保存到UserDefaults
        UserDefaults.standard.set(videoURL.absoluteString, forKey: "custom_wallpaper_url")
        
        print("✨ 设置自定义动态壁纸: \(videoURL.lastPathComponent)")
    }
    
    /// 重置为默认预设壁纸
    private func resetToDefaultWallpaper() {
        customWallpaperURL = nil
        
        // 从UserDefaults移除
        UserDefaults.standard.removeObject(forKey: "custom_wallpaper_url")
        
        print("🔄 重置为默认预设壁纸")
    }
    
    /// 加载保存的自定义壁纸设置
    private func loadCustomWallpaperSetting() {
        if let savedURLString = UserDefaults.standard.string(forKey: "custom_wallpaper_url"),
           let savedURL = URL(string: savedURLString),
           FileManager.default.fileExists(atPath: savedURL.path) {
            customWallpaperURL = savedURL
            print("📱 加载保存的自定义壁纸: \(savedURL.lastPathComponent)")
        }
    }
    
    // 🎯 新增：显示敬请期待Toast的方法
    private func showComingSoonToast(_ feature: String) {
        toastMessage = "\(feature)敬请期待"
        showToast = true
        
        // 2秒后自动隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    // 🎯 新增：启动海盗对话气泡定时器
    private func startPirateBubbleTimer() {
        // 停止现有定时器
        stopPirateBubbleTimer()
        
        // 创建新的定时器，每10秒触发一次
        bubbleTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            // 只在首页状态下显示气泡
            if case .home = appState, !showPirateBubble {
                showPirateBubble = true
            }
        }
        
        print("🏴‍☠️ 海盗对话气泡定时器已启动")
    }
    
    // 🎯 新增：停止海盗对话气泡定时器
    private func stopPirateBubbleTimer() {
        bubbleTimer?.invalidate()
        bubbleTimer = nil
        showPirateBubble = false
        print("🏴‍☠️ 海盗对话气泡定时器已停止")
    }
}

// MARK: - 底部导航栏项目组件
struct NavigationBarItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 图标
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(height: 28)
                
                // 文字标签
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 液态玻璃按钮组件
struct LiquidGlassButton: View {
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            // 内容层 - 纯文字，白色
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            // 液态玻璃效果背景
            LiquidGlassBackground()
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - 透视旋转扩展
extension View {
    func perspectiveRotation(angle: Double, axis: (x: CGFloat, y: CGFloat, z: CGFloat)) -> some View {
        self.rotation3DEffect(
            .degrees(angle),
            axis: axis,
            perspective: 0.5
        )
    }
}

// MARK: - 液态玻璃背景效果
struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            // 背景模糊层 (liquidGlass-effect) - 增加透明度
            RoundedRectangle(cornerRadius: 32)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
            
            // 色调层 (liquidGlass-tint) - 进一步降低不透明度
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // 光泽层 (liquidGlass-shine) - 保持边框光泽但降低强度
            RoundedRectangle(cornerRadius: 32)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            
            // 顶部高光 - 进一步减少高光强度
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
        }
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 6)
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 2)
        .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 0)
    }
}

// MARK: - Toast提示组件
struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.black.opacity(0.8))
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25))
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Spacer()
            }
            
            Spacer()
                .frame(height: 120) // 距离底部适当距离
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

#Preview {
    HomeView()
} 