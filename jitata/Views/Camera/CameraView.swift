//
//  CameraView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var visionService = VisionService.shared
    @State private var showingImagePicker = false
    @State private var showingPhotoCapture = false
    @State private var capturedImage: UIImage?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingImageProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // 标题和描述
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("拍照收集潮玩")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("拍摄你喜爱的潮流玩具，我们会自动移除背景并制作成精美贴纸")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // 拍照按钮
                VStack(spacing: 20) {
                    Button(action: {
                        checkCameraPermission()
                    }) {
                        VStack {
                            Image(systemName: "camera.circle.fill")
                                .font(.system(size: 50))
                            Text("拍照")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(radius: 10)
                    }
                    
                    // 从相册选择
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("从相册选择")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
                
                // 功能说明
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "scissors", title: "智能抠图", description: "自动移除背景")
                    FeatureRow(icon: "wand.and.stars", title: "贴纸特效", description: "制作精美贴纸")
                    FeatureRow(icon: "folder", title: "自动保存", description: "添加到我的图鉴")
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("拍照收集")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage)
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureView(capturedImage: $capturedImage)
        }
        .onChange(of: capturedImage) { image in
            if let image = image {
                showingImageProcessing = true
            }
        }
        .fullScreenCover(isPresented: $showingImageProcessing) {
            if let image = capturedImage {
                ImageProcessingView(originalImage: image)
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func checkCameraPermission() {
        // 检查是否在模拟器中运行
        #if targetEnvironment(simulator)
        // 模拟器中直接使用照片库
        showingPhotoCapture = true
        return
        #endif
        
        // 检查相机是否可用
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            alertMessage = "设备不支持相机功能，将使用照片库"
            showingAlert = true
            showingPhotoCapture = true  // 即使没有相机也显示选择器
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async {
                self.showingPhotoCapture = true
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showingPhotoCapture = true
                    } else {
                        self.alertMessage = "需要相机权限才能拍照，请在设置中开启"
                        self.showingAlert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.alertMessage = "请在设置 → 隐私与安全性 → 相机中开启Jitata的相机权限"
                self.showingAlert = true
            }
        @unknown default:
            DispatchQueue.main.async {
                self.alertMessage = "相机权限状态未知，请重试"
                self.showingAlert = true
            }
        }
    }
    

}

// MARK: - 功能说明行
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 相机管理器
class CameraManager: ObservableObject {
    
}

#Preview {
    CameraView()
} 