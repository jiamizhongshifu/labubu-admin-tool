import Foundation
import UIKit
import SwiftUI

/// 图片缓存管理器
/// 提供内存缓存和磁盘缓存功能，优化图片加载性能
class ImageCacheManager: ObservableObject {
    static let shared = ImageCacheManager()
    
    // MARK: - 缓存配置
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheDirectory: URL
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50MB
    private let maxDiskCacheSize: Int = 200 * 1024 * 1024 // 200MB
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7天
    
    // MARK: - URL缓存
    private var urlCache: [String: String] = [:]
    private let urlCacheQueue = DispatchQueue(label: "com.jitata.urlcache", attributes: .concurrent)
    
    private init() {
        // 设置内存缓存限制
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100 // 最多缓存100张图片
        
        // 创建磁盘缓存目录
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheDirectory = cacheDir.appendingPathComponent("LabubuImageCache")
        
        // 确保缓存目录存在
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        
        // 清理过期缓存
        cleanExpiredCache()
        
        print("🖼️ [图片缓存] 初始化完成，缓存目录: \(diskCacheDirectory.path)")
    }
    
    // MARK: - URL缓存管理
    
    /// 缓存模型ID对应的图片URL
    func cacheImageUrl(_ url: String, for modelId: String) {
        urlCacheQueue.async(flags: .barrier) {
            self.urlCache[modelId] = url
        }
    }
    
    /// 获取缓存的图片URL
    func getCachedImageUrl(for modelId: String) -> String? {
        return urlCacheQueue.sync {
            return urlCache[modelId]
        }
    }
    
    // MARK: - 图片缓存管理
    
    /// 从缓存获取图片
    func getImage(for key: String) -> UIImage? {
        // 先检查内存缓存
        if let image = memoryCache.object(forKey: NSString(string: key)) {
            print("🖼️ [图片缓存] 内存命中: \(key)")
            return image
        }
        
        // 检查磁盘缓存
        if let image = loadImageFromDisk(key: key) {
            print("🖼️ [图片缓存] 磁盘命中: \(key)")
            // 重新加入内存缓存
            let cost = Int(image.size.width * image.size.height * 4) // 估算内存占用
            memoryCache.setObject(image, forKey: NSString(string: key), cost: cost)
            return image
        }
        
        print("🖼️ [图片缓存] 缓存未命中: \(key)")
        return nil
    }
    
    /// 缓存图片
    func setImage(_ image: UIImage, for key: String) {
        // 保存到内存缓存
        let cost = Int(image.size.width * image.size.height * 4) // 估算内存占用
        memoryCache.setObject(image, forKey: NSString(string: key), cost: cost)
        
        // 异步保存到磁盘缓存
        DispatchQueue.global(qos: .utility).async {
            self.saveImageToDisk(image, key: key)
        }
        
        print("🖼️ [图片缓存] 已缓存: \(key)")
    }
    
    // MARK: - 磁盘缓存操作
    
    private func loadImageFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheDirectory.appendingPathComponent(cacheKey(for: key))
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // 检查文件是否过期
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modificationDate) > cacheExpiration {
                // 文件过期，删除
                try? FileManager.default.removeItem(at: fileURL)
                return nil
            }
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    private func saveImageToDisk(_ image: UIImage, key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileURL = diskCacheDirectory.appendingPathComponent(cacheKey(for: key))
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("❌ [图片缓存] 保存到磁盘失败: \(error)")
        }
    }
    
    private func cacheKey(for key: String) -> String {
        return key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
    }
    
    // MARK: - 缓存清理
    
    /// 清理过期缓存
    private func cleanExpiredCache() {
        DispatchQueue.global(qos: .utility).async {
            guard let files = try? FileManager.default.contentsOfDirectory(at: self.diskCacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return
            }
            
            let now = Date()
            var deletedCount = 0
            
            for file in files {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let modificationDate = attributes[.modificationDate] as? Date {
                    if now.timeIntervalSince(modificationDate) > self.cacheExpiration {
                        try? FileManager.default.removeItem(at: file)
                        deletedCount += 1
                    }
                }
            }
            
            if deletedCount > 0 {
                print("🖼️ [图片缓存] 清理了 \(deletedCount) 个过期文件")
            }
        }
    }
    
    /// 清空所有缓存
    func clearAllCache() {
        // 清空内存缓存
        memoryCache.removeAllObjects()
        
        // 清空URL缓存
        urlCacheQueue.async(flags: .barrier) {
            self.urlCache.removeAll()
        }
        
        // 清空磁盘缓存
        DispatchQueue.global(qos: .utility).async {
            try? FileManager.default.removeItem(at: self.diskCacheDirectory)
            try? FileManager.default.createDirectory(at: self.diskCacheDirectory, withIntermediateDirectories: true)
        }
        
        print("🖼️ [图片缓存] 已清空所有缓存")
    }
    
    /// 获取缓存统计信息
    func getCacheStats() -> (memoryCount: Int, diskSize: String) {
        let memoryCount = memoryCache.countLimit
        
        var diskSize: Int64 = 0
        if let files = try? FileManager.default.contentsOfDirectory(at: diskCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
                   let fileSize = attributes[.size] as? Int64 {
                    diskSize += fileSize
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        
        return (memoryCount, formatter.string(fromByteCount: diskSize))
    }
}

// MARK: - 缓存图片视图
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        let cacheKey = url.absoluteString
        
        // 先检查缓存
        if let cachedImage = ImageCacheManager.shared.getImage(for: cacheKey) {
            self.image = cachedImage
            return
        }
        
        // 从网络加载
        isLoading = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                
                if let downloadedImage = UIImage(data: data) {
                    await MainActor.run {
                        // 缓存图片
                        ImageCacheManager.shared.setImage(downloadedImage, for: cacheKey)
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ [缓存图片] 加载失败: \(error)")
            }
        }
    }
} 