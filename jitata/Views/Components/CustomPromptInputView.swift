import SwiftUI

/// 自定义提示词输入界面
struct CustomPromptInputView: View {
    let sticker: ToySticker
    let onEnhance: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var customPrompt: String = ""
    @State private var selectedModel: AIModel = .fluxKontext
    @State private var showingTemplates: Bool = false
    @State private var isKeyboardVisible: Bool = false
    @FocusState private var isTextEditorFocused: Bool
    
    // 键盘监听方法
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = false
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题和说明
                VStack(spacing: 8) {
                    Text("AI增强设置")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("输入您想要的增强效果描述，选择AI模型")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // 模型选择 - 键盘弹起时缩小
                VStack(alignment: .leading, spacing: isKeyboardVisible ? 8 : 12) {
                    Text("选择AI模型")
                        .font(isKeyboardVisible ? .subheadline : .headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: isKeyboardVisible ? 8 : 12) {
                        ForEach(AIModel.allCases) { model in
                            ModelSelectionCard(
                                model: model,
                                isSelected: selectedModel == model,
                                isCompact: isKeyboardVisible
                            ) {
                                selectedModel = model
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
                
                // 提示词输入区域 - 键盘弹起时变大
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("增强提示词")
                            .font(isKeyboardVisible ? .subheadline : .headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if !isKeyboardVisible {
                            Button("模板") {
                                showingTemplates = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $customPrompt)
                            .frame(minHeight: isKeyboardVisible ? 200 : 120)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isKeyboardVisible ? Color.blue.opacity(0.5) : Color(.systemGray4), lineWidth: isKeyboardVisible ? 2 : 1)
                            )
                            .focused($isTextEditorFocused)
                        
                        // 占位符文本
                        if customPrompt.isEmpty {
                            Text("请输入您想要的增强效果描述...")
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                    
                    if !isKeyboardVisible {
                        Text("描述您希望的增强效果，例如：提升色彩饱和度、增强材质质感、添加光影效果等")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        if !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onEnhance(customPrompt)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("开始AI增强")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [Color.gray, Color.gray] : [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button("取消") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // 不再自动填充默认提示词，让用户自己输入
            setupKeyboardObservers()
        }
        .onDisappear {
            removeKeyboardObservers()
        }
        .onChange(of: isTextEditorFocused) { _, focused in
            withAnimation(.easeInOut(duration: 0.3)) {
                isKeyboardVisible = focused
            }
        }
        .sheet(isPresented: $showingTemplates) {
            PromptTemplatesView(selectedPrompt: $customPrompt)
        }
    }
}

/// 模型选择卡片
struct ModelSelectionCard: View {
    let model: AIModel
    let isSelected: Bool
    let isCompact: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            if isCompact {
                // 紧凑模式 - 键盘弹起时的简化布局
                HStack(spacing: 8) {
                    Image(systemName: model.iconName)
                        .font(.title3)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Text(model.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? 
                              LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing) :
                              LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]), startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
            } else {
                // 正常模式 - 完整布局
                VStack(spacing: 8) {
                    Image(systemName: model.iconName)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    Text(model.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(model.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? 
                              LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing) :
                              LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
                .scaleEffect(isSelected ? 1.05 : 1.0)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: isCompact)
    }
}

/// 提示词模板选择界面
struct PromptTemplatesView: View {
    @Binding var selectedPrompt: String
    @Environment(\.presentationMode) var presentationMode
    
    private let templates = PromptManager.shared.getPromptTemplates()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("选择提示词模板")) {
                    ForEach(templates, id: \.self) { template in
                        Button(action: {
                            selectedPrompt = template
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .navigationTitle("提示词模板")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

