//
//  Category.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import Foundation
import SwiftData

@Model
final class Category: Identifiable {
    var id: UUID
    var name: String
    var iconName: String
    var createdDate: Date
    
    init(name: String, iconName: String = "toy.fill") {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.createdDate = Date()
    }
}

extension Category {
    static let defaultCategories: [Category] = {
        return CategoryConstants.allCategories.map { categoryName in
            Category(name: categoryName, iconName: CategoryConstants.iconName(for: categoryName))
        }
    }()
} 