//
//  LabubuFamilyTreeView.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import SwiftUI

/// Labubu族谱视图（简化版本）
struct LabubuFamilyTreeView: View {
    let recognitionResult: LabubuRecognitionResult
    @Environment(\.dismiss) private var dismiss
    @StateObject private var databaseManager = LabubuDatabaseManager.shared
    @State private var showingReRecognition = false
    
    // 重新识别的回调
    let onReRecognition: ((LabubuRecognitionResult) -> Void)?
    
    init(recognitionResult: LabubuRecognitionResult, onReRecognition: ((LabubuRecognitionResult) -> Void)? = nil) {
        self.recognitionResult = recognitionResult
        self.onReRecognition = onReRecognition
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 识别结果头部
                    recognitionHeader
                    
                    // 基本信息卡片
                    basicInfoCard
                    
                    // 价格信息卡片
                    priceInfoCard
                    
                    // 系列信息卡片
                    seriesInfoCard
                    
                    // 识别详情卡片
                    recognitionDetailsCard
                }
                .padding()
            }
            .navigationTitle("资料页")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
    
    // MARK: - 视图组件
    
    private var recognitionHeader: some View {
        VStack(spacing: 12) {
            // 识别的图片
            Image(uiImage: recognitionResult.originalImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)
            
            // 识别结果标题
            VStack(spacing: 4) {
                Text(recognitionResult.bestMatch?.model.name ?? "未识别")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(recognitionResult.bestMatch?.series?.name ?? "未知系列")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("基本信息")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "名称", value: recognitionResult.bestMatch?.model.name ?? "未知")
                InfoRow(title: "系列", value: recognitionResult.bestMatch?.series?.name ?? "未知系列")
                InfoRow(title: "稀有度", value: recognitionResult.bestMatch?.model.rarity.displayName ?? "未知")
                InfoRow(title: "识别置信度", value: String(format: "%.1f%%", recognitionResult.confidence * 100))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var priceInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.green)
                Text("价格信息")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if let price = recognitionResult.bestMatch?.model.currentMarketPrice?.average {
                    InfoRow(title: "市场均价", value: "¥\(String(format: "%.0f", price))")
                } else {
                    InfoRow(title: "市场均价", value: "暂无数据")
                }
                
                if let originalPrice = recognitionResult.bestMatch?.model.originalPrice {
                    InfoRow(title: "发售价", value: "¥\(String(format: "%.0f", originalPrice))")
                } else {
                    InfoRow(title: "发售价", value: "暂无数据")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var seriesInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundColor(.purple)
                Text("系列信息")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "系列名称", value: recognitionResult.bestMatch?.series?.name ?? "未知系列")
                InfoRow(title: "系列描述", value: recognitionResult.bestMatch?.series?.description ?? "暂无描述")
                
                // 简化的族谱成员数量显示
                let seriesModels = databaseManager.getModels(for: recognitionResult.bestMatch?.model.seriesId ?? "")
                InfoRow(title: "系列成员", value: "\(seriesModels.count) 个")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var recognitionDetailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.orange)
                Text("识别详情")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "识别方法", value: "数据库比对")
                InfoRow(title: "处理时间", value: String(format: "%.2f秒", recognitionResult.processingTime))
                InfoRow(title: "识别时间", value: DateFormatter.localizedString(from: recognitionResult.timestamp, dateStyle: .medium, timeStyle: .short))
                
                if let matchedFeatures = recognitionResult.bestMatch?.matchedFeatures, !matchedFeatures.isEmpty {
                    InfoRow(title: "匹配特征", value: matchedFeatures.joined(separator: ", "))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 重新识别视图
    private var reRecognitionView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 原始图片
                Image(uiImage: recognitionResult.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                Text("重新识别这张图片")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("将使用最新的识别算法重新分析这张图片")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // 重新识别按钮
                LabubuRecognitionButton(
                    image: recognitionResult.originalImage,
                    onRecognitionComplete: { newResult in
                        // 识别完成后的回调
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
}

// MARK: - 辅助视图
// InfoRow已在LabubuRecognitionButton.swift中定义

// MARK: - 预览

#Preview {
    // 创建示例图片
    let sampleImage = UIImage(systemName: "heart.fill") ?? UIImage()
    
    // 创建示例视觉特征
    let sampleVisualFeatures = VisualFeatures(
        primaryColors: [],
        colorDistribution: [:],
        shapeDescriptor: ShapeDescriptor(
            aspectRatio: 1.0,
            roundness: 0.8,
            symmetry: 0.9,
            complexity: 0.5,
            keyPoints: []
        ),
        contourPoints: nil,
        textureFeatures: LabubuTextureFeatures(
            smoothness: 0.7,
            roughness: 0.3,
            patterns: [],
            materialType: .plush
        ),
        specialMarks: [],
        featureVector: []
    )
    
    // 创建示例匹配结果
    let sampleMatch = LabubuModel(
        id: "labubu_001",
        name: "经典粉色Labubu",
        nameCN: "经典粉色拉布布",
        seriesId: "series_001",
        variant: .standard,
        rarity: .common,
        releaseDate: Date(),
        originalPrice: 199.0,
        currentMarketPrice: MarketPrice(
            average: 299.0,
            min: 250.0,
            max: 350.0,
            lastUpdated: Date(),
            source: "市场数据"
        ),
        referenceImages: [],
        visualFeatures: sampleVisualFeatures,
        tags: ["经典", "粉色"],
        description: "最经典的粉色款式，深受收藏家喜爱"
    )
    
    // 创建示例系列
    let sampleSeries = LabubuSeries(
        id: "series_001",
        name: "经典系列",
        nameCN: "经典系列",
        description: "Labubu的经典系列，包含多种颜色款式",
        releaseDate: Date(),
        theme: "经典",
        totalVariants: 12,
        imageURL: nil,
        isLimited: false,
        averagePrice: 299.0,
        isActive: true
    )
    
    let sampleResult = LabubuRecognitionResult(
        originalImage: sampleImage,
        bestMatch: LabubuMatch(
            model: sampleMatch,
            series: sampleSeries,
            confidence: 0.85,
            matchedFeatures: ["颜色匹配", "形状相似"]
        ),
        alternatives: [],
        confidence: 0.85,
        processingTime: 1.2,
        features: sampleVisualFeatures,
        timestamp: Date()
    )
    
    LabubuFamilyTreeView(recognitionResult: sampleResult)
} 