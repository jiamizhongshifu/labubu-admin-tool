//
//  jitataApp.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI
import SwiftData

@main
struct jitataApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [ToySticker.self, Category.self])
                .onAppear {
                    // 配置DataManager
                    if let container = try? ModelContainer(for: ToySticker.self, Category.self) {
                        let context = ModelContext(container)
                        DataManager.shared.configure(with: context)
                    }
                }
        }
    }
}
