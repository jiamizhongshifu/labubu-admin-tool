//
//  LabubuRecognitionButton.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import SwiftUI

/// 简化的Labubu识别按钮
struct LabubuRecognitionButton: View {
    let image: UIImage
    let onRecognitionComplete: (LabubuRecognitionResult) -> Void
    
    @StateObject private var recognitionService = LabubuRecognitionService.shared
    @StateObject private var aiRecognitionService = LabubuAIRecognitionService.shared
    @State private var recognitionState: LabubuRecognitionState = .idle
    @State private var recognitionResult: LabubuRecognitionResult?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // 主识别按钮
            Button(action: startRecognition) {
                buttonContent
            }
            .disabled(recognitionService.isRecognizing)
            
            // 进度条
            if recognitionService.isRecognizing {
                progressSection
            }
            
            // 错误信息
            if let errorMessage = errorMessage {
                errorSection(errorMessage)
            }
        }
    }
    
    // MARK: - 视图组件
    
    private var buttonContent: some View {
        HStack(spacing: 12) {
            recognitionIcon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if recognitionService.isRecognizing {
                    Text("正在识别中...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            if recognitionService.isRecognizing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(buttonBackgroundColor)
        )
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressView(value: recognitionService.recognitionProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(Int(recognitionService.recognitionProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .padding(.horizontal)
    }
    
    private var recognitionIcon: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(.white)
    }
    
    private var buttonTitle: String {
        switch recognitionState {
        case .idle:
            return "识别Labubu"
        case .recognizing:
            return "识别中..."
        case .completed:
            return "重新识别"
        case .failed:
            return "重试识别"
        }
    }
    
    private var iconName: String {
        switch recognitionState {
        case .idle:
            return "camera.viewfinder"
        case .recognizing:
            return "magnifyingglass"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch recognitionState {
        case .idle:
            return .blue
        case .recognizing:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    // MARK: - 识别逻辑
    
    private func startRecognition() {
        Task {
            await performRecognition()
        }
    }
    
    @MainActor
    private func performRecognition() async {
        recognitionState = .recognizing
        errorMessage = nil
        
        do {
            // 优先尝试AI识别
            print("🤖 尝试AI识别...")
            let aiResult = try await aiRecognitionService.recognizeUserPhoto(image)
            
            // 转换AI识别结果为标准格式
            let result = convertAIResultToStandardResult(aiResult, originalImage: image)
            
            recognitionResult = result
            recognitionState = .completed
            onRecognitionComplete(result)
            
        } catch {
            print("⚠️ AI识别失败，降级到简单识别: \(error)")
            
            // AI识别失败，降级到简单识别
            do {
                let result = try await recognitionService.recognizeLabubu(image)
                
                recognitionResult = result
                recognitionState = .completed
                onRecognitionComplete(result)
                
            } catch let fallbackError {
                recognitionState = .failed
                errorMessage = "识别失败: \(fallbackError.localizedDescription)"
                
                // 3秒后重置状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    recognitionState = .idle
                    errorMessage = nil
                }
            }
        }
    }
    
    /// 转换AI识别结果为标准识别结果格式
    private func convertAIResultToStandardResult(_ aiResult: LabubuAIRecognitionResult, originalImage: UIImage) -> LabubuRecognitionResult {
        // 转换匹配结果
        let bestMatch: LabubuMatch? = aiResult.matchResults.first.map { dbMatch in
            LabubuMatch(
                model: dbMatch.model,
                series: nil, // AI结果中没有series信息，可以后续查询
                confidence: dbMatch.similarity,
                matchedFeatures: dbMatch.matchedFeatures
            )
        }
        
        // 转换备选项
        let alternatives = aiResult.matchResults.dropFirst().map { $0.model }
        
        // 创建默认特征
        let features = VisualFeatures(
            primaryColors: [],
            colorDistribution: [:],
            shapeDescriptor: ShapeDescriptor(
                aspectRatio: 0.8,
                roundness: 0.85,
                symmetry: 0.9,
                complexity: 0.4,
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
        
        return LabubuRecognitionResult(
            originalImage: originalImage,
            bestMatch: bestMatch,
            alternatives: Array(alternatives),
            confidence: aiResult.confidence,
            processingTime: aiResult.processingTime,
            features: features,
            timestamp: aiResult.timestamp
        )
    }
}

// MARK: - 识别状态

enum LabubuRecognitionState {
    case idle
    case recognizing
    case completed
    case failed
}

// MARK: - 识别结果视图

struct LabubuRecognitionResultView: View {
    let result: LabubuRecognitionResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    originalImageView
                    resultContentView
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
    
    private var originalImageView: some View {
        Image(uiImage: result.originalImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 200)
            .cornerRadius(12)
    }
    
    private var resultContentView: some View {
        Group {
            if let match = result.bestMatch {
                matchedResultView(match: match)
            } else {
                noMatchView
            }
        }
    }
    
    private func matchedResultView(match: LabubuMatch) -> some View {
        VStack(spacing: 16) {
            matchInfoView(match: match)
            confidenceView
            detailInfoView(match: match)
        }
    }
    
    private func matchInfoView(match: LabubuMatch) -> some View {
        VStack(spacing: 8) {
            Text(match.model.nameCN)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(match.model.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let series = match.series {
                Text(series.nameCN)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
            }
        }
    }
    
    private var confidenceView: some View {
        VStack(spacing: 4) {
            Text("识别置信度")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: result.confidence)
                .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor))
            
            Text("\(Int(result.confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    private func detailInfoView(match: LabubuMatch) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("详细信息")
                .font(.headline)
            
            InfoRow(title: "稀有度", value: match.model.rarity.displayName)
            InfoRow(title: "发布日期", value: formatDate(match.model.releaseDate ?? Date()))
            InfoRow(title: "原价", value: "¥\(Int(match.model.originalPrice ?? 0))")
            
            if let description = match.model.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var noMatchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("未能识别")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("抱歉，无法识别这个Labubu款式")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var confidenceColor: Color {
        if result.confidence > 0.8 {
            return .green
        } else if result.confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - 辅助视图

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - 预览

#Preview {
    LabubuRecognitionButton(
        image: UIImage(systemName: "photo")!,
        onRecognitionComplete: { _ in }
    )
} 