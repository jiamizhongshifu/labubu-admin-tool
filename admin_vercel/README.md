# Labubu管理工具 - Vercel部署版

这是Labubu数据管理工具的Vercel部署版本，提供了完整的身份验证和数据管理功能。

## 功能特性

- ✅ 安全的身份验证系统
- ✅ 模型数据的增删改查
- ✅ 响应式设计，支持移动端
- ✅ 与Supabase数据库集成
- ✅ 简洁的管理界面

## 技术架构

- **前端**: Vue.js 3 + 原生CSS
- **后端**: Vercel API Routes (Node.js)
- **数据库**: Supabase PostgreSQL
- **身份验证**: JWT + bcrypt
- **部署**: Vercel

## 快速部署

### 1. 准备工作

确保您已经有：
- Vercel账户
- Supabase项目和数据库
- 管理员邮箱和密码

### 2. 部署到Vercel

1. **Fork或下载此项目**
2. **连接到Vercel**
   - 登录Vercel控制台
   - 点击"New Project"
   - 导入此项目

3. **配置环境变量**
   在Vercel项目设置中添加以下环境变量：

   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
   ADMIN_EMAIL=admin@example.com
   ADMIN_PASSWORD=$2a$10$hashed_password_here
   JWT_SECRET=your_random_jwt_secret
   ```

4. **生成密码哈希**
   
   使用在线bcrypt工具或Node.js生成密码哈希：
   ```javascript
   const bcrypt = require('bcryptjs');
   const hashedPassword = bcrypt.hashSync('your_password', 10);
   console.log(hashedPassword);
   ```

5. **部署**
   - 点击"Deploy"
   - 等待部署完成

### 3. 访问管理工具

部署完成后：
1. 访问您的Vercel域名
2. 使用配置的管理员邮箱和密码登录
3. 开始管理Labubu数据

## 本地开发

### 安装依赖
```bash
npm install
```

### 配置环境变量
```bash
cp env.example .env.local
# 编辑 .env.local 填入实际配置
```

### 启动开发服务器
```bash
npm run dev
```

### 访问应用
- 登录页面: http://localhost:3000
- 管理面板: http://localhost:3000/dashboard

## 项目结构

```
admin_vercel/
├── api/                    # Vercel API Routes
│   ├── login.js           # 登录API
│   ├── verify-token.js    # Token验证API
│   └── models.js          # 模型数据API
├── public/                # 静态文件
│   ├── index.html         # 登录页面
│   └── dashboard.html     # 管理面板
├── package.json           # 项目配置
├── vercel.json           # Vercel配置
├── env.example           # 环境变量示例
└── README.md             # 说明文档
```

## API接口

### 身份验证
- `POST /api/login` - 用户登录
- `POST /api/verify-token` - 验证Token

### 数据管理
- `GET /api/models` - 获取所有模型
- `POST /api/models` - 创建新模型
- `PUT /api/models` - 更新模型
- `DELETE /api/models?id=<id>` - 删除模型

## 安全特性

- JWT Token身份验证
- bcrypt密码加密
- API请求权限验证
- 环境变量保护敏感信息

## 故障排除

### 常见问题

1. **登录失败**
   - 检查ADMIN_EMAIL和ADMIN_PASSWORD环境变量
   - 确认密码已正确使用bcrypt加密

2. **数据库连接失败**
   - 检查SUPABASE_URL和SUPABASE_SERVICE_ROLE_KEY
   - 确认Supabase项目状态正常

3. **Token验证失败**
   - 检查JWT_SECRET环境变量
   - 清除浏览器localStorage重新登录

### 日志查看

在Vercel控制台的"Functions"标签页可以查看API调用日志。

## 更新和维护

### 更新代码
1. 更新代码后推送到Git仓库
2. Vercel会自动重新部署

### 数据备份
建议定期备份Supabase数据库数据。

## 支持

如有问题，请检查：
1. Vercel部署日志
2. 浏览器开发者工具控制台
3. Supabase项目状态

## 许可证

MIT License 