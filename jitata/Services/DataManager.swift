//
//  DataManager.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import SwiftData
import UIKit

@MainActor
class DataManager: ObservableObject {
    
    static let shared = DataManager()
    
    @Published var toyStickers: [ToySticker] = []
    @Published var categories: [Category] = []
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    /// 配置SwiftData模型容器
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
        createDefaultCategoriesIfNeeded()
    }
    
    /// 加载所有数据
    private func loadData() {
        loadToyStickers()
        loadCategories()
    }
    
    /// 加载所有贴纸
    private func loadToyStickers() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ToySticker>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            toyStickers = try context.fetch(descriptor)
        } catch {
            print("加载贴纸失败: \(error)")
            toyStickers = []
        }
    }
    
    /// 加载所有分类
    private func loadCategories() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<Category>(
                sortBy: [SortDescriptor(\.createdDate, order: .forward)]
            )
            categories = try context.fetch(descriptor)
        } catch {
            print("加载分类失败: \(error)")
            categories = []
        }
    }
    
    /// 创建默认分类（如果不存在）
    private func createDefaultCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        
        for defaultCategory in Category.defaultCategories {
            addCategory(defaultCategory)
        }
    }
    
    // MARK: - 贴纸管理
    
    /// 添加新贴纸
    func addToySticker(_ sticker: ToySticker) {
        guard let context = modelContext else { return }
        
        context.insert(sticker)
        
        do {
            try context.save()
            toyStickers.insert(sticker, at: 0) // 插入到开头
            
            // 🚀 自动触发AI增强
            Task {
                await triggerAutoEnhancement(for: sticker, context: context)
            }
        } catch {
            print("保存贴纸失败: \(error)")
        }
    }
    
    /// 自动触发AI增强
    private func triggerAutoEnhancement(for sticker: ToySticker, context: ModelContext) async {
        print("🔍 检查AI增强触发条件...")
        print("   - 贴纸名称: \(sticker.name)")
        print("   - 贴纸状态: \(sticker.currentEnhancementStatus)")
        
        // 检查API是否已配置
        guard ImageEnhancementService.shared.isAPIConfigured else {
            print("❌ API未配置，跳过AI增强")
            return
        }
        
        print("✅ API已配置，开始AI增强...")
        
        let success = await ImageEnhancementService.shared.enhanceSticker(sticker, modelContext: context)
        
        print("🎯 AI增强结果: \(success ? "成功" : "失败")")
        
        if success {
            // 刷新数据
            await MainActor.run {
                print("🔄 刷新数据...")
                loadToyStickers()
            }
        }
    }
    
    /// 删除贴纸
    func deleteToySticker(_ sticker: ToySticker) {
        guard let context = modelContext else { return }
        
        context.delete(sticker)
        
        do {
            try context.save()
            toyStickers.removeAll { $0.id == sticker.id }
        } catch {
            print("删除贴纸失败: \(error)")
        }
    }
    
    /// 更新贴纸
    func updateToySticker(_ sticker: ToySticker) {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
            // 更新本地数组
            if let index = toyStickers.firstIndex(where: { $0.id == sticker.id }) {
                toyStickers[index] = sticker
            }
        } catch {
            print("更新贴纸失败: \(error)")
        }
    }
    
    /// 切换贴纸收藏状态
    func toggleFavorite(for sticker: ToySticker) {
        sticker.isFavorite.toggle()
        updateToySticker(sticker)
    }
    
    // MARK: - 分类管理
    
    /// 添加新分类
    func addCategory(_ category: Category) {
        guard let context = modelContext else { return }
        
        context.insert(category)
        
        do {
            try context.save()
            categories.append(category)
        } catch {
            print("保存分类失败: \(error)")
        }
    }
    
    /// 删除分类
    func deleteCategory(_ category: Category) {
        guard let context = modelContext else { return }
        
        // 检查是否有贴纸使用此分类
        let stickersInCategory = toyStickers.filter { $0.categoryName == category.name }
        
        if !stickersInCategory.isEmpty {
            // 将这些贴纸移动到"其他"分类
            for sticker in stickersInCategory {
                sticker.categoryName = "其他"
            }
            
            do {
                try context.save()
            } catch {
                print("更新贴纸分类失败: \(error)")
            }
        }
        
        context.delete(category)
        
        do {
            try context.save()
            categories.removeAll { $0.id == category.id }
        } catch {
            print("删除分类失败: \(error)")
        }
    }
    
    // MARK: - 查询方法
    
    /// 获取指定分类的贴纸
    func getToyStickers(for categoryName: String) -> [ToySticker] {
        return toyStickers.filter { $0.categoryName == categoryName }
    }
    
    /// 获取收藏的贴纸
    func getFavoriteToyStickers() -> [ToySticker] {
        return toyStickers.filter { $0.isFavorite }
    }
    
    /// 搜索贴纸
    func searchToyStickers(with keyword: String) -> [ToySticker] {
        guard !keyword.isEmpty else { return toyStickers }
        
        return toyStickers.filter { sticker in
            sticker.name.localizedCaseInsensitiveContains(keyword) ||
            sticker.categoryName.localizedCaseInsensitiveContains(keyword) ||
            sticker.notes.localizedCaseInsensitiveContains(keyword)
        }
    }
    
    /// 获取统计信息
    func getStatistics() -> (totalStickers: Int, categories: Int, favorites: Int) {
        return (
            totalStickers: toyStickers.count,
            categories: categories.count,
            favorites: getFavoriteToyStickers().count
        )
    }
    
    /// 获取分类统计
    func getCategoryStatistics() -> [(categoryName: String, count: Int)] {
        var categoryStats: [String: Int] = [:]
        
        for sticker in toyStickers {
            categoryStats[sticker.categoryName, default: 0] += 1
        }
        
        return categoryStats.map { (categoryName: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
} 