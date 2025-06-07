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
    @Query private var categories: [Category]
    
    @State private var selectedCategory: String = "全部"
    @State private var searchText = ""
    @State private var showingGrid = true
    
    var filteredStickers: [ToySticker] {
        var filtered = stickers
        
        // 按分类筛选
        if selectedCategory != "全部" {
            filtered = filtered.filter { $0.categoryName == selectedCategory }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.categoryName.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.createdDate > $1.createdDate }
    }
    
    var allCategories: [String] {
        let categoryNames = stickers.map { $0.categoryName }
        let uniqueCategories = Array(Set(categoryNames)).sorted()
        return ["全部"] + uniqueCategories
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // 分类选择器
                CategorySelector(
                    categories: allCategories,
                    selectedCategory: $selectedCategory
                )
                .padding(.vertical, 8)
                
                // 统计信息和视图切换
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("我的图鉴")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("已收集 \(filteredStickers.count) 件潮玩")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 视图切换按钮
                    HStack(spacing: 12) {
                        Button(action: { showingGrid = true }) {
                            Image(systemName: "grid.circle.fill")
                                .font(.title2)
                                .foregroundColor(showingGrid ? .blue : .gray)
                        }
                        
                        Button(action: { showingGrid = false }) {
                            Image(systemName: "list.bullet.circle.fill")
                                .font(.title2)
                                .foregroundColor(!showingGrid ? .blue : .gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
                
                // 内容区域
                if filteredStickers.isEmpty {
                    EmptyCollectionView()
                } else {
                    if showingGrid {
                        GridCollectionView(stickers: filteredStickers)
                    } else {
                        ListCollectionView(stickers: filteredStickers)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            // 初始化默认分类
            initializeDefaultCategories()
        }
    }
    
    private func initializeDefaultCategories() {
        // 如果数据库中没有分类，添加默认分类
        if categories.isEmpty {
            for category in Category.defaultCategories {
                modelContext.insert(category)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - 搜索栏
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索潮玩...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - 分类选择器
struct CategorySelector: View {
    let categories: [String]
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryButton(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 网格视图
struct GridCollectionView: View {
    let stickers: [ToySticker]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(stickers) { sticker in
                    NavigationLink(destination: StickerDetailView(sticker: sticker)) {
                        StickerGridCard(sticker: sticker)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 列表视图
struct ListCollectionView: View {
    let stickers: [ToySticker]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(stickers) { sticker in
                    NavigationLink(destination: StickerDetailView(sticker: sticker)) {
                        StickerListCard(sticker: sticker)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 空状态视图
struct EmptyCollectionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("还没有收集任何潮玩")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("开始拍照收集你喜爱的潮流玩具吧！")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 这里可以添加一个跳转到拍照的按钮
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

#Preview {
    CollectionView()
} 