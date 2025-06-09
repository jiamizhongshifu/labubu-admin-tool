import Foundation

// MARK: - OpenAI Image API Request Models

/// OpenAI图片编辑请求
struct OpenAIImageEditRequest: Codable {
    let model: String
    let prompt: String
    let size: String?
    let quality: String?
    let format: String?
    let background: String?
    let outputCompression: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case size
        case quality
        case format
        case background
        case outputCompression = "output_compression"
    }
}

/// OpenAI图片生成请求
struct OpenAIImageGenerateRequest: Codable {
    let model: String
    let prompt: String
    let size: String?
    let quality: String?
    let format: String?
    let background: String?
    let outputCompression: Int?
    let n: Int?
    
    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case size
        case quality
        case format
        case background
        case outputCompression = "output_compression"
        case n
    }
}

// MARK: - OpenAI Image API Response Models

/// OpenAI图片API响应
struct OpenAIImageResponse: Codable {
    let created: Int
    let data: [ImageData]
}

/// 图片数据
struct ImageData: Codable {
    let b64Json: String?
    let url: String?
    let revisedPrompt: String?
    
    enum CodingKeys: String, CodingKey {
        case b64Json = "b64_json"
        case url
        case revisedPrompt = "revised_prompt"
    }
}

// MARK: - Helper Extensions

extension OpenAIImageEditRequest {
    /// 创建图片增强编辑请求
    static func createImageEnhancementRequest(
        prompt: String,
        model: String = APIConfig.openAIModel
    ) -> OpenAIImageEditRequest {
        return OpenAIImageEditRequest(
            model: model,
            prompt: prompt,
            size: "1024x1024",
            quality: "high",
            format: "png",
            background: "transparent",
            outputCompression: nil
        )
    }
}

extension OpenAIImageGenerateRequest {
    /// 创建图片生成请求
    static func createImageGenerationRequest(
        prompt: String,
        model: String = APIConfig.openAIModel
    ) -> OpenAIImageGenerateRequest {
        return OpenAIImageGenerateRequest(
            model: model,
            prompt: prompt,
            size: "1024x1024",
            quality: "high",
            format: "png",
            background: "transparent",
            outputCompression: nil,
            n: 1
        )
    }
} 