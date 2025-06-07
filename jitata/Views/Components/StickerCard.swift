//
//  StickerCard.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

// MARK: - 网格卡片
struct StickerGridCard: View {
    let sticker: ToySticker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 图片区域
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1, contentMode: .fit)
                
                if let image = sticker.processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.secondary)
                        Text("图片加载失败")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 收藏标识
                if sticker.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                                .background(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                )
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // 信息区域
            VStack(alignment: .leading, spacing: 4) {
                Text(sticker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(sticker.categoryName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formatDate(sticker.createdDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 列表卡片
struct StickerListCard: View {
    let sticker: ToySticker
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 60, height: 60)
                
                if let image = sticker.processedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            
            // 信息区域
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sticker.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if sticker.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Text(sticker.categoryName)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if !sticker.notes.isEmpty {
                    Text(sticker.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(sticker.createdDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 箭头指示
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - 辅助函数
private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    let calendar = Calendar.current
    let now = Date()
    
    // 检查是否是今天
    if calendar.isDate(date, inSameDayAs: now) {
        formatter.timeStyle = .short
        return "今天 " + formatter.string(from: date)
    }
    
    // 检查是否是昨天
    if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
       calendar.isDate(date, inSameDayAs: yesterday) {
        return "昨天"
    }
    
    // 检查是否在本周
    if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now),
       weekInterval.contains(date) {
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    // 其他情况显示短日期
        formatter.dateStyle = .short
        return formatter.string(from: date)
}

#Preview {
    VStack(spacing: 16) {
        // 创建示例数据用于预览
        let sampleImage = UIImage(systemName: "figure.stand") ?? UIImage()
        let sampleSticker = ToySticker(
            name: "示例手办",
            categoryName: "手办",
            originalImage: sampleImage,
            processedImage: sampleImage,
            notes: "这是一个示例手办的描述"
        )
        
        StickerGridCard(sticker: sampleSticker)
            .frame(width: 120)
        
        StickerListCard(sticker: sampleSticker)
    }
    .padding()
} 