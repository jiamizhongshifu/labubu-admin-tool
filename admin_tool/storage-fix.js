// 存储访问修复工具
// 解决 "Access to storage is not allowed from this context" 错误

class StorageFix {
    constructor() {
        this.memoryStorage = {};
        this.isStorageAvailable = this.checkStorageAvailability();
        this.initializeStorageFix();
    }

    // 检查存储是否可用
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

    // 初始化存储修复
    initializeStorageFix() {
        // 如果localStorage不可用，创建一个兼容的替代方案
        if (!this.isStorageAvailable) {
            this.createStoragePolyfill();
        }
    }

    // 创建存储兼容层
    createStoragePolyfill() {
        const self = this;
        
        // 创建一个兼容的localStorage对象
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

    // 安全的存储操作方法
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

    safeRemoveItem(key) {
        try {
            if (this.isStorageAvailable) {
                localStorage.removeItem(key);
            }
            delete this.memoryStorage[key];
            return true;
        } catch (e) {
            console.warn(`移除存储项失败 ${key}:`, e.message);
            delete this.memoryStorage[key];
            return false;
        }
    }

    // 获取存储状态信息
    getStorageInfo() {
        return {
            isStorageAvailable: this.isStorageAvailable,
            memoryStorageKeys: Object.keys(this.memoryStorage),
            memoryStorageSize: Object.keys(this.memoryStorage).length,
            userAgent: navigator.userAgent,
            isSecureContext: window.isSecureContext,
            protocol: window.location.protocol
        };
    }

    // 测试存储功能
    testStorage() {
        const testKey = 'storage_test_' + Date.now();
        const testValue = 'test_value_' + Math.random();
        
        console.log('🧪 开始存储测试...');
        
        // 测试设置
        const setResult = this.safeSetItem(testKey, testValue);
        console.log('设置测试:', setResult ? '✅ 成功' : '❌ 失败');
        
        // 测试获取
        const getValue = this.safeGetItem(testKey);
        const getResult = getValue === testValue;
        console.log('获取测试:', getResult ? '✅ 成功' : '❌ 失败', '值:', getValue);
        
        // 测试删除
        const removeResult = this.safeRemoveItem(testKey);
        console.log('删除测试:', removeResult ? '✅ 成功' : '❌ 失败');
        
        // 验证删除
        const verifyDelete = this.safeGetItem(testKey) === null;
        console.log('删除验证:', verifyDelete ? '✅ 成功' : '❌ 失败');
        
        const overallResult = setResult && getResult && removeResult && verifyDelete;
        console.log('📊 存储测试总结:', overallResult ? '✅ 全部通过' : '⚠️ 部分失败');
        
        return {
            setResult,
            getResult,
            removeResult,
            verifyDelete,
            overallResult,
            storageInfo: this.getStorageInfo()
        };
    }
}

// 自动初始化存储修复
const storageFix = new StorageFix();

// 导出给全局使用
window.StorageFix = StorageFix;
window.storageFix = storageFix;

// 提供简化的API
window.safeStorage = {
    getItem: (key) => storageFix.safeGetItem(key),
    setItem: (key, value) => storageFix.safeSetItem(key, value),
    removeItem: (key) => storageFix.safeRemoveItem(key),
    test: () => storageFix.testStorage(),
    info: () => storageFix.getStorageInfo()
};

console.log('🚀 存储修复工具已加载');
console.log('📋 使用方法:');
console.log('  - safeStorage.getItem(key)');
console.log('  - safeStorage.setItem(key, value)');
console.log('  - safeStorage.removeItem(key)');
console.log('  - safeStorage.test() // 运行测试');
console.log('  - safeStorage.info() // 获取状态信息'); 