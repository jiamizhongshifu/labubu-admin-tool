#!/bin/bash

# Labubu CoreML模型添加脚本
# 使用方法: ./add_models.sh /path/to/your/models/

set -e

echo "🚀 Labubu CoreML模型添加脚本"
echo "================================"

# 检查参数
if [ $# -eq 0 ]; then
    echo "❌ 错误: 请提供模型文件目录路径"
    echo "使用方法: ./add_models.sh /path/to/your/models/"
    exit 1
fi

MODEL_SOURCE_DIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📁 源模型目录: $MODEL_SOURCE_DIR"
echo "📁 项目目录: $PROJECT_DIR"

# 检查源目录是否存在
if [ ! -d "$MODEL_SOURCE_DIR" ]; then
    echo "❌ 错误: 源目录不存在: $MODEL_SOURCE_DIR"
    exit 1
fi

# 需要的模型文件
REQUIRED_MODELS=(
    "LabubuQuickClassifier.mlmodel"
    "LabubuFeatureExtractor.mlmodel"
    "LabubuAdvancedClassifier.mlmodel"
)

echo ""
echo "🔍 检查模型文件..."

# 检查所有必需的模型文件是否存在
for model in "${REQUIRED_MODELS[@]}"; do
    if [ -f "$MODEL_SOURCE_DIR/$model" ]; then
        echo "✅ 找到: $model"
    else
        echo "❌ 缺失: $model"
        echo "请确保以下文件存在于源目录中:"
        for req_model in "${REQUIRED_MODELS[@]}"; do
            echo "  - $req_model"
        done
        exit 1
    fi
done

echo ""
echo "📋 模型文件信息:"
for model in "${REQUIRED_MODELS[@]}"; do
    if [ -f "$MODEL_SOURCE_DIR/$model" ]; then
        size=$(du -h "$MODEL_SOURCE_DIR/$model" | cut -f1)
        echo "  $model: $size"
    fi
done

echo ""
echo "📦 复制模型文件到项目..."

# 复制模型文件到MLModels目录
for model in "${REQUIRED_MODELS[@]}"; do
    echo "📄 复制 $model..."
    cp "$MODEL_SOURCE_DIR/$model" "$SCRIPT_DIR/"
    echo "✅ 已复制: $model"
done

echo ""
echo "🎯 下一步操作:"
echo "1. 在Xcode中打开项目"
echo "2. 右键点击 'jitata' 项目根目录"
echo "3. 选择 'Add Files to \"jitata\"'"
echo "4. 选择 MLModels 文件夹中的所有 .mlmodel 文件"
echo "5. 确保 'Add to target' 勾选了 'jitata'"
echo "6. 点击 'Add'"
echo ""
echo "🔄 重新编译并运行应用，查看控制台输出:"
echo "✅ 成功从Bundle加载模型: LabubuQuickClassifier"
echo "✅ 成功从Bundle加载模型: LabubuFeatureExtractor"
echo "✅ 成功从Bundle加载模型: LabubuAdvancedClassifier"
echo ""
echo "🎉 模型文件添加完成！" 