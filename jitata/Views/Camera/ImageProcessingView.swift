//
//  ImageProcessingView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct ImageProcessingView: View {
    let originalImage: UIImage
    @Environment(\.presentationMode) var presentationMode
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
                                    Image(systemName: "plus.circle.fill")
                                    Text("添加到图鉴")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        
                        // 重新处理按钮
                        Button(action: {
                            if processedImage == nil {
                                processImage()
                            } else {
                                // 重新拍摄，回到拍摄页面
                                presentationMode.wrappedValue.dismiss()
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
                        .disabled(isProcessing)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("智能抠图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
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
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func processImage() {
        isProcessing = true
        
        Task {
            do {
                let backgroundRemovedImage = try await visionService.removeBackground(from: originalImage)
                // 直接应用默认的贴纸效果：白色描边和投影
                let styledImage = ImageProcessor.shared.applyStickerEffect(
                    to: backgroundRemovedImage,
                    style: .withShadow
                )
                
                await MainActor.run {
                    self.processedImage = styledImage
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
        
        let sticker = ToySticker(
            name: name,
            categoryName: category,
            originalImage: originalImage,
            processedImage: processedImage,
            notes: notes
        )
        
        // 使用DataManager统一管理数据
        DataManager.shared.addToySticker(sticker)
        presentationMode.wrappedValue.dismiss()
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
        HStack(spacing: 16) {
            // 原图
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                Text("原图")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 箭头
            Image(systemName: "arrow.right")
                .font(.title2)
                .foregroundColor(.blue)
            
            // 处理后
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                    
                    if let processedImage = processedImage {
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack {
                            Image(systemName: "wand.and.stars")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("处理中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("抠图结果")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
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
            Form {
                Section {
                    // 预览图
                    HStack {
                        Spacer()
                        Image(uiImage: processedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Spacer()
                    }
                }
                
                Section("基本信息") {
                    TextField("给你的潮玩起个名字", text: $name)
                    
                    Picker("分类", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("备注") {
                    TextField("添加一些备注信息...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
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