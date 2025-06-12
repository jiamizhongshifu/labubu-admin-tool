#!/usr/bin/env python3
"""
Labubu数据验证脚本
验证导入到Supabase的数据是否完整和正确
"""

import requests
import json
from typing import Dict, List, Any

class LabubuDataVerifier:
    def __init__(self, supabase_url: str, service_role_key: str):
        self.supabase_url = supabase_url.rstrip('/')
        self.headers = {
            'apikey': service_role_key,
            'Authorization': f'Bearer {service_role_key}',
            'Content-Type': 'application/json'
        }
    
    def verify_series(self) -> Dict[str, Any]:
        """验证系列数据"""
        try:
            response = requests.get(
                f"{self.supabase_url}/rest/v1/labubu_series",
                headers=self.headers
            )
            
            if response.status_code == 200:
                series_data = response.json()
                return {
                    'success': True,
                    'count': len(series_data),
                    'data': series_data
                }
            else:
                return {
                    'success': False,
                    'error': f"HTTP {response.status_code}: {response.text}"
                }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def verify_models(self) -> Dict[str, Any]:
        """验证模型数据"""
        try:
            response = requests.get(
                f"{self.supabase_url}/rest/v1/labubu_models",
                headers=self.headers
            )
            
            if response.status_code == 200:
                models_data = response.json()
                return {
                    'success': True,
                    'count': len(models_data),
                    'data': models_data
                }
            else:
                return {
                    'success': False,
                    'error': f"HTTP {response.status_code}: {response.text}"
                }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def check_data_integrity(self, series_result: Dict, models_result: Dict) -> List[str]:
        """检查数据完整性"""
        issues = []
        
        if not series_result['success'] or not models_result['success']:
            issues.append("❌ 数据获取失败")
            return issues
        
        series_data = series_result['data']
        models_data = models_result['data']
        
        # 检查系列数据
        series_ids = set()
        for series in series_data:
            series_ids.add(series['id'])
            
            # 检查必需字段
            required_fields = ['name', 'name_en', 'description', 'release_year']
            for field in required_fields:
                if not series.get(field):
                    issues.append(f"⚠️ 系列 {series.get('name', 'Unknown')} 缺少字段: {field}")
        
        # 检查模型数据
        for model in models_data:
            # 检查系列关联
            if model.get('series_id') not in series_ids:
                issues.append(f"⚠️ 模型 {model.get('name', 'Unknown')} 的系列ID不存在")
            
            # 检查必需字段
            required_fields = ['name', 'name_cn', 'rarity', 'visual_features']
            for field in required_fields:
                if not model.get(field):
                    issues.append(f"⚠️ 模型 {model.get('name', 'Unknown')} 缺少字段: {field}")
            
            # 检查参考图片
            ref_images = model.get('reference_images', [])
            if len(ref_images) == 0:
                issues.append(f"⚠️ 模型 {model.get('name', 'Unknown')} 没有参考图片")
            
            # 检查视觉特征
            visual_features = model.get('visual_features', {})
            if not visual_features.get('feature_vector'):
                issues.append(f"⚠️ 模型 {model.get('name', 'Unknown')} 缺少特征向量")
        
        return issues
    
    def generate_report(self) -> str:
        """生成验证报告"""
        print("🔍 开始验证Labubu数据...")
        
        # 验证系列
        print("📚 验证系列数据...")
        series_result = self.verify_series()
        
        # 验证模型
        print("🎭 验证模型数据...")
        models_result = self.verify_models()
        
        # 检查完整性
        print("🔧 检查数据完整性...")
        issues = self.check_data_integrity(series_result, models_result)
        
        # 生成报告
        report = "=== Labubu数据验证报告 ===\n\n"
        
        # 基本统计
        if series_result['success']:
            report += f"✅ 系列数量: {series_result['count']}\n"
        else:
            report += f"❌ 系列数据获取失败: {series_result['error']}\n"
        
        if models_result['success']:
            report += f"✅ 模型数量: {models_result['count']}\n"
        else:
            report += f"❌ 模型数据获取失败: {models_result['error']}\n"
        
        report += "\n"
        
        # 数据质量问题
        if issues:
            report += "⚠️ 发现的问题:\n"
            for issue in issues:
                report += f"   {issue}\n"
        else:
            report += "✅ 数据完整性检查通过，未发现问题\n"
        
        report += "\n"
        
        # 详细统计
        if models_result['success']:
            models_data = models_result['data']
            
            # 按稀有度统计
            rarity_stats = {}
            for model in models_data:
                rarity = model.get('rarity', 'unknown')
                rarity_stats[rarity] = rarity_stats.get(rarity, 0) + 1
            
            report += "📊 稀有度分布:\n"
            for rarity, count in rarity_stats.items():
                report += f"   {rarity}: {count}\n"
            
            # 按系列统计
            series_stats = {}
            for model in models_data:
                series_id = model.get('series_id', 'unknown')
                series_stats[series_id] = series_stats.get(series_id, 0) + 1
            
            report += "\n📊 系列分布:\n"
            for series_id, count in series_stats.items():
                # 查找系列名称
                series_name = series_id
                if series_result['success']:
                    for series in series_result['data']:
                        if series['id'] == series_id:
                            series_name = series.get('name', series_id)
                            break
                report += f"   {series_name}: {count}\n"
        
        return report

def main():
    """主函数"""
    print("=== Labubu数据验证工具 ===\n")
    
    # 配置信息
    SUPABASE_URL = input("请输入Supabase URL: ").strip()
    SERVICE_ROLE_KEY = input("请输入Service Role Key: ").strip()
    
    if not SUPABASE_URL or not SERVICE_ROLE_KEY:
        print("❌ 配置信息不完整，请重新运行脚本")
        return
    
    # 创建验证器并生成报告
    verifier = LabubuDataVerifier(SUPABASE_URL, SERVICE_ROLE_KEY)
    report = verifier.generate_report()
    
    print("\n" + report)
    
    # 保存报告到文件
    with open('labubu_verification_report.txt', 'w', encoding='utf-8') as f:
        f.write(report)
    
    print("📄 验证报告已保存到: labubu_verification_report.txt")

if __name__ == "__main__":
    main() 