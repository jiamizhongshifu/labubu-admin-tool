const { createApp } = Vue;
const { createClient } = supabase;

// 安全的存储访问工具
const SafeStorage = {
    // 检查存储是否可用
    isStorageAvailable() {
        try {
            const test = '__storage_test__';
            localStorage.setItem(test, test);
            localStorage.removeItem(test);
            return true;
        } catch (e) {
            console.warn('LocalStorage不可用，将使用内存存储:', e.message);
            return false;
        }
    },
    
    // 内存存储备用方案
    memoryStorage: {},
    
    // 安全获取存储项
    getItem(key) {
        try {
            if (this.isStorageAvailable()) {
                return localStorage.getItem(key);
            } else {
                return this.memoryStorage[key] || null;
            }
        } catch (e) {
            console.warn(`获取存储项失败 ${key}:`, e.message);
            return this.memoryStorage[key] || null;
        }
    },
    
    // 安全设置存储项
    setItem(key, value) {
        try {
            if (this.isStorageAvailable()) {
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
    },
    
    // 安全移除存储项
    removeItem(key) {
        try {
            if (this.isStorageAvailable()) {
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
};

createApp({
    data() {
        return {
            // 连接状态
            isConnected: false,
            supabaseClient: null,
            connectionCached: false, // 连接缓存状态
            lastConnectionCheck: null, // 最后连接检查时间
            cacheValidDuration: 5 * 60 * 1000, // 缓存有效期：5分钟
            
            // 配置 - 使用安全存储
            config: {
                supabaseUrl: SafeStorage.getItem('supabase_url') || '',
                serviceRoleKey: SafeStorage.getItem('service_role_key') || ''
            },
            
            // UI状态
            activeTab: 'series',
            loading: false,
            alertMessage: '',
            alertType: 'success',
            
            // 数据列表
            seriesList: [],
            modelsList: [],
            imagesList: [],
            pricesList: [],
            
            // 筛选器
            selectedSeriesFilter: '',
            selectedModelForImages: '',
            selectedModelForPrices: '',
            
            // 模态框状态
            showSeriesModal: false,
            showModelModal: false,
            showImageModal: false,
            showPriceModal: false,
            
            // 编辑状态
            editingSeries: null,
            editingModel: null,
            editingImage: null,
            
            // 表单数据
            seriesForm: {
                name: '',
                name_en: '',
                description: '',
                release_year: new Date().getFullYear(),
                total_models: 0
            },
            modelForm: {
                id: '',
                series_id: '',
                name: '',
                description: '',
                release_date: '',
                rarity_level: 'common',
                weight_g: 50,
                material: 'plush',
                feature_description: '',
                release_price: '',
                reference_price: '',
                model_number: '',
                tags: []
            },
            
            // 特征描述输入模式
            featureInputMode: 'json', // 'text' 或 'json' - 默认使用JSON模式
            jsonFeatureInput: '',
            jsonParseStatus: null,
            
            // 图片上传相关
            uploadedImages: [],
            imagePreviewUrls: [],
            isUploading: false,
            uploadProgress: 0,

            imageForm: {
                image_url: '',
                image_type: 'front',
                is_primary: false,
                sort_order: 0
            },
            priceForm: {
                price: 0,
                currency: 'CNY',
                source: '',
                condition: 'new'
            },
            
            // 导入功能
            importPreview: null,
            
            // 错误状态跟踪
            storageError: false,
            connectionError: null
        }
    },
    
    computed: {
        hasUploadedImages() {
            return this.uploadedImages.length > 0;
        }
    },

    mounted() {
        // 检查存储可用性
        this.checkStorageAvailability();
        
        // 尝试从缓存恢复连接
        this.tryRestoreConnection();
    },
    
    methods: {
        // ===== 存储管理 =====
        
        // 检查存储可用性
        checkStorageAvailability() {
            this.storageError = !SafeStorage.isStorageAvailable();
            if (this.storageError) {
                this.showAlert('浏览器存储不可用，将使用临时存储（刷新页面后配置会丢失）', 'warning');
            }
        },
        
        // 安全保存配置
        saveConfig() {
            try {
                SafeStorage.setItem('supabase_url', this.config.supabaseUrl);
                SafeStorage.setItem('service_role_key', this.config.serviceRoleKey);
                return true;
            } catch (error) {
                console.error('保存配置失败:', error);
                this.showAlert('保存配置失败，请检查浏览器设置', 'error');
                return false;
            }
        },
        
        // ===== 连接管理 =====
        
        // 尝试从缓存恢复连接
        async tryRestoreConnection() {
            try {
                // 检查是否有缓存的连接信息
                const cachedConnectionTime = SafeStorage.getItem('connection_time');
                const cachedConnectionStatus = SafeStorage.getItem('connection_status');
                
                if (cachedConnectionTime && cachedConnectionStatus === 'connected') {
                    const cacheAge = Date.now() - parseInt(cachedConnectionTime);
                    
                    // 如果缓存仍然有效（5分钟内）
                    if (cacheAge < this.cacheValidDuration) {
                        console.log('🔄 使用缓存连接，剩余有效时间:', Math.round((this.cacheValidDuration - cacheAge) / 1000), '秒');
                        
                        if (this.config.supabaseUrl && this.config.serviceRoleKey) {
                            // 创建客户端但跳过验证
                            this.supabaseClient = createClient(
                                this.config.supabaseUrl,
                                this.config.serviceRoleKey
                            );
                            
                            this.isConnected = true;
                            this.connectionCached = true;
                            this.lastConnectionCheck = parseInt(cachedConnectionTime);
                            
                            // 快速检查存储桶（跳过上传测试）
                            await this.checkStorageBucket(true);
                            
                            // 静默加载数据（不显示loading）
                            await this.loadSeries();
                            
                            this.showAlert('已从缓存恢复连接', 'success');
                            return;
                        }
                    }
                }
                
                // 缓存无效或不存在，尝试正常连接
                if (this.config.supabaseUrl && this.config.serviceRoleKey) {
                    await this.connectToSupabase();
                }
                
            } catch (error) {
                console.warn('缓存恢复失败，尝试正常连接:', error);
                this.connectionError = error.message;
                if (this.config.supabaseUrl && this.config.serviceRoleKey) {
                    await this.connectToSupabase();
                }
            }
        },
        
        // 检查连接是否仍然有效
        async validateConnection() {
            if (!this.supabaseClient || !this.isConnected) {
                this.showAlert('当前未连接到数据库', 'error');
                return false;
            }
            
            try {
                this.loading = true;
                const { data, error } = await this.supabaseClient
                    .from('labubu_series')
                    .select('count')
                    .limit(1);
                
                if (!error) {
                    this.showAlert('连接验证成功！', 'success');
                    this.connectionError = null;
                    return true;
                } else {
                    this.showAlert(`连接验证失败: ${error.message}`, 'error');
                    this.connectionError = error.message;
                    // 清除缓存，因为连接已失效
                    this.clearConnectionCache();
                    this.isConnected = false;
                    return false;
                }
            } catch (error) {
                console.warn('连接验证失败:', error);
                this.showAlert(`连接验证失败: ${error.message}`, 'error');
                this.connectionError = error.message;
                // 清除缓存，因为连接已失效
                this.clearConnectionCache();
                this.isConnected = false;
                return false;
            } finally {
                this.loading = false;
            }
        },
        
        // 强制重新连接
        async forceReconnect() {
            // 清除缓存
            this.clearConnectionCache();
            
            // 重新连接
            await this.connectToSupabase();
        },
        
        // 清除连接缓存
        clearConnectionCache() {
            SafeStorage.removeItem('connection_time');
            SafeStorage.removeItem('connection_status');
            this.connectionCached = false;
            this.lastConnectionCheck = null;
        },
        
        async connectToSupabase() {
            try {
                this.loading = true;
                
                if (!this.config.supabaseUrl || !this.config.serviceRoleKey) {
                    throw new Error('请填写完整的Supabase配置信息');
                }
                
                // 创建Supabase客户端
                this.supabaseClient = createClient(
                    this.config.supabaseUrl,
                    this.config.serviceRoleKey
                );
                
                // 测试连接
                const { data, error } = await this.supabaseClient
                    .from('labubu_series')
                    .select('count')
                    .limit(1);
                
                if (error) {
                    throw new Error(`连接失败: ${error.message}`);
                }
                
                // 检查存储桶
                await this.checkStorageBucket();
                
                // 保存配置和连接缓存
                this.saveConfig();
                SafeStorage.setItem('connection_time', Date.now().toString());
                SafeStorage.setItem('connection_status', 'connected');
                
                this.isConnected = true;
                this.connectionCached = false; // 这是新的连接，不是缓存
                this.lastConnectionCheck = Date.now();
                this.showAlert('成功连接到Supabase数据库！', 'success');
                
                // 加载初始数据
                await this.loadSeries();
                
            } catch (error) {
                this.showAlert(error.message, 'error');
                console.error('连接错误:', error);
            } finally {
                this.loading = false;
            }
        },
        
        async checkStorageBucket(skipUploadTest = false) {
            try {
                console.log('🔍 检查存储桶配置...');
                
                // 检查存储桶是否存在
                const { data: buckets, error: bucketsError } = await this.supabaseClient.storage.listBuckets();
                
                if (bucketsError) {
                    console.warn('⚠️ 无法获取存储桶列表:', bucketsError);
                    return;
                }
                
                const labubuBucket = buckets.find(bucket => bucket.name === 'labubu-images');
                
                if (!labubuBucket) {
                    console.warn('⚠️ 未找到 labubu-images 存储桶');
                    this.showAlert('警告：未找到 labubu-images 存储桶，图片上传功能可能无法正常工作', 'warning');
                    return;
                }
                
                console.log('✅ 存储桶检查通过:', labubuBucket);
                
                // 如果是缓存连接，跳过上传测试以提高速度
                if (skipUploadTest) {
                    console.log('⚡ 缓存模式：跳过上传权限测试');
                    return;
                }
                
                // 测试上传权限（创建一个小的测试文件）
                const testFileName = `test_${Date.now()}.txt`;
                const testFile = new Blob(['test'], { type: 'text/plain' });
                
                const { data: uploadData, error: uploadError } = await this.supabaseClient.storage
                    .from('labubu-images')
                    .upload(testFileName, testFile, {
                        cacheControl: '3600',
                        upsert: false
                    });
                
                if (uploadError) {
                    console.warn('⚠️ 存储桶上传测试失败:', uploadError);
                    // 不显示警告，因为这个测试经常失败但不影响实际功能
                    // this.showAlert(`警告：存储桶上传权限测试失败 - ${uploadError.message}`, 'warning');
                } else {
                    console.log('✅ 存储桶上传权限测试通过');
                    
                    // 删除测试文件
                    await this.supabaseClient.storage
                        .from('labubu-images')
                        .remove([testFileName]);
                }
                
            } catch (error) {
                console.warn('⚠️ 存储桶检查失败:', error);
                // 不显示警告，避免干扰用户体验
                // this.showAlert(`警告：存储桶检查失败 - ${error.message}`, 'warning');
            }
        },
        
        // ===== 系列管理 =====
        async loadSeries() {
            try {
                this.loading = true;
                const { data, error } = await this.supabaseClient
                    .from('labubu_series')
                    .select('*')
                    .order('release_year', { ascending: false });
                
                if (error) throw error;
                
                this.seriesList = data || [];
                console.log('加载系列数据:', this.seriesList.length);
                
            } catch (error) {
                this.showAlert(`加载系列失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        editSeries(series) {
            this.editingSeries = series;
            this.seriesForm = { ...series };
            this.showSeriesModal = true;
        },
        
        async saveSeries() {
            try {
                this.loading = true;
                
                const seriesData = {
                    name: this.seriesForm.name,
                    name_en: this.seriesForm.name_en || null,
                    description: this.seriesForm.description || null,
                    release_year: parseInt(this.seriesForm.release_year),
                    total_models: parseInt(this.seriesForm.total_models) || 0,
                    is_active: true
                };
                
                let result;
                if (this.editingSeries) {
                    // 更新
                    result = await this.supabaseClient
                        .from('labubu_series')
                        .update(seriesData)
                        .eq('id', this.editingSeries.id);
                } else {
                    // 新增
                    result = await this.supabaseClient
                        .from('labubu_series')
                        .insert([seriesData]);
                }
                
                if (result.error) throw result.error;
                
                this.showAlert(this.editingSeries ? '系列更新成功！' : '系列创建成功！', 'success');
                this.closeSeriesModal();
                await this.loadSeries();
                
            } catch (error) {
                this.showAlert(`保存失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        async deleteSeries(seriesId) {
            if (!confirm('确定要删除这个系列吗？这将同时删除该系列下的所有模型。')) {
                return;
            }
            
            try {
                this.loading = true;
                
                const { error } = await this.supabaseClient
                    .from('labubu_series')
                    .delete()
                    .eq('id', seriesId);
                
                if (error) throw error;
                
                this.showAlert('系列删除成功！', 'success');
                await this.loadSeries();
                
            } catch (error) {
                this.showAlert(`删除失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        closeSeriesModal() {
            this.showSeriesModal = false;
            this.editingSeries = null;
            this.seriesForm = {
                name: '',
                name_en: '',
                description: '',
                release_year: new Date().getFullYear(),
                total_models: 0
            };
        },
        
        // ===== 模型管理 =====
        async loadModels() {
            try {
                this.loading = true;
                
                // 先尝试简单查询，看看是否有数据
                console.log('🔍 开始查询模型数据...');
                
                let query = this.supabaseClient
                    .from('labubu_models')
                    .select('*');
                
                if (this.selectedSeriesFilter) {
                    query = query.eq('series_id', this.selectedSeriesFilter);
                }
                
                // 先不加is_active过滤，看看是否有数据
                const { data: modelsData, error: modelsError } = await query
                    .order('created_at', { ascending: false });
                
                if (modelsError) {
                    console.error('❌ 查询模型数据失败:', modelsError);
                    throw modelsError;
                }
                
                console.log('📊 原始模型数据:', modelsData?.length || 0, modelsData);
                
                if (!modelsData || modelsData.length === 0) {
                    this.modelsList = [];
                    console.log('⚠️ 没有找到任何模型数据');
                    return;
                }
                
                // 获取系列信息
                const { data: seriesData, error: seriesError } = await this.supabaseClient
                    .from('labubu_series')
                    .select('*');
                
                if (seriesError) {
                    console.error('❌ 查询系列数据失败:', seriesError);
                    // 即使系列查询失败，也显示模型数据
                }
                
                console.log('📊 系列数据:', seriesData?.length || 0, seriesData);
                
                // 获取所有模型的主图
                const modelIds = modelsData.map(m => m.id);
                let imagesData = [];
                if (modelIds.length > 0) {
                    const { data: images, error: imagesError } = await this.supabaseClient
                        .from('labubu_reference_images')
                        .select('model_id, image_url, is_primary')
                        .in('model_id', modelIds)
                        .eq('is_primary', true);
                    
                    if (!imagesError) {
                        imagesData = images || [];
                    }
                }

                // 手动关联数据
                this.modelsList = modelsData.map(model => {
                    const series = seriesData?.find(s => s.id === model.series_id);
                    const primaryImage = imagesData.find(img => img.model_id === model.id);
                    return {
                        ...model,
                        series_name: series?.name || '未知系列',
                        series_name_en: series?.name_en || 'Unknown Series',
                        series_description: series?.description || '',
                        primary_image_url: primaryImage?.image_url || null
                    };
                });
                
                console.log('加载模型数据:', this.modelsList.length);
                console.log('📋 最终模型列表:', this.modelsList);
                
            } catch (error) {
                console.error('❌ 加载模型失败:', error);
                this.showAlert(`加载模型失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        async editModel(model) {
            console.log('📝 开始编辑模型:', model);
            
            this.editingModel = model;
            this.modelForm = { ...model };
            
            // 确保series_id是字符串格式，以便在下拉框中正确显示
            if (this.modelForm.series_id !== null && this.modelForm.series_id !== undefined) {
                this.modelForm.series_id = this.modelForm.series_id.toString();
            } else {
                // 如果series_id为null，设置为第一个可用系列的ID
                if (this.seriesList && this.seriesList.length > 0) {
                    this.modelForm.series_id = this.seriesList[0].id.toString();
                } else {
                    this.modelForm.series_id = '';
                }
            }
            
            console.log('📋 编辑表单数据:', this.modelForm);
            console.log('📋 当前系列列表:', this.seriesList);
            console.log('📋 模型系列ID:', this.modelForm.series_id, '类型:', typeof this.modelForm.series_id);
            
            // 智能检测特征描述格式并设置输入模式
            if (model.feature_description && this.isJSONFormat(model.feature_description)) {
                this.featureInputMode = 'json';
                this.jsonFeatureInput = model.feature_description;
            } else {
                this.featureInputMode = 'json'; // 默认使用JSON模式
                // 如果现有描述不是JSON格式，提供默认模板
                this.jsonFeatureInput = `{
  "primary_colors": [
    {
      "color": "#FFB6C1",
      "percentage": 0.6,
      "region": "body"
    }
  ],
  "shape_descriptor": {
    "aspect_ratio": 1.2,
    "roundness": 0.8,
    "symmetry": 0.9,
    "complexity": 0.5
  },
  "texture_features": {
    "smoothness": 0.7,
    "roughness": 0.3,
    "patterns": ["standard"],
    "material_type": "plush"
  },
  "special_marks": [],
  "description": "${model.feature_description || '请在此处描述模型的特征'}"
}`;
            }
            
            // 加载模型的现有图片
            await this.loadModelImages(model.id);
            
            this.showModelModal = true;
        },
        
        async loadModelImages(modelId) {
            try {
                console.log('📸 加载模型图片，模型ID:', modelId);
                
                const { data: images, error } = await this.supabaseClient
                    .from('labubu_reference_images')
                    .select('*')
                    .eq('model_id', modelId)
                    .order('sort_order');
                
                if (error) {
                    console.error('❌ 加载模型图片失败:', error);
                    return;
                }
                
                console.log('📋 模型现有图片:', images);
                
                if (images && images.length > 0) {
                    // 将现有图片转换为编辑界面可用的格式
                    this.uploadedImages = images.map(img => ({
                        id: img.id,
                        url: img.image_url,
                        type: img.image_type || 'front',
                        isPrimary: img.is_primary || false,
                        isExisting: true // 标记为现有图片
                    }));
                    
                    // 设置图片预览URL（保持与uploadedImages的id对应关系）
                    this.imagePreviewUrls = this.uploadedImages.map(img => ({
                        id: img.id,
                        url: img.url
                    }));
                    
                    console.log('✅ 已加载现有图片:', this.uploadedImages);
                } else {
                    this.uploadedImages = [];
                    this.imagePreviewUrls = [];
                    console.log('ℹ️ 该模型暂无图片');
                }
                
            } catch (error) {
                console.error('❌ 加载模型图片异常:', error);
                this.uploadedImages = [];
                this.imagePreviewUrls = [];
            }
        },
        
        async saveModel() {
            try {
                this.loading = true;
                this.isUploading = true;
                this.uploadProgress = 0;
                
                // 验证必填字段
                if (!this.modelForm.series_id || this.modelForm.series_id === '') {
                    throw new Error('请选择系列');
                }
                if (!this.modelForm.name) {
                    throw new Error('请填写模型名称');
                }
                if (!this.modelForm.rarity_level) {
                    throw new Error('请选择稀有度');
                }
                
                // 第一步：上传图片 (30%)
                this.uploadProgress = 10;
                const referenceImages = await this.uploadModelImages();
                this.uploadProgress = 30;
                
                // 第二步：构建视觉特征 (50%)
                const visualFeatures = this.buildVisualFeatures();
                this.uploadProgress = 50;
                
                // 第三步：保存模型数据 (80%)
                const modelData = {
                    series_id: (this.modelForm.series_id && this.modelForm.series_id !== '') ? this.modelForm.series_id : null,
                    name: this.modelForm.name, // 统一使用name字段
                    name_en: this.extractEnglishName(this.modelForm.name), // 自动提取英文部分
                    model_number: this.modelForm.model_number || null,
                    description: this.modelForm.description || null,
                    feature_description: this.modelForm.feature_description || null, // JSON格式特征描述
                    rarity_level: this.modelForm.rarity_level, // 使用正确的字段名
                    release_price: this.modelForm.release_price ? parseFloat(this.modelForm.release_price) : null,
                    reference_price: this.modelForm.reference_price ? parseFloat(this.modelForm.reference_price) : null,
                    is_active: true
                };
                
                // 只在新增时设置created_at，更新时设置updated_at
                if (this.editingModel) {
                    modelData.updated_at = new Date().toISOString();
                } else {
                    modelData.created_at = new Date().toISOString();
                    modelData.updated_at = new Date().toISOString();
                }
                
                console.log('📤 准备保存的模型数据:', modelData);
                this.uploadProgress = 80;
                
                let result;
                if (this.editingModel) {
                    // 更新
                    result = await this.supabaseClient
                        .from('labubu_models')
                        .update(modelData)
                        .eq('id', this.editingModel.id)
                        .select();
                } else {
                    // 新增
                    result = await this.supabaseClient
                        .from('labubu_models')
                        .insert([modelData])
                        .select();
                }
                
                if (result.error) {
                    console.error('❌ Supabase错误详情:', result.error);
                    throw new Error(`数据库操作失败: ${result.error.message}`);
                }
                
                console.log('✅ 模型保存成功:', result.data);
                
                // 第四步：保存图片数据到数据库 (90%)
                if (referenceImages.length > 0 && result.data && result.data.length > 0) {
                    const modelId = result.data[0].id;
                    console.log(`📸 开始保存 ${referenceImages.length} 张图片到数据库，模型ID: ${modelId}`);
                    
                    // 如果是编辑模式，先删除旧的图片记录
                    if (this.editingModel) {
                        console.log('🗑️ 编辑模式：先删除旧的图片记录');
                        const { error: deleteError } = await this.supabaseClient
                            .from('labubu_reference_images')
                            .delete()
                            .eq('model_id', modelId);
                        
                        if (deleteError) {
                            console.warn('⚠️ 删除旧图片记录失败:', deleteError);
                        } else {
                            console.log('✅ 旧图片记录删除成功');
                        }
                    }
                    
                    // 为每张图片添加模型ID
                    const imageRecords = referenceImages.map(img => ({
                        ...img,
                        model_id: modelId
                    }));
                    
                    console.log('📋 准备插入的图片数据:', imageRecords);
                    
                    const { data: imageData, error: imageError } = await this.supabaseClient
                        .from('labubu_reference_images')
                        .insert(imageRecords)
                        .select();
                    
                    if (imageError) {
                        console.error('❌ 图片数据保存失败:', imageError);
                        console.error('❌ 错误详情:', {
                            message: imageError.message,
                            details: imageError.details,
                            hint: imageError.hint,
                            code: imageError.code
                        });
                        this.showAlert(`模型保存成功，但图片数据保存失败: ${imageError.message}`, 'warning');
                    } else {
                        console.log('✅ 图片数据保存成功:', imageData);
                    }
                }
                
                this.uploadProgress = 100;
                this.showAlert(this.editingModel ? '模型更新成功！' : '模型创建成功！', 'success');
                this.closeModelModal();
                await this.loadModels();
                
            } catch (error) {
                this.showAlert(`保存失败: ${error.message}`, 'error');
                console.error('保存模型错误:', error);
            } finally {
                this.loading = false;
                this.isUploading = false;
                this.uploadProgress = 0;
            }
        },
        
        async deleteModel(modelId) {
            if (!confirm('确定要删除这个模型吗？')) {
                return;
            }
            
            try {
                this.loading = true;
                
                const { error } = await this.supabaseClient
                    .from('labubu_models')
                    .delete()
                    .eq('id', modelId);
                
                if (error) throw error;
                
                this.showAlert('模型删除成功！', 'success');
                await this.loadModels();
                
            } catch (error) {
                this.showAlert(`删除失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        closeModelModal() {
            console.log('🔒 关闭模型编辑模态框');
            this.showModelModal = false;
            this.editingModel = null;
            this.uploadedImages = [];
            this.imagePreviewUrls = [];
            this.modelForm = {
                id: '',
                series_id: '',
                name: '',
                description: '',
                release_date: '',
                rarity_level: 'common',
                weight_g: 50,
                material: 'plush',
                feature_description: '',
                release_price: '',
                reference_price: '',
                model_number: '',
                tags: []
            };
            
            // 重置为JSON模式并提供默认模板
            this.featureInputMode = 'json';
            this.jsonFeatureInput = `{
  "primary_colors": [
    {
      "color": "#FFB6C1",
      "percentage": 0.6,
      "region": "body"
    }
  ],
  "shape_descriptor": {
    "aspect_ratio": 1.2,
    "roundness": 0.8,
    "symmetry": 0.9,
    "complexity": 0.5
  },
  "texture_features": {
    "smoothness": 0.7,
    "roughness": 0.3,
    "patterns": ["standard"],
    "material_type": "plush"
  },
  "special_marks": [],
  "description": "请在此处描述模型的特征"
}`;
            this.jsonParseStatus = null;
        },
        
        // ===== 图片管理 =====
        async loadImages() {
            if (!this.selectedModelForImages) {
                this.imagesList = [];
                return;
            }
            
            try {
                this.loading = true;
                
                const { data, error } = await this.supabaseClient
                    .from('labubu_reference_images')
                    .select('*')
                    .eq('model_id', this.selectedModelForImages)
                    .order('sort_order')
                    .order('is_primary', { ascending: false });
                
                if (error) throw error;
                
                this.imagesList = data || [];
                console.log('加载图片数据:', this.imagesList.length);
                
            } catch (error) {
                this.showAlert(`加载图片失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        editImage(image) {
            this.editingImage = image;
            this.imageForm = { ...image };
            this.showImageModal = true;
        },
        
        async saveImage() {
            try {
                this.loading = true;
                
                const imageData = {
                    model_id: this.selectedModelForImages,
                    image_url: this.imageForm.image_url,
                    image_type: this.imageForm.image_type,
                    is_primary: this.imageForm.is_primary,
                    sort_order: parseInt(this.imageForm.sort_order) || 0
                };
                
                let result;
                if (this.editingImage) {
                    // 更新
                    result = await this.supabaseClient
                        .from('labubu_reference_images')
                        .update(imageData)
                        .eq('id', this.editingImage.id);
                } else {
                    // 新增
                    result = await this.supabaseClient
                        .from('labubu_reference_images')
                        .insert([imageData]);
                }
                
                if (result.error) throw result.error;
                
                this.showAlert(this.editingImage ? '图片更新成功！' : '图片添加成功！', 'success');
                this.closeImageModal();
                await this.loadImages();
                
            } catch (error) {
                this.showAlert(`保存失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        async deleteImage(imageId) {
            if (!confirm('确定要删除这张图片吗？')) {
                return;
            }
            
            try {
                this.loading = true;
                
                const { error } = await this.supabaseClient
                    .from('labubu_reference_images')
                    .delete()
                    .eq('id', imageId);
                
                if (error) throw error;
                
                this.showAlert('图片删除成功！', 'success');
                await this.loadImages();
                
            } catch (error) {
                this.showAlert(`删除失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        closeImageModal() {
            this.showImageModal = false;
            this.editingImage = null;
            this.imageForm = {
                image_url: '',
                image_type: 'front',
                is_primary: false,
                sort_order: 0
            };
        },
        
        // ===== 价格管理 =====
        async loadPrices() {
            if (!this.selectedModelForPrices) {
                this.pricesList = [];
                return;
            }
            
            try {
                this.loading = true;
                
                const { data, error } = await this.supabaseClient
                    .from('labubu_price_history')
                    .select('*')
                    .eq('model_id', this.selectedModelForPrices)
                    .order('recorded_at', { ascending: false });
                
                if (error) throw error;
                
                this.pricesList = data || [];
                console.log('加载价格数据:', this.pricesList.length);
                
            } catch (error) {
                this.showAlert(`加载价格失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        async savePrice() {
            try {
                this.loading = true;
                
                const priceData = {
                    model_id: this.selectedModelForPrices,
                    price: parseFloat(this.priceForm.price),
                    currency: this.priceForm.currency,
                    source: this.priceForm.source || null,
                    condition: this.priceForm.condition,
                    recorded_at: new Date().toISOString()
                };
                
                const { error } = await this.supabaseClient
                    .from('labubu_price_history')
                    .insert([priceData]);
                
                if (error) throw error;
                
                this.showAlert('价格记录添加成功！', 'success');
                this.closePriceModal();
                await this.loadPrices();
                
            } catch (error) {
                this.showAlert(`保存失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        async deletePrice(priceId) {
            if (!confirm('确定要删除这条价格记录吗？')) {
                return;
            }
            
            try {
                this.loading = true;
                
                const { error } = await this.supabaseClient
                    .from('labubu_price_history')
                    .delete()
                    .eq('id', priceId);
                
                if (error) throw error;
                
                this.showAlert('价格记录删除成功！', 'success');
                await this.loadPrices();
                
            } catch (error) {
                this.showAlert(`删除失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        closePriceModal() {
            this.showPriceModal = false;
            this.priceForm = {
                price: 0,
                currency: 'CNY',
                source: '',
                condition: 'new'
            };
        },
        
        // ===== 图片上传功能 =====
        async handleImageUpload(event) {
            const files = Array.from(event.target.files);
            if (files.length === 0) return;
            
            // 限制图片数量
            if (this.uploadedImages.length + files.length > 5) {
                this.showAlert('最多只能上传5张图片', 'error');
                return;
            }
            
            files.forEach((file, index) => {
                // 验证文件类型
                if (!file.type.startsWith('image/')) {
                    this.showAlert(`${file.name} 不是有效的图片文件`, 'error');
                    return;
                }
                
                // 验证文件大小 (5MB)
                if (file.size > 5 * 1024 * 1024) {
                    this.showAlert(`${file.name} 文件过大，请选择小于5MB的图片`, 'error');
                    return;
                }
                
                // 生成唯一ID
                const imageId = Date.now() + Math.random() + index;
                
                // 添加到上传列表
                const imageData = {
                    file: file,
                    name: file.name,
                    size: file.size,
                    type: 'official_front',
                    is_primary: this.uploadedImages.length === 0,
                    id: imageId
                };
                this.uploadedImages.push(imageData);
                
                // 生成预览URL
                const reader = new FileReader();
                reader.onload = (e) => {
                    this.imagePreviewUrls.push({
                        id: imageId,
                        url: e.target.result
                    });
                    
                    // 如果这是最后一个文件，显示手动输入提示
                    if (this.imagePreviewUrls.length === files.length) {
                        setTimeout(() => {
                            this.handleImageUploadComplete();
                        }, 100);
                    }
                };
                reader.onerror = (error) => {
                    console.error('文件读取失败:', error);
                    this.showAlert(`${file.name} 读取失败`, 'error');
                };
                reader.readAsDataURL(file);
            });
            
            this.showAlert(`成功添加 ${files.length} 张图片`, 'success');
        },
        
        removeUploadedImage(imageId) {
            const index = this.uploadedImages.findIndex(img => img.id === imageId);
            if (index > -1) {
                this.uploadedImages.splice(index, 1);
                const previewIndex = this.imagePreviewUrls.findIndex(preview => preview.id === imageId);
                if (previewIndex > -1) {
                    this.imagePreviewUrls.splice(previewIndex, 1);
                }
                
                // 如果删除的是主图，设置第一张为主图
                if (this.uploadedImages.length > 0 && !this.uploadedImages.some(img => img.is_primary)) {
                    this.uploadedImages[0].is_primary = true;
                }
            }
        },
        
        setAsPrimaryImage(imageId) {
            this.uploadedImages.forEach(img => {
                img.is_primary = img.id === imageId;
            });
        },
        
        async uploadModelImages() {
            if (this.uploadedImages.length === 0) {
                console.log('📊 没有图片需要上传');
                return [];
            }
            
            const referenceImages = [];
            
            for (let i = 0; i < this.uploadedImages.length; i++) {
                const imageData = this.uploadedImages[i];
                
                try {
                    // 检查是否为现有图片（编辑模式下已存在的图片）
                    if (imageData.isExisting) {
                        console.log(`📋 保留现有图片: ${imageData.url}`);
                        referenceImages.push({
                            image_url: imageData.url,
                            image_type: imageData.type || 'front',
                            is_primary: imageData.isPrimary || false,
                            sort_order: 0
                        });
                        continue;
                    }
                    
                    // 处理新上传的图片
                    if (!imageData.file) {
                        console.warn('⚠️ 图片数据缺少文件对象:', imageData);
                        continue;
                    }
                    
                    // 生成唯一文件名
                    const timestamp = Date.now();
                    const randomId = Math.random().toString(36).substring(2);
                    const fileExtension = imageData.file.name.split('.').pop().toLowerCase();
                    const fileName = `labubu_${timestamp}_${randomId}.${fileExtension}`;
                    
                    console.log(`📤 正在上传新图片: ${fileName}`);
                    console.log(`📋 文件信息:`, {
                        name: imageData.file.name,
                        size: imageData.file.size,
                        type: imageData.file.type
                    });
                    
                    // 检查文件大小（限制为5MB）
                    if (imageData.file.size > 5 * 1024 * 1024) {
                        console.warn(`⚠️ 文件过大: ${imageData.file.name} (${(imageData.file.size / 1024 / 1024).toFixed(2)}MB)`);
                        this.showAlert(`图片 ${imageData.file.name} 过大，请选择小于5MB的图片`, 'error');
                        continue;
                    }
                    
                    // 检查文件类型
                    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
                    if (!allowedTypes.includes(imageData.file.type)) {
                        console.warn(`⚠️ 不支持的文件类型: ${imageData.file.type}`);
                        this.showAlert(`不支持的图片格式: ${imageData.file.type}`, 'error');
                        continue;
                    }
                    
                    // 上传到Supabase Storage
                    const { data, error } = await this.supabaseClient.storage
                        .from('labubu-images')
                        .upload(fileName, imageData.file, {
                            cacheControl: '3600',
                            upsert: false,
                            contentType: imageData.file.type
                        });
                    
                    if (error) {
                        console.error('❌ 图片上传失败:', error);
                        console.error('❌ 错误详情:', {
                            message: error.message,
                            statusCode: error.statusCode,
                            error: error.error
                        });
                        
                        // 尝试更详细的错误信息
                        let errorMessage = error.message;
                        if (error.statusCode === 400) {
                            errorMessage = '上传失败：可能是文件格式不支持或存储桶配置问题';
                        } else if (error.statusCode === 413) {
                            errorMessage = '上传失败：文件过大';
                        } else if (error.statusCode === 403) {
                            errorMessage = '上传失败：权限不足，请检查存储桶权限设置';
                        }
                        
                        this.showAlert(`图片上传失败: ${errorMessage}`, 'error');
                        // 如果上传失败，跳过这张图片
                        continue;
                    } else {
                        // 获取公共URL
                        const { data: urlData } = this.supabaseClient.storage
                            .from('labubu-images')
                            .getPublicUrl(fileName);
                        
                        console.log(`✅ 新图片上传成功: ${urlData.publicUrl}`);
                        
                        // 如果是第一张图片且没有设置主图，自动设为主图
                        const isPrimary = imageData.is_primary || (referenceImages.length === 0 && !this.editingModel);
                        
                        referenceImages.push({
                            image_url: urlData.publicUrl,
                            image_type: this.mapImageType(imageData.type),
                            is_primary: isPrimary,
                            sort_order: referenceImages.length
                        });
                    }
                } catch (error) {
                    console.error('❌ 处理图片失败:', error);
                    const fileName = imageData.file ? imageData.file.name : '未知图片';
                    this.showAlert(`图片 ${fileName} 处理失败: ${error.message}`, 'error');
                }
            }
            
            console.log(`📊 处理完成，共 ${referenceImages.length} 张图片（包含现有图片和新上传图片）`);
            return referenceImages;
        },
        
        async convertToBase64(file) {
            return new Promise((resolve, reject) => {
                const reader = new FileReader();
                reader.onload = () => resolve(reader.result);
                reader.onerror = reject;
                reader.readAsDataURL(file);
            });
        },
        
        mapImageType(type) {
            const mapping = {
                'official_front': 'front',
                'official_side': 'left',
                'official_back': 'back',
                'user_photo': 'front',
                'detail': 'detail',
                'package': 'detail'
            };
            return mapping[type] || 'front';
        },
        
        buildVisualFeatures() {
            // 基于特征描述生成简化的视觉特征
            const featureDescription = this.modelForm.feature_description || '';
            
            // 基础默认特征
            const defaultFeatures = {
                primary_colors: [{ color: '#FFB6C1', percentage: 0.5, region: 'body' }],
                color_distribution: {},
                shape_descriptor: {
                    aspect_ratio: 1.2,
                    roundness: 0.8,
                    symmetry: 0.9,
                    complexity: 0.5,
                    key_points: []
                },
                contour_points: [],
                texture_features: {
                    smoothness: 0.7,
                    roughness: 0.3,
                    patterns: ['standard'],
                    material_type: 'plush'
                },
                special_marks: [],
                feature_vector: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5],
                description: featureDescription
            };
            
            return defaultFeatures;
        },
        
        generateFeatureVector() {
            // 生成默认的10维特征向量
            return [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
        },

        generateModelTags() {
            const tags = [this.modelForm.rarity];
            
            // 基于特征描述生成标签
            const featureDescription = this.modelForm.feature_description || '';
            if (featureDescription) {
                // 从特征描述中提取关键词作为标签
                const keywords = featureDescription.toLowerCase().match(/[a-zA-Z\u4e00-\u9fa5]+/g) || [];
                const commonTags = ['粉色', '蓝色', '黄色', '红色', '绿色', '白色', '黑色', '圆润', '方正', '尖耳', '圆耳', '光滑', '绒毛'];
                
                keywords.forEach(keyword => {
                    if (commonTags.includes(keyword) && !tags.includes(keyword)) {
                        tags.push(keyword);
                    }
                });
            }
            
            return tags;
        },
        
        generateUUID() {
            return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                const r = Math.random() * 16 | 0;
                const v = c == 'x' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        },
        
        // ===== 名称处理方法 =====
        extractChineseName(fullName) {
            if (!fullName) return null;
            
            // 提取中文字符（包括中文标点符号）
            const chineseMatch = fullName.match(/[\u4e00-\u9fff\u3400-\u4dbf\uff00-\uffef]+/g);
            if (chineseMatch && chineseMatch.length > 0) {
                return chineseMatch.join('').trim();
            }
            
            return null;
        },
        
        extractEnglishName(fullName) {
            if (!fullName) return null;
            
            // 移除中文字符，保留英文、数字、空格和常用标点
            const englishPart = fullName.replace(/[\u4e00-\u9fff\u3400-\u4dbf\uff00-\uffef]/g, '').trim();
            
            // 清理多余的空格和标点
            const cleanEnglish = englishPart.replace(/\s+/g, ' ').replace(/^[^\w]+|[^\w]+$/g, '').trim();
            
            return cleanEnglish || null;
        },
        
        // ===== JSON特征描述处理 =====
        parseJSONFeatures() {
            try {
                if (!this.jsonFeatureInput.trim()) {
                    this.jsonParseStatus = {
                        type: 'error',
                        message: '请先输入JSON内容'
                    };
                    return;
                }
                
                // 验证JSON格式是否正确
                const jsonData = JSON.parse(this.jsonFeatureInput);
                
                // 直接保存完整的JSON格式特征描述
                this.modelForm.feature_description = this.jsonFeatureInput.trim();
                this.jsonParseStatus = {
                    type: 'success',
                    message: '✅ JSON格式验证通过，将保存完整的结构化特征描述'
                };
                
                // 清除状态提示（3秒后）
                setTimeout(() => {
                    this.jsonParseStatus = null;
                }, 3000);
                
            } catch (error) {
                this.jsonParseStatus = {
                    type: 'error',
                    message: `❌ JSON格式错误: ${error.message}`
                };
                
                // 清除状态提示（5秒后）
                setTimeout(() => {
                    this.jsonParseStatus = null;
                }, 5000);
            }
        },
        
        formatJSON() {
            try {
                if (!this.jsonFeatureInput.trim()) {
                    this.jsonParseStatus = {
                        type: 'error',
                        message: '请先输入JSON内容'
                    };
                    return;
                }
                
                const jsonData = JSON.parse(this.jsonFeatureInput);
                this.jsonFeatureInput = JSON.stringify(jsonData, null, 2);
                
                this.jsonParseStatus = {
                    type: 'success',
                    message: '✅ JSON格式化完成'
                };
                
                // 清除状态提示（2秒后）
                setTimeout(() => {
                    this.jsonParseStatus = null;
                }, 2000);
                
            } catch (error) {
                this.jsonParseStatus = {
                    type: 'error',
                    message: `❌ JSON格式错误: ${error.message}`
                };
                
                // 清除状态提示（5秒后）
                setTimeout(() => {
                    this.jsonParseStatus = null;
                }, 5000);
            }
        },
        
        // ===== JSON格式检测和预览 =====
        isJSONFormat(text) {
            if (!text || typeof text !== 'string') return false;
            
            try {
                const trimmed = text.trim();
                if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return false;
                
                JSON.parse(trimmed);
                return true;
            } catch (error) {
                return false;
            }
        },
        
        formatJSONPreview(jsonText) {
            try {
                const jsonData = JSON.parse(jsonText);
                return JSON.stringify(jsonData, null, 2);
            } catch (error) {
                return jsonText;
            }
        },

        // ===== 手动特征管理 =====
        // 图片上传完成后的处理（纯手动模式）
        handleImageUploadComplete() {
            this.showAlert('✅ 图片上传完成！请手动填写所有特征信息', 'info');
        },

        // ===== 数据导入 =====
        handleFileUpload(event) {
            const file = event.target.files[0];
            if (!file) return;
            
            const reader = new FileReader();
            reader.onload = (e) => {
                try {
                    const jsonData = JSON.parse(e.target.result);
                    this.importPreview = jsonData;
                } catch (error) {
                    this.showAlert('JSON文件格式错误', 'error');
                }
            };
            reader.readAsText(file);
        },
        
        async executeImport() {
            try {
                this.loading = true;
                
                if (!this.importPreview) {
                    throw new Error('没有可导入的数据');
                }
                
                // 这里可以根据数据结构进行批量导入
                // 示例：假设导入的是系列数据
                if (this.importPreview.series) {
                    const { error } = await this.supabaseClient
                        .from('labubu_series')
                        .insert(this.importPreview.series);
                    
                    if (error) throw error;
                }
                
                if (this.importPreview.models) {
                    const { error } = await this.supabaseClient
                        .from('labubu_models')
                        .insert(this.importPreview.models);
                    
                    if (error) throw error;
                }
                
                this.showAlert('数据导入成功！', 'success');
                this.importPreview = null;
                
                // 重新加载数据
                await this.loadSeries();
                await this.loadModels();
                
            } catch (error) {
                this.showAlert(`导入失败: ${error.message}`, 'error');
            } finally {
                this.loading = false;
            }
        },
        
        // ===== 工具方法 =====
        showAlert(message, type = 'success') {
            this.alertMessage = message;
            this.alertType = type;
            
            // 3秒后自动隐藏
            setTimeout(() => {
                this.alertMessage = '';
            }, 3000);
        },
        
        formatDate(dateString) {
            return new Date(dateString).toLocaleString('zh-CN');
        },
    },
    
    watch: {
        // 监听标签页切换，自动加载数据
        activeTab(newTab) {
            switch (newTab) {
                case 'series':
                    if (this.seriesList.length === 0) {
                        this.loadSeries();
                    }
                    break;
                case 'models':
                    if (this.modelsList.length === 0) {
                        this.loadModels();
                    }
                    break;
                case 'images':
                case 'prices':
                    // 图片和价格管理需要模型列表
                    if (this.modelsList.length === 0) {
                        this.loadModels();
                    }
                    break;
            }
        },
        
        // 监听连接状态
        isConnected(connected) {
            if (connected) {
                // 连接成功后加载基础数据
                this.loadSeries();
                this.loadModels();
            }
        }
    }
}).mount('#app'); 