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
        
        // 🎯 优化设备选择，优先选择支持微距的设备
        var videoDevice: AVCaptureDevice?
        
        // iOS 15+ 尝试使用微距镜头
        if #available(iOS 15.0, *) {
            // 首先尝试获取支持微距的设备
            let deviceTypes: [AVCaptureDevice.DeviceType] = [
                .builtInTripleCamera,      // iPhone Pro系列的三摄系统
                .builtInDualWideCamera,    // 双摄系统
                .builtInWideAngleCamera    // 标准广角镜头
            ]
            
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .back
            )
            
            videoDevice = discoverySession.devices.first
            print("📱 选择的相机设备: \(videoDevice?.localizedName ?? "未知")")
        } else {
            videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        }
        
        guard let videoDevice = videoDevice else {
            print("❌ 无法获取相机设备")
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
            
            // 🎯 优化对焦配置，增强近距离对焦能力
            try videoDevice.lockForConfiguration()
            
            // 🎯 设置连续自动对焦作为默认模式（适合预览）
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
                print("✅ 设置连续自动对焦模式")
            } else if videoDevice.isFocusModeSupported(.autoFocus) {
                videoDevice.focusMode = .autoFocus
                print("✅ 设置单次自动对焦模式")
            }
            
            // 🎯 启用微距对焦（如果设备支持）
            if #available(iOS 15.0, *) {
                if videoDevice.isAutoFocusRangeRestrictionSupported {
                    videoDevice.autoFocusRangeRestriction = .none  // 允许全范围对焦，包括微距
                    print("✅ 启用全范围对焦（包括微距）")
                }
            }
            
            // 🎯 启用平滑自动对焦（减少对焦时的抖动）
            if videoDevice.isSmoothAutoFocusSupported {
                videoDevice.isSmoothAutoFocusEnabled = true
                print("✅ 启用平滑自动对焦")
            }
            
            // 设置自动曝光模式
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            // 设置自动白平衡
            if videoDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                videoDevice.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // 🎯 检查并报告设备能力
            print("📋 设备对焦能力报告:")
            print("   - 支持连续自动对焦: \(videoDevice.isFocusModeSupported(.continuousAutoFocus))")
            print("   - 支持单次自动对焦: \(videoDevice.isFocusModeSupported(.autoFocus))")
            print("   - 支持对焦点设置: \(videoDevice.isFocusPointOfInterestSupported)")
            print("   - 支持平滑对焦: \(videoDevice.isSmoothAutoFocusSupported)")
            if #available(iOS 15.0, *) {
                print("   - 支持对焦范围限制: \(videoDevice.isAutoFocusRangeRestrictionSupported)")
            }
            
            videoDevice.unlockForConfiguration()
            
        } catch {
            print("❌ 无法创建视频输入或配置设备: \(error)")
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
              let previewLayer = self.previewLayer else { 
            print("❌ 对焦失败：设备或预览层不可用")
            return 
        }
        
        print("🎯 开始手动对焦，点击位置: (\(point.x), \(point.y))")
        
        // 将屏幕坐标转换为相机坐标
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        print("📍 转换后的设备坐标: (\(devicePoint.x), \(devicePoint.y))")
        
        do {
            try videoDevice.lockForConfiguration()
            
            // 🎯 优化对焦设置，特别针对近距离对焦
            if videoDevice.isFocusPointOfInterestSupported {
                videoDevice.focusPointOfInterest = devicePoint
                
                // 🎯 使用单次自动对焦进行精确对焦
                if videoDevice.isFocusModeSupported(.autoFocus) {
                    videoDevice.focusMode = .autoFocus
                    print("✅ 设置单次自动对焦模式")
                }
                
                // 🎯 启用微距对焦范围（如果支持）
                if #available(iOS 15.0, *) {
                    if videoDevice.isAutoFocusRangeRestrictionSupported {
                        videoDevice.autoFocusRangeRestriction = .none
                        print("✅ 启用全范围对焦（包括微距）")
                    }
                }
            } else {
                print("⚠️ 设备不支持对焦点设置")
            }
            
            // 设置曝光点
            if videoDevice.isExposurePointOfInterestSupported {
                videoDevice.exposurePointOfInterest = devicePoint
                if videoDevice.isExposureModeSupported(.autoExpose) {
                    videoDevice.exposureMode = .autoExpose
                    print("✅ 设置曝光点")
                }
            }
            
            videoDevice.unlockForConfiguration()
            print("✅ 手动对焦设置完成")
            
            // 🎯 添加对焦完成监听，自动恢复连续对焦
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.restoreContinuousFocus()
            }
            
        } catch {
            print("❌ 对焦失败: \(error.localizedDescription)")
        }
    }
    
    // 🎯 新增：恢复连续对焦模式
    private func restoreContinuousFocus() {
        guard let videoDevice = self.videoDevice else { return }
        
        do {
            try videoDevice.lockForConfiguration()
            
            // 恢复连续自动对焦模式
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
                print("🔄 恢复连续自动对焦模式")
            }
            
            // 恢复连续曝光模式
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            
            videoDevice.unlockForConfiguration()
            
        } catch {
            print("❌ 恢复连续对焦失败: \(error.localizedDescription)")
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