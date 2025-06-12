# .env文件配置快速指南

## 🚀 快速开始

只需3步即可完成AI识别功能的配置：

### 第1步：创建.env文件

```bash
# 在项目根目录执行
cp env.example .env
```

### 第2步：获取API密钥

1. 访问 [TUZI API官网](https://api.tu-zi.com)
2. 注册账号并获取API密钥
3. 复制您的API密钥（格式类似：`sk-xxxxxxxxxxxxxxxxxxxxxxxx`）

### 第3步：编辑.env文件

用文本编辑器打开`.env`文件，替换以下内容：

```bash
# AI识别API配置
TUZI_API_KEY=sk-your-actual-api-key-here  # 替换为您的真实API密钥
TUZI_API_BASE=https://api.tu-zi.com/v1

# 向后兼容配置（可选）
OPENAI_API_KEY=sk-your-actual-api-key-here

# Supabase数据库配置（如果使用数据库功能）
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
SUPABASE_STORAGE_BUCKET=jitata-images
```

## ✅ 验证配置

### 方法1：使用配置检查工具

```bash
# 打开配置检查工具
open admin_tool/check-config.html
```

### 方法2：手动验证

确保您的`.env`文件包含以下必需配置：
- ✅ `TUZI_API_KEY` 已设置且不是默认值
- ✅ `TUZI_API_BASE` 已设置（通常使用默认值即可）

## 🔒 安全注意事项

1. **不要提交.env文件到Git**
   ```bash
   # 确保.gitignore包含以下内容
   .env
   ```

2. **保护您的API密钥**
   - 不要在代码中硬编码API密钥
   - 不要在公开场所分享API密钥
   - 定期轮换API密钥

3. **文件权限**
   ```bash
   # 设置适当的文件权限（仅所有者可读写）
   chmod 600 .env
   ```

## 🎯 配置优先级

系统会按以下优先级读取配置：

1. **环境变量** - 最高优先级
2. **.env文件** - 推荐方式
3. **配置文件** - admin_tool/config.js
4. **默认值** - 最低优先级

## 📱 支持的功能

配置完成后，以下功能将可用：

### iOS应用
- ✅ 用户拍照后的AI识别
- ✅ 详细的特征分析报告
- ✅ 智能数据库匹配

### Web管理工具
- ✅ 上传图片后的智能特征生成
- ✅ 自动填充颜色、形状、纹理等特征
- ✅ AI生成的详细描述文案

## 🛠️ 故障排除

### 常见问题

**Q: 提示"API配置缺失"**
```
A: 检查.env文件是否存在，TUZI_API_KEY是否正确设置
```

**Q: 提示"API请求失败: 401"**
```
A: API密钥无效或已过期，请检查密钥是否正确
```

**Q: iOS应用无法读取.env文件**
```
A: 确保.env文件在项目根目录，且文件格式正确
```

**Q: Web工具无法访问.env文件**
```
A: 浏览器安全限制，建议使用config.js配置文件
```

### 调试方法

1. **检查文件路径**
   ```bash
   ls -la .env  # 确认文件存在
   ```

2. **检查文件内容**
   ```bash
   cat .env  # 查看文件内容
   ```

3. **检查配置格式**
   - 确保没有多余的空格
   - 确保使用正确的等号格式
   - 确保没有引号包围值

## 📞 技术支持

如果遇到问题：

1. 查看本指南的故障排除部分
2. 使用配置检查工具验证配置
3. 查看应用控制台的错误信息
4. 参考详细的[AI识别配置指南](ai-recognition-setup.md)

## 🔄 更新配置

如需更新API密钥：

1. 编辑`.env`文件
2. 替换新的API密钥
3. 重启应用或刷新页面
4. 验证新配置是否生效

---

**提示**：配置完成后，建议先使用测试图片验证AI识别功能是否正常工作。 