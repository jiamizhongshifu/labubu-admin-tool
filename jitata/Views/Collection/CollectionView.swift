//
//  CollectionView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stickers: [ToySticker]
    @State private var showingCamera = false
    
    // 获取今日收集的贴纸
    var todayStickers: [ToySticker] {
        let today = Date()
        let calendar = Calendar.current
        return stickers.filter { sticker in
            calendar.isDate(sticker.createdDate, inSameDayAs: today)
        }.sorted { $0.createdDate > $1.createdDate }
    }
    
    // 获取所有贴纸（按创建时间倒序）
    var allStickers: [ToySticker] {
        return stickers.sorted { $0.createdDate > $1.createdDate }
    }
    
    // 双列网格配置
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            // 背景色
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部日期和数量信息
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTodayDate())
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(todayStickers.count)个潮玩")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // 潮玩网格展示
                if allStickers.isEmpty {
                    // 空状态
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        VStack(spacing: 8) {
                            Text("还没有收集任何潮玩")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("点击下方拍照按钮开始收集")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(allStickers) { sticker in
                                NavigationLink(destination: StickerDetailView(sticker: sticker)) {
                                    SimpleStickerCard(sticker: sticker)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120) // 为悬浮按钮留出空间
                    }
                }
            }
            
            // 悬浮拍照按钮
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingCamera = true
                    }) {
                        ZStack {
                            // 外圈渐变背景
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(.systemBlue),
                                            Color(.systemPurple)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            // 内圈图标
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView()
        }
    }
    
    // 格式化今日日期
    private func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: Date())
    }
}

// MARK: - 简洁贴纸卡片
struct SimpleStickerCard: View {
    let sticker: ToySticker
    
    var body: some View {
        VStack(spacing: 12) {
            // 贴纸图片 - 无背景无投影直接展示
            if let image = sticker.processedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // 加载失败占位符
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            
                            Text("加载失败")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
            
            // 贴纸名称
            Text(sticker.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    NavigationView {
        CollectionView()
    }
} 