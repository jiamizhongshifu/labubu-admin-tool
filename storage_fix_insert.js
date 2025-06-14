        // 存储修复工具
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
        }

        // 初始化存储修复
        const storageFix = new StorageFix();
        window.safeStorage = {
            getItem: (key) => storageFix.safeGetItem(key),
            setItem: (key, value) => storageFix.safeSetItem(key, value),
            info: () => storageFix.getStorageInfo()
        }; 