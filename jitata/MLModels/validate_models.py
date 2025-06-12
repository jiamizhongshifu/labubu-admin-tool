#!/usr/bin/env python3
"""
Labubu CoreML模型验证脚本
验证模型是否符合应用要求的规格
"""

import os
import sys
import coremltools as ct
from pathlib import Path

def validate_model(model_path, expected_specs):
    """验证单个模型文件"""
    print(f"\n🔍 验证模型: {model_path.name}")
    
    if not model_path.exists():
        print(f"❌ 文件不存在: {model_path}")
        return False
    
    try:
        # 加载模型
        model = ct.models.MLModel(str(model_path))
        spec = model.get_spec()
        
        # 检查文件大小
        file_size = model_path.stat().st_size / (1024 * 1024)  # MB
        print(f"📦 文件大小: {file_size:.2f} MB")
        
        if file_size > expected_specs.get('max_size_mb', 50):
            print(f"⚠️  文件大小超过建议值 {expected_specs.get('max_size_mb', 50)} MB")
        
        # 检查输入规格
        print("📥 输入规格:")
        for input_name, input_spec in spec.description.input:
            if input_spec.type.WhichOneof('Type') == 'imageType':
                image_spec = input_spec.type.imageType
                print(f"  - {input_name}: 图像 {image_spec.width}x{image_spec.height}")
                
                # 验证输入尺寸
                if image_spec.width != 224 or image_spec.height != 224:
                    print(f"❌ 输入尺寸错误，期望 224x224，实际 {image_spec.width}x{image_spec.height}")
                    return False
                else:
                    print("✅ 输入尺寸正确 (224x224)")
            else:
                print(f"  - {input_name}: {input_spec.type}")
        
        # 检查输出规格
        print("📤 输出规格:")
        for output_name, output_spec in spec.description.output:
            print(f"  - {output_name}: {output_spec.type}")
        
        # 检查模型类型
        model_type = spec.WhichOneof('Type')
        print(f"🧠 模型类型: {model_type}")
        
        # 特定模型验证
        model_name = model_path.stem
        if model_name == "LabubuQuickClassifier":
            return validate_quick_classifier(spec)
        elif model_name == "LabubuFeatureExtractor":
            return validate_feature_extractor(spec)
        elif model_name == "LabubuAdvancedClassifier":
            return validate_advanced_classifier(spec)
        
        return True
        
    except Exception as e:
        print(f"❌ 模型加载失败: {e}")
        return False

def validate_quick_classifier(spec):
    """验证快速分类器"""
    print("🎯 验证快速分类器规格...")
    
    # 检查输出是否为二分类
    outputs = list(spec.description.output)
    if len(outputs) != 1:
        print(f"❌ 输出数量错误，期望1个，实际{len(outputs)}个")
        return False
    
    output_name, output_spec = outputs[0]
    if output_spec.type.WhichOneof('Type') == 'dictionaryType':
        print("✅ 输出类型正确 (分类概率)")
    else:
        print(f"❌ 输出类型错误，期望分类概率，实际{output_spec.type}")
        return False
    
    return True

def validate_feature_extractor(spec):
    """验证特征提取器"""
    print("🎯 验证特征提取器规格...")
    
    # 检查输出是否为特征向量
    outputs = list(spec.description.output)
    if len(outputs) != 1:
        print(f"❌ 输出数量错误，期望1个，实际{len(outputs)}个")
        return False
    
    output_name, output_spec = outputs[0]
    if output_spec.type.WhichOneof('Type') == 'multiArrayType':
        array_spec = output_spec.type.multiArrayType
        shape = list(array_spec.shape)
        print(f"✅ 输出特征向量维度: {shape}")
        
        # 检查特征向量维度
        if len(shape) == 1 and shape[0] >= 256:
            print("✅ 特征向量维度合适")
        else:
            print(f"⚠️  特征向量维度可能不够: {shape}")
    else:
        print(f"❌ 输出类型错误，期望多维数组，实际{output_spec.type}")
        return False
    
    return True

def validate_advanced_classifier(spec):
    """验证高级分类器"""
    print("🎯 验证高级分类器规格...")
    
    # 检查输出是否为多分类
    outputs = list(spec.description.output)
    if len(outputs) < 1:
        print(f"❌ 输出数量错误，期望至少1个，实际{len(outputs)}个")
        return False
    
    # 通常有两个输出：类别标签和概率
    for output_name, output_spec in outputs:
        output_type = output_spec.type.WhichOneof('Type')
        print(f"  - {output_name}: {output_type}")
    
    print("✅ 高级分类器格式正确")
    return True

def main():
    """主函数"""
    print("🚀 Labubu CoreML模型验证脚本")
    print("=" * 40)
    
    # 检查coremltools是否安装
    try:
        import coremltools
        print(f"📦 CoreML Tools版本: {coremltools.__version__}")
    except ImportError:
        print("❌ 错误: 请先安装coremltools")
        print("pip install coremltools")
        sys.exit(1)
    
    # 获取模型目录
    if len(sys.argv) > 1:
        model_dir = Path(sys.argv[1])
    else:
        model_dir = Path(__file__).parent
    
    print(f"📁 模型目录: {model_dir}")
    
    # 定义期望的模型规格
    model_specs = {
        "LabubuQuickClassifier": {
            "max_size_mb": 2,
            "description": "快速二分类模型"
        },
        "LabubuFeatureExtractor": {
            "max_size_mb": 10,
            "description": "特征提取模型"
        },
        "LabubuAdvancedClassifier": {
            "max_size_mb": 20,
            "description": "高级分类模型"
        }
    }
    
    all_valid = True
    
    # 验证每个模型
    for model_name, specs in model_specs.items():
        model_path = model_dir / f"{model_name}.mlmodel"
        print(f"\n{'='*50}")
        print(f"📋 {specs['description']}: {model_name}")
        
        is_valid = validate_model(model_path, specs)
        if is_valid:
            print(f"✅ {model_name} 验证通过")
        else:
            print(f"❌ {model_name} 验证失败")
            all_valid = False
    
    print(f"\n{'='*50}")
    if all_valid:
        print("🎉 所有模型验证通过！")
        print("\n📋 下一步:")
        print("1. 使用 add_models.sh 脚本将模型添加到Xcode项目")
        print("2. 重新编译并运行应用")
        print("3. 查看控制台确认模型加载成功")
    else:
        print("❌ 部分模型验证失败，请检查模型格式")
        sys.exit(1)

if __name__ == "__main__":
    main() 