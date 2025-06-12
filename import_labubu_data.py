#!/usr/bin/env python3
"""
Labubu数据导入脚本
将sample_data.json中的数据批量导入到Supabase数据库
"""

import json
import requests
import uuid
from datetime import datetime
from typing import Dict, List, Any

class LabubuDataImporter:
    def __init__(self, supabase_url: str, service_role_key: str):
        self.supabase_url = supabase_url.rstrip('/')
        self.headers = {
            'apikey': service_role_key,
            'Authorization': f'Bearer {service_role_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
    
    def load_sample_data(self, file_path: str = 'sample_data.json') -> Dict[str, Any]:
        """加载sample_data.json文件"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"❌ 加载数据文件失败: {e}")
            return {}
    
    def import_series(self, series_data: List[Dict]) -> Dict[str, str]:
        """导入系列数据，返回系列名称到ID的映射"""
        series_mapping = {}
        
        for series in series_data:
            series_id = str(uuid.uuid4())
            series_record = {
                'id': series_id,
                'name': series['name'],
                'name_en': series['name_en'],
                'description': series['description'],
                'release_year': series['release_year'],
                'total_models': series['total_models'],
                'theme': series['theme'],
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            try:
                response = requests.post(
                    f"{self.supabase_url}/rest/v1/labubu_series",
                    headers=self.headers,
                    json=series_record
                )
                
                if response.status_code in [200, 201]:
                    series_mapping[series['name']] = series_id
                    print(f"✅ 导入系列: {series['name']}")
                else:
                    print(f"❌ 导入系列失败: {series['name']} - {response.text}")
                    
            except Exception as e:
                print(f"❌ 导入系列异常: {series['name']} - {e}")
        
        return series_mapping
    
    def import_models(self, models_data: List[Dict], series_mapping: Dict[str, str]):
        """导入模型数据"""
        for model in models_data:
            model_id = str(uuid.uuid4())
            series_id = series_mapping.get(model['series_name'])
            
            if not series_id:
                print(f"⚠️ 跳过模型 {model['name']}：找不到对应系列")
                continue
            
            # 处理参考图片
            reference_images = []
            for img in model.get('reference_images', []):
                reference_images.append({
                    'id': str(uuid.uuid4()),
                    'image_url': img['url'],
                    'angle': self.map_image_type(img['type']),
                    'upload_date': datetime.now().isoformat()
                })
            
            # 处理视觉特征
            visual_features = model.get('visual_features', {})
            processed_features = {
                'primary_colors': self.process_colors(visual_features.get('dominant_colors', [])),
                'color_distribution': {},
                'shape_descriptor': {
                    'aspect_ratio': visual_features.get('height_cm', 6.5) / visual_features.get('width_cm', 4.2),
                    'roundness': 0.8,  # 默认值，可根据body_shape调整
                    'symmetry': 0.9,
                    'complexity': 0.6,
                    'key_points': []
                },
                'texture_features': {
                    'smoothness': 0.8 if visual_features.get('surface_texture') == '光滑' else 0.4,
                    'roughness': 0.2 if visual_features.get('surface_texture') == '光滑' else 0.6,
                    'patterns': [visual_features.get('pattern_type', '纯色')],
                    'material_type': 'plush'
                },
                'special_marks': [visual_features.get('special_marks', '')],
                'feature_vector': visual_features.get('feature_vector', [0.5] * 10)
            }
            
            model_record = {
                'id': model_id,
                'name': model['name_en'],
                'name_cn': model['name'],
                'series_id': series_id,
                'variant': 'standard',
                'rarity': model['rarity_level'],
                'release_date': model.get('release_date'),
                'original_price': model.get('original_price'),
                'reference_images': reference_images,
                'visual_features': processed_features,
                'tags': self.extract_tags(model),
                'description': model.get('description'),
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            try:
                response = requests.post(
                    f"{self.supabase_url}/rest/v1/labubu_models",
                    headers=self.headers,
                    json=model_record
                )
                
                if response.status_code in [200, 201]:
                    print(f"✅ 导入模型: {model['name']}")
                else:
                    print(f"❌ 导入模型失败: {model['name']} - {response.text}")
                    
            except Exception as e:
                print(f"❌ 导入模型异常: {model['name']} - {e}")
    
    def map_image_type(self, image_type: str) -> str:
        """映射图片类型"""
        mapping = {
            'official_front': 'front',
            'official_side': 'left',
            'official_back': 'back',
            'user_photo': 'front',
            'detail': 'detail'
        }
        return mapping.get(image_type, 'front')
    
    def process_colors(self, colors: List[str]) -> List[Dict]:
        """处理颜色数据"""
        processed = []
        for i, color in enumerate(colors[:3]):  # 最多3个主要颜色
            processed.append({
                'color': color,
                'percentage': 0.4 if i == 0 else 0.3 if i == 1 else 0.3,
                'region': 'body' if i == 0 else 'face' if i == 1 else 'accessory'
            })
        return processed
    
    def extract_tags(self, model: Dict) -> List[str]:
        """提取标签"""
        tags = []
        visual = model.get('visual_features', {})
        
        # 添加颜色标签
        for color in visual.get('dominant_colors', [])[:2]:
            if color.startswith('#'):
                color_name = self.hex_to_color_name(color)
                if color_name:
                    tags.append(color_name)
        
        # 添加形状标签
        if visual.get('body_shape'):
            tags.append(visual['body_shape'])
        if visual.get('ear_type'):
            tags.append(visual['ear_type'])
        
        # 添加稀有度标签
        tags.append(model['rarity_level'])
        
        return tags
    
    def hex_to_color_name(self, hex_color: str) -> str:
        """将十六进制颜色转换为颜色名称"""
        color_map = {
            '#FFB6C1': '粉色',
            '#87CEEB': '蓝色', 
            '#FFD700': '黄色',
            '#FF0000': '红色',
            '#00FF00': '绿色',
            '#FFFFFF': '白色',
            '#000000': '黑色'
        }
        return color_map.get(hex_color.upper(), '')
    
    def run_import(self):
        """执行完整的数据导入流程"""
        print("🚀 开始导入Labubu数据...")
        
        # 加载数据
        data = self.load_sample_data()
        if not data:
            return
        
        # 导入系列
        print("\n📚 导入系列数据...")
        series_mapping = self.import_series(data.get('series', []))
        
        # 导入模型
        print(f"\n🎭 导入模型数据...")
        self.import_models(data.get('models', []), series_mapping)
        
        print(f"\n✅ 数据导入完成！")
        print(f"   - 系列数量: {len(series_mapping)}")
        print(f"   - 模型数量: {len(data.get('models', []))}")

def main():
    """主函数"""
    print("=== Labubu数据导入工具 ===\n")
    
    # 配置信息（请替换为您的实际配置）
    SUPABASE_URL = input("请输入Supabase URL: ").strip()
    SERVICE_ROLE_KEY = input("请输入Service Role Key: ").strip()
    
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("❌ 配置信息不完整，请重新运行脚本")
        return
    
    # 创建导入器并执行导入
    importer = LabubuDataImporter(SUPABASE_URL, SERVICE_ROLE_KEY)
    importer.run_import()

if __name__ == "__main__":
    main() 