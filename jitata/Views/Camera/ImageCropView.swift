//
//  ImageCropView.swift
//  jitata
//
//  Created by 钟庆标 on 2025/6/7.
//

import SwiftUI

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var cropRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    // 图片显示区域
                    GeometryReader { geometry in
                        ZStack {
                            // 背景图片
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // 简单的裁剪框指示
                            Rectangle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(
                                    width: geometry.size.width * 0.8,
                                    height: geometry.size.height * 0.8
                                )
                        }
                    }
                    
                    // 提示文字
                    Text("点击完成将按当前框架裁剪图片")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .navigationTitle("裁剪图片")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                }
                .foregroundColor(.white),
                trailing: Button("完成") {
                    cropImage()
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
            )
        }
    }
    
    private func cropImage() {
        // 简单的中心裁剪
        let croppedImage = cropImageToCenter(image)
        onCrop(croppedImage)
        dismiss()
    }
    
    private func cropImageToCenter(_ image: UIImage) -> UIImage {
        let size = image.size
        let cropSize = min(size.width, size.height) * 0.8
        let cropRect = CGRect(
            x: (size.width - cropSize) / 2,
            y: (size.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )
        
        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return image
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

#Preview {
    ImageCropView(image: UIImage(systemName: "photo")!, onCrop: { _ in })
} 