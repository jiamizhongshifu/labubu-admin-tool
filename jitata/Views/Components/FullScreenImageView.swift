import SwiftUI

/// 全屏图片预览视图
struct FullScreenImageView: View {
    let sticker: ToySticker
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isSavingToPhotoLibrary = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    @State private var saveAlertTitle = ""
    @State private var showingImageSwitcher = false
    
    // 最小和最大缩放比例
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0
    
    var body: some View {
        ZStack {
            // 黑色背景
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    // 点击背景关闭预览
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // 图片内容
            GeometryReader { geometry in
                if let image = sticker.displayImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                // 缩放手势
                                MagnificationGesture()
                                    .onChanged { value in
                                        let newScale = lastScale * value
                                        scale = min(max(newScale, minScale), maxScale)
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        
                                        // 如果缩放小于最小值，重置到最小值
                                        if scale < minScale {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                scale = minScale
                                                offset = .zero
                                            }
                                            lastScale = minScale
                                            lastOffset = .zero
                                        }
                                    },
                                
                                // 拖拽手势
                                DragGesture()
                                    .onChanged { value in
                                        // 只有在放大状态下才允许拖拽
                                        if scale > minScale {
                                            let newOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            
                                            // 限制拖拽范围
                                            let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                                            let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                                            
                                            offset = CGSize(
                                                width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
                                                height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .onTapGesture(count: 2) {
                            // 双击缩放
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if scale > minScale {
                                    // 如果已经放大，则重置
                                    scale = minScale
                                    offset = .zero
                                    lastScale = minScale
                                    lastOffset = .zero
                                } else {
                                    // 如果是原始大小，则放大到2倍
                                    scale = 2.0
                                    lastScale = 2.0
                                }
                            }
                        }
                } else {
                    // 图片加载失败的占位符
                    VStack(spacing: 20) {
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("图片加载失败")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // 顶部工具栏
            VStack {
                HStack {
                    // 关闭按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 图片信息
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(sticker.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                        
                        if let image = sticker.displayImage {
                            Text("\(Int(image.size.width))×\(Int(image.size.height))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(color: .black.opacity(0.5), radius: 1)
                        }
                    }
                    
                    Spacer()
                    
                    // 图片切换按钮
                    if sticker.hasEnhancedImage {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sticker.toggleImageDisplay()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Image(systemName: sticker.isShowingEnhancedImage ? "sparkles" : "photo")
                                    .font(.system(size: 16, weight: .medium))
                                Text(sticker.isShowingEnhancedImage ? "AI" : "原图")
                                    .font(.system(size: 8, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    } else {
                        // 没有增强图片时显示占位符
                        VStack(spacing: 2) {
                            Image(systemName: "photo")
                                .font(.system(size: 16, weight: .medium))
                            Text("原图")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            
            // 底部工具栏
            VStack {
                Spacer()
                
                // 缩放提示
                if scale > minScale {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("\(Int(scale * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    .padding(.bottom, 8)
                }
                
                // 保存按钮区域
                if sticker.hasEnhancedImage {
                    // 有增强图片时显示选择保存按钮
                    HStack(spacing: 16) {
                        // 保存原图按钮
                        Button(action: {
                            saveImageToPhotoLibrary(saveEnhanced: false)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "photo.circle.fill")
                                    .font(.system(size: 24))
                                Text("保存原图")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 60)
                            .background(Color.blue.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .disabled(isSavingToPhotoLibrary)
                        
                        // 保存增强图按钮
                        Button(action: {
                            saveImageToPhotoLibrary(saveEnhanced: true)
                        }) {
                            VStack(spacing: 4) {
                                if isSavingToPhotoLibrary {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "sparkles.rectangle.stack.fill")
                                        .font(.system(size: 24))
                                }
                                Text(isSavingToPhotoLibrary ? "保存中" : "保存增强版")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 60)
                            .background(Color.green.opacity(0.8))
                            .cornerRadius(12)
                        }
                        .disabled(isSavingToPhotoLibrary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                } else {
                    // 没有增强图片时显示单个保存按钮
                    Button(action: {
                        saveImageToPhotoLibrary(saveEnhanced: false)
                    }) {
                        HStack(spacing: 8) {
                            if isSavingToPhotoLibrary {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18))
                            }
                            Text(isSavingToPhotoLibrary ? "保存中..." : "保存到相册")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 200)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(25)
                    }
                    .disabled(isSavingToPhotoLibrary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .statusBarHidden()
        .alert(saveAlertTitle, isPresented: $showingSaveAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    /// 保存图片到相册
    /// - Parameter saveEnhanced: true保存增强版，false保存原图
    private func saveImageToPhotoLibrary(saveEnhanced: Bool) {
        guard !isSavingToPhotoLibrary else { return }
        
        // 获取要保存的图片
        let imageToSave: UIImage?
        let imageDescription: String
        let imageSize: String
        
        if saveEnhanced && sticker.hasEnhancedImage {
            // 保存增强图片的高清版本
            if let enhancedData = sticker.enhancedImageData {
                imageToSave = UIImage(data: enhancedData)
                imageDescription = "AI增强版"
                imageSize = "(\(enhancedData.count / 1024)KB)"
            } else {
                imageToSave = sticker.processedImage
                imageDescription = "原图"
                imageSize = "(\(sticker.processedImageData.count / 1024)KB)"
            }
        } else {
            // 保存原图的高清版本
            imageToSave = sticker.processedImage
            imageDescription = "原图"
            imageSize = "(\(sticker.processedImageData.count / 1024)KB)"
        }
        
        guard let image = imageToSave else {
            saveAlertTitle = "保存失败"
            saveAlertMessage = "无法获取图片数据"
            showingSaveAlert = true
            return
        }
        
        // 确保图片方向正确并获取图片尺寸信息
        let correctedImage = image.orientationCorrected
        let imageDimensions = "\(Int(correctedImage.size.width))×\(Int(correctedImage.size.height))"
        
        isSavingToPhotoLibrary = true
        
        // 使用PhotoLibraryService保存图片
        PhotoLibraryService.shared.saveImageToPhotoLibrary(correctedImage) { success, errorMessage in
            DispatchQueue.main.async {
                isSavingToPhotoLibrary = false
                
                if success {
                    saveAlertTitle = "保存成功"
                    saveAlertMessage = "\(imageDescription)已保存到相册\n尺寸：\(imageDimensions) \(imageSize)"
                } else {
                    saveAlertTitle = "保存失败"
                    if let error = errorMessage, error.contains("权限") {
                        saveAlertMessage = "\(error)\n\n请在设置中允许访问相册"
                    } else {
                        saveAlertMessage = errorMessage ?? "未知错误"
                    }
                }
                
                showingSaveAlert = true
            }
        }
    }
}

#Preview {
    // 创建示例贴纸用于预览
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    let sampleSticker = ToySticker(
        name: "示例潮玩",
        categoryName: "手办",
        originalImage: sampleImage,
        processedImage: sampleImage
    )
    
    return FullScreenImageView(
        sticker: sampleSticker,
        isPresented: .constant(true)
    )
} 