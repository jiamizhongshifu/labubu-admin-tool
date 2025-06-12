//
//  LabubuAPIService.swift
//  jitata
//
//  Created by AI Assistant on 2025/6/7.
//

import Foundation
import UIKit
import SwiftUI

/// Labubu云端API服务
class LabubuAPIService {
    
    static let shared = LabubuAPIService()
    
    // MARK: - 配置
    private let baseURL = "https://api.tu-zi.com/v1/labubu"
    private let timeout: TimeInterval = 10.0
    
    // MARK: - 网络会话
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // MARK: - 主要API接口
    
    /// 云端精确识别
    func recognizeLabubu(_ image: UIImage) async throws -> LabubuCloudRecognitionResult {
        let endpoint = "\(baseURL)/recognize"
        
        // 压缩图片
        guard let imageData = compressImage(image, maxSizeKB: 500) else {
            throw LabubuAPIError.imageCompressionFailed
        }
        
        // 创建请求
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        
        // 构建请求体
        let requestBody = LabubuRecognitionRequest(
            imageData: imageData.base64EncodedString(),
            options: LabubuRecognitionOptions(
                includeMetadata: true,
                includeFamilyTree: true,
                maxResults: 5
            )
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 发送请求
        let (data, response) = try await session.data(for: request)
        
        // 检查响应
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LabubuAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw LabubuAPIError.httpError(httpResponse.statusCode)
        }
        
        // 解析响应
        let result = try JSONDecoder().decode(LabubuCloudRecognitionResult.self, from: data)
        return result
    }
    
    /// 获取系列元数据
    func fetchSeriesMetadata(seriesId: String) async throws -> LabubuCloudSeriesMetadata {
        let endpoint = "\(baseURL)/series/\(seriesId)"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuAPIError.metadataNotFound
        }
        
        return try JSONDecoder().decode(LabubuCloudSeriesMetadata.self, from: data)
    }
    
    /// 获取族谱信息
    func fetchFamilyTree(seriesId: String) async throws -> [FamilyMember] {
        let endpoint = "\(baseURL)/series/\(seriesId)/family"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuAPIError.familyTreeNotFound
        }
        
        return try JSONDecoder().decode([FamilyMember].self, from: data)
    }
    
    /// 获取价格信息
    func fetchPriceInfo(seriesId: String) async throws -> LabubuPriceInfo {
        let endpoint = "\(baseURL)/series/\(seriesId)/price"
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuAPIError.priceInfoNotFound
        }
        
        return try JSONDecoder().decode(LabubuPriceInfo.self, from: data)
    }
    
    /// 轻量级识别（快速检测）
    func quickRecognition(_ image: UIImage) async throws -> LabubuQuickResult {
        let endpoint = "\(baseURL)/quick-recognize"
        
        // 更小的图片压缩用于快速识别
        guard let imageData = compressImage(image, maxSizeKB: 100) else {
            throw LabubuAPIError.imageCompressionFailed
        }
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAPIKey())", forHTTPHeaderField: "Authorization")
        
        let requestBody = LabubuQuickRequest(
            imageData: imageData.base64EncodedString()
        )
        
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LabubuAPIError.quickRecognitionFailed
        }
        
        return try JSONDecoder().decode(LabubuQuickResult.self, from: data)
    }
    
    // MARK: - 辅助方法
    
    private func getAPIKey() -> String {
        // 从环境变量或配置文件获取API密钥
        return ProcessInfo.processInfo.environment["LABUBU_API_KEY"] ?? "demo_key"
    }
    
    private func compressImage(_ image: UIImage, maxSizeKB: Int) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        return imageData
    }
}

// MARK: - API数据模型

/// 识别请求
struct LabubuRecognitionRequest: Codable {
    let imageData: String
    let options: LabubuRecognitionOptions
}

struct LabubuRecognitionOptions: Codable {
    let includeMetadata: Bool
    let includeFamilyTree: Bool
    let maxResults: Int
}

/// 云端识别结果
struct LabubuCloudRecognitionResult: Codable {
    let success: Bool
    let results: [LabubuCloudMatch]
    let processingTime: Double
    let requestId: String?
}

struct LabubuCloudMatch: Codable {
    let seriesId: String
    let confidence: Double
    let features: [Double]?
}

/// 云端系列元数据
struct LabubuCloudSeriesMetadata: Codable {
    let id: String
    let name: String
    let description: String
    let releaseDate: String  // ISO8601 格式
    let theme: String
    let totalVariants: Int
    let imageURL: String?
    let isLimited: Bool
}

/// 价格信息
struct LabubuPriceInfo: Codable {
    let seriesId: String
    let currentPrice: Double
    let averagePrice7d: Double
    let averagePrice30d: Double
    let priceChange7d: Double
    let priceChange30d: Double
    let currency: String
    let lastUpdated: Date
    let marketTrend: MarketTrend
    
    enum MarketTrend: String, Codable {
        case rising = "rising"
        case falling = "falling"
        case stable = "stable"
        
        var displayName: String {
            switch self {
            case .rising: return "上涨"
            case .falling: return "下跌"
            case .stable: return "稳定"
            }
        }
        
        var color: Color {
            switch self {
            case .rising: return .green
            case .falling: return .red
            case .stable: return .gray
            }
        }
    }
}

/// 快速识别请求
struct LabubuQuickRequest: Codable {
    let imageData: String
}

/// 快速识别结果
struct LabubuQuickResult: Codable {
    let isLabubu: Bool
    let confidence: Double
    let processingTime: Double
}

// MARK: - API错误类型

enum LabubuAPIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case imageCompressionFailed
    case metadataNotFound
    case familyTreeNotFound
    case priceInfoNotFound
    case quickRecognitionFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "无效的服务器响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .metadataNotFound:
            return "未找到系列元数据"
        case .familyTreeNotFound:
            return "未找到族谱信息"
        case .priceInfoNotFound:
            return "未找到价格信息"
        case .quickRecognitionFailed:
            return "快速识别失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
} 