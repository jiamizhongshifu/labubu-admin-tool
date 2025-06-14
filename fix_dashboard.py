#!/usr/bin/env python3
import re

# 读取原始文件
with open('dashboard.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 存储修复代码
storage_fix_code = '''        // 存储修复工具
        class StorageFix {
            constructor() {
                this.memoryStorage = {};
                this.isStorageAvailable = this.checkStorageAvailability();
                this.initializeStorageFix();
            }

            checkStorageAvailability() {
                try {
                    const test = '__storage_test__';
                    localStorage.setItem(test, test);
                    localStorage.removeItem(test);
                    console.log('✅ LocalStorage 可用');
                    return true;
                } catch (e) {
                    console.warn('⚠️ LocalStorage 不可用，启用内存存储备用方案:', e.message);
                    return false;
                }
            }

            initializeStorageFix() {
                if (!this.isStorageAvailable) {
                    this.createStoragePolyfill();
                }
            }

            createStoragePolyfill() {
                const self = this;
                window.localStorage = {
                    getItem: function(key) {
                        return self.memoryStorage[key] || null;
                    },
                    setItem: function(key, value) {
                        self.memoryStorage[key] = String(value);
                    },
                    removeItem: function(key) {
                        delete self.memoryStorage[key];
                    },
                    clear: function() {
                        self.memoryStorage = {};
                    },
                    get length() {
                        return Object.keys(self.memoryStorage).length;
                    },
                    key: function(index) {
                        const keys = Object.keys(self.memoryStorage);
                        return keys[index] || null;
                    }
                };
                console.log('🔧 已启用localStorage兼容层');
            }

            safeGetItem(key) {
                try {
                    if (this.isStorageAvailable) {
                        return localStorage.getItem(key);
                    } else {
                        return this.memoryStorage[key] || null;
                    }
                } catch (e) {
                    console.warn(`获取存储项失败 ${key}:`, e.message);
                    return this.memoryStorage[key] || null;
                }
            }

            safeSetItem(key, value) {
                try {
                    if (this.isStorageAvailable) {
                        localStorage.setItem(key, value);
                    } else {
                        this.memoryStorage[key] = value;
                    }
                    return true;
                } catch (e) {
                    console.warn(`设置存储项失败 ${key}:`, e.message);
                    this.memoryStorage[key] = value;
                    return false;
                }
            }
        }

        // 初始化存储修复
        const storageFix = new StorageFix();
        window.safeStorage = {
            getItem: (key) => storageFix.safeGetItem(key),
            setItem: (key, value) => storageFix.safeSetItem(key, value)
        };

'''

# 在 const { createApp } = Vue; 之前插入存储修复代码
content = content.replace(
    '        const { createApp } = Vue;',
    storage_fix_code + '        const { createApp } = Vue;'
)

# 修复Vue版本
content = content.replace('vue.global.js', 'vue.global.prod.js')

# 替换存储调用
content = content.replace('this.safeLocalStorage()', 'window.safeStorage')

# 删除原有的safeLocalStorage方法
# 使用正则表达式删除整个方法
pattern = r'                safeLocalStorage\(\) \{.*?\},\s*'
content = re.sub(pattern, '', content, flags=re.DOTALL)

# 写入修复后的文件
with open('dashboard.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ dashboard.html 修复完成") 