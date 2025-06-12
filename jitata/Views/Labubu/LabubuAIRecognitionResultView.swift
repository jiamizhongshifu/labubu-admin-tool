//
//  LabubuAIRecognitionResultView.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import SwiftUI

/// Labubu AI识别结果展示视图
struct LabubuAIRecognitionResultView: View {
    let result: LabubuAIRecognitionResult
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMatchIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 原始图片
                    originalImageSection
                    
                    // AI分析结果
                    aiAnalysisSection
                    
                    // 匹配结果
                    if !result.matchResults.isEmpty {
                        matchResultsSection
                    } else {
                        noMatchSection
                    }
                    
                    // 详细信息
                    detailsSection
                }
                .padding()
            }
            .navigationTitle("识别结果")
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
    
    // MARK: - 原始图片部分
    private var originalImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("拍摄图片")
                .font(.headline)
                .foregroundColor(.primary)
            
            Image(uiImage: result.originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 200)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
    
    // MARK: - AI分析结果部分
    private var aiAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI分析结果")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 置信度显示
                HStack(spacing: 4) {
                    Image(systemName: result.aiAnalysis.isLabubu ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.aiAnalysis.isLabubu ? .green : .red)
                    
                    Text(result.aiAnalysis.isLabubu ? "是Labubu" : "不是Labubu")
                        .font(.caption)
                        .foregroundColor(result.aiAnalysis.isLabubu ? .green : .red)
                }
            }
            
            // 置信度条
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("置信度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(result.aiAnalysis.confidence * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: result.aiAnalysis.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
            }
            
            // AI描述
            if !result.aiAnalysis.detailedDescription.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("特征描述")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.aiAnalysis.detailedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            // 关键特征
            if !result.aiAnalysis.keyFeatures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("关键特征")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80))
                    ], spacing: 8) {
                        ForEach(result.aiAnalysis.keyFeatures, id: \.self) { feature in
                            Text(feature)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - 匹配结果部分
    private var matchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("匹配结果")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 匹配选择器
            if result.matchResults.count > 1 {
                Picker("选择匹配", selection: $selectedMatchIndex) {
                    ForEach(0..<result.matchResults.count, id: \.self) { index in
                        let match = result.matchResults[index]
                        Text("匹配 \(index + 1) - \(Int(match.similarity * 100))%")
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // 选中的匹配详情
            if selectedMatchIndex < result.matchResults.count {
                let selectedMatch = result.matchResults[selectedMatchIndex]
                matchDetailView(selectedMatch)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - 匹配详情视图
    private func matchDetailView(_ match: LabubuDatabaseMatch) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 模型信息
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.model.nameCN)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !match.model.name.isEmpty && match.model.name != match.model.nameCN {
                        Text(match.model.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("相似度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(match.similarity * 100))%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            // 匹配特征
            if !match.matchedFeatures.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("匹配特征")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80))
                    ], spacing: 6) {
                        ForEach(match.matchedFeatures, id: \.self) { feature in
                            Text(feature)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // 模型描述
            if let description = match.model.description, !description.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("模型描述")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - 无匹配结果部分
    private var noMatchSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("未找到匹配")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("AI识别到这是Labubu，但在数据库中未找到匹配的模型")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - 详细信息部分
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                detailRow("识别时间", value: formatDate(result.timestamp))
                detailRow("处理时长", value: String(format: "%.2f秒", result.processingTime))
                
                if !result.aiAnalysis.seriesHints.isEmpty {
                    detailRow("系列提示", value: result.aiAnalysis.seriesHints)
                }
                
                if !result.aiAnalysis.materialAnalysis.isEmpty {
                    detailRow("材质分析", value: result.aiAnalysis.materialAnalysis)
                }
                
                if !result.aiAnalysis.styleAnalysis.isEmpty {
                    detailRow("风格分析", value: result.aiAnalysis.styleAnalysis)
                }
                
                if !result.aiAnalysis.conditionAssessment.isEmpty {
                    detailRow("状态评估", value: result.aiAnalysis.conditionAssessment)
                }
                
                if !result.aiAnalysis.rarityHints.isEmpty {
                    detailRow("稀有度提示", value: result.aiAnalysis.rarityHints)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - 辅助方法
    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private var confidenceColor: Color {
        switch result.aiAnalysis.confidence {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - 预览
struct LabubuAIRecognitionResultView_Previews: PreviewProvider {
    static var previews: some View {
        LabubuAIRecognitionResultView(result: sampleResult)
    }
    
    static var sampleResult: LabubuAIRecognitionResult {
        let analysis = LabubuAIAnalysis(
            isLabubu: true,
            confidence: 0.85,
            detailedDescription: "这是一个粉色的Labubu玩具，具有圆润的身体形状和可爱的表情。表面光滑，呈现出典型的Labubu特征。",
            visualFeatures: LabubuVisualFeatures(
                dominantColors: ["#FFB6C1", "#FFFFFF"],
                bodyShape: "圆润",
                headShape: "圆形",
                earType: "尖耳",
                surfaceTexture: "光滑",
                patternType: "纯色",
                estimatedSize: "小型"
            ),
            keyFeatures: ["粉色", "圆润", "可爱"],
            seriesHints: "经典系列",
            materialAnalysis: "毛绒材质",
            styleAnalysis: "可爱风格",
            conditionAssessment: "全新",
            rarityHints: "常见"
        )
        
        return LabubuAIRecognitionResult(
            originalImage: UIImage(systemName: "photo") ?? UIImage(),
            aiAnalysis: analysis,
            matchResults: [],
            processingTime: 2.5,
            timestamp: Date()
        )
    }
} 