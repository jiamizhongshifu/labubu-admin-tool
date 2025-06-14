# 🔧 数据库400错误修复指南

## 🚨 问题诊断
从控制台日志看到：
```
Failed to load resource: the server responded with a status of 400 ()
❌ 加载模型失败: Object
```

这表明**数据库表不存在**或**权限配置问题**。

## ✅ 解决方案

### 1. 登录Supabase控制台
访问 https://supabase.com/dashboard

### 2. 创建数据库表
在SQL Editor中运行以下代码：

```sql
-- 创建 labubu_models 表
CREATE TABLE IF NOT EXISTS public.labubu_models (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    series TEXT,
    release_price TEXT,
    reference_price TEXT,
    rarity TEXT,
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 配置权限策略
ALTER TABLE public.labubu_models ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all operations" ON public.labubu_models 
    FOR ALL USING (true) WITH CHECK (true);

-- 插入测试数据
INSERT INTO public.labubu_models (name, series, release_price, reference_price, rarity) VALUES
('Labubu草莓马卡龙', 'The Monsters', '59', '120', '普通'),
('Labubu巧克力马卡龙', 'The Monsters', '59', '150', '不常见');
```

### 3. 验证表创建
运行查询验证：
```sql
SELECT * FROM public.labubu_models;
```

### 4. 重新配置dashboard
1. 访问 https://labubu-admin-tool.vercel.app/dashboard
2. 点击 **"⚙️ 配置数据库"**
3. 输入正确的Supabase URL和Anon Key
4. 点击 **"保存并连接"**

## 🎯 预期结果
修复后应该看到：
- ✅ 数据库连接正常
- 显示Labubu模型列表
- 可以添加新模型

## 📞 如需帮助
如果仍有问题，请检查：
1. Supabase项目是否处于活跃状态
2. API密钥是否正确
3. 网络连接是否正常 