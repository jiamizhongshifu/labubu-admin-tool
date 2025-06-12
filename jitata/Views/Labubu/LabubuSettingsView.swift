import SwiftUI

/// 简化的Labubu设置视图
struct LabubuSettingsView: View {
    @StateObject private var databaseManager = LabubuDatabaseManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // 用户设置
    @AppStorage("labubu_enable_haptic") private var enableHaptic = true
    @AppStorage("labubu_confidence_threshold") private var confidenceThreshold = 0.6
    @AppStorage("labubu_show_alternatives") private var showAlternatives = true
    @AppStorage("labubu_auto_save_results") private var autoSaveResults = true
    
    var body: some View {
        NavigationView {
            List {
                // 识别设置
                Section("识别设置") {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("置信度阈值")
                                .font(.subheadline)
                            
                            Text("低于此值的识别结果将被忽略")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(confidenceThreshold * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: $confidenceThreshold, in: 0.3...0.9, step: 0.1)
                        .padding(.leading, 32)
                    
                    Toggle(isOn: $showAlternatives) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.green)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("显示备选结果")
                                    .font(.subheadline)
                                
                                Text("显示其他可能的匹配结果")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Toggle(isOn: $autoSaveResults) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("自动保存结果")
                                    .font(.subheadline)
                                
                                Text("自动保存识别结果到相册")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 用户体验
                Section("用户体验") {
                    Toggle(isOn: $enableHaptic) {
                        HStack {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                                .foregroundColor(.orange)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("触觉反馈")
                                    .font(.subheadline)
                                
                                Text("识别过程中提供触觉反馈")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 数据库信息
                Section("数据库信息") {
                    HStack {
                        Image(systemName: "cylinder.split.1x2")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Labubu模型数量")
                                .font(.subheadline)
                            
                            Text("本地数据库中的模型数量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(databaseManager.models.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("系列数量")
                                .font(.subheadline)
                            
                            Text("可识别的Labubu系列数量")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(databaseManager.series.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("识别方式")
                                .font(.subheadline)
                            
                            Text("基于数据库比对的本地识别")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(.orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("识别速度")
                                .font(.subheadline)
                            
                            Text("通常在1-2秒内完成")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "checkmark.shield")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("隐私保护")
                                .font(.subheadline)
                            
                            Text("所有识别在本地完成，不上传图片")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // 重置选项
                Section("重置") {
                    Button(action: resetSettings) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("重置所有设置")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Labubu设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 私有方法
    
    private func resetSettings() {
        enableHaptic = true
        confidenceThreshold = 0.6
        showAlternatives = true
        autoSaveResults = true
    }
}

// MARK: - 预览

#Preview {
    LabubuSettingsView()
} 
