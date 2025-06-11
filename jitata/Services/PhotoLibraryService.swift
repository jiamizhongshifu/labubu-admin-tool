import Foundation
import Photos
import UIKit

/// 相册服务 - 负责保存图片到用户相册
class PhotoLibraryService: NSObject {
    static let shared = PhotoLibraryService()
    
    private override init() {
        super.init()
    }
    
    /// 保存图片到相册
    /// - Parameters:
    ///   - image: 要保存的图片
    ///   - completion: 完成回调，返回是否成功和错误信息
    func saveImageToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        // 首先检查权限
        checkPhotoLibraryPermission { [weak self] hasPermission in
            guard hasPermission else {
                DispatchQueue.main.async {
                    completion(false, "需要相册访问权限才能保存图片")
                }
                return
            }
            
            // 保存图片
            self?.performSaveImage(image, completion: completion)
        }
    }
    
    /// 保存高清图片数据到相册
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - completion: 完成回调
    func saveImageDataToPhotoLibrary(_ imageData: Data, completion: @escaping (Bool, String?) -> Void) {
        guard let image = UIImage(data: imageData) else {
            completion(false, "图片数据无效")
            return
        }
        
        saveImageToPhotoLibrary(image, completion: completion)
    }
    
    /// 检查相册权限
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .denied, .restricted:
            completion(false)
        case .notDetermined:
            // 请求权限
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// 执行保存图片操作
    private func performSaveImage(_ image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            // 🎯 保存高清原图，不进行任何压缩
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            // 设置图片的创建日期为当前时间
            request.creationDate = Date()
            
            // 添加到"最近添加"相册
            request.location = nil // 不添加位置信息
            
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "保存失败"
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    /// 批量保存图片到相册
    /// - Parameters:
    ///   - images: 要保存的图片数组
    ///   - completion: 完成回调，返回成功数量和失败数量
    func saveImagesToPhotoLibrary(_ images: [UIImage], completion: @escaping (Int, Int) -> Void) {
        checkPhotoLibraryPermission { [weak self] hasPermission in
            guard hasPermission else {
                DispatchQueue.main.async {
                    completion(0, images.count)
                }
                return
            }
            
            self?.performBatchSaveImages(images, completion: completion)
        }
    }
    
    /// 执行批量保存操作
    private func performBatchSaveImages(_ images: [UIImage], completion: @escaping (Int, Int) -> Void) {
        var successCount = 0
        var failureCount = 0
        let group = DispatchGroup()
        
        for image in images {
            group.enter()
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    successCount += 1
                } else {
                    failureCount += 1
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(successCount, failureCount)
        }
    }
    
    /// 获取权限状态描述
    func getPermissionStatusDescription() -> String {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized:
            return "已授权"
        case .limited:
            return "有限访问"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限制"
        case .notDetermined:
            return "未确定"
        @unknown default:
            return "未知状态"
        }
    }
    
    /// 打开系统设置页面
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - 扩展UIImage以支持高质量保存
extension UIImage {
    /// 获取高质量的PNG数据
    var highQualityPNGData: Data? {
        return self.pngData()
    }
    
    /// 获取高质量的JPEG数据
    /// - Parameter compressionQuality: 压缩质量，默认0.95（高质量）
    func highQualityJPEGData(compressionQuality: CGFloat = 0.95) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
    
    /// 确保图片方向正确
    var orientationCorrected: UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
} 