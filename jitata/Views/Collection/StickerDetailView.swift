//
//  StickerDetailView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import SwiftData

struct StickerDetailView: View {
    let sticker: ToySticker
    @Environment(\.modelContext) private var modelContext
    @Environment(\.presentationMode) var presentationMode
    @Query private var allStickers: [ToySticker]
    
    @State private var selectedStickerIndex: Int = 0
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingSeriesView = false
    @State private var isRetryingEnhancement = false
    @State private var showingCustomPromptInput = false
    @State private var showingFullScreenImage = false
    @State private var showingFullScreen = false
    @State private var showingVideoDetail = false
    @State private var showingAIEnhancement = false
    @State private var showingAspectRatioSelection = false
    @State private var selectedAspectRatio = KlingConfig.defaultAspectRatio
    @State private var showingBackgroundRemoval = false
    @State private var showingLabubuRecognition = false
    @State private var labubuRecognitionResult: LabubuRecognitionResult?
    @StateObject private var labubuService = LabubuRecognitionService.shared
    
    // 获取当天收集的贴纸（最新的在最左边）
    var todayStickers: [ToySticker] {
        let calendar = Calendar.current
        let stickers = allStickers.filter { otherSticker in
            calendar.isDate(otherSticker.createdDate, inSameDayAs: sticker.createdDate)
        }.sorted { $0.createdDate > $1.createdDate } // 改为降序排列，最新的在前
        
        return stickers
    }
    
    // 当前选中的贴纸
    var currentSticker: ToySticker {
        return todayStickers.indices.contains(selectedStickerIndex) ? todayStickers[selectedStickerIndex] : sticker
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 当天收集的潮玩小图横向滚动
                if todayStickers.count > 1 {
                    thumbnailScrollView
                }
                
                // 中间区域 - 大图展示和左右滑动
                mainImageTabView
                
                // 底部区域 - 潮玩信息和操作按钮
                bottomContentView
            }
            
            Spacer()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(formatDate(sticker.createdDate))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(todayStickers.count)个潮玩")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // 设置初始选中的贴纸索引
            if let index = todayStickers.firstIndex(where: { $0.id == sticker.id }) {
                selectedStickerIndex = index
            }
            
            // 从贴纸对象中读取用户之前选择的比例
            selectedAspectRatio = currentSticker.preferredAspectRatio
            
            // 🎬 监听视频重新生成通知
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("VideoRegenerationRequested"),
                object: nil,
                queue: .main
            ) { notification in
                if let userInfo = notification.userInfo,
                   let stickerID = userInfo["stickerID"] as? String,
                   stickerID == currentSticker.id.uuidString {
                    // 当前贴纸的视频被重新生成，刷新界面
                    print("🔄 收到视频重新生成通知，刷新界面")
                }
            }
        }
        .sheet(isPresented: $showingSeriesView) {
            SeriesInfoView(categoryName: currentSticker.categoryName)
        }
        .sheet(isPresented: $showingCustomPromptInput) {
            CustomPromptInputView(
                sticker: currentSticker,
                onEnhance: { prompt in
                    Task {
                        await enhanceWithAI(prompt: prompt, aspectRatio: selectedAspectRatio)
                    }
                }
            )
        }
        .sheet(isPresented: $showingAspectRatioSelection) {
            AspectRatioSelectionView(
                selectedAspectRatio: $selectedAspectRatio,
                onConfirm: {
                    // 保存用户选择的比例到贴纸对象
                    currentSticker.preferredAspectRatio = selectedAspectRatio
                    showingCustomPromptInput = true
                }
            )
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(sticker: currentSticker, isPresented: $showingFullScreenImage)
        }
        .sheet(isPresented: $showingLabubuRecognition) {
            if let result = labubuRecognitionResult {
                LabubuFamilyTreeView(recognitionResult: result)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 触发AI增强
    private func triggerEnhancement(with prompt: String, using model: AIModel, aspectRatio: String = "1:1") {
        Task {
            isRetryingEnhancement = true
            
            // 设置状态为处理中
            currentSticker.aiEnhancementStatus = .processing
            currentSticker.aiEnhancementMessage = "准备增强..."
            currentSticker.aiEnhancementProgress = 0.0
            
            _ = await ImageEnhancementService.shared.enhanceImage(for: currentSticker, customPrompt: prompt, model: model, aspectRatio: aspectRatio)
            await MainActor.run {
                isRetryingEnhancement = false
            }
        }
    }
    
    /// 获取增强按钮文字
    private func getEnhancementButtonText() -> String {
        if isRetryingEnhancement {
            return "AI增强中..."
        }
        
        switch currentSticker.aiEnhancementStatus {
        case .pending:
            return "AI增强"
        case .processing:
            return "增强中..."
        case .completed:
            return "重新增强"
        case .failed:
            return "重试增强"
        }
    }
    
    /// 获取增强按钮颜色
    private func getEnhancementButtonColors() -> [Color] {
        switch currentSticker.aiEnhancementStatus {
        case .pending:
            return [Color.blue, Color.purple]
        case .processing:
            return [Color.gray, Color.gray.opacity(0.8)]
        case .completed:
            return [Color.green, Color.teal]
        case .failed:
            return [Color.orange, Color.red]
        }
    }
    
    // MARK: - 子视图
    
    private var thumbnailScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(todayStickers.enumerated()), id: \.element.id) { index, daySticker in
                        ThumbnailView(
                            sticker: daySticker,
                            isSelected: index == selectedStickerIndex
                        )
                        .id(index)
                        .onTapGesture {
                            HapticFeedbackManager.shared.lightTap()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedStickerIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .onChange(of: selectedStickerIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
    
    private var mainImageTabView: some View {
        TabView(selection: $selectedStickerIndex) {
            ForEach(Array(todayStickers.enumerated()), id: \.element.id) { index, daySticker in
                LargeImageView(sticker: daySticker) {
                    showingFullScreenImage = true
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 350)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var bottomContentView: some View {
        VStack(spacing: 16) {
            stickerInfoView
            storageStatusView
            imageToggleButton
            actionButtonsView
        }
    }
    
    private var stickerInfoView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(currentSticker.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                AIEnhancementStatusIndicator(sticker: currentSticker)
            }
            
            HStack {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.blue)
                    Text(currentSticker.categoryName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedbackManager.shared.lightTap()
                    showingSeriesView = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 12))
                        Text("查看系列")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
            
            if !currentSticker.notes.isEmpty {
                Text(currentSticker.notes)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var storageStatusView: some View {
        Group {
            if let storedURL = currentSticker.supabaseImageURL, !storedURL.isEmpty {
                HStack {
                    if storedURL.hasPrefix("file://") {
                        Image(systemName: "internaldrive.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        Text("图片已预存储到本地")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Image(systemName: "cloud.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("图片已预上传到云端")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(storedURL.hasPrefix("file://") ? .blue : .green)
                        .font(.system(size: 12))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
    
    @ViewBuilder
    private var imageToggleButton: some View {
        if currentSticker.hasEnhancedImage {
            Button(action: {
                HapticFeedbackManager.shared.lightTap()
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSticker.toggleImageDisplay()
                }
            }) {
                HStack {
                    Image(systemName: currentSticker.isShowingEnhancedImage ? "photo" : "sparkles")
                        .font(.system(size: 14, weight: .medium))
                    Text("当前显示：\(currentSticker.currentImageTypeDescription)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 12))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .transition(.opacity.combined(with: .scale))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            labubuRecognitionButtonView
            aiEnhancementButtonView
            aiEnhancementProgressView
            videoGenerationButtonView
            videoManagementView
        }
    }
    
    private var labubuRecognitionButtonView: some View {
        LabubuRecognitionButton(image: currentSticker.processedImage ?? UIImage()) { result in
            // 识别完成后的回调
            labubuRecognitionResult = result
            showingLabubuRecognition = true
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private var aiEnhancementButtonView: some View {
        if currentSticker.aiEnhancementStatus != .processing {
            Button(action: {
                HapticFeedbackManager.shared.lightTap()
                showingAspectRatioSelection = true
            }) {
                HStack {
                    if currentSticker.aiEnhancementStatus == .processing || isRetryingEnhancement {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: currentSticker.aiEnhancementStatus == .completed ? "sparkles" : "wand.and.stars")
                    }
                    Text(getEnhancementButtonText())
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: getEnhancementButtonColors()),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: getEnhancementButtonColors()[0].opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .disabled(currentSticker.aiEnhancementStatus == .processing || isRetryingEnhancement)
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var aiEnhancementProgressView: some View {
        if currentSticker.aiEnhancementStatus == .processing {
            VStack(spacing: 12) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text(currentSticker.aiEnhancementMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    ProgressView(value: currentSticker.aiEnhancementProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(y: 1.5)
                }
                .padding(.horizontal, 20)
                
                Button(action: {
                    HapticFeedbackManager.shared.lightTap()
                    cancelEnhancement()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("取消增强")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.red, Color.orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private var videoGenerationButtonView: some View {
        if let enhancedURL = currentSticker.enhancedSupabaseImageURL, !enhancedURL.isEmpty {
            let videoStatus = currentSticker.videoGenerationStatus
            if videoStatus == .none || videoStatus == .pending || videoStatus == .processing || videoStatus == .failed {
                VideoGenerationButton(sticker: currentSticker)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private var videoManagementView: some View {
        if currentSticker.videoGenerationStatus == .completed,
           let videoURL = currentSticker.videoURL, !videoURL.isEmpty {
            VideoManagementView(sticker: currentSticker)
                .padding(.horizontal, 20)
                .padding(.top, 8)
        }
    }
    
    /// 取消AI增强
    private func cancelEnhancement() {
        ImageEnhancementService.shared.cancelEnhancement(for: currentSticker)
        isRetryingEnhancement = false
    }
    
    /// 重试AI增强（保留原有方法以兼容）
    private func retryEnhancement() {
        // 使用默认提示词和模型重试，但使用用户选择的比例
        let defaultPrompt = PromptManager.shared.getDefaultPrompt()
        triggerEnhancement(with: defaultPrompt, using: .fluxKontext, aspectRatio: selectedAspectRatio)
    }
    
    /// 增强AI
    private func enhanceWithAI(prompt: String, aspectRatio: String) async {
        guard let enhancedData = await ImageEnhancementService.shared.enhanceImage(
            for: currentSticker,
            customPrompt: prompt,
            model: .fluxKontext,
            aspectRatio: aspectRatio
        ) else {
            return
        }
        
        // 保存增强后的图片数据
        await MainActor.run {
            currentSticker.enhancedImageData = enhancedData
            currentSticker.isShowingEnhancedImage = true
        }
    }
    
    /// 执行Labubu识别
    private func performLabubuRecognition() {
        guard let image = currentSticker.processedImage else { return }
        
        Task {
            do {
                // 使用新的AI识别服务
                let result = try await LabubuAIRecognitionService.shared.recognizeUserPhoto(image)
                
                await MainActor.run {
                    if result.isSuccessful {
                        // 保存识别结果到贴纸
                        currentSticker.labubuInfo = convertToOldFormat(result)
                        labubuRecognitionResult = convertToOldFormat(result)
                        showingLabubuRecognition = true
                    } else {
                        // 显示未识别提示
                        print("未识别为Labubu系列")
                    }
                }
            } catch {
                await MainActor.run {
                    print("Labubu AI识别失败: \(error)")
                    // 这里可以显示错误提示
                }
            }
        }
    }
    
    /// 将新的AI识别结果转换为旧格式（临时兼容方案）
    private func convertToOldFormat(_ aiResult: LabubuAIRecognitionResult) -> LabubuRecognitionResult? {
        // 由于LabubuRecognitionResult结构已简化，这里创建一个兼容的结果
        // 在实际应用中，应该统一使用新的AI识别结果格式
        return nil
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 缩略图组件
struct ThumbnailView: View {
    let sticker: ToySticker
    let isSelected: Bool
    
    var body: some View {
        // 图片 - 优先显示增强图片
        Group {
            if let image = sticker.displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
            } else {
                // 加载失败时的占位符，使用半透明圆形背景
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    )
            }
        }
        .opacity(isSelected ? 1.0 : 0.6) // 选中状态100%透明度，未选中60%透明度
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 大图展示组件
struct LargeImageView: View {
    let sticker: ToySticker
    let onTap: () -> Void
    
    var body: some View {
        // 优先显示增强图片
        if let image = sticker.displayImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 320)
                .onTapGesture {
                    onTap()
                }
        } else {
            // 加载失败时的占位符，使用半透明背景
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6).opacity(0.3))
                .frame(height: 320)
                .overlay(
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("图片加载失败")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
}

// MARK: - 系列信息视图
struct SeriesInfoView: View {
    let categoryName: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 占位内容
                    VStack(spacing: 20) {
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("\(categoryName)系列")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("系列信息功能开发中...")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text("这里将显示该潮玩系列的详细信息、相关产品和收集进度等内容。")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationTitle("系列信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        let sampleImage = UIImage(systemName: "figure.stand") ?? UIImage()
        let sampleSticker = ToySticker(
            name: "示例手办",
            categoryName: "手办",
            originalImage: sampleImage,
            processedImage: sampleImage,
            notes: "这是一个非常精美的手办模型，制作工艺精良，颜色鲜艳，是收藏的好选择。"
        )
        
        StickerDetailView(sticker: sampleSticker)
    }
} 