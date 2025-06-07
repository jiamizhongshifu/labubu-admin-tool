//
//  StickerDetailView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct StickerDetailView: View {
    let sticker: ToySticker
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // 图片展示区域
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(height: 300)
                    
                    if let image = sticker.processedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 10)
                    } else {
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("图片加载失败")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 基本信息
                VStack(alignment: .leading, spacing: 16) {
                    
                    // 名称和收藏按钮
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sticker.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.blue)
                                Text(sticker.categoryName)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: toggleFavorite) {
                            Image(systemName: sticker.isFavorite ? "heart.fill" : "heart")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Divider()
                    
                    // 收集信息
                    InfoSection(title: "收集信息") {
                        InfoRow(label: "收集时间", value: formatDetailDate(sticker.createdDate))
                        InfoRow(label: "分类", value: sticker.categoryName)
                    }
                    
                    // 备注信息
                    if !sticker.notes.isEmpty {
                        InfoSection(title: "备注") {
                            Text(sticker.notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                        }
                    }
                    
                    Divider()
                    
                    // 操作按钮
                    VStack(spacing: 12) {
                        
                        // 编辑按钮
                        Button(action: { showingEditSheet = true }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("编辑")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // 分享按钮
                        Button(action: shareSticker) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // 删除按钮
                        Button(action: { showingDeleteAlert = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("删除")
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingEditSheet) {
            StickerEditView(sticker: sticker)
        }
        .alert("删除确认", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                deleteSticker()
            }
        } message: {
            Text("确定要删除这个潮玩贴纸吗？此操作无法撤销。")
        }
    }
    
    private func toggleFavorite() {
        // 这里需要实现收藏切换逻辑
        // 由于@Model的限制，实际实现需要通过环境对象
        print("切换收藏状态")
    }
    
    private func shareSticker() {
        // 实现分享功能
        guard let image = sticker.processedImage else { return }
        
        let activityController = UIActivityViewController(
            activityItems: [image, sticker.name],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func deleteSticker() {
        // 实现删除功能
        // 需要通过环境对象来删除
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 信息区域组件
struct InfoSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 编辑视图
struct StickerEditView: View {
    let sticker: ToySticker
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var categoryName: String
    @State private var notes: String
    
    init(sticker: ToySticker) {
        self.sticker = sticker
        self._name = State(initialValue: sticker.name)
        self._categoryName = State(initialValue: sticker.categoryName)
        self._notes = State(initialValue: sticker.notes)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("名称", text: $name)
                    TextField("分类", text: $categoryName)
                }
                
                Section("备注") {
                    TextField("备注信息", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑潮玩")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        // 实现保存逻辑
        // 需要通过环境对象来更新数据
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 辅助函数
private func formatDetailDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    formatter.locale = Locale(identifier: "zh_CN")
    return formatter.string(from: date)
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