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
            
            print("📌 贴纸已保存到本地数据库")
            
            // 🚀 异步预上传图片到Supabase
            Task {
                await preUploadImageToSupabase(for: sticker)
            }
            
            print("📌 贴纸已保存，可在详情页手动触发AI增强")
        } catch {
            print("❌ 保存贴纸失败: \(error)")
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
    
    // MARK: - Supabase预上传功能
    
    /// 预上传图片到存储
    /// 在贴纸保存后立即执行，为后续AI增强做准备
    /// 优先使用Supabase，配置无效时使用本地存储
    private func preUploadImageToSupabase(for sticker: ToySticker) async {
        print("📝 [预上传] 🚀 开始为贴纸 \(sticker.name) 预上传图片")
        
        // 检查是否已经有存储URL
        if let existingURL = sticker.supabaseImageURL, !existingURL.isEmpty {
            print("📝 [预上传] ✅ 贴纸已有存储URL，跳过上传")
            return
        }
        
        // 检查Supabase配置是否有效
        let isSupabaseConfigValid = {
            guard let supabaseURL = APIConfig.supabaseURL,
                  let supabaseKey = APIConfig.supabaseServiceRoleKey,
                  !supabaseURL.isEmpty && !supabaseKey.isEmpty,
                  !supabaseURL.contains("your_supabase_project_url_here"),
                  !supabaseKey.contains("your_supabase_service_role_key_here") else {
                return false
            }
            return true
        }()
        
        if !isSupabaseConfigValid {
            print("📝 [预上传] ⚠️ Supabase配置无效，使用本地存储方案")
            await useLocalStorageForPreUpload(for: sticker)
            return
        }
        
        // 获取处理后的图片数据
        guard let processedImage = sticker.processedImage else {
            print("📝 [预上传] ❌ 无法获取处理后的图片")
            return
        }
        
        // 压缩图片以优化上传
        guard let compressedData = SupabaseStorageService.shared.compressImageForUpload(processedImage, maxSizeKB: 800) else {
            print("📝 [预上传] ❌ 图片压缩失败")
            return
        }
        
        print("📝 [预上传] 📦 图片压缩完成，大小: \(compressedData.count) 字节")
        
        do {
            // 上传到Supabase
            let supabaseURL = try await SupabaseStorageService.shared.uploadImage(
                compressedData,
                stickerId: sticker.id.uuidString
            )
            
            // 更新贴纸的Supabase URL
            await MainActor.run {
                sticker.supabaseImageURL = supabaseURL
                updateToySticker(sticker)
                print("📝 [预上传] ✅ 预上传成功，URL已保存: \(supabaseURL)")
            }
            
        } catch {
            print("📝 [预上传] ❌ Supabase预上传失败: \(error.localizedDescription)")
            print("📝 [预上传] 🔄 降级到本地存储方案")
            // Supabase失败时降级到本地存储
            await useLocalStorageForPreUpload(for: sticker)
        }
    }
    
    /// 本地存储预上传方案
    /// 当Supabase不可用时的备选方案
    private func useLocalStorageForPreUpload(for sticker: ToySticker) async {
        print("📝 [本地存储] 🚀 开始本地存储预处理")
        
        // 获取处理后的图片数据
        guard let processedImage = sticker.processedImage else {
            print("📝 [本地存储] ❌ 无法获取处理后的图片")
            return
        }
        
        // 压缩图片以优化后续处理
        guard let compressedData = SupabaseStorageService.shared.compressImageForUpload(processedImage, maxSizeKB: 800) else {
            print("📝 [本地存储] ❌ 图片压缩失败")
            return
        }
        
        print("📝 [本地存储] 📦 图片压缩完成，大小: \(compressedData.count) 字节")
        
        do {
            // 保存到应用文档目录
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "sticker_\(sticker.id.uuidString)_\(Date().timeIntervalSince1970).png"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try compressedData.write(to: fileURL)
            
            // 生成本地文件URL
            let localURL = fileURL.absoluteString
            
            // 更新贴纸的存储URL（使用本地路径）
            await MainActor.run {
                sticker.supabaseImageURL = localURL
                updateToySticker(sticker)
                print("📝 [本地存储] ✅ 本地存储成功，路径已保存: \(fileName)")
                print("📝 [本地存储] 💡 AI增强时将使用本地文件，速度更快")
            }
            
        } catch {
            print("📝 [本地存储] ❌ 本地存储失败: \(error.localizedDescription)")
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