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
    
    // 取景框相关状态
    @State private var focusPoint: CGPoint = CGPoint(x: 0.5, y: 0.5) // 相对坐标 (0-1)
    @State private var showFocusAnimation = false
    
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
                CameraPreviewView(cameraManager: cameraManager) { location in
                    handleTapToFocus(at: location)
                }
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
                        HapticFeedbackManager.shared.lightTap()
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
                
                // 中间区域 - 动态取景框
                GeometryReader { geometry in
                    ZStack {
                        // 动态取景框
                        ModernViewfinder(
                            focusPoint: focusPoint,
                            showAnimation: showFocusAnimation,
                            screenSize: geometry.size
                        )
                        .allowsHitTesting(false) // 不拦截点击事件
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
                        HapticFeedbackManager.shared.lightTap()
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
                        HapticFeedbackManager.shared.lightTap()
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
                        HapticFeedbackManager.shared.lightTap()
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
    
    // MARK: - 点击对焦处理
    private func handleTapToFocus(at location: CGPoint) {
        HapticFeedbackManager.shared.lightTap()
        
        // 获取屏幕尺寸
        let screenSize = UIScreen.main.bounds.size
        
        // 计算相对坐标 (0-1)，限制在安全范围内
        let relativeX = max(0.1, min(0.9, location.x / screenSize.width))
        let relativeY = max(0.1, min(0.9, location.y / screenSize.height))
        
        // 更新焦点位置
        withAnimation(.easeInOut(duration: 0.3)) {
            focusPoint = CGPoint(x: relativeX, y: relativeY)
        }
        
        // 显示对焦动画
        showFocusAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFocusAnimation = false
            }
        }
        
        print("🎯 点击对焦: 屏幕坐标(\(location.x), \(location.y)) -> 相对坐标(\(relativeX), \(relativeY))")
    }
}

// MARK: - 现代化取景框组件
struct ModernViewfinder: View {
    let focusPoint: CGPoint
    let showAnimation: Bool
    let screenSize: CGSize
    
    private let viewfinderSize: CGFloat = 120
    
    var body: some View {
        ZStack {
            // 计算取景框在屏幕上的实际位置
            let centerX = focusPoint.x * screenSize.width
            let centerY = focusPoint.y * screenSize.height
            
            // 只显示四个断开的圆角，不要外边框
            ForEach(0..<4, id: \.self) { index in
                ReferenceCornerBracket(corner: Corner.allCases[index])
                    .position(
                        x: centerX + cornerOffset(for: Corner.allCases[index]).x,
                        y: centerY + cornerOffset(for: Corner.allCases[index]).y
                    )
                    .opacity(showAnimation ? 1.0 : 0.8)
                    .scaleEffect(showAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: showAnimation)
            }
        }
    }
    
    private func cornerOffset(for corner: Corner) -> CGPoint {
        let offset = viewfinderSize / 2
        switch corner {
        case .topLeft:
            return CGPoint(x: -offset, y: -offset)
        case .topRight:
            return CGPoint(x: offset, y: -offset)
        case .bottomLeft:
            return CGPoint(x: -offset, y: offset)
        case .bottomRight:
            return CGPoint(x: offset, y: offset)
        }
    }
}

// MARK: - 参考图样式角标组件
struct ReferenceCornerBracket: View {
    let corner: Corner
    
    private let lineLength: CGFloat = 30
    private let lineWidth: CGFloat = 5
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        ZStack {
            switch corner {
            case .topLeft:
                Path { path in
                    // 垂直线（带圆角）
                    path.move(to: CGPoint(x: 0, y: lineLength))
                    path.addLine(to: CGPoint(x: 0, y: cornerRadius))
                    path.addQuadCurve(to: CGPoint(x: cornerRadius, y: 0), control: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: lineLength, y: 0))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
            case .topRight:
                Path { path in
                    // 水平线到垂直线（带圆角）
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: lineLength - cornerRadius, y: 0))
                    path.addQuadCurve(to: CGPoint(x: lineLength, y: cornerRadius), control: CGPoint(x: lineLength, y: 0))
                    path.addLine(to: CGPoint(x: lineLength, y: lineLength))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
            case .bottomLeft:
                Path { path in
                    // 垂直线到水平线（带圆角）
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: lineLength - cornerRadius))
                    path.addQuadCurve(to: CGPoint(x: cornerRadius, y: lineLength), control: CGPoint(x: 0, y: lineLength))
                    path.addLine(to: CGPoint(x: lineLength, y: lineLength))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                
            case .bottomRight:
                Path { path in
                    // 水平线到垂直线（带圆角）
                    path.move(to: CGPoint(x: 0, y: lineLength))
                    path.addLine(to: CGPoint(x: lineLength - cornerRadius, y: lineLength))
                    path.addQuadCurve(to: CGPoint(x: lineLength, y: lineLength - cornerRadius), control: CGPoint(x: lineLength, y: lineLength))
                    path.addLine(to: CGPoint(x: lineLength, y: 0))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }
        }
        .frame(width: lineLength, height: lineLength)
    }
}

// MARK: - 角落枚举
enum Corner: CaseIterable {
    case topLeft, topRight, bottomLeft, bottomRight
}



#Preview {
    CameraView(appState: .constant(.camera))
} 