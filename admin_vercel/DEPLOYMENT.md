# 🚀 Labubu管理工具 - 快速部署指南

## 📋 部署前准备清单

- [ ] Vercel账户已创建
- [ ] Supabase项目已设置
- [ ] 管理员邮箱和密码已确定
- [ ] Git仓库已准备

## ⚡ 5分钟快速部署

### 步骤1: 生成密码哈希

```bash
cd admin_vercel
npm install
node generate-password.js your_admin_password
```

复制输出的哈希密码和JWT密钥备用。

### 步骤2: 部署前检查

```bash
npm run deploy-check
```

确保所有检查项都通过。

### 步骤3: 部署到Vercel

1. **推送代码到Git**
   ```bash
   git add .
   git commit -m "Add Labubu admin tool"
   git push
   ```

2. **在Vercel中导入项目**
   - 访问 [vercel.com](https://vercel.com)
   - 点击 "New Project"
   - 选择您的Git仓库
   - 选择 `admin_vercel` 目录作为根目录

3. **配置环境变量**
   在Vercel项目设置中添加：
   
   | 变量名 | 值 | 说明 |
   |--------|----|----|
   | `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase项目URL |
   | `SUPABASE_SERVICE_ROLE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` | Supabase服务密钥 |
   | `ADMIN_EMAIL` | `admin@example.com` | 管理员邮箱 |
   | `ADMIN_PASSWORD` | `$2a$10$...` | 步骤1生成的哈希密码 |
   | `JWT_SECRET` | `abc123...` | 步骤1生成的JWT密钥 |

4. **点击部署**
   - 点击 "Deploy" 按钮
   - 等待部署完成（通常1-2分钟）

### 步骤4: 验证部署

1. 访问分配的Vercel域名
2. 使用管理员邮箱和原始密码登录
3. 确认可以正常访问管理面板

## 🔧 环境变量获取指南

### Supabase配置

1. **SUPABASE_URL**
   - 登录Supabase控制台
   - 选择项目
   - 在Settings > API中找到"Project URL"

2. **SUPABASE_SERVICE_ROLE_KEY**
   - 在同一页面找到"service_role"密钥
   - ⚠️ 注意：这是敏感信息，请妥善保管

### 管理员配置

1. **ADMIN_EMAIL**
   - 设置您希望的管理员邮箱地址

2. **ADMIN_PASSWORD**
   - 使用 `node generate-password.js <密码>` 生成
   - 必须使用哈希值，不能使用明文密码

3. **JWT_SECRET**
   - 使用 `node generate-password.js` 生成的随机密钥
   - 或使用在线工具生成64位随机字符串

## 🛠️ 故障排除

### 常见问题

1. **部署失败**
   ```bash
   npm run deploy-check
   ```
   运行检查脚本确认所有文件正确

2. **登录失败**
   - 检查ADMIN_EMAIL和ADMIN_PASSWORD环境变量
   - 确认使用的是哈希密码，不是明文
   - 检查JWT_SECRET是否设置

3. **数据库连接失败**
   - 验证SUPABASE_URL格式正确
   - 确认SUPABASE_SERVICE_ROLE_KEY有效
   - 检查Supabase项目状态

4. **API调用失败**
   - 在Vercel控制台查看Function日志
   - 检查浏览器开发者工具的网络请求

### 调试技巧

1. **查看部署日志**
   - Vercel控制台 > Deployments > 点击具体部署

2. **查看Function日志**
   - Vercel控制台 > Functions > 选择API函数

3. **本地测试**
   ```bash
   cp env.example .env.local
   # 编辑.env.local填入配置
   npm run dev
   ```

## 🔄 更新部署

### 代码更新
```bash
git add .
git commit -m "Update admin tool"
git push
```
Vercel会自动重新部署。

### 环境变量更新
在Vercel控制台的Settings > Environment Variables中修改。

## 📊 监控和维护

### 性能监控
- Vercel控制台提供访问统计和性能指标
- 关注API响应时间和错误率

### 安全建议
- 定期更换JWT_SECRET
- 监控异常登录尝试
- 定期备份Supabase数据

### 数据备份
建议设置Supabase自动备份或定期手动导出数据。

## 📞 获取帮助

如果遇到问题：

1. 检查本文档的故障排除部分
2. 查看Vercel和Supabase的官方文档
3. 检查项目的GitHub Issues

---

🎉 **恭喜！您的Labubu管理工具已成功部署！** 