kling图生视频 API使用文档

本文档介绍了如何使用 Kling API 进行图生视频和获取任务（视频）状态的操作。

认证
所有 API 请求都需要在 Header 中添加 Authorization 参数。其值为 Bearer 之后拼接您的 API Token。

示例：
Authorization: Bearer YOUR_API_TOKEN

API 端点
1. 图生视频 (Image to Video)
此端点用于根据输入的图像和提示词生成视频。

HTTP 方法: POST
URL: https://api.tu-zi.com/kling/v1/videos/image2video
请求参数
Header 参数

参数名	类型	是否必需	描述	示例值
Authorization	string	是	API 授权凭证 (Bearer Token)	Bearer YOUR_API_TOKEN
Content-Type	string	是	请求体格式，固定为 application/json	application/json
Body 参数 (application/json)

参数名	类型	是否必需	描述	示例值
model_name	string	是	模型名称	"kling-v1"、"kling-v2"等
mode	string	是	生成模式	"pro"
prompt	string	是	视频内容的描述性提示词	"宇航员站起身走了"
aspect_ratio	string	是	视频宽高比 (注意：此参数在您的Python脚本中未体现，但文档中标记为必需)	(例如 "16:9", "1:1")
duration	integer	是	视频时长 (单位：秒)	5
negative_prompt	string	是	反向提示词，描述不希望在视频中出现的内容 (注意：此参数在您的Python脚本中未体现，但文档中标记为必需)	(例如 "模糊, 低质量")
cfg_scale	number	是	CFG (Classifier-Free Guidance) 强度，控制提示词与视频内容的符合程度	0.5
image	string	是	输入图像的 URL	"https://h2.inkwai.com/bs2/upload-ylab-stunt/se/ai_portal_queue_mmu_image_upscale_aiweb/3214b798-e1b4-4b00-b7af-72b5b0417420_raw_image_0.jpg"
static_mask	string	否	静态蒙版图像的 URL (可选参数，根据您的Python脚本推断)	"https://h2.inkwai.com/bs2/upload-ylab-stunt/ai_portal/1732888177/cOLNrShrSO/static_mask.png"
dynamic_masks	array	否	动态蒙版数组，包含蒙版图像URL和轨迹 (可选参数，根据您的Python脚本推断)	[ { "mask": "mask_url", "trajectories": [{"x":279,"y":219},{"x":417,"y":65}] } ]
Python 示例 (requests 库)
import requests
import json

# 替换为您的 API Token
api_token = "YOUR_API_TOKEN"
url = 'https://api.tu-zi.com/kling/v1/videos/image2video'
headers = {
    'Authorization': f'Bearer {api_token}',
    'Content-Type': 'application/json'
}

# 注意：请根据 API 文档补齐 aspect_ratio 和 negative_prompt 参数
data = {
    "model_name": "kling-v1",
    "mode": "pro",
    "duration": 5, # 文档中为 integer，示例中为 "5" (string)，此处统一为 integer
    "image": "https://h2.inkwai.com/bs2/upload-ylab-stunt/se/ai_portal_queue_mmu_image_upscale_aiweb/3214b798-e1b4-4b00-b7af-72b5b0417420_raw_image_0.jpg",
    "prompt": "宇航员站起身走了",
    "cfg_scale": 0.5,
    # "aspect_ratio": "16:9", # 根据需要取消注释并设置
    # "negative_prompt": "模糊, 低质量", # 根据需要取消注释并设置
    "static_mask": "https://h2.inkwai.com/bs2/upload-ylab-stunt/ai_portal/1732888177/cOLNrShrSO/static_mask.png", # 可选
    "dynamic_masks": [ # 可选
      {
        "mask": "https://h2.inkwai.com/bs2/upload-ylab-stunt/ai_portal/1732888130/WU8spl23dA/dynamic_mask_1.png",
        "trajectories": [
          {"x":279,"y":219},{"x":417,"y":65}
        ]
      }
    ]
}

response = requests.post(url, headers=headers, data=json.dumps(data))

print(f"Status Code: {response.status_code}")
print("Response JSON:")
try:
    print(response.json())
except json.JSONDecodeError:
    print(response.text)
预期响应：

请求成功后，API 会返回一个 JSON 对象，其中通常包含任务 ID (task_id)，用于后续查询视频生成状态。

2. 获取任务（视频） (Get Task/Video Status)
此端点用于根据任务 ID 获取视频生成的状态或结果。

HTTP 方法: GET
URL: https://api.tu-zi.com/kling/v1/videos/image2video/{task_id}
请求参数
Header 参数

参数名	类型	是否必需	描述	示例值
Authorization	string	是	API 授权凭证 (Bearer Token)	Bearer YOUR_API_TOKEN
Path 参数

参数名	类型	是否必需	描述
task_id	string	是	要查询的任务 ID。
Python 示例 (http.client 库)
import http.client
import json # 用于更好地打印JSON响应

# 替换为您的 API Token
api_token = "YOUR_API_TOKEN"
# 替换为您的任务 ID
task_id = "Cl6kH2gHPegAAAAACQhRzQ" # 这是一个示例 ID

conn = http.client.HTTPSConnection("api.tu-zi.com")
payload = '' # GET 请求通常没有 payload
headers = {
    'Authorization': f'Bearer {api_token}'
}

conn.request("GET", f"/kling/v1/videos/image2video/{task_id}", payload, headers)
res = conn.getresponse()
data = res.read()

print(f"Status Code: {res.status}")
print("Response Data:")
try:
    # 尝试将响应解析为JSON并格式化打印
    response_json = json.loads(data.decode("utf-8"))
    print(json.dumps(response_json, indent=4, ensure_ascii=False))
except json.JSONDecodeError:
    print(data.decode("utf-8"))
except UnicodeDecodeError:
    print(data) # 如果解码失败，直接打印原始数据

conn.close()
预期响应：

请求成功后，API 会返回一个 JSON 对象，其中包含任务的状态信息（例如：处理中、已完成、失败）以及可能的视频链接或其他结果。