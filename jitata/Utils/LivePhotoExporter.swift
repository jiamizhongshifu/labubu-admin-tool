import Foundation
import Photos
import PhotosUI
import AVFoundation
import MobileCoreServices

/// Live Photo导出器
class LivePhotoExporter {
    static let shared = LivePhotoExporter()
    
    private init() {}
    
    /// 从视频生成Live Photo并保存到相册
    /// - Parameters:
    ///   - videoURL: 视频文件URL
    ///   - keyFrameTime: 关键帧时间（用作静态图片的时间点）
    ///   - completion: 完成回调
    func exportLivePhoto(
        from videoURL: URL,
        keyFrameTime: CMTime = CMTime(seconds: 0, preferredTimescale: 600),
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // 检查相册权限
        checkPhotoLibraryPermission { [weak self] authorized in
            guard authorized else {
                completion(.failure(LivePhotoError.noPhotoLibraryPermission))
                return
            }
            
            self?.processVideoToLivePhoto(
                videoURL: videoURL,
                keyFrameTime: keyFrameTime,
                completion: completion
            )
        }
    }
    
    /// 检查相册权限
    private func checkPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    /// 处理视频并生成Live Photo
    private func processVideoToLivePhoto(
        videoURL: URL,
        keyFrameTime: CMTime,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task {
            do {
                // 1. 从视频中提取关键帧作为静态图片
                let keyFrameImage = try await extractKeyFrame(from: videoURL, at: keyFrameTime)
                
                // 2. 准备临时文件路径
                let tempDirectory = FileManager.default.temporaryDirectory
                let imagePath = tempDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                let videoPath = tempDirectory.appendingPathComponent(UUID().uuidString + ".mov")
                
                // 3. 保存关键帧图片
                if let imageData = keyFrameImage.jpegData(compressionQuality: 0.9) {
                    try imageData.write(to: imagePath)
                } else {
                    throw LivePhotoError.imageProcessingFailed
                }
                
                // 4. 复制并处理视频（确保格式兼容）
                try await processVideoForLivePhoto(from: videoURL, to: videoPath)
                
                // 5. 创建Live Photo并保存到相册
                try await saveLivePhotoToPhotoLibrary(imageURL: imagePath, videoURL: videoPath)
                
                // 6. 清理临时文件
                try? FileManager.default.removeItem(at: imagePath)
                try? FileManager.default.removeItem(at: videoPath)
                
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
    
    /// 从视频中提取关键帧
    private func extractKeyFrame(from videoURL: URL, at time: CMTime) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            throw LivePhotoError.keyFrameExtractionFailed
        }
    }
    
    /// 处理视频以确保Live Photo兼容
    private func processVideoForLivePhoto(from sourceURL: URL, to destinationURL: URL) async throws {
        let asset = AVAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw LivePhotoError.videoProcessingFailed
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        // 设置时间范围（Live Photo通常为3秒左右）
        let duration = min(asset.duration, CMTime(seconds: 3, preferredTimescale: 600))
        exportSession.timeRange = CMTimeRange(start: .zero, duration: duration)
        
        await exportSession.export()
        
        if exportSession.status != .completed {
            throw LivePhotoError.videoExportFailed
        }
    }
    
    /// 保存Live Photo到相册
    private func saveLivePhotoToPhotoLibrary(imageURL: URL, videoURL: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                
                // 添加Live Photo资源
                let options = PHAssetResourceCreationOptions()
                request.addResource(with: .photo, fileURL: imageURL, options: options)
                request.addResource(with: .pairedVideo, fileURL: videoURL, options: options)
                
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? LivePhotoError.saveToPhotoLibraryFailed)
                }
            }
        }
    }
}

// MARK: - 错误定义

enum LivePhotoError: LocalizedError {
    case noPhotoLibraryPermission
    case imageProcessingFailed
    case keyFrameExtractionFailed
    case videoProcessingFailed
    case videoExportFailed
    case saveToPhotoLibraryFailed
    
    var errorDescription: String? {
        switch self {
        case .noPhotoLibraryPermission:
            return "没有相册访问权限"
        case .imageProcessingFailed:
            return "图片处理失败"
        case .keyFrameExtractionFailed:
            return "关键帧提取失败"
        case .videoProcessingFailed:
            return "视频处理失败"
        case .videoExportFailed:
            return "视频导出失败"
        case .saveToPhotoLibraryFailed:
            return "保存到相册失败"
        }
    }
} 