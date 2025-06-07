//
//  CameraPreviewView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// MARK: - 相机管理器
class CameraManager: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var isSessionRunning = false
    @Published var hasPermission = false
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    private func setupCamera() {
        // 检查相机权限
        checkCameraPermission()
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasPermission = true
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.hasPermission = granted
                    if granted {
                        self.configureSession()
                    }
                }
            }
        case .denied, .restricted:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        // 设置会话质量
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
        }
        
        // 添加视频输入
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
        } catch {
            print("无法创建视频输入: \(error)")
            session.commitConfiguration()
            return
        }
        
        // 添加照片输出
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            // 使用新的API设置最大照片尺寸
            if #available(iOS 16.0, *) {
                photoOutput.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
            } else {
                photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            if let connection = photoOutput.connection(with: .video) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
        }
        
        session.commitConfiguration()
        
        // 创建预览层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // 启动会话
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func capturePhoto() {
        guard hasPermission && isSessionRunning else { return }
        
        var settings = AVCapturePhotoSettings()
        
        // 设置照片格式 - 使用新的API
        if #available(iOS 17.0, *) {
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
        }
        
        // 启用高分辨率 - 使用新的API
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = CMVideoDimensions(width: 4032, height: 3024)
        } else {
            settings.isHighResolutionPhotoEnabled = true
        }
        
        // 拍照
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func startSession() {
        guard !isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("拍照错误: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("无法获取图像数据")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
} 