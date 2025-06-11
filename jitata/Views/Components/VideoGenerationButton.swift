import SwiftUI
import SwiftData

/// 视频生成按钮
struct VideoGenerationButton: View {
    @Bindable var sticker: ToySticker
    @Environment(\.modelContext) private var modelContext
    
    @State private var isGenerating = false
    @State private var generationProgress: Double = 0.0
    @State private var progressMessage = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showPromptInput = false
    @State private var selectedPrompt = ""
    @State private var showCancelConfirmation = false
    
    var body: some View {
        VStack(spacing: 16) {
            mainButton
            
            if sticker.videoGenerationStatus == .processing {
                progressSection
            }
        }
        .sheet(isPresented: $showPromptInput) {
            promptInputSheet
        }
        .alert("取消视频生成", isPresented: $showCancelConfirmation) {
            Button("继续生成", role: .cancel) { }
            Button("确认取消", role: .destructive) {
                cancelVideoGeneration()
            }
        } message: {
            Text("确定要取消当前的视频生成吗？")
        }
        .alert("生成失败", isPresented: $showError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - 子视图组件
    
    private var mainButton: some View {
        Button(action: {
            if sticker.videoGenerationStatus == .processing {
                showCancelConfirmation = true
            } else {
                showPromptInput = true
            }
        }) {
            HStack {
                if sticker.videoGenerationStatus == .processing {
                    Image(systemName: "stop.circle.fill")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.white)
                }
                
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(buttonBackground)
            .cornerRadius(12)
            .shadow(color: buttonShadowColor, radius: 6, x: 0, y: 3)
        }
        .disabled(sticker.videoGenerationStatus == .processing && !canCancel)
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "video.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                
                Text(sticker.videoGenerationMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            ProgressView(value: sticker.videoGenerationProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 1.5)
        }
    }
    
    private var promptInputSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择视频生成提示词")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(videoPrompts, id: \.self) { prompt in
                        Button(action: {
                            selectedPrompt = prompt
                            showPromptInput = false
                            startVideoGeneration()
                        }) {
                            Text(prompt)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("视频生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showPromptInput = false
                    }
                }
            }
        }
    }
    
    // MARK: - 计算属性
    
    private var buttonTitle: String {
        switch sticker.videoGenerationStatus {
        case .processing:
            return "取消生成"
        case .completed:
            return "重新生成视频"
        case .failed:
            return "重试生成视频"
        default:
            return "生成动态视频"
        }
    }
    
    private var buttonBackground: LinearGradient {
        switch sticker.videoGenerationStatus {
        case .processing:
            return LinearGradient(
                gradient: Gradient(colors: [Color.red, Color.orange]),
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    private var buttonShadowColor: Color {
        switch sticker.videoGenerationStatus {
        case .processing:
            return Color.red.opacity(0.3)
        default:
            return Color.blue.opacity(0.3)
        }
    }
    
    private var canCancel: Bool {
        return sticker.videoGenerationStatus == .processing
    }
    
    private var videoPrompts: [String] {
        return [
            "轻柔摇摆",
            "缓慢旋转",
            "上下浮动",
            "左右摆动",
            "闪烁光芒",
            "渐变色彩"
        ]
    }
    
    // MARK: - 私有方法
    
    private func startVideoGeneration() {
        guard let enhancedImageURL = sticker.enhancedSupabaseImageURL else {
            errorMessage = "请先进行AI增强并等待上传完成"
            showError = true
            return
        }
        
        isGenerating = true
        generationProgress = 0.1
        progressMessage = "准备生成视频..."
        
        sticker.videoGenerationStatus = .processing
        sticker.videoGenerationPrompt = selectedPrompt
        sticker.videoGenerationProgress = 0.1
        sticker.videoGenerationMessage = progressMessage
        
        try? modelContext.save()
        
        detectImageAspectRatio(imageURL: enhancedImageURL) { aspectRatio in
            let finalAspectRatio = aspectRatio ?? "1:1"
            print("🎯 检测到图片比例: \(finalAspectRatio)")
            
            KlingAPIService.shared.generateVideoFromImage(
                imageURL: enhancedImageURL,
                prompt: selectedPrompt,
                aspectRatio: finalAspectRatio
            ) { result in
                DispatchQueue.main.async {
                    handleVideoGenerationResult(result)
                }
            }
        }
    }
    
    private func detectImageAspectRatio(imageURL: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: imageURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            let width = image.size.width
            let height = image.size.height
            let ratio = width / height
            
            let aspectRatio: String
            if abs(ratio - 1.0) < 0.1 {
                aspectRatio = "1:1"
            } else if ratio > 1.5 {
                aspectRatio = "16:9"
            } else if ratio < 0.7 {
                aspectRatio = "9:16"
            } else {
                aspectRatio = "1:1"
            }
            
            DispatchQueue.main.async {
                completion(aspectRatio)
            }
        }.resume()
    }
    
    private func handleVideoGenerationResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let videoURL):
            if let oldLocalURL = sticker.localVideoURL {
                try? FileManager.default.removeItem(at: oldLocalURL)
                print("🗑️ 已清理旧的本地视频文件")
            }
            
            sticker.videoURL = videoURL
            sticker.videoGenerationStatus = .completed
            sticker.videoGenerationProgress = 1.0
            sticker.videoGenerationMessage = "视频生成完成"
            try? modelContext.save()
            
            print("✅ 视频生成完成，URL: \(videoURL)")
            print("📝 新视频已保存到云端，可在详情页进行管理")
            
        case .failure(let error):
            sticker.videoGenerationStatus = .failed
            sticker.videoGenerationProgress = 0.0
            sticker.videoGenerationMessage = "生成失败: \(error.localizedDescription)"
            try? modelContext.save()
            
            errorMessage = error.localizedDescription
            showError = true
            print("❌ 视频生成失败: \(error)")
        }
        
        isGenerating = false
    }
    
    private func cancelVideoGeneration() {
        if let taskId = sticker.videoTaskId {
            KlingAPIService.shared.cancelTask(taskId: taskId)
        }
        
        sticker.videoGenerationStatus = .none
        sticker.videoGenerationProgress = 0.0
        sticker.videoGenerationMessage = ""
        sticker.videoTaskId = nil
        
        try? modelContext.save()
        
        isGenerating = false
        print("🚫 用户取消了视频生成")
    }
} 