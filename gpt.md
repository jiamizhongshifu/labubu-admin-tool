使用 Bash 脚本调用 Tu-Zi 的 OpenAI 协议对话接口生成图片
目标
通过一个简单的 Bash 脚本，使用 curl 请求调用 Tu-Zi 的 OpenAI 协议对话接口，将输入的图片按照指定的风格（例如动画风格）进行重绘，并将生成的图片下载到本地。

流程简介
准备工作：
获取 Tu-Zi 的 API Token。
准备一张需要转化的图片（支持 .jpg 或 .png 格式）。
确保本地环境支持 Bash 和 curl 命令。
脚本执行步骤：
检查输入的图片文件是否存在且格式正确。
将图片转换为 Base64 编码。
提示用户输入描述生成图片的提示词（prompt）。
构造 JSON 请求数据，使用 curl 调用 Tu-Zi 的对话接口 /v1/chat/completions。
从 API 返回的流式响应中提取任务 ID，等待任务完成（通过检查 stop 标志）。
从响应中提取生成的图片 URL，并下载图片到本地 output 目录。
输出：
生成的图片将保存到 output 目录，文件名为 generated_image_时间戳.jpg。
准备工作
获取 API Token：
登录 Tu-Zi API Token 页面 创建一个 API Token。
复制生成的 API Token（格式为 sk-xxxx），在脚本中替换 API_KEY 的值。
API 信息：
API 基础地址：https://api.tu-zi.com/v1
对话请求地址：https://api.tu-zi.com/v1/chat/completions
支持的模型（按需选择）：
gpt-4o-all：按 token 计费，价格便宜，用户较多。
gpt-4o-image：按次计费，价格便宜，用户较少。
gpt-4o-image-vip：按次计费，价格较高，用户最少。
本脚本默认使用 gpt-4o-image-vip 模型。
环境要求：
确保系统支持 Bash 脚本运行。
确保已安装 curl 命令。
确保有权限在脚本运行目录下创建 output 文件夹。
Bash 脚本实现
以下是完整的 Bash 脚本，用于调用 Tu-Zi 的对话接口生成图片：

#!/bin/bash

# 前置检查和变量定义
IMAGE_FILE="$1"
OUTPUT_DIR="output"
API_URL="https://api.tu-zi.com/v1/chat/completions"
API_KEY="Bearer sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
TEMP_JSON="/tmp/request.json"
RESPONSE_FILE="/tmp/response_stream.txt"

# 检查参数和文件
if [ $# -ne 1 ] || [ ! -f "$IMAGE_FILE" ] || [[ ! "$IMAGE_FILE" =~ \.(jpg|png)$ ]]; then
    echo "用法: $0 <图片文件>"
    exit 1
fi

[ ! -d "$OUTPUT_DIR" ] && mkdir "$OUTPUT_DIR"

# 转换图片为 base64
BASE64_IMAGE=$(base64 < "$IMAGE_FILE" | tr -d '\n')

# 获取用户输入的 prompt
echo "请输入你的 prompt："
read PROMPT
[ -z "$PROMPT" ] && { echo "错误: prompt 不能为空"; exit 1; }

# 构造 JSON 数据
JSON_DATA=$(cat <<EOF
{
    "model": "gpt-4o-image-vip",
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "$PROMPT"
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": "data:image/jpeg;base64,$BASE64_IMAGE"
                    }
                }
            ]
        }
    ],
    "n_tokens": 3000,
    "stream": true
}
EOF
)

echo "$JSON_DATA" > "$TEMP_JSON"

# 实时处理流式响应并保存到文件
echo "正在调用 API 提交任务..."
curl -s -H "Authorization: $API_KEY" \
     -H "Content-Type: application/json" \
     -d "@$TEMP_JSON" \
     --no-buffer \
     "$API_URL" | tee "$RESPONSE_FILE" | while read -r line; do
    # 显示当前行，便于监控
    echo "$line"

    # 检查 finish_reason
    FINISH_REASON=$(echo "$line" | grep -o '"finish_reason":"[^"]*"' | sed 's/"finish_reason":"//;s/"//')
    if [ "$FINISH_REASON" = "stop" ]; then
        echo "任务已完成！(finish_reason: $FINISH_REASON)"
        break
    elif [ -n "$FINISH_REASON" ] && [ "$FINISH_REASON" != "null" ]; then
        echo "任务异常结束！(finish_reason: $FINISH_REASON)"
        exit 1
    fi

    # 显示进度
    PROGRESS=$(echo "$line" | grep -o '> 进度 [0-9]*%' | grep -o '[0-9]*')
    [ -n "$PROGRESS" ] && echo "任务进度: $PROGRESS%"
done

# 检查是否成功退出循环
if [ $? -ne 0 ]; then
    echo "错误: API 调用失败或未检测到结束标志"
    cat "$RESPONSE_FILE"
    rm -f "$TEMP_JSON" "$RESPONSE_FILE"
    exit 1
fi

# 从完整响应中提取图像 URL
echo "正在提取图像 URL..."
IMAGE_URL=$(grep -o '!\[.*\](https://[^)]*)' "$RESPONSE_FILE" | sed 's/.*(//;s/)//')
if [ -z "$IMAGE_URL" ]; then
    echo "错误: 无法提取图像 URL"
    cat "$RESPONSE_FILE"
    rm -f "$TEMP_JSON" "$RESPONSE_FILE"
    exit 1
fi
echo "图像 URL: $IMAGE_URL"

# 下载图片
TIMESTAMP=$(date +%Y%m%d%H%M%S)
OUTPUT_FILE="$OUTPUT_DIR/generated_image_$TIMESTAMP.jpg"
echo "正在下载图片到 $OUTPUT_FILE..."
curl -s -o "$OUTPUT_FILE" "$IMAGE_URL"
[ $? -eq 0 ] && echo "图片已成功下载到 $OUTPUT_FILE" || echo "错误: 图片下载失败"

# 清理
rm -f "$TEMP_JSON" "$RESPONSE_FILE"
exit 0
脚本使用方法
1. 保存脚本
将上述代码保存为 sub.sh 文件。
2. 赋予执行权限
在终端运行以下命令，为脚本添加执行权限：
chmod +x sub.sh
3. 准备输入图片
准备一张需要转化的图片（例如 plot.png），并将其放置在脚本所在的目录。
4. 替换 API Token
打开 sub.sh 文件，将 API_KEY 的值替换为你在 Tu-Zi 平台获取的 API Token：
API_KEY="Bearer 你的API Token"
5. 运行脚本
在终端运行脚本，并提供图片文件名作为参数：
./sub.sh plot.png
脚本会提示你输入 prompt，例如：
请输入你的 prompt（描述你想要生成的图片内容）：
输入描述，例如：
把它转化为动画的风格
脚本会提交任务，等待任务完成，并将生成的图片下载到 output 目录。
6. 查看结果
如果成功，脚本会输出类似以下信息：
图片已成功下载到 output/generated_image_20250330123456.jpg
打开 output 目录，查看生成的图片。
示例：生成吉卜力风格图片
假设你有一张图片 plot.png，希望将其转化为吉卜力动画风格：

将图片放置在脚本目录下。
运行脚本：
./sub.sh plot.png
输入 prompt：
请将这张图片转化为吉卜力动画风格
等待任务完成，生成的图片会保存在 output 目录中。
总结
本脚本通过 Bash 和 curl 实现了对 Tu-Zi API 的调用，支持将图片转化为指定风格（例如动画风格）。