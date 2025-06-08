//
//  ToySticker.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import SwiftData
import UIKit

@Model
final class ToySticker: Identifiable {
    var id: UUID
    var name: String
    var categoryName: String
    var originalImageData: Data
    var processedImageData: Data
    var createdDate: Date
    var notes: String
    var isFavorite: Bool
    
    init(name: String, categoryName: String, originalImage: UIImage, processedImage: UIImage, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.categoryName = categoryName
        self.originalImageData = originalImage.jpegData(compressionQuality: 0.8) ?? Data()
        // 🎯 修复：使用PNG格式保存抠图结果，保持透明背景
        self.processedImageData = processedImage.pngData() ?? Data()
        self.createdDate = Date()
        self.notes = notes
        self.isFavorite = false
    }
    
    var originalImage: UIImage? {
        return UIImage(data: originalImageData)
    }
    
    var processedImage: UIImage? {
        return UIImage(data: processedImageData)
    }
}

extension ToySticker {
    static let sampleData: [ToySticker] = []
} 