#!/usr/bin/env python3
"""
Labubu渐进式数据导入脚本
支持先导入基础数据，后续逐步补充更多图片和特征
"""

import json
import requests
import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional

class ProgressiveLabubuImporter:
    def __init__(self, supabase_url: str, service_role_key: str):
        self.supabase_url = supabase_url.rstrip('/')
        self.headers = {
            'apikey': service_role_key,
            'Authorization': f'Bearer {service_role_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
    
    def create_minimal_model(self, 
                           name: str,
                           name_cn: str, 
                           series_id: str,
                           primary_image_url: str,
                           dominant_colors: List[str],
                           rarity: str = "common",
                           description: Optional[str] = None) -> Dict[str, Any]:
        """创建最小化的模型数据"""
        
        model_id = str(uuid.uuid4())
        
        # 最基础的参考图片（只需要一张）
        reference_images = [{
            'id': str(uuid.uuid4()),
            'image_url': primary_image_url,
            'angle': 'front',
            'is_primary': True,
            'quality_score': 0.9,
            'upload_date': datetime.now().isoformat()
        }]
        
        # 基于单张图片的视觉特征
        visual_features = self.extract_basic_features(dominant_colors)
        
        model_record = {
            'id': model_id,
            'name': name,
            'name_cn': name_cn,
            'series_id': series_id,
            'variant': 'standard',
            'rarity': rarity,
            'reference_images': reference_images,
            'visual_features': visual_features,
            'tags': self.generate_basic_tags(dominant_colors, rarity),
            'description': description or f"{name_cn}的基础信息",
            'created_at': datetime.now().isoformat(),
            'updated_at': datetime.now().isoformat(),
            'data_completeness': 'basic'  # 标记数据完整度
        }
        
        return model_record
    
    def extract_basic_features(self, dominant_colors: List[str]) -> Dict[str, Any]:
        """从基础信息提取视觉特征"""
        
        # 处理颜色特征
        primary_colors = []
        for i, color in enumerate(dominant_colors[:3]):
            primary_colors.append({
                'color': color,
                'percentage': 0.5 if i == 0 else 0.3 if i == 1 else 0.2,
                'region': 'body' if i == 0 else 'face' if i == 1 else 'accessory'
            })
        
        # 基础形状特征（Labubu的通用特征）
        shape_descriptor = {
            'aspect_ratio': 1.5,  # 典型的Labubu比例
            'roundness': 0.8,     # 圆润度
            'symmetry': 0.9,      # 对称性
            'complexity': 0.6,    # 复杂度
            'key_points': []
        }
        
        # 基础纹理特征
        texture_features = {
            'smoothness': 0.8,    # Labubu通常是光滑的
            'roughness': 0.2,
            'patterns': ['solid'], # 默认纯色
            'material_type': 'plush'
        }
        
        # 生成基础特征向量（基于颜色和默认形状）
        feature_vector = self.generate_basic_feature_vector(dominant_colors)
        
        return {
            'primary_colors': primary_colors,
            'color_distribution': {},
            'shape_descriptor': shape_descriptor,
            'contour_points': [],
            'texture_features': texture_features,
            'special_marks': [],
            'feature_vector': feature_vector
        }
    
    def generate_basic_feature_vector(self, colors: List[str]) -> List[float]:
        """生成基础特征向量"""
        # 10维特征向量
        vector = [0.5] * 10  # 默认值
        
        # 根据颜色调整前几维
        color_map = {
            '#FFB6C1': [0.9, 0.1, 0.7],  # 粉色
            '#87CEEB': [0.1, 0.9, 0.7],  # 蓝色
            '#FFD700': [0.9, 0.9, 0.1],  # 黄色
            '#FF0000': [1.0, 0.1, 0.1],  # 红色
            '#00FF00': [0.1, 1.0, 0.1],  # 绿色
            '#FFFFFF': [0.9, 0.9, 0.9],  # 白色
            '#000000': [0.1, 0.1, 0.1],  # 黑色
        }
        
        if colors:
            primary_color = colors[0].upper()
            if primary_color in color_map:
                color_features = color_map[primary_color]
                vector[0] = color_features[0]  # R分量
                vector[1] = color_features[1]  # G分量
                vector[2] = color_features[2]  # B分量
        
        return vector
    
    def generate_basic_tags(self, colors: List[str], rarity: str) -> List[str]:
        """生成基础标签"""
        tags = [rarity]
        
        # 添加颜色标签
        color_names = {
            '#FFB6C1': '粉色',
            '#87CEEB': '蓝色', 
            '#FFD700': '黄色',
            '#FF0000': '红色',
            '#00FF00': '绿色',
            '#FFFFFF': '白色',
            '#000000': '黑色'
        }
        
        for color in colors[:2]:  # 最多2个颜色标签
            if color.upper() in color_names:
                tags.append(color_names[color.upper()])
        
        return tags
    
    def import_basic_model(self, model_data: Dict[str, Any]) -> bool:
        """导入基础模型数据"""
        try:
            response = requests.post(
                f"{self.supabase_url}/rest/v1/labubu_models",
                headers=self.headers,
                json=model_data
            )
            
            if response.status_code in [200, 201]:
                print(f"✅ 导入基础模型: {model_data['name_cn']}")
                return True
            else:
                print(f"❌ 导入失败: {model_data['name_cn']} - {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ 导入异常: {model_data['name_cn']} - {e}")
            return False
    
    def add_additional_image(self, model_id: str, image_url: str, image_type: str = "user_photo") -> bool:
        """为已存在的模型添加额外图片"""
        try:
            # 获取现有模型数据
            response = requests.get(
                f"{self.supabase_url}/rest/v1/labubu_models?id=eq.{model_id}",
                headers=self.headers
            )
            
            if response.status_code != 200:
                print(f"❌ 获取模型失败: {response.text}")
                return False
            
            models = response.json()
            if not models:
                print(f"❌ 模型不存在: {model_id}")
                return False
            
            model = models[0]
            
            # 添加新图片
            new_image = {
                'id': str(uuid.uuid4()),
                'image_url': image_url,
                'angle': self.map_image_type(image_type),
                'is_primary': False,
                'quality_score': 0.8,
                'upload_date': datetime.now().isoformat()
            }
            
            reference_images = model.get('reference_images', [])
            reference_images.append(new_image)
            
            # 更新模型
            update_data = {
                'reference_images': reference_images,
                'updated_at': datetime.now().isoformat(),
                'data_completeness': 'enhanced'  # 标记为增强数据
            }
            
            response = requests.patch(
                f"{self.supabase_url}/rest/v1/labubu_models?id=eq.{model_id}",
                headers=self.headers,
                json=update_data
            )
            
            if response.status_code in [200, 204]:
                print(f"✅ 添加图片成功: {model.get('name_cn', 'Unknown')}")
                return True
            else:
                print(f"❌ 添加图片失败: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ 添加图片异常: {e}")
            return False
    
    def map_image_type(self, image_type: str) -> str:
        """映射图片类型"""
        mapping = {
            'official_front': 'front',
            'official_side': 'left', 
            'official_back': 'back',
            'user_photo': 'front',
            'package': 'detail',
            'detail': 'detail'
        }
        return mapping.get(image_type, 'front')
    
    def batch_import_basic_models(self, models_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        """批量导入基础模型"""
        results = {
            'success': 0,
            'failed': 0,
            'model_ids': []
        }
        
        for model_data in models_data:
            model_record = self.create_minimal_model(
                name=model_data['name'],
                name_cn=model_data['name_cn'],
                series_id=model_data['series_id'],
                primary_image_url=model_data['primary_image_url'],
                dominant_colors=model_data['dominant_colors'],
                rarity=model_data.get('rarity', 'common'),
                description=model_data.get('description')
            )
            
            if self.import_basic_model(model_record):
                results['success'] += 1
                results['model_ids'].append(model_record['id'])
            else:
                results['failed'] += 1
        
        return results

def main():
    """主函数 - 演示渐进式导入"""
    print("=== Labubu渐进式数据导入工具 ===\n")
    
    # 配置信息
    SUPABASE_URL = input("请输入Supabase URL: ").strip()
    SERVICE_ROLE_KEY = input("请输入Service Role Key: ").strip()
    
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("❌ 配置信息不完整")
        return
    
    importer = ProgressiveLabubuImporter(SUPABASE_URL, SERVICE_ROLE_KEY)
    
    # 示例：导入基础模型数据
    basic_models = [
        {
            'name': 'Classic Pink Labubu',
            'name_cn': '经典粉色Labubu',
            'series_id': 'series_001',  # 需要先创建系列
            'primary_image_url': 'https://example.com/pink_labubu.jpg',
            'dominant_colors': ['#FFB6C1', '#FFFFFF'],
            'rarity': 'common',
            'description': '最经典的粉色款式'
        },
        {
            'name': 'Classic Blue Labubu', 
            'name_cn': '经典蓝色Labubu',
            'series_id': 'series_001',
            'primary_image_url': 'https://example.com/blue_labubu.jpg',
            'dominant_colors': ['#87CEEB', '#FFFFFF'],
            'rarity': 'common',
            'description': '经典蓝色款式'
        }
    ]
    
    print("🚀 开始导入基础模型...")
    results = importer.batch_import_basic_models(basic_models)
    
    print(f"\n✅ 导入完成:")
    print(f"   成功: {results['success']}")
    print(f"   失败: {results['failed']}")
    
    # 演示：为已导入的模型添加额外图片
    if results['model_ids']:
        print(f"\n📷 演示添加额外图片...")
        model_id = results['model_ids'][0]
        importer.add_additional_image(
            model_id, 
            'https://example.com/pink_labubu_side.jpg',
            'official_side'
        )

if __name__ == "__main__":
    main() 