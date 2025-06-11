import Foundation
import Photos
import AVFoundation
import UIKit

/// Live Photo导出服务
class LivePhotoExporter {
    static let shared = LivePhotoExporter()
    
    private init() {}
    
    /// 从视频导出Live Photo
    func exportLivePhoto(from videoURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // 检查相册权限
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    completion(.failure(LivePhotoError.noPhotoLibraryPermission))
                }
                return
            }
            
            // 开始导出过程
            self.performLivePhotoExport(from: videoURL, completion: completion)
        }
    }
    
    private func performLivePhotoExport(from videoURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                // 1. 从视频中提取静态图片（第一帧）
                let stillImage = try await extractStillImage(from: videoURL)
                
                // 2. 创建临时文件路径
                let tempDirectory = FileManager.default.temporaryDirectory
                let imageURL = tempDirectory.appendingPathComponent("livePhoto_\(UUID().uuidString).jpg")
                let videoTempURL = tempDirectory.appendingPathComponent("livePhoto_\(UUID().uuidString).mov")
                
                // 3. 保存静态图片
                guard let imageData = stillImage.jpegData(compressionQuality: 0.9) else {
                    throw LivePhotoError.imageProcessingFailed
                }
                try imageData.write(to: imageURL)
                
                // 4. 复制视频文件到临时位置
                try FileManager.default.copyItem(at: videoURL, to: videoTempURL)
                
                // 5. 创建Live Photo并保存到相册
                try await saveLivePhotoToLibrary(imageURL: imageURL, videoURL: videoTempURL)
                
                // 6. 清理临时文件
                try? FileManager.default.removeItem(at: imageURL)
                try? FileManager.default.removeItem(at: videoTempURL)
                
                DispatchQueue.main.async {
                    completion(.success(()))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func extractStillImage(from videoURL: URL) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceAfter = .zero
        imageGenerator.requestedTimeToleranceBefore = .zero
        
        // 提取第一帧
        let time = CMTime(seconds: 0, preferredTimescale: 600)
        let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
        
        return UIImage(cgImage: cgImage)
    }
    
    private func saveLivePhotoToLibrary(imageURL: URL, videoURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let creationRequest = PHAssetCreationRequest.forAsset()
                
                // 添加静态图片
                let imageOptions = PHAssetResourceCreationOptions()
                imageOptions.shouldMoveFile = false
                creationRequest.addResource(with: .photo, fileURL: imageURL, options: imageOptions)
                
                // 添加视频（作为Live Photo的动态部分）
                let videoOptions = PHAssetResourceCreationOptions()
                videoOptions.shouldMoveFile = false
                creationRequest.addResource(with: .pairedVideo, fileURL: videoURL, options: videoOptions)
                
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? LivePhotoError.saveFailed)
                }
            }
        }
    }
}

// MARK: - 错误类型
enum LivePhotoError: LocalizedError {
    case noPhotoLibraryPermission
    case imageProcessingFailed
    case saveFailed
    case videoProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotoLibraryPermission:
            return "需要相册访问权限才能保存Live Photo"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .saveFailed:
            return "保存到相册失败"
        case .videoProcessingFailed:
            return "视频处理失败"
        }
    }
} 