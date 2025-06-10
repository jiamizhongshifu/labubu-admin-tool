import SwiftUI

/// 自定义提示词输入界面
struct CustomPromptInputView: View {
    @Binding var isPresented: Bool
    @State private var customPrompt: String = ""
    @State private var selectedModel: AIModel = .fluxKontext
    @State private var showingTemplates: Bool = false
    
    let onConfirm: (String, AIModel) -> Void
    
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
                
                // 模型选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择AI模型")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(AIModel.allCases) { model in
                            ModelSelectionCard(
                                model: model,
                                isSelected: selectedModel == model
                            ) {
                                selectedModel = model
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // 提示词输入区域
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("增强提示词")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button("模板") {
                            showingTemplates = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                    
                    TextEditor(text: $customPrompt)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    
                    Text("描述您希望的增强效果，例如：提升色彩饱和度、增强材质质感、添加光影效果等")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 操作按钮
                VStack(spacing: 12) {
                    Button(action: {
                        if !customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onConfirm(customPrompt, selectedModel)
                            isPresented = false
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
                        isPresented = false
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
            // 设置默认提示词
            if customPrompt.isEmpty {
                customPrompt = PromptManager.shared.getDefaultPrompt()
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
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

#Preview {
    CustomPromptInputView(isPresented: .constant(true)) { prompt, model in
        print("Selected prompt: \(prompt)")
        print("Selected model: \(model)")
    }
} 