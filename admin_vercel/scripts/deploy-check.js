#!/usr/bin/env node

/**
 * 部署前检查脚本
 * 验证所有必要的文件和配置是否就绪
 */

const fs = require('fs');
const path = require('path');

console.log('🔍 开始部署前检查...\n');

// 检查必要文件
const requiredFiles = [
    'package.json',
    'vercel.json',
    'api/login.js',
    'api/verify-token.js',
    'api/models.js',
    'public/index.html',
    'public/dashboard.html'
];

let allFilesExist = true;

console.log('📁 检查必要文件:');
requiredFiles.forEach(file => {
    const exists = fs.existsSync(path.join(__dirname, '..', file));
    console.log(`  ${exists ? '✅' : '❌'} ${file}`);
    if (!exists) allFilesExist = false;
});

// 检查package.json内容
console.log('\n📦 检查package.json配置:');
try {
    const packageJson = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8'));
    
    const requiredDeps = ['@supabase/supabase-js', 'bcryptjs', 'jsonwebtoken'];
    requiredDeps.forEach(dep => {
        const exists = packageJson.dependencies && packageJson.dependencies[dep];
        console.log(`  ${exists ? '✅' : '❌'} ${dep}`);
        if (!exists) allFilesExist = false;
    });
} catch (error) {
    console.log('  ❌ package.json 格式错误');
    allFilesExist = false;
}

// 检查vercel.json配置
console.log('\n⚙️ 检查vercel.json配置:');
try {
    const vercelJson = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'vercel.json'), 'utf8'));
    
    const hasApiRoutes = vercelJson.routes && vercelJson.routes.some(route => route.src === '/api/(.*)');
    console.log(`  ${hasApiRoutes ? '✅' : '❌'} API路由配置`);
    
    const hasEnvVars = vercelJson.env && Object.keys(vercelJson.env).length > 0;
    console.log(`  ${hasEnvVars ? '✅' : '❌'} 环境变量配置`);
    
    if (!hasApiRoutes || !hasEnvVars) allFilesExist = false;
} catch (error) {
    console.log('  ❌ vercel.json 格式错误');
    allFilesExist = false;
}

// 检查API文件语法
console.log('\n🔧 检查API文件语法:');
const apiFiles = ['api/login.js', 'api/verify-token.js', 'api/models.js'];
apiFiles.forEach(file => {
    try {
        const content = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
        // 简单的语法检查
        if (content.includes('export default') && content.includes('async function handler')) {
            console.log(`  ✅ ${file}`);
        } else {
            console.log(`  ❌ ${file} - 缺少必要的导出或处理函数`);
            allFilesExist = false;
        }
    } catch (error) {
        console.log(`  ❌ ${file} - 读取失败`);
        allFilesExist = false;
    }
});

// 检查HTML文件
console.log('\n🌐 检查HTML文件:');
const htmlFiles = ['public/index.html', 'public/dashboard.html'];
htmlFiles.forEach(file => {
    try {
        const content = fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
        const hasVue = content.includes('vue@3');
        const hasScript = content.includes('<script>');
        console.log(`  ${hasVue && hasScript ? '✅' : '❌'} ${file}`);
        if (!hasVue || !hasScript) allFilesExist = false;
    } catch (error) {
        console.log(`  ❌ ${file} - 读取失败`);
        allFilesExist = false;
    }
});

// 最终结果
console.log('\n' + '='.repeat(50));
if (allFilesExist) {
    console.log('🎉 所有检查通过！项目已准备好部署到Vercel。');
    console.log('\n📋 部署步骤:');
    console.log('1. 将项目推送到Git仓库');
    console.log('2. 在Vercel中导入项目');
    console.log('3. 配置环境变量:');
    console.log('   - SUPABASE_URL');
    console.log('   - SUPABASE_SERVICE_ROLE_KEY');
    console.log('   - ADMIN_EMAIL');
    console.log('   - ADMIN_PASSWORD (使用bcrypt哈希)');
    console.log('   - JWT_SECRET');
    console.log('4. 点击部署');
    console.log('\n💡 提示: 使用 node generate-password.js <密码> 生成密码哈希');
    process.exit(0);
} else {
    console.log('❌ 检查失败！请修复上述问题后再部署。');
    process.exit(1);
} 