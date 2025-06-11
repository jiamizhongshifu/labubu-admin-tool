import SwiftUI

/// 调试版本的HomeView，用于测试界面显示问题
struct DebugHomeView: View {
    @State private var debugMessage = "正在初始化..."
    
    var body: some View {
        ZStack {
            // 明显的背景色，确保视图可见
            Color.red.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🐛 调试模式")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(debugMessage)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("测试按钮") {
                    debugMessage = "按钮点击成功！\n时间: \(Date().formatted())"
                }
                .font(.title3)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("系统信息:")
                        .font(.headline)
                    
                    Text("• iOS版本: \(UIDevice.current.systemVersion)")
                    Text("• 设备型号: \(UIDevice.current.model)")
                    Text("• 屏幕尺寸: \(UIScreen.main.bounds.size)")
                }
                .font(.caption)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            print("🐛 DebugHomeView appeared")
            debugMessage = "界面加载成功！\n如果您能看到这个消息，说明SwiftUI渲染正常。"
        }
    }
}

#Preview {
    DebugHomeView()
} 