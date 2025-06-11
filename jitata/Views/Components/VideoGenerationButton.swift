import SwiftUI

/// 视频生成按钮
struct VideoGenerationButton: View {
    let sticker: ToySticker
    @Environment(\.modelContext) private var modelContext
    
    @State private var showPromptInput = false
    @State private var showTemplates = false
    @State private var selectedPrompt = ""
    @State private var isGenerating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var generationProgress: Double = 0.0
    @State private var progressMessage = "准备生成..."
    
    var body: some View {
        Button(action: {
            if sticker.videoGenerationStatus == .none || sticker.videoGenerationStatus == .failed {
                showPromptInput = true
            }
        }) {
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: sticker.videoGenerationStatus.icon)
                        .font(.system(size: 18))
                }
                
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(buttonBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(isGenerating || sticker.videoGenerationStatus == .processing)
        .sheet(isPresented: $showPromptInput) {
            VideoPromptInputView(
                selectedPrompt: $selectedPrompt,
                showTemplates: $showTemplates,
                onGenerate: {
                    startVideoGeneration()
                }
            )
        }
        .alert("生成失败", isPresented: $showError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
        .overlay(
            Group {
                if isGenerating {
                    VStack(spacing: 12) {
                        Text(progressMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        ProgressView(value: generationProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .frame(width: 200)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                    .offset(y: -60)
                }
            }
        )
    }
    
    private var buttonTitle: String {
        switch sticker.videoGenerationStatus {
        case .none:
            return "生成动态壁纸"
        case .pending:
            return "等待生成"
        case .processing:
            return "生成中..."
        case .completed:
            return "已生成壁纸"
        case .failed:
            return "生成动态视频壁纸"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch sticker.videoGenerationStatus {
        case .none, .failed:
            return Color.purple
        case .pending, .processing:
            return Color.orange
        case .completed:
            return Color.green
        }
    }
    
    private func startVideoGeneration() {
        // 🎯 检查是否有AI增强图片的Supabase URL
        guard let enhancedImageURL = sticker.enhancedSupabaseImageURL else {
            errorMessage = "请先进行AI增强并等待上传完成"
            showError = true
            return
        }
        
        isGenerating = true
        generationProgress = 0.1
        progressMessage = "准备生成视频..."
        
        // 更新贴纸状态
        sticker.videoGenerationStatus = .processing
        sticker.videoGenerationPrompt = selectedPrompt
        sticker.videoGenerationProgress = 0.1
        sticker.videoGenerationMessage = progressMessage
        
        // 保存状态
        try? modelContext.save()
        
        // 🎯 使用AI增强图片的URL调用可灵API生成视频
        KlingAPIService.shared.generateVideoFromImage(
            imageURL: enhancedImageURL,
            prompt: selectedPrompt
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let taskId):
                    // 保存任务ID
                    sticker.videoTaskId = taskId
                    sticker.videoGenerationProgress = 0.3
                    progressMessage = "视频生成中，请稍候..."
                    try? modelContext.save()
                    
                    // 开始轮询任务状态
                    pollVideoGenerationStatus(taskId: taskId)
                    
                case .failure(let error):
                    isGenerating = false
                    sticker.videoGenerationStatus = .failed
                    errorMessage = error.localizedDescription
                    showError = true
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func pollVideoGenerationStatus(taskId: String) {
        KlingAPIService.shared.pollTaskUntilComplete(taskId: taskId) { result in
            DispatchQueue.main.async {
                isGenerating = false
                
                switch result {
                case .success(let videoURL):
                    // 保存视频URL
                    sticker.videoURL = videoURL
                    sticker.videoGenerationStatus = .completed
                    sticker.videoGenerationProgress = 0.9
                    sticker.videoGenerationMessage = "正在下载到本地..."
                    try? modelContext.save()
                    
                    // 🎯 自动下载视频到本地
                    downloadVideoToLocal(videoURL: videoURL)
                    
                case .failure(let error):
                    sticker.videoGenerationStatus = .failed
                    errorMessage = error.localizedDescription
                    showError = true
                    try? modelContext.save()
                }
            }
        }
    }
    
    // MARK: - 本地视频下载
    
    private func downloadVideoToLocal(videoURL: String) {
        let stickerID = sticker.id.uuidString
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let videosPath = documentsPath.appendingPathComponent("Videos")
        
        // 确保目录存在
        if !FileManager.default.fileExists(atPath: videosPath.path) {
            try? FileManager.default.createDirectory(at: videosPath, withIntermediateDirectories: true)
        }
        
        let localURL = videosPath.appendingPathComponent("video_\(stickerID).mp4")
        
        // 如果本地文件已存在，直接完成
        if FileManager.default.fileExists(atPath: localURL.path) {
            sticker.videoGenerationProgress = 1.0
            sticker.videoGenerationMessage = "视频已保存到本地"
            try? modelContext.save()
            return
        }
        
        guard let url = URL(string: videoURL) else {
            sticker.videoGenerationMessage = "视频下载失败：无效URL"
            try? modelContext.save()
            return
        }
        
        print("⬇️ 开始下载视频到本地: \(videoURL)")
        
        // 开始下载
        let task = URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 视频下载失败: \(error.localizedDescription)")
                    sticker.videoGenerationMessage = "视频下载失败"
                    try? modelContext.save()
                    return
                }
                
                guard let tempURL = tempURL else {
                    sticker.videoGenerationMessage = "视频下载失败：无数据"
                    try? modelContext.save()
                    return
                }
                
                do {
                    // 移动临时文件到目标位置
                    if FileManager.default.fileExists(atPath: localURL.path) {
                        try FileManager.default.removeItem(at: localURL)
                    }
                    try FileManager.default.moveItem(at: tempURL, to: localURL)
                    
                    print("✅ 视频下载完成: \(localURL.path)")
                    sticker.videoGenerationProgress = 1.0
                    sticker.videoGenerationMessage = "视频已保存到本地"
                    try? modelContext.save()
                } catch {
                    print("❌ 视频文件移动失败: \(error.localizedDescription)")
                    sticker.videoGenerationMessage = "视频保存失败"
                    try? modelContext.save()
                }
            }
        }
        
        task.resume()
    }
}

/// 视频提示词输入视图
struct VideoPromptInputView: View {
    @Binding var selectedPrompt: String
    @Binding var showTemplates: Bool
    let onGenerate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var customPrompt = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("描述视频效果")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 提示词输入框
                VStack(alignment: .leading, spacing: 8) {
                    Text("视频描述")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $customPrompt)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // 模板按钮
                Button(action: {
                    showTemplates = true
                }) {
                    HStack {
                        Image(systemName: "text.badge.star")
                        Text("使用模板")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
                
                // 模板列表
                if showTemplates {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(KlingConfig.videoPromptTemplates, id: \.self) { template in
                                Button(action: {
                                    customPrompt = template
                                    showTemplates = false
                                }) {
                                    Text(template)
                                        .font(.system(size: 14))
                                        .multilineTextAlignment(.leading)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
                
                // 生成按钮
                Button(action: {
                    selectedPrompt = customPrompt.isEmpty ? "潮玩在竖直画面中央缓缓旋转360度，背景简洁，适合手机壁纸" : customPrompt
                    dismiss()
                    onGenerate()
                }) {
                    Text("开始生成")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.purple)
                        )
                }
            }
            .padding()
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