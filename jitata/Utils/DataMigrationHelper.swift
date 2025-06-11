import Foundation
import SwiftData
import UIKit

/// 数据迁移辅助工具
/// 用于处理SwiftData模型变更导致的迁移问题
class DataMigrationHelper {
    
    /// 创建新的ModelContainer，处理迁移错误
    /// - Returns: ModelContainer
    static func createModelContainer() -> ModelContainer {
        do {
            let container = try ModelContainer(for: ToySticker.self)
            print("✅ ModelContainer创建成功")
            return container
        } catch {
            print("❌ ModelContainer创建失败: \(error)")
            
            // 如果失败，删除数据库文件后重试
            print("🔄 删除数据库文件后重试...")
            deleteExistingDatabase()
            
            do {
                let container = try ModelContainer(for: ToySticker.self)
                print("✅ 重试后ModelContainer创建成功")
                
                // 设置用户提示标记
                UserDefaults.standard.set(true, forKey: "database_was_reset")
                
                return container
            } catch {
                print("❌ 重试后仍然失败: \(error)")
                fatalError("无法创建ModelContainer: \(error)")
            }
        }
    }
    
    /// 删除现有数据库文件
    private static func deleteExistingDatabase() {
        let fileManager = FileManager.default
        
        // 获取应用支持目录
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("❌ 无法获取应用支持目录")
            return
        }
        
        do {
            // 确保目录存在
            try fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
            
            // 列出所有文件
            let files = try fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil)
            
            // 删除数据库相关文件
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.contains("default.store") || 
                   fileName.contains(".sqlite") ||
                   fileName.contains(".db") ||
                   fileName.hasSuffix("-wal") ||
                   fileName.hasSuffix("-shm") {
                    try fileManager.removeItem(at: file)
                    print("🗑️ 已删除数据库文件: \(fileName)")
                }
            }
        } catch {
            print("❌ 删除数据库文件时出错: \(error)")
        }
    }
    
    /// 应用启动时的数据迁移处理
    /// - Returns: 配置好的ModelContainer
    static func handleAppLaunchMigration() -> ModelContainer {
        print("🚀 开始数据迁移检查...")
        
        #if DEBUG
        // 开发环境下强制清理数据库
        print("🧹 开发环境：强制清理数据库...")
        DeveloperTools.clearAllDatabaseFiles()
        #endif
        
        // 创建容器
        let container = createModelContainer()
        
        print("✅ 数据库初始化完成")
        return container
    }
} 