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
    
    // SwiftData环境
    @Environment(\.modelContext) private var modelContext
    
    // 视频相关状态
    @State private var videos: [VideoItem] = []
    @State private var selectedVideo: VideoItem?
    @State private var showingVideoDetail = false
    @State private var showingVideoTest = false
    
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
    
    // 🎯 新增：重构后的首页内容 - 以视频展示为主
    private var homeContentView: some View {
        NavigationView {
            ZStack {
                // 深色背景，突出视频内容
                Color.black.opacity(0.95)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部导航栏
                    HStack {
                        // Logo和标题
                        HStack(spacing: 12) {
                            Image(systemName: "play.rectangle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Jitata")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Text("潮玩动态图鉴")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            // 图鉴入口按钮
                            Button(action: {
                                appState = .collection()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 16))
                                    Text("我的图鉴")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // 测试入口按钮
                            Button(action: {
                                showingVideoTest = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "testtube.2")
                                        .font(.system(size: 16))
                                    Text("测试")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.3))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                                )
                            }
                            

                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Color.black.opacity(0.3)
                            .background(.ultraThinMaterial)
                    )
                    
                    // 视频内容区域
                    if videos.isEmpty {
                        // 空状态视图 - 只有在预设视频也无法加载时才显示
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: "video.slash")
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.3))
                            
                            VStack(spacing: 12) {
                                Text("暂无可用视频")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("开始创作您的第一个动态作品吧")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                appState = .collection()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                    Text("开始创作")
                                    Image(systemName: "arrow.right")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.white)
                                )
                            }
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        // 视频墙 - 显示用户视频和预设视频
                        VideoWallView(
                            videos: videos,
                            onVideoTap: { video in
                                selectedVideo = video
                                showingVideoDetail = true
                            }
                        )
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            print("🎬 homeContentView appeared, loading videos...")
            loadVideos()
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
        .sheet(isPresented: $showingVideoTest) {
            VideoTestView()
        }
    }
    
    /// 加载视频列表
    private func loadVideos() {
        print("🔄 开始加载视频列表...")
        
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
            var userVideos: [VideoItem] = stickers.compactMap { sticker in
                guard let videoURLString = sticker.videoURL,
                      let videoURL = URL(string: videoURLString) else { 
                    print("⚠️ 跳过无效视频URL的贴纸: \(sticker.name)")
                    return nil 
                }
                
                print("✅ 加载视频: \(sticker.name) - \(videoURLString)")
                return VideoItem(
                    url: videoURL,
                    title: sticker.name,
                    createdAt: sticker.createdDate,
                    stickerID: sticker.id.uuidString
                )
            }
            
            // 如果没有用户生成的视频，添加预设的动态视频壁纸
            if userVideos.isEmpty {
                if let presetVideo = loadPresetVideo() {
                    userVideos.append(presetVideo)
                    print("✨ 添加预设动态视频壁纸")
                }
            }
            
            videos = userVideos
            print("🎬 最终加载了 \(videos.count) 个视频")
        } catch {
            print("❌ 加载视频失败: \(error)")
            
            // 即使数据库加载失败，也尝试加载预设视频
            if let presetVideo = loadPresetVideo() {
                videos = [presetVideo]
                print("✨ 使用预设动态视频壁纸作为备用")
            }
        }
    }
    
    /// 加载预设的动态视频壁纸
    private func loadPresetVideo() -> VideoItem? {
        // 首先尝试从Bundle中获取
        if let bundleURL = Bundle.main.url(forResource: "7084_raw", withExtension: "MP4") {
            return VideoItem(
                url: bundleURL,
                title: "精选动态壁纸",
                createdAt: Date(),
                stickerID: "preset-wallpaper-7084"
            )
        }
        
        // 如果Bundle中没有，尝试从Documents目录获取
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videoURL = documentsPath.appendingPathComponent("7084_raw.MP4")
        
        if FileManager.default.fileExists(atPath: videoURL.path) {
            return VideoItem(
                url: videoURL,
                title: "精选动态壁纸",
                createdAt: Date(),
                stickerID: "preset-wallpaper-7084"
            )
        }
        
        // 最后尝试从项目根目录复制到Documents
        return copyPresetVideoToDocuments()
    }
    
    /// 将预设视频复制到Documents目录
    private func copyPresetVideoToDocuments() -> VideoItem? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsPath.appendingPathComponent("7084_raw.MP4")
        
        // 如果已经存在，直接返回
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return VideoItem(
                url: destinationURL,
                title: "精选动态壁纸",
                createdAt: Date(),
                stickerID: "preset-wallpaper-7084"
            )
        }
        
        // 尝试从项目根目录复制（开发环境）
        let projectRootPath = Bundle.main.bundlePath
        let sourceURL = URL(fileURLWithPath: projectRootPath)
            .deletingLastPathComponent()
            .appendingPathComponent("7084_raw.MP4")
        
        do {
            if FileManager.default.fileExists(atPath: sourceURL.path) {
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                print("✅ 预设视频已复制到Documents目录")
                return VideoItem(
                    url: destinationURL,
                    title: "精选动态壁纸",
                    createdAt: Date(),
                    stickerID: "preset-wallpaper-7084"
                )
            }
        } catch {
            print("❌ 复制预设视频失败: \(error)")
        }
        
        return nil
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
}

#Preview {
    HomeView()
} 