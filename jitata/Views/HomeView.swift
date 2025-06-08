//
//  HomeView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

// 🎯 新增：定义应用的主要页面状态
enum AppState {
    case home
    case camera
    case collection(showSuccessToast: Bool = false) // 添加toast参数
}

struct HomeView: View {
    // 🎯 新增：使用 AppState 来管理当前页面
    @State private var appState: AppState = .home
    
    var body: some View {
        // 🎯 新增：根据 appState 切换页面
        switch appState {
        case .home:
            homeContentView
        case .camera:
            CameraView(appState: $appState)
        case .collection(let showSuccessToast):
            NavigationView {
                CollectionView(showSuccessToast: showSuccessToast, appState: $appState)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                appState = .home
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("返回")
                                        .font(.body)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                        
                        ToolbarItem(placement: .principal) {
                            Text("我的图鉴")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }
    
    // 🎯 新增：将原有的首页内容封装成一个计算属性
    private var homeContentView: some View {
        NavigationView {
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // 应用标题和介绍
                    VStack(spacing: 16) {
                        Text("Jitata")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("潮玩虚拟图鉴")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("拍摄你的潮玩，制作专属贴纸")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // 功能入口按钮
                    VStack(spacing: 24) {
                        // 拍照收集按钮
                        Button(action: {
                            // 🎯 修复：点击按钮时更新 appState
                            appState = .camera
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("拍照收集")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("智能抠图，制作贴纸")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        
                        // 我的图鉴按钮
                        Button(action: {
                            // 🎯 修复：点击按钮时更新 appState
                            appState = .collection()
                        }) {
                            HStack(spacing: 16) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("我的图鉴")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("查看收藏，管理分类")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // 底部装饰
                    VStack(spacing: 8) {
                        Text("让每个潮玩都有自己的数字身份")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("AI智能抠图")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    HomeView()
} 