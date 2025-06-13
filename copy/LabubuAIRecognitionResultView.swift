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
    @State private var showingReRecognition = false
    @State private var modelDetails: LabubuModelData?
    @State private var referenceImages: [String] = []
    @State private var priceHistory: [LabubuPriceHistory] = []
    @State private var isLoadingDetails = false
    
    // 重新识别的回调
    let onReRecognition: ((LabubuAIRecognitionResult) -> Void)?
    
    @StateObject private var databaseManager = LabubuDatabaseManager.shared
    
    init(result: LabubuAIRecognitionResult, onReRecognition: ((LabubuAIRecognitionResult) -> Void)? = nil) {
        self.result = result
        self.onReRecognition = onReRecognition
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 匹配结果 - 最重要的信息放在顶部
                    if !result.matchResults.isEmpty {
                        matchedModelMainSection
                        
                        // 如果有多个匹配结果，显示其他候选
                        if result.matchResults.count > 1 {
                            otherMatchesSection
                        }
                    } else {
                        noMatchSection
                    }
                    
                    // 原始图片对比
                    originalImageComparisonSection
                    
                    // AI分析摘要（简化版）
                    aiAnalysisSummarySection
                }
                .padding()
            }
            .navigationTitle("识别结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重新识别") {
                        showingReRecognition = true
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingReRecognition) {
                reRecognitionView
            }
            .onAppear {
                loadModelDetails()
            }
        }
    }
    
    // MARK: - 匹配模型主要信息部分
    private var matchedModelMainSection: some View {
        let selectedMatch = result.matchResults[selectedMatchIndex]
        
        return VStack(spacing: 16) {
            // 匹配成功标识
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("识别成功")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(Int(selectedMatch.similarity * 100))% 匹配")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
            }
            
            // 模型主图
            if !referenceImages.isEmpty {
                AsyncImage(url: URL(string: referenceImages[0])) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.2)
                        )
                }
                .frame(maxHeight: 250)
                .cornerRadius(16)
                .shadow(radius: 8)
            } else {
                // 如果没有参考图片，显示占位符
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(maxHeight: 250)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("暂无图片")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    )
                    .cornerRadius(16)
            }
            
            // 模型核心信息
            VStack(spacing: 12) {
                // 系列名称
                if let seriesId = selectedMatch.model.seriesId, !seriesId.isEmpty {
                    Text("系列: \(seriesId)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }
                
                // 模型名称
                VStack(spacing: 4) {
                    Text(selectedMatch.model.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    if let nameEn = selectedMatch.model.nameEn, !nameEn.isEmpty && nameEn != selectedMatch.model.name {
                        Text(nameEn)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // 价格和稀有度信息
                HStack(spacing: 20) {
                    // 价格信息
                    VStack(spacing: 4) {
                        Text("参考价格")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let priceMin = selectedMatch.model.estimatedPriceMin, let priceMax = selectedMatch.model.estimatedPriceMax, priceMin > 0 && priceMax > 0 {
                            if priceMin == priceMax {
                                Text("¥\(Int(priceMin))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            } else {
                                Text("¥\(Int(priceMin))-\(Int(priceMax))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text("价格待定")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 稀有度信息
                    VStack(spacing: 4) {
                        Text("稀有度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(selectedMatch.model.rarityLevel)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(rarityColor(selectedMatch.model.rarityLevel))
                    }
                }
                .padding(.vertical, 8)
                
                // 推出时间（如果有的话）
                if !selectedMatch.model.createdAt.isEmpty {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        
                        Text("推出时间")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatCreatedDate(selectedMatch.model.createdAt))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // 模型编号
                if let modelNumber = selectedMatch.model.modelNumber, !modelNumber.isEmpty {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(.secondary)
                        
                        Text("模型编号")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(modelNumber)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
    
    // MARK: - 其他候选匹配结果部分
    private var otherMatchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("其他候选")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 候选选择器
            Picker("选择匹配", selection: $selectedMatchIndex) {
                ForEach(0..<result.matchResults.count, id: \.self) { index in
                    let match = result.matchResults[index]
                    Text("候选 \(index + 1) - \(Int(match.similarity * 100))%")
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // 其他候选的简要信息
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<result.matchResults.count, id: \.self) { index in
                        if index != selectedMatchIndex {
                            let match = result.matchResults[index]
                            otherMatchCard(match, index: index)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - 其他候选卡片
    private func otherMatchCard(_ match: LabubuDatabaseMatch, index: Int) -> some View {
        Button(action: {
            selectedMatchIndex = index
        }) {
            VStack(spacing: 8) {
                // 候选图片
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundColor(.secondary)
                            Text("候选\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    )
                    .cornerRadius(8)
                
                // 候选信息
                VStack(spacing: 2) {
                    Text(match.model.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text("\(Int(match.similarity * 100))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
            }
        }
        .frame(width: 100)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 原始图片对比部分
    private var originalImageComparisonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图片对比")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                // 拍摄图片
                VStack(spacing: 8) {
                    Text("您的拍摄")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: result.originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                // 匹配图片
                VStack(spacing: 8) {
                    Text("匹配模型")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if !result.matchResults.isEmpty && !referenceImages.isEmpty {
                        AsyncImage(url: URL(string: referenceImages[0])) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(0.8)
                                )
                        }
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    } else {
                        // 如果没有参考图片，显示占位符
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                            .frame(height: 120)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                    Text("暂无图片")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            )
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // MARK: - AI分析摘要部分（简化版）
    private var aiAnalysisSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI分析摘要")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                // 置信度
                HStack {
                    Text("AI置信度")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(Int(result.aiAnalysis.confidence * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: result.aiAnalysis.isLabubu ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.aiAnalysis.isLabubu ? .green : .red)
                    }
                }
                
                // 处理时长
                HStack {
                    Text("识别耗时")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f秒", result.processingTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                // 识别时间
                HStack {
                    Text("识别时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDate(result.timestamp))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
    
    // MARK: - 辅助方法
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatCreatedDate(_ dateString: String) -> String {
        // 尝试解析ISO 8601格式的日期字符串
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        
        // 如果解析失败，尝试其他常见格式
        let fallbackFormatter = DateFormatter()
        fallbackFormatter.dateFormat = "yyyy-MM-dd"
        if let date = fallbackFormatter.date(from: String(dateString.prefix(10))) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.locale = Locale(identifier: "zh_CN")
            return displayFormatter.string(from: date)
        }
        
        // 如果都解析失败，返回原始字符串的前10个字符（日期部分）
        return String(dateString.prefix(10))
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
    
    // MARK: - 数据加载方法
    
    /// 加载模型详细信息
    private func loadModelDetails() {
        guard !result.matchResults.isEmpty else { return }
        
        let selectedMatch = result.matchResults[selectedMatchIndex]
        isLoadingDetails = true
        
        // 从数据库管理器获取模型的参考图片
        Task {
            do {
                // 尝试从数据库获取模型的参考图片
                let images = await databaseManager.getModelReferenceImages(modelId: selectedMatch.model.id)
                
                await MainActor.run {
                    self.referenceImages = images
                    self.isLoadingDetails = false
                }
            } catch {
                print("❌ 加载模型参考图片失败: \(error)")
                await MainActor.run {
                    // 如果加载失败，使用空数组
                    self.referenceImages = []
                    self.isLoadingDetails = false
                }
            }
        }
    }
    
    // MARK: - 重新识别视图
    private var reRecognitionView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 原始图片
                Image(uiImage: result.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                Text("重新识别这张图片")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("将使用最新的AI模型重新分析这张图片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // 重新识别按钮
                LabubuRecognitionButton(
                    image: result.originalImage,
                    onRecognitionComplete: { _ in
                        // 旧格式识别完成 - 暂时关闭sheet
                        showingReRecognition = false
                    },
                    onAIRecognitionComplete: { newResult in
                        // AI识别完成后的回调
                        showingReRecognition = false
                        onReRecognition?(newResult)
                        dismiss()
                    }
                )
                
                Spacer()
            }
            .padding()
            .navigationTitle("重新识别")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        showingReRecognition = false
                    }
                }
            }
        }
    }
    
    /// 根据稀有度返回对应颜色
    private func rarityColor(_ rarity: String) -> Color {
        switch rarity.lowercased() {
        case "common", "普通":
            return .gray
        case "uncommon", "不常见":
            return .blue
        case "rare", "稀有":
            return .purple
        case "epic", "史诗":
            return .orange
        case "legendary", "传说":
            return .red
        default:
            return .secondary
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