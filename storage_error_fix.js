// 全局存储错误捕获和修复
(function() {
    'use strict';
    
    console.log('🔧 启动全局存储错误修复...');
    
    // 捕获所有未处理的Promise错误
    window.addEventListener('unhandledrejection', function(event) {
        if (event.reason && event.reason.message && 
            event.reason.message.includes('Access to storage is not allowed')) {
            console.warn('🛡️ 捕获并阻止存储访问错误:', event.reason.message);
            event.preventDefault(); // 阻止错误显示在控制台
        }
    });
    
    // 捕获所有JavaScript错误
    window.addEventListener('error', function(event) {
        if (event.message && event.message.includes('Access to storage is not allowed')) {
            console.warn('🛡️ 捕获并阻止存储访问错误:', event.message);
            event.preventDefault();
        }
    });
    
    // 重写localStorage以提供更好的错误处理
    const originalLocalStorage = window.localStorage;
    const memoryStorage = {};
    
    function createSafeStorage() {
        return {
            getItem: function(key) {
                try {
                    return originalLocalStorage.getItem(key);
                } catch (e) {
                    console.warn('🔄 localStorage访问失败，使用内存存储:', key);
                    return memoryStorage[key] || null;
                }
            },
            setItem: function(key, value) {
                try {
                    originalLocalStorage.setItem(key, value);
                } catch (e) {
                    console.warn('🔄 localStorage写入失败，使用内存存储:', key);
                    memoryStorage[key] = String(value);
                }
            },
            removeItem: function(key) {
                try {
                    originalLocalStorage.removeItem(key);
                } catch (e) {
                    console.warn('🔄 localStorage删除失败，使用内存存储:', key);
                    delete memoryStorage[key];
                }
            },
            clear: function() {
                try {
                    originalLocalStorage.clear();
                } catch (e) {
                    console.warn('🔄 localStorage清空失败，清空内存存储');
                    Object.keys(memoryStorage).forEach(key => delete memoryStorage[key]);
                }
            },
            get length() {
                try {
                    return originalLocalStorage.length;
                } catch (e) {
                    return Object.keys(memoryStorage).length;
                }
            },
            key: function(index) {
                try {
                    return originalLocalStorage.key(index);
                } catch (e) {
                    const keys = Object.keys(memoryStorage);
                    return keys[index] || null;
                }
            }
        };
    }
    
    // 如果localStorage不可用，替换它
    try {
        localStorage.setItem('__test__', '__test__');
        localStorage.removeItem('__test__');
        console.log('✅ 原生localStorage可用');
    } catch (e) {
        console.warn('⚠️ 原生localStorage不可用，启用安全存储代理');
        Object.defineProperty(window, 'localStorage', {
            value: createSafeStorage(),
            writable: false,
            configurable: false
        });
    }
    
    console.log('✅ 全局存储错误修复已启动');
})(); 