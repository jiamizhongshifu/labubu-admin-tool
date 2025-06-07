//
//  PhotoPreviewView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct PhotoPreviewView: View {
    let originalImage: UIImage
    @State private var processedImage: UIImage?
    @State private var showingOriginal = false
    @State private var isProcessing = false
    @State private var showingCrop = false
    @State private var showingNameInput = false
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
        ZStack {
            // 背景
            Color(.systemGray5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部区域
                HStack {
                    Text(dateFormatter.string(from: Date()))
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 识别整张图片按钮
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingOriginal.toggle()
                        }
                    }) {
                        Text(showingOriginal ? "点击识别主体" : "点击识别整张图片")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // 图片预览区域
                ZStack {
                    if isProcessing {
                        // 处理中状态
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("正在智能抠图...")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // 🎯 修复：强制使用ZStack和纯色背景，确保透明效果清晰可见
                        let displayImage = showingOriginal ? originalImage : (processedImage ?? originalImage)
                        
                        ZStack {
                            // 强制黑色背景，凸显透明效果
                            Color.black
                            
                            Image(uiImage: displayImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                
                Spacer()
                
                // 底部操作按钮
                HStack(spacing: 40) {
                    // 裁剪按钮
                    Button(action: {
                        showingCrop = true
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "crop")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("裁剪")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(isProcessing || (processedImage == nil && !showingOriginal))
                    
                    // 确认按钮
                    Button(action: {
                        if processedImage != nil || showingOriginal {
                            showingNameInput = true
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("确认")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .disabled(isProcessing)
                    
                    // 取消按钮
                    Button(action: {
                        dismiss()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.primary)
                            }
                            
                            Text("取消")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            processImage()
        }
        .sheet(isPresented: $showingCrop) {
            let imageToEdit = showingOriginal ? originalImage : (processedImage ?? originalImage)
            ImageCropView(image: imageToEdit) { croppedImage in
                if showingOriginal {
                    // 如果当前显示原图，裁剪后需要重新处理
                    processImage(from: croppedImage)
                } else {
                    // 如果当前显示处理后的图，直接更新
                    processedImage = croppedImage
                }
            }
        }
        .sheet(isPresented: $showingNameInput) {
            let finalImage = showingOriginal ? originalImage : (processedImage ?? originalImage)
            StickerNameInputView(
                originalImage: originalImage,
                processedImage: finalImage,
                initialName: .constant(""),
                selectedCategory: .constant("手办"),
                notes: .constant(""),
                categories: ["手办", "盲盒", "积木", "卡牌", "其他"]
            ) { name, category, notes in
                saveSticker(name: name, category: category, notes: notes, image: finalImage)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {
                if alertMessage.contains("保存成功") {
                    dismiss()
                }
            }
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
    
    private func saveSticker(name: String, category: String, notes: String, image: UIImage) {
        // 🎯 修复：在最终保存前，应用贴纸效果
        let finalImageWithEffect = ImageProcessor.shared.applyStickerEffect(
            to: image,
            style: .withShadow
        )
        
        let sticker = ToySticker(
            name: name,
            categoryName: category,
            originalImage: originalImage,
            processedImage: finalImageWithEffect,
            notes: notes
        )
        
        DataManager.shared.addToySticker(sticker)
        
        alertMessage = "贴纸保存成功！"
        showingAlert = true
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

#Preview {
    PhotoPreviewView(originalImage: UIImage(systemName: "photo")!)
} 