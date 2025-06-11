import SwiftUI

struct PirateBubbleView: View {
    @Binding var isVisible: Bool
    @State private var currentMessage: String = ""
    @State private var animationOffset: CGFloat = 50
    @State private var animationOpacity: Double = 0
    
    // 海盗风格对话内容
    private let pirateMessages = [
        "想不想跟我一起出海冒险？",
        "船长，准备好扬帆起航了吗？",
        "宝藏就在前方，跟我来吧！",
        "勇敢的水手，加入我的船队吧！",
        "海风在呼唤，我们出发吧！",
        "传说中的宝岛等着我们探索！",
        "船长，是时候征服七海了！",
        "跟着我，寻找失落的黄金！",
        "海盗的冒险即将开始，准备好了吗？",
        "勇敢的心，无畏的魂，一起闯荡吧！"
    ]
    
    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    // 对话气泡
                    Button(action: {
                        dismissBubble()
                    }) {
                        HStack(spacing: 12) {
                            // 海盗头像图标
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            
                            // 对话文字
                            Text(currentMessage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            // 毛玻璃背景效果
                            ZStack {
                                // 基础毛玻璃层
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.85)
                                
                                // 渐变色彩层
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.pink.opacity(0.3),
                                                Color.yellow.opacity(0.2),
                                                Color.green.opacity(0.2),
                                                Color.blue.opacity(0.3)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                // 边缘发光效果
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.6),
                                                Color.white.opacity(0.2),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .shadow(color: .white.opacity(0.1), radius: 5, x: 0, y: -2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(animationOpacity == 1 ? 1 : 0.8)
                    .offset(y: animationOffset)
                    .opacity(animationOpacity)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120) // 避免与底部导航栏重叠
            }
            .onAppear {
                setupRandomMessage()
                animateIn()
            }
        }
    }
    
    // 设置随机消息
    private func setupRandomMessage() {
        currentMessage = pirateMessages.randomElement() ?? pirateMessages[0]
    }
    
    // 入场动画
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationOffset = 0
            animationOpacity = 1
        }
    }
    
    // 消失动画
    private func dismissBubble() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationOffset = 50
            animationOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isVisible = false
        }
    }
}

// 预览
struct PirateBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PirateBubbleView(isVisible: .constant(true))
        }
    }
} 