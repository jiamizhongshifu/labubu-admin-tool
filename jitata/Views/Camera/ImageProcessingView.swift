//
//  ImageProcessingView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct ImageProcessingView: View {
    let originalImage: UIImage
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var visionService = VisionService.shared
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingNameInput = false
    @State private var selectedCategory = "手办"
    @State private var stickerName = ""
    @State private var notes = ""
    @State private var selectedStyle: ImageProcessor.StickerStyle = .withShadow
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    let categories = ["手办", "盲盒", "积木", "卡牌", "其他"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                if isProcessing {
                    // 处理中状态
                    ProcessingView()
                } else {
                    // 图像对比展示
                    ImageComparisonView(
                        originalImage: originalImage,
                        processedImage: processedImage
                    )
                    
                    Spacer()
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        if processedImage != nil {
                            // 保存按钮
                            Button(action: { showingNameInput = true }) {
                                HStack {
                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    Text(isSaving ? "保存中..." : "添加到图鉴")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isSaving ? Color.gray : Color.blue)
                                .cornerRadius(12)
                            }
                            .disabled(isSaving)
                        }
                        
                        // 重新处理按钮
                        Button(action: {
                            if processedImage == nil {
                                processImage()
                            } else {
                                // 重新拍摄，回到拍摄页面
                                dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: processedImage == nil ? "arrow.clockwise" : "camera")
                                Text(processedImage == nil ? "开始处理" : "重新拍摄")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing || isSaving)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("智能抠图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            processImage()
        }
        .sheet(isPresented: $showingNameInput) {
            StickerNameInputView(
                originalImage: originalImage,
                processedImage: processedImage!,
                initialName: $stickerName,
                selectedCategory: $selectedCategory,
                notes: $notes,
                categories: categories
            ) { name, category, notes in
                saveSticker(name: name, category: category, notes: notes)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { 
                if alertMessage.contains("保存成功") {
                    // 保存成功后返回主页
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func processImage() {
        isProcessing = true
        
        Task {
            do {
                let backgroundRemovedImage = try await visionService.removeBackground(from: originalImage)
                // 预览阶段不添加任何滤镜效果，直接显示抠图结果
                
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
    
    private func saveSticker(name: String, category: String, notes: String) {
        guard let processedImage = processedImage else { return }
        
        isSaving = true
        
        // 🎯 新增：保存前先将图片裁剪为1:1比例，最小化留白区域
        let squareImage = ImageProcessor.shared.cropToSquareAspectRatio(processedImage)
        
        // 🎯 应用透明贴纸效果（无白色背景）
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
        
        // 使用DataManager统一管理数据
        DataManager.shared.addToySticker(sticker)
        
        // 模拟保存过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSaving = false
            self.alertMessage = "潮玩贴纸保存成功！已添加到你的图鉴中。"
            self.showingAlert = true
        }
    }
}

// MARK: - 处理中视图
struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("正在智能抠图...")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("使用AI技术自动移除背景")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 图像对比视图
struct ImageComparisonView: View {
    let originalImage: UIImage
    let processedImage: UIImage?
    
    var body: some View {
        VStack(spacing: 20) {
            // 原图
            VStack(spacing: 8) {
                Image(uiImage: originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                
                Text("原图")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 箭头
            Image(systemName: "arrow.down")
                .font(.title2)
                .foregroundColor(.blue)
            
            // 处理后 - 使用ZStack确保黑色背景不被任何父视图覆盖
            VStack(spacing: 8) {
                if let processedImage = processedImage {
                    // 🎯 使用ZStack强制黑色背景，彻底解决白色背景问题
                    ZStack {
                        // 强制黑色背景，不受任何父视图影响
                        Color.black
                            .frame(maxHeight: 270)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // 透明抠图结果
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 250)
                    }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 250)
                        .overlay(
                            VStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("处理中...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                Text("抠图结果")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - 透明背景视图
struct TransparentBackgroundView: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 12 // 更小的网格
            let rows = Int(size.height / squareSize) + 1
            let cols = Int(size.width / squareSize) + 1
            
            for row in 0..<rows {
                for col in 0..<cols {
                    let isEven = (row + col) % 2 == 0
                    // 使用经典的透明背景网格颜色
                    let color = isEven ? Color.white : Color.gray.opacity(0.3)
                    
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

// MARK: - 贴纸命名输入视图
struct StickerNameInputView: View {
    let originalImage: UIImage
    let processedImage: UIImage
    @Binding var initialName: String
    @Binding var selectedCategory: String
    @Binding var notes: String
    let categories: [String]
    let onSave: (String, String, String) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    
    var body: some View {
        NavigationView {
            // 🎯 彻底重构：用VStack替代Form，获得完全的背景控制权
            ScrollView {
                VStack(spacing: 24) {
                    // 预览图区域 - 使用ZStack确保黑色背景不被覆盖
                    VStack(spacing: 12) {
                        Text("预览效果")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ZStack {
                            // 强制黑色背景，不受任何父视图影响
                            Color.black
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // 透明抠图结果
                            Image(uiImage: processedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 120)
                        }
                    }
                    
                    // 基本信息区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("基本信息")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            // 名称输入
                            VStack(alignment: .leading, spacing: 6) {
                                Text("潮玩名称")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("给你的潮玩起个名字", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // 分类选择
                            VStack(alignment: .leading, spacing: 6) {
                                Text("分类")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Picker("分类", selection: $selectedCategory) {
                                    ForEach(categories, id: \.self) { category in
                                        Text(category).tag(category)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                    }
                    
                    // 备注区域
                    VStack(alignment: .leading, spacing: 16) {
                        Text("备注")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("添加一些备注信息")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("添加一些备注信息...", text: $notes, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground)) // 使用系统标准的分组背景色
            .navigationTitle("添加到图鉴")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        onSave(name, selectedCategory, notes)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            name = initialName
        }
    }
}

#Preview {
    let sampleImage = UIImage(systemName: "figure.stand") ?? UIImage()
    return ImageProcessingView(originalImage: sampleImage)
} 