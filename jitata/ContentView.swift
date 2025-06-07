//
//  ContentView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 拍照收集页面
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("拍照收集")
                }
            
            // 我的图鉴页面
            CollectionView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("我的图鉴")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
