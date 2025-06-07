//
//  HomeView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct HomeView: View {
    @State private var showingCamera = false
    @State private var showingCollection = false
    
    var body: some View {
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
                            showingCamera = true
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
                            showingCollection = true
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
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView()
        }
        .fullScreenCover(isPresented: $showingCollection) {
            NavigationView {
                CollectionView()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showingCollection = false
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
}

#Preview {
    HomeView()
} 