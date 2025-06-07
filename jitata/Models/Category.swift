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
    static let defaultCategories: [Category] = [
        Category(name: "手办", iconName: "figure.stand"),
        Category(name: "盲盒", iconName: "cube.box"),
        Category(name: "积木", iconName: "building.2"),
        Category(name: "卡牌", iconName: "rectangle.stack"),
        Category(name: "其他", iconName: "questionmark.circle")
    ]
} 