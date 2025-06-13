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
    
    // 新增：toast相关状态
    let showSuccessToast: Bool
    @State private var isToastVisible = false
    
    // 新增：删除相关状态
    @State private var selectedStickerForDeletion: ToySticker?
    @State private var showingDeleteConfirmation = false
    @State private var editingStickerId: UUID?
    
    // 新增：导航状态
    @Binding var appState: AppState
    
    init(showSuccessToast: Bool = false, appState: Binding<AppState>) {
        self.showSuccessToast = showSuccessToast
        self._appState = appState
    }
    
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
    
    // 侧滑返回手势
    private var swipeBackGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                // 检测从左边缘向右滑动的手势
                let isFromLeftEdge = value.startLocation.x < 50
                let isRightSwipe = value.translation.width > 80
                let isHorizontalSwipe = abs(value.translation.width) > abs(value.translation.height)
                
                if isFromLeftEdge && isRightSwipe && isHorizontalSwipe {
                    // 添加触觉反馈
                    HapticFeedbackManager.shared.lightTap()
                    
                    // 侧滑返回到首页
                    withAnimation(.easeInOut(duration: 0.3)) {
                        appState = .home
                    }
                }
            }
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
            .onTapGesture {
                // 点击背景区域退出编辑模式
                if editingStickerId != nil {
                    editingStickerId = nil
                }
            }
            
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
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ], spacing: 30) {
                                    if let stickersForDate = groupedStickers[date] {
                                        ForEach(stickersForDate) { sticker in
                                            SimpleStickerCard(
                                                sticker: sticker,
                                                isEditing: editingStickerId == sticker.id,
                                                isInEditingMode: editingStickerId != nil,
                                                onDelete: {
                                                    selectedStickerForDeletion = sticker
                                                    showingDeleteConfirmation = true
                                                }
                                            )
                                            .onTapGesture {
                                                if editingStickerId == nil {
                                                    HapticFeedbackManager.shared.lightTap()
                                                    self.showingStickerDetail = sticker
                                                }
                                            }
                                            .onLongPressGesture {
                                                HapticFeedbackManager.shared.lightTap()
                                                if editingStickerId == sticker.id {
                                                    editingStickerId = nil
                                                } else {
                                                    editingStickerId = sticker.id
                                                }
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
            
            // Toast 提示
            if isToastVisible {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        
                        Text("收集成功！")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                    .padding(.bottom, 100) // 距离底部安全区域
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isToastVisible)
            }
            
            // 悬浮拍照按钮
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        HapticFeedbackManager.shared.lightTap()
                        appState = .camera
                    }) {
                        // 相机图标
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 64, height: 64)
                            .background(
                                // 毛玻璃背景效果 - 与对话气泡一致
                                ZStack {
                                    // 基础毛玻璃层
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.85)
                                    
                                    // 渐变色彩层
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.pink.opacity(0.3),
                                                    Color.yellow.opacity(0.2),
                                                    Color.green.opacity(0.2),
                                                    Color.blue.opacity(0.3)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    // 边缘发光效果
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.6),
                                                    Color.white.opacity(0.2),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .shadow(color: .white.opacity(0.1), radius: 5, x: 0, y: -2)
                    }
                    .scaleEffect(editingStickerId != nil ? 0.8 : 1.0) // 编辑模式下缩小
                    .opacity(editingStickerId != nil ? 0.6 : 1.0) // 编辑模式下半透明
                    .animation(.easeInOut(duration: 0.3), value: editingStickerId != nil)
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .gesture(swipeBackGesture)
        .sheet(item: $showingStickerDetail) { sticker in
            NavigationView {
                StickerDetailView(sticker: sticker)
            }
        }
        .alert("删除确认", isPresented: $showingDeleteConfirmation) {
            Button("取消", role: .cancel) { 
                // 取消删除时退出编辑模式
                editingStickerId = nil
                selectedStickerForDeletion = nil
            }
            Button("删除", role: .destructive) {
                if let stickerToDelete = selectedStickerForDeletion {
                    deleteToySticker(stickerToDelete)
                }
            }
        } message: {
            Text("确定要删除这个潮玩吗？删除后无法恢复。")
        }
        .onAppear {
            // 如果需要显示toast，则在页面出现时显示
            if showSuccessToast {
                isToastVisible = true
                
                // 2秒后自动隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation {
                        isToastVisible = false
                    }
                }
            }
        }
    }
    
    // MARK: - 删除方法
    private func deleteToySticker(_ sticker: ToySticker) {
        withAnimation {
            modelContext.delete(sticker)
            editingStickerId = nil
            selectedStickerForDeletion = nil
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
    let isEditing: Bool
    let isInEditingMode: Bool
    let onDelete: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: -8) {
                // 贴纸图片容器
                ZStack {
                    // 贴纸图片 - 优先显示增强图片
                    if let image = sticker.displayImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .aspectRatio(1, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .scaleEffect(0.77) // 缩小23%
                    } else {
                        // 加载失败占位符
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .aspectRatio(1, contentMode: .fit)
                            .scaleEffect(0.77) // 缩小23%
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
                    
                    // AI增强状态指示器
                    VStack {
                        HStack {
                            Spacer()
                            AIEnhancementStatusIndicator(sticker: sticker)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                
                // 贴纸名称
                Text(sticker.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .opacity(opacityValue)
            .animation(.easeInOut(duration: 0.3), value: opacityValue)
            
            // 删除按钮 - 只在编辑模式下显示
            if isEditing {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticFeedbackManager.shared.lightTap()
                            onDelete()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .offset(x: 8, y: -8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // 计算透明度值
    private var opacityValue: Double {
        if isInEditingMode {
            return isEditing ? 1.0 : 0.4  // 编辑中的图片完全不透明，其他图片半透明
        } else {
            return 1.0  // 非编辑模式下所有图片完全不透明
        }
    }
    

}

#Preview {
    NavigationView {
        CollectionView(appState: .constant(.collection()))
    }
} 