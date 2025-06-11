//
//  PhotoPreviewView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct PhotoPreviewView: View {
    let originalImage: UIImage
    let onSaveSuccess: () -> Void
    let onCancel: () -> Void
    @State private var processedImage: UIImage?
    @State private var showingOriginal = false
    @State private var isProcessing = false
    @State private var showingNameInput = false
    @State private var showingConfirmation = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var visionService = VisionService.shared
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 底色 - 参考界面的优雅渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray4),
                        Color(.systemGray5),
                        Color(.systemGray6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Layer 1: The Image - 强制全屏填充
                let displayImage = showingOriginal ? originalImage : (processedImage ?? originalImage)
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .transition(.opacity.animation(.easeInOut))
                    .id(displayImage.hashValue)

                // Layer 2: Gradient overlays for UI readability - 更柔和的渐变
                VStack(spacing: 0) {
                    LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                    Spacer()
                    LinearGradient(colors: [.clear, .black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        .frame(height: 160)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Layer 3: Top UI Controls
                VStack {
                    // Top controls - 简洁的顶部设计
                    HStack {
                        Text(dateFormatter.string(from: Date()))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, geometry.safeAreaInsets.top + 30)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Layer 4: Center Processing State
                if isProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        
                        Text("正在智能抠图...")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Layer 5: Bottom Controls - 绝对居中定位
                HStack(spacing: 60) {
                    // 重拍按钮
                    VStack(spacing: 8) {
                        Button(action: {
                            onCancel()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "arrow.uturn.left")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("重拍")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    
                    // 确认按钮
                    VStack(spacing: 8) {
                        Button(action: { 
                            if processedImage != nil {
                                showingConfirmation = true
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        .disabled(isProcessing || processedImage == nil)
                        
                        Text("确认")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                    
                    // 取消按钮
                    VStack(spacing: 8) {
                        Button(action: { onCancel() }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("取消")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    }
                }
                .opacity(isProcessing ? 0.5 : 1.0)
                .disabled(isProcessing)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height - geometry.safeAreaInsets.bottom - 80
                )
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .statusBarHidden(true)
        .onAppear {
            if processedImage == nil {
                processImage()
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            if let processedImage = processedImage {
                StickerConfirmationView(
                    originalImage: originalImage,
                    processedImage: ImageProcessor.shared.cropToSquareAspectRatio(processedImage),
                    onRetake: {
                        showingConfirmation = false
                        onCancel()
                    },
                    onConfirm: { name, category, notes in
                        // 保存贴纸
                        let squareImage = ImageProcessor.shared.cropToSquareAspectRatio(processedImage)
                        let finalImageWithEffect = ImageProcessor.shared.applyStickerEffect(
                            to: squareImage,
                            style: .transparent
                        )
                        
                        let sticker = ToySticker(
                            name: name,
                            categoryName: category,
                            originalImage: originalImage,
                            processedImage: finalImageWithEffect,
                            notes: notes
                        )
                        
                        DataManager.shared.addToySticker(sticker)
                        
                        // 🎯 修复：直接触发跳转，不关闭任何页面，让CameraView统一处理
                        onSaveSuccess()
                    },
                    onCancel: {
                        showingConfirmation = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingNameInput) {
            let finalImage = showingOriginal ? originalImage : (processedImage ?? originalImage)
            StickerNameInputView(
                originalImage: originalImage,
                processedImage: finalImage,
                initialName: .constant(""),
                selectedCategory: .constant(CategoryConstants.defaultCategory),
                notes: .constant(""),
                categories: CategoryConstants.allCategories
            ) { name, category, notes in
                // 保存贴纸
                let squareImage = ImageProcessor.shared.cropToSquareAspectRatio(finalImage)
                let finalImageWithEffect = ImageProcessor.shared.applyStickerEffect(
                    to: squareImage,
                    style: .transparent
                )
                
                let sticker = ToySticker(
                    name: name,
                    categoryName: category,
                    originalImage: originalImage,
                    processedImage: finalImageWithEffect,
                    notes: notes
                )
                
                DataManager.shared.addToySticker(sticker)
                
                // 调用保存成功回调
                onSaveSuccess()
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }

    }
    
    private func processImage(from sourceImage: UIImage? = nil) {
        let imageToProcess = sourceImage ?? originalImage
        isProcessing = true
        
        Task {
            do {
                // 🎯 修复：在预览阶段，只显示纯粹的抠图结果，不加任何贴纸效果
                let backgroundRemovedImage = try await visionService.removeBackground(from: imageToProcess)
                
                await MainActor.run {
                    self.processedImage = backgroundRemovedImage
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.alertMessage = "图像处理失败: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }
    

}

// MARK: - 透明背景网格组件
struct TransparencyGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 12
            let lightGray = Color(.systemGray5)
            let darkGray = Color(.systemGray4)
            
            let rows = Int(ceil(size.height / squareSize))
            let cols = Int(ceil(size.width / squareSize))
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    let color = isEven ? lightGray : darkGray
                    
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - 贴纸确认页面
struct StickerConfirmationView: View {
    let originalImage: UIImage
    let processedImage: UIImage
    let onRetake: () -> Void
    let onConfirm: (String, String, String) -> Void
    let onCancel: () -> Void
    
    @State private var stickerName = ""
    @State private var selectedCategory = CategoryConstants.defaultCategory
    @State private var notes = ""
    @State private var isKeyboardVisible = false
    @State private var shouldNavigateToCollection = false
    
    let categories = CategoryConstants.allCategories
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray6),
                    Color(.systemGray5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 标题 - 减少顶部留白
                Text("添加信息")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.top, 2)
                    .padding(.bottom, 20)
                
                // 主体图片 - 增加上下留白
                Image(uiImage: processedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipped()
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                
                // 底部输入区域
                VStack(spacing: 16) {
                    // 分类选择
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    
                    // 名称输入
                    TextField("给你的潮玩起个名字", text: $stickerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    // 底部按钮 - 同一行布局
                    HStack(spacing: 16) {
                        // 取消按钮 - 简洁样式
                        Button(action: onCancel) {
                            Text("取消")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        
                        // 确认保存按钮
                        Button(action: {
                            let finalName = stickerName.isEmpty ? "未命名潮玩" : stickerName
                            onConfirm(finalName, selectedCategory, "")
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("确认保存")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40) // 底部安全区域
            }
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
}

#Preview {
    PhotoPreviewView(
        originalImage: UIImage(systemName: "photo")!,
        onSaveSuccess: {},
        onCancel: {}
    )
} 