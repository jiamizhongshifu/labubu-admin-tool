# 🗄️ Supabase数据库设置指南

## 问题诊断
从控制台错误看，数据库查询返回400错误，可能原因：
1. `labubu_models`表不存在
2. 行级安全策略(RLS)配置问题
3. API权限不足

## 解决步骤

### 1. 登录Supabase控制台
访问 [https://supabase.com/dashboard](https://supabase.com/dashboard)

### 2. 选择您的项目
找到并点击您的Labubu项目

### 3. 创建数据库表
1. 点击左侧菜单 **"SQL Editor"**
2. 点击 **"New query"**
3. 复制并粘贴 `CREATE_LABUBU_TABLE.sql` 中的SQL代码
4. 点击 **"Run"** 执行

### 4. 验证表创建
在SQL Editor中运行：
```sql
SELECT * FROM public.labubu_models;
```

### 5. 检查API权限
1. 点击左侧菜单 **"Settings"** → **"API"**
2. 确认以下信息：
   - **Project URL**: `https://your-project.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### 6. 配置行级安全策略
如果表已存在但仍有权限问题，在SQL Editor中运行：
```sql
-- 禁用RLS（仅用于测试）
ALTER TABLE public.labubu_models DISABLE ROW LEVEL SECURITY;

-- 或者创建允许所有操作的策略
CREATE POLICY "Allow all operations" ON public.labubu_models
    FOR ALL USING (true) WITH CHECK (true);
```

## 配置dashboard
1. 访问 https://labubu-admin-tool.vercel.app/dashboard
2. 点击 **"⚙️ 配置数据库"**
3. 输入您的Supabase URL和Anon Key
4. 点击 **"保存并连接"**

## 验证成功
连接成功后应该看到：
- ✅ 数据库连接正常
- 显示示例Labubu模型数据
- 可以添加、编辑、删除模型

## 故障排除
如果仍有问题：
1. 检查Supabase项目是否暂停
2. 确认API密钥是否正确
3. 查看Supabase项目的API日志
4. 尝试在Supabase控制台直接查询表 