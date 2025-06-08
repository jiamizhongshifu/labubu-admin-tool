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
    
    // 获取当天收集的贴纸
    var todayStickers: [ToySticker] {
        let calendar = Calendar.current
        let stickers = allStickers.filter { otherSticker in
            calendar.isDate(otherSticker.createdDate, inSameDayAs: sticker.createdDate)
        }.sorted { $0.createdDate < $1.createdDate }
        
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(todayStickers.enumerated()), id: \.element.id) { index, daySticker in
                                ThumbnailView(
                                    sticker: daySticker,
                                    isSelected: index == selectedStickerIndex
                                )
                                .onTapGesture {
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
                }
                
                // 中间区域 - 大图展示和左右滑动
                TabView(selection: $selectedStickerIndex) {
                    ForEach(Array(todayStickers.enumerated()), id: \.element.id) { index, daySticker in
                        LargeImageView(sticker: daySticker)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 350)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // 底部区域 - 潮玩信息和查看系列按钮
                VStack(spacing: 16) {
                    // 潮玩基本信息
                    VStack(spacing: 12) {
                        Text(currentSticker.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.blue)
                            Text(currentSticker.categoryName)
                                .font(.subheadline)
                                .foregroundColor(.blue)
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
                    
                    // 查看系列按钮
                    Button(action: {
                        showingSeriesView = true
                    }) {
                        HStack {
                            Image(systemName: "cube.box.fill")
                            Text("查看系列")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding(.bottom, 40)
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
        }
        .sheet(isPresented: $showingSeriesView) {
            SeriesInfoView(categoryName: currentSticker.categoryName)
        }
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
        ZStack {
            // 选中状态的边框
            Circle()
                .stroke(
                    isSelected ? Color.blue : Color.clear,
                    lineWidth: 3
                )
                .frame(width: 70, height: 70)
            
            // 图片 - 移除背景，直接显示透明图片
            Group {
                if let image = sticker.processedImage {
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
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 大图展示组件
struct LargeImageView: View {
    let sticker: ToySticker
    
    var body: some View {
        // 直接显示图片，去除白色背景
        if let image = sticker.processedImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 320)
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