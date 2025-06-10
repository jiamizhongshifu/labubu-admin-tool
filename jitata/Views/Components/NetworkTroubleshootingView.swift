import SwiftUI

/// 网络故障排除视图
struct NetworkTroubleshootingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isRetrying = false
    
    let onRetry: () async -> Void
    let errorMessage: String
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 错误图标
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                    .padding(.top, 20)
                
                // 标题
                Text("网络连接问题")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 错误信息
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 故障排除建议
                VStack(alignment: .leading, spacing: 12) {
                    Text("请尝试以下解决方案：")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    TroubleshootingItem(
                        icon: "wifi",
                        title: "检查WiFi连接",
                        description: "确保设备已连接到稳定的WiFi网络"
                    )
                    
                    TroubleshootingItem(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "尝试移动网络",
                        description: "如果WiFi不稳定，可以切换到移动数据"
                    )
                    
                    TroubleshootingItem(
                        icon: "arrow.clockwise",
                        title: "重启网络",
                        description: "关闭并重新打开WiFi或移动数据"
                    )
                    
                    TroubleshootingItem(
                        icon: "location",
                        title: "更换位置",
                        description: "移动到信号更好的位置"
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            isRetrying = true
                            await onRetry()
                            isRetrying = false
                        }
                    }) {
                        HStack {
                            if isRetrying {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            }
                            Text(isRetrying ? "正在重试..." : "重试")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRetrying)
                    
                    Button("稍后再试") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("网络问题")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// 故障排除项目视图
struct TroubleshootingItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    NetworkTroubleshootingView(
        onRetry: {
            // 模拟重试
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        },
        errorMessage: "网络连接丢失，无法连接到AI增强服务器"
    )
} 