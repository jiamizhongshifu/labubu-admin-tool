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
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    /// 配置SwiftData模型容器
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    /// 加载所有数据
    private func loadData() {
        loadToyStickers()
    }
    
    /// 加载所有贴纸
    private func loadToyStickers() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ToySticker>(
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            toyStickers = try context.fetch(descriptor)
            print("📊 加载了 \(toyStickers.count) 个贴纸")
        } catch {
            print("❌ 加载贴纸失败: \(error)")
            toyStickers = []
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
        
        // 生成唯一文件名
        let fileName = "sticker_\(sticker.id.uuidString)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        do {
            // 上传到Supabase
            let publicURL = try await SupabaseStorageService.shared.uploadImage(
                compressedData,
                fileName: fileName,
                stickerId: sticker.id.uuidString
            )
            
            // 更新贴纸的存储URL
            await MainActor.run {
                sticker.supabaseImageURL = publicURL
                updateToySticker(sticker)
            }
            
            print("📝 [预上传] ✅ 图片上传成功: \(publicURL)")
            
        } catch {
            print("📝 [预上传] ❌ Supabase上传失败: \(error)")
            // 降级到本地存储
            await useLocalStorageForPreUpload(for: sticker)
        }
    }
    
    /// 使用本地存储作为预上传的降级方案
    private func useLocalStorageForPreUpload(for sticker: ToySticker) async {
        print("📝 [预上传] 📁 使用本地存储方案")
        
        // 获取处理后的图片
        guard let processedImage = sticker.processedImage else {
            print("📝 [预上传] ❌ 无法获取处理后的图片")
            return
        }
        
        // 保存到本地Documents目录
        let fileName = "sticker_\(sticker.id.uuidString).jpg"
        
        do {
            // 获取Documents目录
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            // 将图片转换为JPEG数据并保存
            if let imageData = processedImage.jpegData(compressionQuality: 0.8) {
                try imageData.write(to: fileURL)
                
                // 更新贴纸的本地存储路径（暂时使用notes字段记录）
                await MainActor.run {
                    sticker.notes = "本地存储: \(fileURL.path)"
                    updateToySticker(sticker)
                }
                
                print("📝 [预上传] ✅ 图片保存到本地: \(fileURL.path)")
            } else {
                print("📝 [预上传] ❌ 图片数据转换失败")
            }
            
        } catch {
            print("📝 [预上传] ❌ 本地存储失败: \(error)")
        }
    }
    
    // MARK: - 数据库重置功能
    
    /// 重置数据库（清除所有数据）
    func resetDatabase() {
        guard let context = modelContext else { return }
        
        do {
            // 删除所有贴纸
            for sticker in toyStickers {
                context.delete(sticker)
            }
            
            try context.save()
            
            // 清空本地数组
            toyStickers.removeAll()
            
            // 设置重置标记
            UserDefaults.standard.set(true, forKey: "database_was_reset")
            
            print("✅ 数据库重置完成")
            
        } catch {
            print("❌ 数据库重置失败: \(error)")
        }
    }
} 