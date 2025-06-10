import Foundation
import UIKit

/// Supabase存储服务
/// 负责处理图片的上传、管理和URL生成
class SupabaseStorageService {
    static let shared = SupabaseStorageService()
    
    private init() {}
    
    // MARK: - 上传图片到Supabase
    
    /// 上传图片到Supabase存储
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - fileName: 文件名（可选，会自动生成）
    ///   - stickerId: 贴纸ID，用于生成唯一文件名
    /// - Returns: 公开访问的图片URL
    func uploadImage(_ imageData: Data, fileName: String? = nil, stickerId: String) async throws -> String {
        guard let supabaseURL = APIConfig.supabaseURL,
              let supabaseKey = APIConfig.supabaseServiceRoleKey,
              !supabaseURL.isEmpty && !supabaseKey.isEmpty,
              !supabaseURL.contains("your_supabase_project_url_here"),
              !supabaseKey.contains("your_supabase_service_role_key_here") else {
            print("📝 [Supabase存储] ❌ 配置缺失或使用占位符")
            print("📝 [Supabase存储] SUPABASE_URL: \(APIConfig.supabaseURL ?? "未设置")")
            print("📝 [Supabase存储] SUPABASE_SERVICE_ROLE_KEY: \(APIConfig.supabaseServiceRoleKey?.prefix(20) ?? "未设置")...")
            
            if let url = APIConfig.supabaseURL, url.contains("your_supabase_project_url_here") {
                print("📝 [Supabase存储] 💡 请将.env文件中的占位符替换为真实的Supabase项目URL")
            }
            if let key = APIConfig.supabaseServiceRoleKey, key.contains("your_supabase_service_role_key_here") {
                print("📝 [Supabase存储] 💡 请将.env文件中的占位符替换为真实的Supabase Service Role Key")
            }
            
            throw SupabaseStorageError.configurationMissing
        }
        
        let bucket = APIConfig.supabaseStorageBucket
        let finalFileName = fileName ?? generateFileName(for: stickerId)
        let uploadURL = URL(string: "\(supabaseURL)/storage/v1/object/\(bucket)/\(finalFileName)")!
        
        print("📝 [Supabase存储] 🔄 开始上传图片")
        print("📝 [Supabase存储] 存储桶: \(bucket)")
        print("📝 [Supabase存储] 文件名: \(finalFileName)")
        print("📝 [Supabase存储] 上传URL: \(uploadURL.absoluteString)")
        print("📝 [Supabase存储] 图片数据大小: \(imageData.count) 字节")
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/png", forHTTPHeaderField: "Content-Type")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("public", forHTTPHeaderField: "x-upsert") // 允许覆盖同名文件
        request.httpBody = imageData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("📝 [Supabase存储] ❌ 无效的HTTP响应")
                throw SupabaseStorageError.invalidResponse
            }
            
            print("📝 [Supabase存储] 📥 响应状态码: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // 构建公开访问URL
                let publicURL = "\(supabaseURL)/storage/v1/object/public/\(bucket)/\(finalFileName)"
                print("📝 [Supabase存储] ✅ 图片上传成功: \(publicURL)")
                return publicURL
            } else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "未知错误"
                print("📝 [Supabase存储] ❌ 上传失败 (\(httpResponse.statusCode)): \(errorMessage)")
                
                // 提供具体的错误建议
                switch httpResponse.statusCode {
                case 404:
                    print("📝 [Supabase存储] 💡 建议：请检查存储桶 '\(bucket)' 是否存在")
                case 403:
                    print("📝 [Supabase存储] 💡 建议：请检查API密钥权限和存储桶访问策略")
                case 401:
                    print("📝 [Supabase存储] 💡 建议：请检查SUPABASE_SERVICE_ROLE_KEY是否正确")
                default:
                    break
                }
                
                throw SupabaseStorageError.uploadFailed(statusCode: httpResponse.statusCode, message: errorMessage)
            }
        } catch {
            print("📝 [Supabase存储] ❌ 网络错误: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - 辅助方法
    
    /// 生成唯一的文件名
    private func generateFileName(for stickerId: String) -> String {
        let timestamp = Date().timeIntervalSince1970
        return "sticker_\(stickerId)_\(timestamp).png"
    }
    
    /// 压缩图片以优化上传
    func compressImageForUpload(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        // 首先尝试PNG格式
        if let pngData = image.pngData(), pngData.count <= maxSizeKB * 1024 {
            return pngData
        }
        
        // 如果PNG太大，尝试压缩JPEG
        var compressionQuality: CGFloat = 0.8
        while compressionQuality > 0.1 {
            if let jpegData = image.jpegData(compressionQuality: compressionQuality),
               jpegData.count <= maxSizeKB * 1024 {
                return jpegData
            }
            compressionQuality -= 0.1
        }
        
        // 如果还是太大，缩小尺寸
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        
        if scale < 1.0 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.pngData()
        }
        
        return image.pngData()
    }
}

// MARK: - 错误类型定义

enum SupabaseStorageError: LocalizedError {
    case configurationMissing
    case invalidResponse
    case uploadFailed(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "Supabase配置缺失，请检查环境变量"
        case .invalidResponse:
            return "无效的服务器响应"
        case .uploadFailed(let statusCode, let message):
            return "上传失败 (状态码: \(statusCode)): \(message)"
        }
    }
} 