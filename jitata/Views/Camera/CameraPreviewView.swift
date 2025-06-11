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
    var onTap: ((CGPoint) -> Void)?
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.cameraManager = cameraManager
        view.onTap = onTap
        
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
        
        if let previewView = uiView as? CameraPreviewUIView {
            previewView.onTap = onTap
        }
    }
}

// MARK: - 自定义UIView支持点击对焦
class CameraPreviewUIView: UIView {
    var cameraManager: CameraManager?
    var onTap: ((CGPoint) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }
    
    private func setupGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // 调用外部传入的点击处理函数
        onTap?(location)
        
        // 同时调用相机对焦
        cameraManager?.focusAt(point: location, in: self)
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
    private var videoDevice: AVCaptureDevice?
    
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
        
        self.videoDevice = videoDevice
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
            
            // 配置自动对焦
            try videoDevice.lockForConfiguration()
            
            // 设置自动对焦模式
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            
            // 设置自动曝光模式
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            // 设置自动白平衡
            if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            videoDevice.unlockForConfiguration()
            
        } catch {
            print("无法创建视频输入或配置设备: \(error)")
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
    
    // MARK: - 对焦功能
    func focusAt(point: CGPoint, in view: UIView) {
        guard let videoDevice = self.videoDevice,
              let previewLayer = self.previewLayer else { return }
        
        // 将屏幕坐标转换为相机坐标
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        
        do {
            try videoDevice.lockForConfiguration()
            
            // 设置对焦点
            if videoDevice.isFocusPointOfInterestSupported {
                videoDevice.focusPointOfInterest = devicePoint
                videoDevice.focusMode = .autoFocus
            }
            
            // 设置曝光点
            if videoDevice.isExposurePointOfInterestSupported {
                videoDevice.exposurePointOfInterest = devicePoint
                videoDevice.exposureMode = .autoExpose
            }
            
            videoDevice.unlockForConfiguration()
            
        } catch {
            print("对焦失败: \(error)")
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