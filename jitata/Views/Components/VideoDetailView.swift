import SwiftUI
import AVKit

/// 视频详情视图
struct VideoDetailView: View {
    let video: VideoItem
    let onExportLivePhoto: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var showExportSuccess = false
    @State private var showExportError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 视频播放器 - 9:16竖屏比例
                    VideoPlayerView(videoURL: video.url)
                        .aspectRatio(9/16, contentMode: .fit)
                        .cornerRadius(20)
                        .padding()
                    
                    // 视频信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text(video.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text(video.createdAt, style: .date)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // 导出按钮
                        Button(action: handleExportLivePhoto) {
                            HStack(spacing: 12) {
                                if isExporting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "livephoto")
                                        .font(.system(size: 20))
                                }
                                
                                Text(isExporting ? "正在导出..." : "导出为 Live Photo")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                        }
                        .disabled(isExporting)
                        
                        Text("导出后可在相册中设置为动态壁纸")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .alert("导出成功", isPresented: $showExportSuccess) {
            Button("好的") { }
        } message: {
            Text("Live Photo 已保存到相册")
        }
        .alert("导出失败", isPresented: $showExportError) {
            Button("确定") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    /// 处理导出Live Photo
    private func handleExportLivePhoto() {
        isExporting = true
        
        LivePhotoExporter.shared.exportLivePhoto(from: video.url) { result in
            DispatchQueue.main.async {
                isExporting = false
                
                switch result {
                case .success:
                    showExportSuccess = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                    showExportError = true
                }
            }
        }
    }
} 