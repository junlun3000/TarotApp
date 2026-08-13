# AI 解读后端（Cloudflare Worker）

代理转发请求到 Anthropic API，这样 Flutter App 里不需要直接放 API key。

## 部署步骤

1. **注册 Cloudflare 账号**（如果还没有）：https://dash.cloudflare.com/sign-up ，免费即可。

2. **登录 Cloudflare**（在这个 `worker/` 目录下执行）：
   ```
   npx wrangler login
   ```
   会打开浏览器，登录/授权后关掉浏览器窗口即可，终端会显示登录成功。

3. **拿到 Anthropic API key**（注意跟 Claude Pro 订阅是两回事）：
   - 打开 https://console.anthropic.com （不是 claude.ai）
   - 注册/登录开发者账号，绑定支付方式（按 token 用量计费）
   - 在 "API Keys" 页面生成一个新 key（长这样：`sk-ant-...`）

4. **把 key 安全地存进 Cloudflare**（不会写进代码/git）：
   ```
   npx wrangler secret put ANTHROPIC_API_KEY
   ```
   会提示你粘贴 key，粘贴后回车即可。

5. **部署**：
   ```
   npx wrangler deploy
   ```
   部署成功后会打印出一个 `https://tarot-ai-reading.<你的账号>.workers.dev` 这样的 URL——
   把这个 URL 填进 Flutter 项目的 `lib/data/ai_reading_service.dart` 里的
   `_workerUrl` 常量。

## 本地测试（不部署，先跑在本机）

```
npx wrangler dev
```
会在本地起一个开发服务器（通常是 `http://localhost:8787`），可以先拿 curl 测试：

```
curl -X POST http://localhost:8787 \
  -H "Content-Type: application/json" \
  -d '{"spreadName":"下一步","question":"我该怎么办？","cards":[{"nameZh":"愚人","positionLabel":"现状","orientation":"upright","keywords":["新开始","冒险"]}]}'
```

## 接口说明

`POST /`

请求体：
```json
{
  "question": "我该如何决定？（可选）",
  "background": "占卜者的背景/近况，可选，帮 AI 判断问题领域",
  "spreadName": "下一步",
  "cards": [
    { "nameZh": "愚人", "positionLabel": "现状", "orientation": "upright", "keywords": ["新开始", "冒险"] }
  ]
}
```

响应：
```json
{ "reading": "AI 生成的解读文字……" }
```

出错时返回非 200 状态码 + `{ "error": "..." }`。
