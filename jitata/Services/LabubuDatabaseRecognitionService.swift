//
//  LabubuDatabaseRecognitionService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import Combine

/// Labubu数据库识别服务 - 整合所有组件的识别服务
@MainActor
class LabubuDatabaseRecognitionService: ObservableObject {
    
    static let shared = LabubuDatabaseRecognitionService()
    
    // MARK: - 发布的属性
    
    @Published var isRecognizing = false
    @Published var recognitionProgress: Double = 0.0
    @Published var recognitionStatus = "准备就绪"
    @Published var lastResult: MatchResult?
    @Published var matchResults: [MatchResult] = []
    @Published var errorMessage: String?
    
    // MARK: - 私有属性
    
    private let databaseManager = LabubuDatabaseManager.shared
    private let featureExtractor = LabubuFeatureExtractor.shared
    private let similarityMatcher = LabubuSimilarityMatcher.shared
    
    private var recognitionTask: Task<Void, Never>?
    
    init() {}
    
    // MARK: - 主要识别接口
    
    /// 识别Labubu图像
    func recognizeLabubu(from image: UIImage) async {
        // 取消之前的任务
        recognitionTask?.cancel()
        
        // 重置状态
        isRecognizing = true
        recognitionProgress = 0.0
        errorMessage = nil
        matchResults = []
        lastResult = nil
        
        recognitionTask = Task {
            do {
                // 步骤1：预处理图像（10%）
                recognitionStatus = "预处理图像..."
                recognitionProgress = 0.1
                
                // 检查图像质量
                guard isImageQualityAcceptable(image) else {
                    throw RecognitionError.poorImageQuality
                }
                
                // 步骤2：提取特征（30%）
                recognitionStatus = "提取视觉特征..."
                recognitionProgress = 0.3
                
                let visualFeatures = try await featureExtractor.extractVisualFeatures(from: image)
                
                // 步骤3：快速预筛选（20%）
                recognitionStatus = "快速匹配..."
                recognitionProgress = 0.5
                
                let allModels = databaseManager.getAllModels()
                guard !allModels.isEmpty else {
                    throw RecognitionError.emptyDatabase
                }
                
                // 使用特征向量进行快速筛选
                let quickMatches = similarityMatcher.quickMatch(
                    featureVector: visualFeatures.featureVector,
                    with: allModels
                )
                
                // 步骤4：详细匹配（30%）
                recognitionStatus = "精确匹配中..."
                recognitionProgress = 0.8
                
                // 对前10个候选进行详细匹配
                let topCandidates = Array(quickMatches.prefix(10)).map { $0.model }
                let detailedMatches = try await similarityMatcher.matchImage(image, with: topCandidates)
                
                // 步骤5：结果处理（10%）
                recognitionStatus = "处理结果..."
                recognitionProgress = 0.9
                
                // 合并结果
                self.matchResults = detailedMatches
                self.lastResult = detailedMatches.first
                
                // 更新状态
                if let bestMatch = lastResult {
                    let quality = similarityMatcher.evaluateMatchQuality(bestMatch.confidence)
                    recognitionStatus = "识别完成 - \(quality.description)"
                    
                    // 记录识别历史
                    await recordRecognitionHistory(match: bestMatch, image: image)
                } else {
                    recognitionStatus = "未找到匹配"
                }
                
                recognitionProgress = 1.0
                
            } catch {
                handleRecognitionError(error)
            }
            
            isRecognizing = false
        }
    }
    
    // 注意：数据库现在是只读的，不支持添加新模型
    // 如果需要添加新模型，应该通过管理员工具更新预置数据
    
    // MARK: - 数据库管理
    
    /// 获取所有系列
    func getAllSeries() -> [LabubuSeries] {
        return databaseManager.getAllSeries()
    }
    
    /// 获取指定系列的模型
    func getModels(for seriesId: String) -> [LabubuModel] {
        return databaseManager.getModels(for: seriesId)
    }
    
    /// 获取数据库统计信息
    func getDatabaseStats() -> DatabaseStats {
        return databaseManager.getStatistics()
    }
    
    /// 搜索模型
    func searchModels(with filter: LabubuSearchFilter) -> [LabubuModel] {
        return databaseManager.searchModels(with: filter)
    }
    
    // 注意：数据库现在是只读的，不支持导入导出
    // 数据更新应该通过应用更新或管理员工具完成
    
    // MARK: - 私有方法
    
    /// 检查图像质量
    private func isImageQualityAcceptable(_ image: UIImage) -> Bool {
        // 检查图像尺寸
        let minSize: CGFloat = 200
        guard image.size.width >= minSize && image.size.height >= minSize else {
            return false
        }
        
        // 检查图像是否过于模糊（简化实现）
        // 实际应该使用更复杂的模糊检测算法
        
        return true
    }
    
    /// 记录识别历史
    private func recordRecognitionHistory(match: MatchResult, image: UIImage) async {
        // 这里可以实现识别历史记录功能
        // 例如保存到UserDefaults或Core Data
        print("记录识别历史: \(match.model.nameCN)")
    }
    
    /// 处理识别错误
    private func handleRecognitionError(_ error: Error) {
        if let recognitionError = error as? RecognitionError {
            switch recognitionError {
            case .poorImageQuality:
                errorMessage = "图像质量不佳，请使用更清晰的图片"
            case .emptyDatabase:
                errorMessage = "数据库为空，请先添加一些Labubu模型"
            case .featureExtractionFailed:
                errorMessage = "特征提取失败，请重试"
            case .noMatchFound:
                errorMessage = "未找到匹配的Labubu"
            }
        } else {
            errorMessage = "识别失败: \(error.localizedDescription)"
        }
        
        recognitionStatus = "识别失败"
        recognitionProgress = 0.0
    }
    
    // MARK: - 便捷方法
    
    /// 生成匹配报告
    func generateMatchReport() -> String? {
        guard let result = lastResult else { return nil }
        return similarityMatcher.generateMatchReport(for: result)
    }
    
    /// 清除识别结果
    func clearResults() {
        lastResult = nil
        matchResults = []
        errorMessage = nil
        recognitionStatus = "准备就绪"
        recognitionProgress = 0.0
    }
    
    /// 取消当前识别任务
    func cancelRecognition() {
        recognitionTask?.cancel()
        isRecognizing = false
        recognitionStatus = "已取消"
        recognitionProgress = 0.0
    }
}

// MARK: - 错误类型

enum RecognitionError: LocalizedError {
    case poorImageQuality
    case emptyDatabase
    case featureExtractionFailed
    case noMatchFound
    
    var errorDescription: String? {
        switch self {
        case .poorImageQuality:
            return "图像质量不佳"
        case .emptyDatabase:
            return "数据库为空"
        case .featureExtractionFailed:
            return "特征提取失败"
        case .noMatchFound:
            return "未找到匹配"
        }
    }
}

// MARK: - 识别配置

struct RecognitionConfiguration {
    var minConfidenceThreshold: Double = 0.6
    var maxCandidates: Int = 10
    var enableQuickMatch: Bool = true
    var saveRecognitionHistory: Bool = true
}

// MARK: - 识别历史记录

struct RecognitionHistoryItem: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let modelId: String
    let modelName: String
    let confidence: Double
    let imageData: Data?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
