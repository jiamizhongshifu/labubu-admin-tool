// 完全安全的localStorage处理
function createSafeStorage() {
    let memoryStorage = new Map();
    
    return {
        getItem: function(key) {
            try {
                if (typeof window !== 'undefined' && window.localStorage) {
                    return window.localStorage.getItem(key);
                }
            } catch (e) {
                console.warn('localStorage access denied, using memory storage');
            }
            return memoryStorage.get(key) || null;
        },
        
        setItem: function(key, value) {
            try {
                if (typeof window !== 'undefined' && window.localStorage) {
                    window.localStorage.setItem(key, value);
                    return;
                }
            } catch (e) {
                console.warn('localStorage access denied, using memory storage');
            }
            memoryStorage.set(key, String(value));
        },
        
        removeItem: function(key) {
            try {
                if (typeof window !== 'undefined' && window.localStorage) {
                    window.localStorage.removeItem(key);
                    return;
                }
            } catch (e) {
                console.warn('localStorage access denied, using memory storage');
            }
            memoryStorage.delete(key);
        }
    };
}

// 全局安全存储
window.safeStorage = createSafeStorage(); 