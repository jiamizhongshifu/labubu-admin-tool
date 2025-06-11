import SwiftUI

/// 相册权限说明视图
struct PhotoLibraryPermissionView: View {
    @Binding var isPresented: Bool
    let onRequestPermission: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                // 图标
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.bottom, 16)
                
                // 标题
                Text("保存到相册")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // 说明文字
                VStack(spacing: 16) {
                    Text("为了保存您的潮玩图片到相册，需要访问相册权限")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionFeatureRow(
                            icon: "photo.fill",
                            title: "保存高清图片",
                            description: "将AI增强后的高清图片保存到相册"
                        )
                        
                        PermissionFeatureRow(
                            icon: "sparkles",
                            title: "保留原始质量",
                            description: "保存时不进行额外压缩，保持最佳画质"
                        )
                        
                        PermissionFeatureRow(
                            icon: "lock.shield",
                            title: "隐私保护",
                            description: "仅用于保存图片，不会访问您的其他照片"
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 12) {
                    Button(action: {
                        onRequestPermission()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("允许访问相册")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("暂不保存")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

/// 权限功能行视图
struct PermissionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PhotoLibraryPermissionView(
        isPresented: .constant(true),
        onRequestPermission: {}
    )
} 