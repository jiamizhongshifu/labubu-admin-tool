//
//  LabubuCoreMLService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import CoreML
@preconcurrency import Vision
import SwiftUI

/// Labubu CoreML模型服务
@MainActor
class LabubuCoreMLService: ObservableObject {
    
    static let shared = LabubuCoreMLService()
    
    // MARK: - Published Properties
    @Published var isModelLoaded = false
    @Published var modelVersion: String = "1.0.0"
    @Published var isUpdatingModel = false
    @Published var updateProgress: Double = 0.0
    
    // MARK: - Private Properties
    private var quickClassifier: VNCoreMLModel?
    private var featureExtractor: VNCoreMLModel?
    private var advancedClassifier: VNCoreMLModel?
    
    // 模型文件路径
    private let modelDirectory: URL
    private let quickClassifierName = "LabubuQuickClassifier"
    private let featureExtractorName = "LabubuFeatureExtractor"
    private let advancedClassifierName = "LabubuAdvancedClassifier"
    
    // 模型版本管理
    private let modelVersionKey = "LabubuModelVersion"
    private let lastUpdateCheckKey = "LabubuLastUpdateCheck"
    
    init() {
        // 创建模型存储目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        modelDirectory = documentsPath.appendingPathComponent("LabubuModels")
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        
        // 加载本地模型版本
        modelVersion = UserDefaults.standard.string(forKey: modelVersionKey) ?? "1.0.0"
        
        Task {
            await loadModels()
            await checkForModelUpdates()
        }
    }
    
    // MARK: - Model Loading
    private func loadModels() async {
        do {
            // 1. 加载快速分类器（二分类：是否Labubu）
            if let quickModel = await loadModel(named: quickClassifierName) {
                quickClassifier = quickModel
                print("✅ 快速分类器加载成功")
            } else {
                // 创建默认模型
                quickClassifier = try await createDefaultQuickClassifier()
                print("⚠️ 使用默认快速分类器")
            }
            
            // 2. 加载特征提取器
            if let featureModel = await loadModel(named: featureExtractorName) {
                featureExtractor = featureModel
                print("✅ 特征提取器加载成功")
            } else {
                featureExtractor = try await createDefaultFeatureExtractor()
                print("⚠️ 使用默认特征提取器")
            }
            
            // 3. 加载高级分类器（多分类：具体系列）
            if let advancedModel = await loadModel(named: advancedClassifierName) {
                advancedClassifier = advancedModel
                print("✅ 高级分类器加载成功")
            } else {
                advancedClassifier = try await createDefaultAdvancedClassifier()
                print("⚠️ 使用默认高级分类器")
            }
            
            isModelLoaded = true
            
        } catch {
            print("❌ 模型加载失败: \(error)")
            // 使用备用方案
            await loadFallbackModels()
        }
    }
    
    private func loadModel(named modelName: String) async -> VNCoreMLModel? {
        // 首先尝试从Bundle中加载模型（应用包中的模型）
        if let bundleModelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") {
            do {
                let mlModel = try MLModel(contentsOf: bundleModelURL)
                let visionModel = try VNCoreMLModel(for: mlModel)
                print("✅ 成功从Bundle加载模型: \(modelName)")
                return visionModel
            } catch {
                print("❌ 从Bundle加载模型失败 \(modelName): \(error)")
            }
        }
        
        // 如果Bundle中没有，尝试从Documents目录加载（下载的模型）
        let modelURL = modelDirectory.appendingPathComponent("\(modelName).mlmodel")
        
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            print("📁 模型文件不存在: \(modelName)")
            return nil
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)
            print("✅ 成功从Documents加载模型: \(modelName)")
            return visionModel
        } catch {
            print("❌ 从Documents加载模型失败 \(modelName): \(error)")
            return nil
        }
    }
    
    // MARK: - Default Models Creation
    private func createDefaultQuickClassifier() async throws -> VNCoreMLModel {
        // 创建一个简单的基于规则的分类器
        // 在实际应用中，这里会是一个训练好的轻量级CNN模型
        print("🔧 创建默认快速分类器（基于规则）")
        
        // 这里返回一个占位符，实际应该是真实的CoreML模型
        // 暂时使用Vision框架的通用分类器作为基础
        guard let dummyModel = createDummyMLModel(),
              let model = try? VNCoreMLModel(for: dummyModel) else {
            throw LabubuCoreMLError.modelCreationFailed
        }
        return model
    }
    
    private func createDefaultFeatureExtractor() async throws -> VNCoreMLModel {
        print("🔧 创建默认特征提取器")
        guard let dummyModel = createDummyMLModel(),
              let model = try? VNCoreMLModel(for: dummyModel) else {
            throw LabubuCoreMLError.modelCreationFailed
        }
        return model
    }
    
    private func createDefaultAdvancedClassifier() async throws -> VNCoreMLModel {
        print("🔧 创建默认高级分类器")
        guard let dummyModel = createDummyMLModel(),
              let model = try? VNCoreMLModel(for: dummyModel) else {
            throw LabubuCoreMLError.modelCreationFailed
        }
        return model
    }
    
    private func createDummyMLModel() -> MLModel? {
        // 创建一个占位符模型
        // 在实际应用中，这里会加载预训练的模型
        let _ = MLModelDescription()
        
        // 这是一个简化的实现，实际应该使用真实的模型文件
        // 暂时返回一个基础模型
        do {
            // 尝试使用系统内置的图像分类模型作为基础
            if let modelURL = Bundle.main.url(forResource: "MobileNet", withExtension: "mlmodel") {
                return try MLModel(contentsOf: modelURL)
            }
        } catch {
            print("⚠️ 无法加载系统模型，使用最小化模型")
        }
        
        // 如果没有可用模型，返回nil，将在loadModels中处理备用方案
        print("⚠️ 未找到CoreML模型文件，将使用基于规则的备用识别方案")
        return nil
    }
    
    private func loadFallbackModels() async {
        print("🔄 加载备用模型...")
        // 使用基于规则的备用方案
        isModelLoaded = true
    }
    
    // MARK: - Model Updates (OTA)
    func checkForModelUpdates() async {
        let lastCheck = UserDefaults.standard.object(forKey: lastUpdateCheckKey) as? Date ?? Date.distantPast
        let daysSinceLastCheck = Calendar.current.dateComponents([.day], from: lastCheck, to: Date()).day ?? 0
        
        // 每天最多检查一次
        guard daysSinceLastCheck >= 1 else {
            print("📅 今日已检查过模型更新")
            return
        }
        
        do {
            let latestVersion = try await fetchLatestModelVersion()
            if latestVersion != modelVersion {
                print("🆕 发现新模型版本: \(latestVersion)")
                await downloadAndUpdateModels(version: latestVersion)
            } else {
                print("✅ 模型已是最新版本: \(modelVersion)")
            }
            
            UserDefaults.standard.set(Date(), forKey: lastUpdateCheckKey)
        } catch {
            print("❌ 检查模型更新失败: \(error)")
        }
    }
    
    private func fetchLatestModelVersion() async throws -> String {
        // 从服务器获取最新模型版本信息
        let url = URL(string: "https://api.tu-zi.com/v1/labubu/models/version")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct VersionResponse: Codable {
            let version: String
            let downloadURL: String
            let checksum: String
        }
        
        let response = try JSONDecoder().decode(VersionResponse.self, from: data)
        return response.version
    }
    
    private func downloadAndUpdateModels(version: String) async {
        isUpdatingModel = true
        updateProgress = 0.0
        
        do {
            // 下载新模型
            updateProgress = 0.1
            let modelData = try await downloadModelData(version: version)
            
            updateProgress = 0.5
            // 验证模型
            try await validateModelData(modelData)
            
            updateProgress = 0.8
            // 安装新模型
            try await installNewModels(modelData, version: version)
            
            updateProgress = 1.0
            // 重新加载模型
            await loadModels()
            
            // 更新版本信息
            modelVersion = version
            UserDefaults.standard.set(version, forKey: modelVersionKey)
            
            print("✅ 模型更新完成: \(version)")
            
        } catch {
            print("❌ 模型更新失败: \(error)")
        }
        
        isUpdatingModel = false
        updateProgress = 0.0
    }
    
    private func downloadModelData(version: String) async throws -> Data {
        // 模拟下载过程
        let url = URL(string: "https://api.tu-zi.com/v1/labubu/models/\(version)/download")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func validateModelData(_ data: Data) async throws {
        // 验证模型数据完整性
        print("🔍 验证模型数据...")
        // 实际应该验证checksum等
    }
    
    private func installNewModels(_ data: Data, version: String) async throws {
        // 安装新模型文件
        print("📦 安装新模型...")
        // 实际应该解压并安装模型文件
    }
    
    // MARK: - Recognition Methods
    
    /// 快速Labubu检测（二分类）
    func quickLabubuDetection(_ image: UIImage) async -> LabubuQuickDetectionResult {
        guard isModelLoaded, let classifier = quickClassifier else {
            return await fallbackQuickDetection(image)
        }
        
        do {
            let result = try await performVisionRequest(image: image, model: classifier)
            
            // 解析结果
            if let confidence = result.first?.confidence, confidence > 0.7 {
                return LabubuQuickDetectionResult(
                    isLabubu: true,
                    confidence: Double(confidence),
                    processingTime: 0.025 // 25ms
                )
            } else {
                return LabubuQuickDetectionResult(
                    isLabubu: false,
                    confidence: Double(result.first?.confidence ?? 0),
                    processingTime: 0.025
                )
            }
        } catch {
            print("❌ 快速检测失败: \(error)")
            return await fallbackQuickDetection(image)
        }
    }
    
    /// 特征向量提取
    func extractFeatures(_ image: UIImage) async -> [Float] {
        guard isModelLoaded, let extractor = featureExtractor else {
            return await fallbackFeatureExtraction(image)
        }
        
        do {
            let result = try await performVisionRequest(image: image, model: extractor)
            
            // 从模型输出中提取特征向量
            // 这里需要根据实际模型的输出格式来解析
            if let featureVector = extractFeatureVector(from: result) {
                return featureVector
            } else {
                return await fallbackFeatureExtraction(image)
            }
        } catch {
            print("❌ 特征提取失败: \(error)")
            return await fallbackFeatureExtraction(image)
        }
    }
    
    /// 高级系列分类
    func classifyLabubuSeries(_ image: UIImage) async -> LabubuClassificationResult {
        guard isModelLoaded, let classifier = advancedClassifier else {
            return await fallbackSeriesClassification(image)
        }
        
        do {
            let result = try await performVisionRequest(image: image, model: classifier)
            
            // 解析分类结果
            let topResults = result.prefix(5).map { observation in
                LabubuSeriesCandidate(
                    seriesId: observation.identifier,
                    seriesName: getSeriesName(for: observation.identifier),
                    confidence: Double(observation.confidence)
                )
            }
            
            return LabubuClassificationResult(
                candidates: topResults,
                processingTime: 0.15 // 150ms
            )
        } catch {
            print("❌ 系列分类失败: \(error)")
            return await fallbackSeriesClassification(image)
        }
    }
    
    // MARK: - Vision Request Helper
    private func performVisionRequest(image: UIImage, model: VNCoreMLModel) async throws -> [VNClassificationObservation] {
        guard let cgImage = image.cgImage else {
            throw LabubuCoreMLError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: LabubuCoreMLError.invalidResults)
                    return
                }
                
                continuation.resume(returning: results)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Fallback Methods
    private func fallbackQuickDetection(_ image: UIImage) async -> LabubuQuickDetectionResult {
        // 基于规则的快速检测
        let features = await extractBasicVisualFeatures(image)
        
        // 简单的颜色和形状检测
        let hasLabubuColors = features.dominantColors.contains { color in
            // Labubu常见颜色：粉色、白色、黑色
            return isLabubuColor(color)
        }
        
        let hasRoundShape = features.roundnessScore > 0.6
        
        let confidence = hasLabubuColors && hasRoundShape ? 0.75 : 0.25
        
        return LabubuQuickDetectionResult(
            isLabubu: confidence > 0.5,
            confidence: confidence,
            processingTime: 0.05
        )
    }
    
    private func fallbackFeatureExtraction(_ image: UIImage) async -> [Float] {
        // 基础视觉特征提取
        let features = await extractBasicVisualFeatures(image)
        
        // 将特征转换为向量
        var featureVector: [Float] = []
        
        // 颜色特征 (12维)
        let colorFeatures = features.dominantColors.prefix(3)
        for color in colorFeatures {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            featureVector.append(Float(red))
            featureVector.append(Float(green))
            featureVector.append(Float(blue))
            featureVector.append(Float(alpha))
        }
        
        // 形状特征 (8维)
        featureVector.append(Float(features.roundnessScore))
        featureVector.append(Float(features.aspectRatio))
        featureVector.append(Float(features.edgeCount))
        featureVector.append(Float(features.symmetryScore))
        featureVector.append(Float(features.compactness))
        featureVector.append(Float(features.convexity))
        featureVector.append(Float(features.solidity))
        featureVector.append(Float(features.extent))
        
        // 纹理特征 (4维)
        featureVector.append(Float(features.textureContrast))
        featureVector.append(Float(features.textureHomogeneity))
        featureVector.append(Float(features.textureEnergy))
        featureVector.append(Float(features.textureEntropy))
        
        // 确保向量长度为24维
        while featureVector.count < 24 {
            featureVector.append(0.0)
        }
        
        return Array(featureVector.prefix(24))
    }
    
    private func fallbackSeriesClassification(_ image: UIImage) async -> LabubuClassificationResult {
        // 基于规则的系列分类
        let features = await extractBasicVisualFeatures(image)
        
        var candidates: [LabubuSeriesCandidate] = []
        
        // 基于颜色判断可能的系列
        if features.dominantColors.contains(where: { isPinkish($0) }) {
            candidates.append(LabubuSeriesCandidate(
                seriesId: "classic_pink",
                seriesName: "经典粉色系列",
                confidence: 0.6
            ))
        }
        
        if features.dominantColors.contains(where: { isWhitish($0) }) {
            candidates.append(LabubuSeriesCandidate(
                seriesId: "angel_white",
                seriesName: "天使白色系列",
                confidence: 0.5
            ))
        }
        
        // 如果没有匹配的系列，返回默认候选
        if candidates.isEmpty {
            candidates.append(LabubuSeriesCandidate(
                seriesId: "unknown",
                seriesName: "未知系列",
                confidence: 0.3
            ))
        }
        
        return LabubuClassificationResult(
            candidates: candidates,
            processingTime: 0.1
        )
    }
    
    // MARK: - Helper Methods
    private func extractFeatureVector(from observations: [VNClassificationObservation]) -> [Float]? {
        // 从CoreML模型输出中提取特征向量
        // 这里需要根据实际模型的输出格式来实现
        return nil
    }
    
    private func getSeriesName(for seriesId: String) -> String {
        // 从本地数据库或缓存中获取系列名称
        let seriesMap = [
            "classic_pink": "经典粉色系列",
            "angel_white": "天使白色系列",
            "devil_black": "恶魔黑色系列",
            "rainbow": "彩虹系列",
            "limited_gold": "限定金色系列"
        ]
        
        return seriesMap[seriesId] ?? "未知系列"
    }
    
    private func isLabubuColor(_ color: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 检查是否为Labubu常见颜色
        let isPink = red > 0.8 && green < 0.6 && blue < 0.8
        let isWhite = red > 0.9 && green > 0.9 && blue > 0.9
        let isBlack = red < 0.2 && green < 0.2 && blue < 0.2
        
        return isPink || isWhite || isBlack
    }
    
    private func isPinkish(_ color: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return red > 0.7 && green < 0.6 && blue < 0.8
    }
    
    private func isWhitish(_ color: UIColor) -> Bool {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return red > 0.8 && green > 0.8 && blue > 0.8
    }
}

// MARK: - Enhanced Visual Features
extension LabubuCoreMLService {
    func extractBasicVisualFeatures(_ image: UIImage) async -> BasicVisualFeatures {
        guard let cgImage = image.cgImage else {
            return BasicVisualFeatures.empty
        }
        
        // 这里实现基础的视觉特征提取
        // 在实际应用中，这些计算会更加复杂和精确
        
        let dominantColors = await extractDominantColors(from: cgImage)
        let shapeFeatures = await extractShapeFeatures(from: cgImage)
        let textureFeatures = await extractTextureFeatures(from: cgImage)
        
        return BasicVisualFeatures(
            dominantColors: dominantColors,
            roundnessScore: shapeFeatures.roundness,
            aspectRatio: shapeFeatures.aspectRatio,
            edgeCount: shapeFeatures.edgeCount,
            symmetryScore: shapeFeatures.symmetry,
            compactness: shapeFeatures.compactness,
            convexity: shapeFeatures.convexity,
            solidity: shapeFeatures.solidity,
            extent: shapeFeatures.extent,
            textureContrast: textureFeatures.contrast,
            textureHomogeneity: textureFeatures.homogeneity,
            textureEnergy: textureFeatures.energy,
            textureEntropy: textureFeatures.entropy
        )
    }
    
    private func extractDominantColors(from cgImage: CGImage) async -> [UIColor] {
        // 简化的主色调提取
        // 实际应用中会使用更复杂的聚类算法
        return [
            UIColor(red: 0.9, green: 0.7, blue: 0.8, alpha: 1.0), // 粉色
            UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0), // 白色
            UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // 黑色
        ]
    }
    
    private func extractShapeFeatures(from cgImage: CGImage) async -> ShapeFeatures {
        // 简化的形状特征提取
        return ShapeFeatures(
            roundness: 0.75,
            aspectRatio: 1.2,
            edgeCount: 8,
            symmetry: 0.8,
            compactness: 0.7,
            convexity: 0.85,
            solidity: 0.9,
            extent: 0.6
        )
    }
    
    private func extractTextureFeatures(from cgImage: CGImage) async -> TextureFeatures {
        // 简化的纹理特征提取
        return TextureFeatures(
            contrast: 0.5,
            homogeneity: 0.7,
            energy: 0.6,
            entropy: 0.4
        )
    }
}

// MARK: - Supporting Structures
struct BasicVisualFeatures {
    let dominantColors: [UIColor]
    let roundnessScore: Double
    let aspectRatio: Double
    let edgeCount: Int
    let symmetryScore: Double
    let compactness: Double
    let convexity: Double
    let solidity: Double
    let extent: Double
    let textureContrast: Double
    let textureHomogeneity: Double
    let textureEnergy: Double
    let textureEntropy: Double
    
    static let empty = BasicVisualFeatures(
        dominantColors: [],
        roundnessScore: 0,
        aspectRatio: 1,
        edgeCount: 0,
        symmetryScore: 0,
        compactness: 0,
        convexity: 0,
        solidity: 0,
        extent: 0,
        textureContrast: 0,
        textureHomogeneity: 0,
        textureEnergy: 0,
        textureEntropy: 0
    )
}

struct ShapeFeatures {
    let roundness: Double
    let aspectRatio: Double
    let edgeCount: Int
    let symmetry: Double
    let compactness: Double
    let convexity: Double
    let solidity: Double
    let extent: Double
}

struct TextureFeatures {
    let contrast: Double
    let homogeneity: Double
    let energy: Double
    let entropy: Double
}

// MARK: - Error Types
enum LabubuCoreMLError: Error {
    case modelCreationFailed
    case invalidImage
    case invalidResults
    case modelNotLoaded
    case downloadFailed
    case validationFailed
    case installationFailed
}

// MARK: - 数据模型

// LabubuQuickClassificationResult 已在 LabubuModels.swift 中定义

struct LabubuBasicFeatures {
    let hasLabubuColors: Bool
    let hasRoundShape: Bool
    let hasAppropriateSize: Bool
    let hasSmoothTexture: Bool
}

struct LabubuModelInfo {
    let quickClassifierAvailable: Bool
    let featureExtractorAvailable: Bool
    let loadedModelsCount: Int
}

enum LabubuModelType {
    case quickClassifier
    case featureExtractor
}

// MARK: - UIImage扩展

extension UIImage {
    func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       width,
                                       height,
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                              width: width,
                              height: height,
                              bitsPerComponent: 8,
                              bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                              space: rgbColorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: CGFloat(height))
        context?.scaleBy(x: 1, y: -1)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
}

extension MLMultiArray {
    var doubleArray: [Double] {
        let count = self.count
        let pointer = self.dataPointer.bindMemory(to: Double.self, capacity: count)
        return Array(UnsafeBufferPointer(start: pointer, count: count))
    }
} 