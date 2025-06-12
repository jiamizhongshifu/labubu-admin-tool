# Labubu AI识别功能配置指南

## 概述

本文档介绍如何配置和使用Labubu AI识别功能（方案3：多模态AI识别）。该功能使用TUZI API进行图像分析和特征文案生成，用于替换用户拍照后的自动识别环节。

## 功能特点

- 🤖 **智能识别**：使用先进的多模态AI模型进行图像分析
- 📝 **特征文案生成**：自动生成详细的特征描述，用于数据库比对
- 🎯 **精准匹配**：基于AI生成的特征文案与数据库进行智能匹配
- 🔄 **降级处理**：API失败时自动降级到Canvas基础分析
- 💾 **特征保存**：保存AI分析结果，供管理员后续使用

## 配置步骤

### 1. 获取TUZI API密钥

1. 访问 [TUZI API官网](https://api.tu-zi.com)
2. 注册账号并获取API密钥
3. 记录您的API密钥，格式类似：`sk-xxxxxxxxxxxxxxxxxxxxxxxx`

### 2. 配置API密钥

#### 方法一：.env文件配置（推荐）

这是最简单和最安全的配置方式，适用于iOS应用和Web管理工具。

1. **创建.env文件**：
   ```bash
   # 在项目根目录复制示例文件
   cp env.example .env
   ```

2. **编辑.env文件**：
   ```bash
   # AI识别API配置
   TUZI_API_KEY=your_actual_api_key_here
   TUZI_API_BASE=https://api.tu-zi.com/v1
   
   # 向后兼容配置（可选）
   OPENAI_API_KEY=your_actual_api_key_here
   
   # Supabase数据库配置（如果使用数据库功能）
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   SUPABASE_STORAGE_BUCKET=jitata-images
   ```

3. **验证配置**：
   ```bash
   # 打开配置检查工具
   open admin_tool/check-config.html
   ```

#### 方法二：使用配置文件

1. 复制 `admin_tool/config.example.js` 为 `admin_tool/config.js`
2. 编辑 `config.js` 文件，填入真实的API密钥：

```javascript
window.TUZI_API_CONFIG = {
    apiKey: 'your-actual-api-key-here',  // 替换为真实API密钥
    baseUrl: 'https://api.tu-zi.com/v1',
    model: 'gemini-2.5-flash-all',
    timeout: 120000,
    imageQuality: 0.8,
    maxImageSize: 1024
};
```

3. 在 `admin_tool/index.html` 中引入配置文件：

```html
<script src="config.js"></script>
<script src="app.js"></script>
```

#### 方法三：环境变量配置

```bash
# macOS/Linux
export TUZI_API_KEY="your-actual-api-key-here"
export TUZI_API_BASE="https://api.tu-zi.com/v1"

# Windows
set TUZI_API_KEY=your-actual-api-key-here
set TUZI_API_BASE=https://api.tu-zi.com/v1
```

#### 方法四：使用localStorage（测试用）

在浏览器控制台中执行：

```javascript
localStorage.setItem('tuzi_api_key', 'your-actual-api-key-here');
localStorage.setItem('tuzi_api_base', 'https://api.tu-zi.com/v1');
```

### 3. 配置iOS应用

iOS应用会自动按以下优先级读取配置：
1. 环境变量
2. .env文件
3. UserDefaults（用于测试）

#### 自动配置（推荐）

如果您已经按照方法一创建了.env文件，iOS应用会自动读取配置，无需额外设置。

#### 手动配置方式

**方法一：环境变量**

在Xcode中设置环境变量：
- `TUZI_API_KEY`: 您的API密钥
- `TUZI_API_BASE`: API基础URL（默认：https://api.tu-zi.com/v1）

**方法二：UserDefaults（测试用）**

```swift
UserDefaults.standard.set("your-actual-api-key-here", forKey: "tuzi_api_key")
UserDefaults.standard.set("https://api.tu-zi.com/v1", forKey: "tuzi_api_base")
```

#### 配置验证

iOS应用启动时会自动验证配置，您可以在控制台看到类似信息：
```
📁 从 /path/to/.env 读取到TUZI_API_KEY
✅ API配置验证通过
```

## 使用方法

### 管理员工具

1. 打开管理员工具
2. 进入"模型管理"页面
3. 点击"添加新模型"
4. 上传Labubu图片
5. 系统将自动调用AI进行分析
6. 查看并确认AI生成的特征描述
7. 保存模型信息

### iOS应用

1. 用户拍摄Labubu照片
2. 系统自动调用AI识别服务
3. 显示识别结果和匹配的数据库模型
4. 用户可查看详细的AI分析报告

## AI分析结果

AI识别服务会生成以下信息：

### 基础判断
- **是否为Labubu**：true/false
- **置信度**：0.0-1.0

### 详细特征描述
- **特征文案**：详细的文字描述，用于数据库匹配
- **关键特征**：提取的关键词列表
- **系列提示**：可能的系列名称

### 视觉特征
- **主要颜色**：十六进制颜色代码
- **身体形状**：圆润/细长/方正
- **头部形状**：圆形/三角形/椭圆形
- **耳朵类型**：尖耳/圆耳/垂耳
- **表面纹理**：光滑/磨砂/粗糙/绒毛
- **图案类型**：纯色/渐变/图案/条纹

### 分析结果
- **材质分析**：毛绒/塑料/金属等
- **风格分析**：可爱/酷炫/复古等
- **状态评估**：全新/良好/一般等
- **稀有度提示**：常见/稀有/限定等

## 数据库匹配机制

1. **文本相似度计算**：将用户图片的AI描述与数据库中的模型描述进行比较
2. **关键词匹配**：匹配关键特征词汇
3. **相似度排序**：按匹配度从高到低排序
4. **阈值过滤**：只返回相似度超过30%的结果

## 错误处理

### 常见错误及解决方案

1. **API配置缺失**
   - 错误：`API配置缺失，请检查TUZI_API_KEY和TUZI_API_BASE`
   - 解决：检查API密钥配置是否正确

2. **网络错误**
   - 错误：`网络错误: API请求失败: 401`
   - 解决：检查API密钥是否有效，账户是否有余额

3. **JSON解析失败**
   - 错误：`JSON解析失败`
   - 解决：通常是AI返回格式异常，系统会自动降级处理

4. **图像处理失败**
   - 错误：`图像处理失败`
   - 解决：检查图片格式和大小是否符合要求

### 降级机制

当AI识别失败时，系统会自动降级到Canvas基础分析：
1. 提取主要颜色
2. 分析基础形状特征
3. 估算尺寸信息
4. 生成默认特征描述

## 性能优化

### 图像预处理
- 自动调整图像尺寸（最大1024px）
- 压缩图像质量（默认80%）
- 支持多种图像格式

### 请求优化
- 设置合理的超时时间（2分钟）
- 错误重试机制
- 本地缓存机制

## 安全注意事项

1. **API密钥保护**
   - 不要在代码中硬编码API密钥
   - 使用环境变量或配置文件
   - 定期轮换API密钥

2. **数据隐私**
   - 图像数据仅用于识别分析
   - 不会永久存储在第三方服务器
   - 遵循相关隐私法规

## 成本控制

- 每次识别大约消耗0.01-0.05美元
- 建议设置月度预算限制
- 监控API使用量和成本

## 技术支持

如遇到问题，请：
1. 检查本文档的常见问题解决方案
2. 查看浏览器控制台的错误信息
3. 联系技术支持团队

## 更新日志

### v1.0.0 (2025-06-07)
- 初始版本发布
- 支持TUZI API集成
- 实现多模态AI识别
- 添加特征文案生成功能 