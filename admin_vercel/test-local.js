#!/usr/bin/env node

/**
 * 本地测试脚本
 * 用于在部署前进行本地功能测试
 */

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

// 简单的静态文件服务器
const server = http.createServer((req, res) => {
    const parsedUrl = url.parse(req.url, true);
    let pathname = parsedUrl.pathname;
    
    // 路由处理
    if (pathname === '/') {
        pathname = '/index.html';
    } else if (pathname === '/dashboard') {
        pathname = '/dashboard.html';
    }
    
    // 静态文件处理
    if (pathname.startsWith('/')) {
        const filePath = path.join(__dirname, 'public', pathname);
        
        fs.readFile(filePath, (err, data) => {
            if (err) {
                res.writeHead(404, { 'Content-Type': 'text/html' });
                res.end('<h1>404 - 页面未找到</h1>');
                return;
            }
            
            // 设置正确的Content-Type
            let contentType = 'text/html';
            if (pathname.endsWith('.css')) {
                contentType = 'text/css';
            } else if (pathname.endsWith('.js')) {
                contentType = 'application/javascript';
            }
            
            res.writeHead(200, { 'Content-Type': contentType });
            res.end(data);
        });
    } else {
        res.writeHead(404, { 'Content-Type': 'text/html' });
        res.end('<h1>404 - 页面未找到</h1>');
    }
});

const PORT = 3000;

server.listen(PORT, () => {
    console.log('🚀 本地测试服务器已启动');
    console.log(`📱 访问地址: http://localhost:${PORT}`);
    console.log('📋 测试页面:');
    console.log(`   - 登录页面: http://localhost:${PORT}/`);
    console.log(`   - 管理面板: http://localhost:${PORT}/dashboard`);
    console.log('\n⚠️  注意: 这只是前端页面测试，API功能需要部署到Vercel后才能使用');
    console.log('💡 按 Ctrl+C 停止服务器');
});

// 优雅关闭
process.on('SIGINT', () => {
    console.log('\n👋 服务器已停止');
    process.exit(0);
}); 