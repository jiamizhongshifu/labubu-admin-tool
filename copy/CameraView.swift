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
    @Binding var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingPhotoPreview = false
    
    // 日期格式化器
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    var body: some View {
        ZStack {
            // 相机预览背景
            if cameraManager.hasPermission && cameraManager.isSessionRunning {
                CameraPreviewView(cameraManager: cameraManager)
                    .ignoresSafeArea()
            } else {
                // 无权限或相机未启动时的黑色背景
                Color.black
                    .ignoresSafeArea()
            }
            

            
            VStack {
                // 顶部区域 - 返回按钮、日期和提示文字
                HStack {
                    // 返回按钮
                    Button(action: {
                        cameraManager.stopSession()
                        appState = .home
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(dateFormatter.string(from: Date()))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("拍摄你的潮玩")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
                
                // 中间区域 - 取景框
                ZStack {
                    // 取景框
                    VStack {
                        Spacer()
                        
                        ZStack {
                            // 取景框背景
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 280, height: 280)
                            
                            // 四个角的装饰
                            VStack {
                                HStack {
                                    CornerBracket(position: .topLeft)
                                    Spacer()
                                    CornerBracket(position: .topRight)
                                }
                                Spacer()
                                HStack {
                                    CornerBracket(position: .bottomLeft)
                                    Spacer()
                                    CornerBracket(position: .bottomRight)
                                }
                            }
                            .frame(width: 280, height: 280)
                            
                            // 中心提示文字
                            Text("将物体放置在框内")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 320)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // 底部区域 - 拍摄按钮和相册入口
                HStack {
                    // 左侧占位
                    Spacer()
                        .frame(width: 60)
                    
                    Spacer()
                    
                    // 中间拍摄按钮
                    Button(action: {
                        capturePhoto()
                    }) {
                        ZStack {
                            // 外圈
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            // 内圈
                            Circle()
                                .fill(Color.white)
                                .frame(width: 64, height: 64)
                        }
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: cameraManager.capturedImage)
                    
                    Spacer()
                    
                    // 右侧相册入口
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            
            // 权限提示
            if !cameraManager.hasPermission {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("需要相机权限")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("请在设置中开启相机权限以使用拍照功能")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("去设置") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.capturedImage) { _, image in
            if image != nil {
                showingPhotoPreview = true
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $cameraManager.capturedImage)
        }
        .fullScreenCover(isPresented: $showingPhotoPreview) {
            if let capturedImage = cameraManager.capturedImage {
                PhotoPreviewView(
                    originalImage: capturedImage,
                    onSaveSuccess: {
                        // 🎯 修复：同时关闭预览页面和跳转到图鉴页面，显示收集成功toast
                        showingPhotoPreview = false
                        appState = .collection(showSuccessToast: true)
                    },
                    onCancel: {
                        showingPhotoPreview = false
                    }
                )
                .onDisappear {
                    // 清除已拍摄的图片，准备下次拍摄
                    cameraManager.capturedImage = nil
                }
            }
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func capturePhoto() {
        #if targetEnvironment(simulator)
        // 模拟器中创建示例图片
        if let sampleImage = createSampleImage() {
            cameraManager.capturedImage = sampleImage
        } else {
            showingImagePicker = true
        }
        #else
        // 真机上使用相机拍照
        if cameraManager.hasPermission && cameraManager.isSessionRunning {
            cameraManager.capturePhoto()
        } else {
            alertMessage = "相机未准备就绪，请检查权限设置"
            showingAlert = true
        }
        #endif
    }
    
    private func createSampleImage() -> UIImage? {
        // 创建一个简单的示例图片用于模拟器测试
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // 绘制背景
        UIColor.systemBlue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        
        // 绘制文字
        let text = "示例潮玩"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - 取景框角落装饰组件
struct CornerBracket: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let position: Position
    
    var body: some View {
        ZStack {
            switch position {
            case .topLeft:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                    Spacer()
                }
            case .topRight:
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                    }
                    Spacer()
                }
            case .bottomLeft:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                        Spacer()
                    }
                }
            case .bottomRight:
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 20)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 20, height: 3)
                    }
                }
            }
        }
        .frame(width: 23, height: 23)
    }
}



#Preview {
    CameraView(appState: .constant(.camera))
} 