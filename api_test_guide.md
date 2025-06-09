# API服务测试指南

## 当前状态
❌ **API密钥未配置** - 需要设置环境变量才能测试API服务

## 设置步骤

### 1. 获取API密钥
- 您需要从API服务提供商获取有效的API密钥
- API服务地址：`https://api.tu-zi.com/v1`
- 使用的模型：`gpt-image-1`

### 2. 设置环境变量

#### 方法一：临时设置（仅当前终端会话有效）
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
```

#### 方法二：永久设置（推荐）
在您的shell配置文件中添加：

**对于 zsh (macOS默认):**
```bash
echo 'export OPENAI_API_KEY="your_actual_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

**对于 bash:**
```bash
echo 'export OPENAI_API_KEY="your_actual_api_key_here"' >> ~/.bash_profile
source ~/.bash_profile
```

### 3. 在Xcode中设置环境变量
1. 打开Xcode项目
2. 选择 Product → Scheme → Edit Scheme...
3. 选择 "Run" 标签
4. 点击 "Arguments" 标签
5. 在 "Environment Variables" 部分添加：
   - Name: `OPENAI_API_KEY`
   - Value: `your_actual_api_key_here`

## 测试命令

### 基础连接测试
```bash
# 设置API密钥后运行
swift test_api.swift
```

### 在应用中测试
1. 确保已设置环境变量
2. 在Xcode中运行应用
3. 拍摄一张照片并保存
4. 观察是否自动触发AI增强功能

## 预期结果

### 成功的测试输出示例：
```
=== OpenAI API 连接测试 ===
🔍 测试API连接...
📍 API地址: https://api.tu-zi.com/v1
🔑 API密钥: sk-1234567...
📡 HTTP状态码: 200
📦 响应数据大小: 1234 bytes
📄 响应内容: {"object":"list","data":[...
✅ API连接成功！
=== 测试完成 ===
```

### 可能的错误和解决方案：

#### 401 认证失败
- **原因**: API密钥无效或过期
- **解决**: 检查API密钥是否正确，联系服务提供商确认

#### 404 端点不存在
- **原因**: API地址错误
- **解决**: 确认API服务地址是否正确

#### 429 请求过于频繁
- **原因**: 达到API调用限制
- **解决**: 等待一段时间后重试

#### 500-599 服务器错误
- **原因**: API服务暂时不可用
- **解决**: 稍后重试，或联系服务提供商

## 应用内测试功能

应用包含以下测试工具：

1. **AIEnhancementTestHelper** - AI增强功能测试
2. **APITestHelper** - API服务连接测试
3. **DeveloperTools** - 开发者调试工具

这些工具可以在开发环境中使用，帮助诊断和调试AI增强功能。

## 注意事项

1. **安全性**: 不要在代码中硬编码API密钥
2. **环境隔离**: 开发和生产环境使用不同的API密钥
3. **错误处理**: 应用已实现完整的错误处理和重试机制
4. **用户体验**: API调用失败时，用户可以手动重试增强功能 