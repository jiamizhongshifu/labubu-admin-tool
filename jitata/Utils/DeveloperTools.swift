import Foundation
import SwiftData
import UIKit

/// 开发者工具
/// 用于开发和调试时的数据库管理
#if DEBUG
class DeveloperTools {
    
    /// 清理所有数据库文件
    static func clearAllDatabaseFiles() {
        let fileManager = FileManager.default
        
        // 清理应用支持目录
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            clearDirectory(appSupportURL, name: "应用支持目录")
        }
        
        // 清理文档目录
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            clearDirectory(documentsURL, name: "文档目录")
        }
    }
    
    /// 清理指定目录中的数据库文件
    private static func clearDirectory(_ url: URL, name: String) {
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            
            for file in files {
                let fileName = file.lastPathComponent
                if fileName.contains("default.store") || 
                   fileName.contains(".sqlite") ||
                   fileName.contains(".db") ||
                   fileName.hasSuffix("-wal") ||
                   fileName.hasSuffix("-shm") ||
                   fileName.contains("CoreData") ||
                   fileName.contains("SwiftData") {
                    try fileManager.removeItem(at: file)
                    print("🗑️ 已从\(name)删除: \(fileName)")
                }
            }
        } catch {
            print("❌ 清理\(name)时出错: \(error)")
        }
    }
}
#endif 