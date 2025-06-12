# Labubu 系列识别系统 - 优化实现方案

基于现有 **Jitata 项目架构** 的 **"拍照 → Labubu 系列识别 → 回显族谱 + 均价"** 渐进式实现方案。

## 🎯 核心设计理念

- **渐进式集成**：基于现有VisionKit和AI增强架构扩展，复用技术投资
- **智能端云协同**：端侧快速预检 + 云端精确识别，成本可控
- **无缝用户体验**：集成到现有拍照流程，保持界面一致性
- **可扩展架构**：为未来扩展到其他潮玩IP奠定基础

---

## 1 · 渐进式识别架构

### 🔄 四层识别流程
```
拍照 → 快速预分类 → 精确识别 → 元数据获取
 ↓        ↓           ↓         ↓
端侧     端侧+云端    云端      云端
30ms     200ms      800ms     1.2s
```

### 📱 端侧组件（基于现有架构）

| 模块          | 技术选型                                                 | 关键代码 / 配置                                         | 成品指标            |
| ----------- | ---------------------------------------------------- | ------------------------------------------------- | --------------- |
| **图像预处理** | 现有 `VisionService.removeBackground()`              | 复用iOS 17+ VNGenerateForegroundInstanceMaskRequest | 35–40 ms 在 A16  |
| **快速预检**    | 轻量CNN二分类模型 → `.mlmodel` (≈500KB)                   | CoreML量化：`computePrecision = 8bit`               | 预检 ≤ 30 ms      |
| **特征提取**    | 基础视觉特征（颜色、形状、纹理）                                   | 集成到现有 `ImageProcessor`                          | 特征提取 ≤ 20 ms   |
| **本地缓存**    | Top-20热门系列特征缓存                                      | UserDefaults + 版本控制                            | 命中率 ≥ 80%      |
| **置信度判断**   | 分层阈值：0.9(确定) / 0.6(可能) / <0.6(未知)                 | 动态调整策略                                          | 端侧解决 ≥ 70% 请求  |

### ☁️ 云端组件（集成现有API架构）

| 模块          | 技术选型                                                 | 关键配置                                            | 性能指标            |
| ----------- | ---------------------------------------------------- | ------------------------------------------------- | --------------- |
| **API网关**   | 复用现有 `ImageEnhancementService` 架构                  | TUZI_API_BASE + 新增Labubu端点                      | <100ms 响应      |
| **精确识别**    | 专用Labubu-CLIP模型 (云端)                              | 512-D特征向量，覆盖200+系列                             | 识别准确率 >95%     |
| **向量检索**    | Supabase + pgvector (复用现有)                        | `SELECT * FROM labubu_series ORDER BY embedding <=> $1 LIMIT 5` | <50ms 检索      |
| **元数据服务**   | 新增 `LabubuDataService`                             | 族谱、价格、稀有度数据API                                  | <200ms 获取      |

> **架构优势**：① 复用现有技术投资；② 降低开发风险；③ 统一用户体验；④ 便于扩展到其他IP。

---

## 2 · 智能成本控制策略

### 💰 分层API调用决策
```swift
// 智能调用决策树
if confidence > 0.85 { 
    return localResult  // 免费，端侧解决
} else if confidence > 0.6 { 
    return await lightweightCloudCheck()  // 低成本API
} else { 
    return await fullCloudRecognition()  // 完整识别
}
```

### 🎯 服务分层架构
- **免费层**：基础系列识别（Top-10热门系列）
- **标准层**：完整数据库 + 基础价格信息
- **专业层**：实时价格追踪 + 投资建议 + 稀有度分析

### 📊 成本预估
| 用户类型 | 月识别次数 | API成本 | 用户价值 |
|---------|-----------|---------|----------|
| 普通用户 | 50次 | $0.5 | 免费使用 |
| 收藏家 | 200次 | $2.0 | $4.99/月 |
| 专业玩家 | 500次 | $5.0 | $9.99/月 |

---

## 3 · 技术实现方案

### 🔧 Phase 1: 基础集成（1周）

#### 扩展现有服务
```swift
// 1. 扩展VisionService
extension VisionService {
    func detectLabubu(_ image: UIImage) async throws -> LabubuDetectionResult {
        // 复用现有抠图能力
        let subject = try await removeBackground(from: image)
        
        // 快速Labubu检测
        let isLabubu = await LabubuClassifier.quickCheck(subject)
        guard isLabubu else { return .notLabubu }
        
        // 基础特征提取
        let features = extractBasicFeatures(subject)
        return await matchLocalDatabase(features)
    }
}

// 2. 新增Labubu识别服务
@MainActor
class LabubuRecognitionService: ObservableObject {
    @Published var recognitionResult: LabubuSeries?
    @Published var confidence: Double = 0.0
    @Published var priceInfo: PriceInfo?
    @Published var isProcessing = false
    
    func recognizeLabubu(_ image: UIImage) async -> LabubuRecognitionResult {
        isProcessing = true
        defer { isProcessing = false }
        
        // 1. 快速预检（端侧）
        let quickResult = await VisionService.shared.detectLabubu(image)
        
        // 2. 根据置信度决定后续流程
        if quickResult.confidence > 0.85 {
            return quickResult  // 端侧结果足够可信
        }
        
        // 3. 云端精确识别
        return await cloudRecognition(image, hint: quickResult)
    }
}
```

#### 集成到现有UI流程
```swift
// 3. 扩展ImageProcessingView
struct ImageProcessingView: View {
    @StateObject private var labubuService = LabubuRecognitionService()
    @State private var labubuInfo: LabubuInfo?
    
    var body: some View {
        VStack {
            // 现有的抠图预览
            processedImageView
            
            // 新增：Labubu识别结果卡片
            if let info = labubuInfo {
                LabubuInfoCard(info: info)
                    .transition(.slide)
            } else if labubuService.isProcessing {
                LabubuRecognitionProgressView()
            }
            
            // 现有的保存按钮
            saveButton
        }
        .onAppear {
            // 自动识别
            Task {
                labubuInfo = await labubuService.recognizeLabubu(processedImage)
            }
        }
    }
}
```

### 🚀 Phase 2: 云端增强（1周）

#### API服务扩展
```swift
// 4. 扩展现有ImageEnhancementService
extension ImageEnhancementService {
    func enhanceWithLabubuRecognition(_ sticker: ToySticker) async {
        // 先做AI增强（复用现有流程）
        let enhanced = try await enhanceSticker(sticker)
        
        // 再做Labubu系列识别
        let recognition = await LabubuAPIService.recognize(enhanced)
        
        // 保存识别结果
        sticker.labubuInfo = recognition
        
        // 获取价格和族谱信息
        if let seriesId = recognition.seriesId {
            sticker.priceInfo = await LabubuAPIService.fetchPriceInfo(seriesId)
            sticker.familyTree = await LabubuAPIService.fetchFamilyTree(seriesId)
        }
    }
}

// 5. 新增Labubu专用API服务
class LabubuAPIService {
    static let shared = LabubuAPIService()
    
    private let baseURL = "https://api.tu-zi.com/v1/labubu"
    
    func recognize(_ image: UIImage) async throws -> LabubuRecognitionResult {
        // 复用现有网络配置和错误处理
        let request = createRecognitionRequest(image)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LabubuRecognitionResult.self, from: data)
    }
    
    func fetchPriceInfo(_ seriesId: String) async throws -> PriceInfo {
        // 获取价格信息
    }
    
    func fetchFamilyTree(_ seriesId: String) async throws -> [FamilyMember] {
        // 获取族谱信息
    }
}
```

### 🎨 Phase 3: UI组件开发（3天）

#### Labubu信息展示卡片
```swift
struct LabubuInfoCard: View {
    let info: LabubuInfo
    @State private var showingFamilyTree = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 系列信息头部
            HStack {
                AsyncImage(url: info.seriesImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(info.seriesName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("置信度: \(Int(info.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let rarity = info.rarity {
                        RarityBadge(rarity: rarity)
                    }
                }
                
                Spacer()
                
                // 价格信息
                if let price = info.averagePrice {
                    VStack(alignment: .trailing) {
                        Text("均价")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(price, specifier: "%.0f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // 操作按钮
            HStack {
                Button("查看族谱") {
                    showingFamilyTree = true
                }
                .buttonStyle(.bordered)
                
                Button("价格趋势") {
                    // 显示价格趋势
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("保存到图鉴") {
                    // 保存操作
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingFamilyTree) {
            LabubuFamilyTreeView(familyTree: info.familyTree)
        }
    }
}
   ```

---

## 4 · 数据模型设计

### 📊 核心数据结构
```swift
// Labubu识别结果
struct LabubuRecognitionResult: Codable {
    let seriesId: String
    let seriesName: String
    let confidence: Double
    let rarity: RarityLevel?
    let averagePrice: Double?
    let priceChange7d: Double?
    let familyTree: [FamilyMember]
    let imageURL: URL?
}

// 族谱成员
struct FamilyMember: Codable, Identifiable {
    let id: String
    let name: String
    let rarity: RarityLevel
    let imageURL: URL?
    let averagePrice: Double?
    let isOwned: Bool  // 用户是否拥有
}

// 稀有度等级
enum RarityLevel: String, Codable, CaseIterable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    case secret = "secret"
    
    var displayName: String {
        switch self {
        case .common: return "普通"
        case .uncommon: return "不常见"
        case .rare: return "稀有"
        case .epic: return "史诗"
        case .legendary: return "传说"
        case .secret: return "隐藏"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .secret: return .pink
        }
    }
}
```

### 🗄️ 扩展现有ToySticker模型
```swift
extension ToySticker {
    // 新增Labubu相关属性
    var labubuInfo: LabubuRecognitionResult? {
        get {
            guard let data = labubuInfoData else { return nil }
            return try? JSONDecoder().decode(LabubuRecognitionResult.self, from: data)
        }
        set {
            labubuInfoData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var labubuInfoData: Data?  // 存储序列化的Labubu信息
    var isLabubuVerified: Bool = false  // 是否已验证为Labubu
    var labubuSeriesId: String?  // 快速访问系列ID
}
```

---

## 5 · 开发里程碑

### 📅 2周冲刺计划

| 阶段 | 时间 | 目标 | 交付物 |
|------|------|------|--------|
| **Phase 1** | 第1周前3天 | 基础识别集成 | LabubuRecognitionService + 基础UI |
| **Phase 2** | 第1周后4天 | 云端API集成 | LabubuAPIService + 网络层 |
| **Phase 3** | 第2周前3天 | UI完善 | LabubuInfoCard + FamilyTreeView |
| **Phase 4** | 第2周后4天 | 测试优化 | 完整功能测试 + 性能优化 |

### ✅ MVP验收标准

1. **基础功能**：
   - ✅ 拍摄Labubu后能自动识别系列（准确率>80%）
   - ✅ 显示系列名称、稀有度、置信度
   - ✅ 集成到现有拍照流程，无缝体验

2. **高级功能**：
   - ✅ 显示族谱信息和价格数据
   - ✅ 支持离线基础识别（Top-20热门系列）
   - ✅ 云端精确识别兜底

3. **性能指标**：
   - ✅ 端侧识别<500ms
   - ✅ 云端识别<2s
   - ✅ 离线识别命中率>70%

---

## 6 · 扩展规划

### 🚀 未来演进方向

1. **IP扩展**：基于相同架构扩展到其他潮玩IP
   - Molly系列识别
   - Hirono系列识别
   - 自定义IP训练平台

2. **社交功能**：
   - 收藏进度分享
   - 族谱完成度挑战
   - 价格预警和投资建议

3. **商业化**：
   - 专业版订阅服务
   - 商家合作和导购
   - 二手交易平台集成

### 💡 技术债务管理

- **模型更新机制**：支持OTA模型更新
- **数据同步策略**：云端数据版本控制
- **性能监控**：识别准确率和响应时间监控
- **用户反馈循环**：错误识别的人工标注和模型改进

---

## 小结

通过**渐进式集成现有架构**，我们能够：

✅ **快速交付**：2周内完成MVP，复用现有技术栈
✅ **风险可控**：基于成熟架构扩展，降低技术风险  
✅ **成本优化**：智能端云协同，API调用成本可控
✅ **用户体验**：无缝集成，保持界面一致性
✅ **可扩展性**：为未来IP扩展奠定技术基础

这种方案既能快速验证Labubu识别的市场需求，又能为后续的**全面潮玩识别平台**做好技术储备，是最优的实现路径。
