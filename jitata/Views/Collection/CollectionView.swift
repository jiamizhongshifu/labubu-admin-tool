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
    @State private var showingStickerDetail: ToySticker?
    
    // 按日期和类别分组的贴纸
    private var groupedStickers: [Date: [ToySticker]] {
        let grouped = Dictionary(grouping: stickers.sorted(by: { $0.createdDate > $1.createdDate })) { (sticker) -> Date in
            return Calendar.current.startOfDay(for: sticker.createdDate)
        }
        return grouped
    }
    
    private var sortedDates: [Date] {
        groupedStickers.keys.sorted(by: >)
    }

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // 主滚动视图
            ScrollView {
                VStack(spacing: 24) {
                    if stickers.isEmpty {
                        // 空状态提示
                        VStack {
                            Image(systemName: "camera.macro")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.bottom, 20)
                            
                            Text("图鉴是空的")
                                .font(.title2)
                                .fontWeight(.medium)
                            
                            Text("快去拍摄你的第一个潮玩吧！")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .frame(height: 500)
                    } else {
                        ForEach(sortedDates, id: \.self) { date in
                            VStack(alignment: .leading, spacing: 12) {
                                GroupHeaderView(date: date)
                                
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120))], spacing: 16) {
                                    if let stickersForDate = groupedStickers[date] {
                                        ForEach(stickersForDate) { sticker in
                                            SimpleStickerCard(sticker: sticker)
                                                .onTapGesture {
                                                    self.showingStickerDetail = sticker
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(item: $showingStickerDetail) { sticker in
            NavigationView {
                StickerDetailView(sticker: sticker)
            }
        }
    }
}

// MARK: - 分组头部视图
struct GroupHeaderView: View {
    let date: Date
    
    // 获取当天的贴纸数量
    @Query private var stickers: [ToySticker]
    
    private var stickersOnDate: [ToySticker] {
        stickers.filter { Calendar.current.isDate($0.createdDate, inSameDayAs: date) }
    }
    
    var body: some View {
        HStack {
            // 日期显示 "MM月dd日"
            Text(date, formatter: dayFormatter)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            // 当天收集的总数
            Text("收集了 \(stickersOnDate.count) 件")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// 日期格式化器
private let dayFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "M月d日"
    return formatter
}()

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