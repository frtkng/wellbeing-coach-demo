# Wellbeing Chat Demo

最小限の構成で ChatGPT ベースの Wellbeing コーチを試せるサーバーレスデモです。

* **Web UI**：静的サイト (HTML/CSS/JS)
* **API**：AWS Lambda + API Gateway
* **デプロイ**：CloudFormation テンプレート & シェルスクリプト
* **シークレット**：AWS Secrets Manager

---

## 🎯 目的

* ブラウザでマルチターン対話 (Web版ChatGPT風) を実現
* 追加ライブラリ不要のシンプル Lambda コード
* 1 スクリプトでインフラ＆コードを自動デプロイ

---

## 🔧 前提条件

1. AWS アカウント (CloudFormation, S3, Lambda, API Gateway, SecretsManager 権限)
2. AWS CLI v2 インストール・`aws configure` 済 (region=ap-northeast-1)
3. OpenAI API キー取得

   * [https://platform.openai.com](https://platform.openai.com) → API Keys → "Create new secret key"

---

## 🔐 OpenAI キー登録

```bash
aws secretsmanager create-secret \
  --name demo/openai \
  --description "OpenAI API key for wellbeing demo" \
  --secret-string sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## 📁 リポジトリ構成

```
wellbeing-coach-demo/
├─ README.md               # このファイル
├─ iac/
│   └─ wb-coach-demo.yml   # CloudFormation テンプレート
├─ web/
│   ├─ index.html          # チャット UI
│   └─ main.js             # multi-turn 対応 JS
└─ scripts/
    ├─ deploy.sh           # CloudFormation デプロイ + .env 出力
    └─ upload_web.sh       # S3 同期 (index.html + main.js)
```

---

## 🚀 デプロイ手順

1. **スクリプトに実行権** を付与

   ```bash
   chmod +x scripts/*.sh
   ```
2. **CloudFormation デプロイ**

   ```bash
   ./scripts/deploy.sh
   ```

   * `.env` が生成され、環境変数 `WEB_URL` と `API_URL` が書き込まれます
3. **Web UI をアップロード**

   ```bash
   ./scripts/upload_web.sh
   ```
4. **ブラウザでアクセス**

   ```bash
   source .env
   open $WEB_URL
   ```

   * メッセージ入力欄で Enter または「送信」を押下すると対話開始

---

## 🗂️ CloudFormation テンプレート

* **S3**: 静的サイトホスティングバケット
* **Secrets Manager**: `/demo/openai` に登録した OpenAI キー
* **Lambda** (`ChatLambda`): inline `ZipFile` で標準ライブラリのみのコード
* **API Gateway**: `POST /chat` + `OPTIONS /chat` (CORS)
* **Outputs**: `WebURL`, `ChatAPI`

---

## 💡 Lambda コード (inline)

```yaml
# iac/wb-coach-demo.yml 内の ChatLambda Code 部分
Code:
  ZipFile: |
    import os, json, urllib.request, urllib.error
    def lambda_handler(event, context):
        body = json.loads(event.get("body","{}"))
        messages = body.get("messages", [])
        if not messages:
            messages = [{"role":"system","content":"あなたは優しい健康コーチです。80文字以内の日本語で答えて。"}]
        payload = json.dumps({"model":"gpt-4o-mini","messages":messages}).encode()
        req = urllib.request.Request(
            "https://api.openai.com/v1/chat/completions",
            data=payload,
            headers={
                "Content-Type":"application/json",
                "Authorization":f"Bearer {os.environ['OPENAI_KEY']}"
            }
        )
        try:
            with urllib.request.urlopen(req, timeout=15) as res:
                result = json.loads(res.read().decode())
        except urllib.error.HTTPError as e:
            return {"statusCode":502,"headers":{"Access-Control-Allow-Origin":"*"},"body":json.dumps({"error":e.read().decode()})}
        reply = result["choices"][0]["message"]["content"]
        return {"statusCode":200,"headers":{"Access-Control-Allow-Origin":"*"},"body":json.dumps({"reply":reply})}
```

---

## 💻 Web UI (web/index.html)

```html
<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8" />
  <title>Wellbeing Chat Demo</title>
  <style>
    body { font-family: sans-serif; max-width: 600px; margin: auto; padding: 1rem; }
    #chat-log { height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: .5rem; margin-bottom: .5rem; }
    .user   { text-align: right; margin: .25rem; }
    .assistant { text-align: left; margin: .25rem; }
    .system { text-align: center; color: #888; margin: .25rem; }
    #prompt { width: calc(100% - 80px); padding: .5rem; }
    #send   { width: 60px; padding: .5rem; }
  </style>
</head>
<body>
  <h1>Wellbeing Chat Demo</h1>
  <div id="chat-log"></div>
  <div>
    <input id="prompt" type="text" placeholder="メッセージを入力…" />
    <button id="send">送信</button>
  </div>
  <script src="main.js"></script>
</body>
</html>
```

---

## 🚦 フロントエンド (web/main.js)

```js
document.addEventListener('DOMContentLoaded', () => {
  source .env が読み込まれる upload_web.sh で<API_URL>を置換
  const API = '<API_URL>';

  const systemPrompt = "あなたは優しい健康コーチです。80文字以内の日本語で答えて。";
  let messages = [{ role: 'system', content: systemPrompt }];

  const logEl = document.getElementById('chat-log');
  const inputEl = document.getElementById('prompt');

  function renderChat() {
    logEl.innerHTML = messages.map(m => {
      const cls = m.role;
      const icon = m.role === 'user' ? '👤' : m.role === 'assistant' ? '🤖' : '⚙️';
      return `<div class="${cls}">${icon} ${m.content}</div>`;
    }).join('');
    logEl.scrollTop = logEl.scrollHeight;
  }

  async function send() {
    const text = inputEl.value.trim(); if (!text) return;
    messages.push({ role: 'user', content: text }); renderChat(); inputEl.value = '';
    const resp = await fetch(API, {
      method:'POST', headers:{'Content-Type':'application/json'},
      body: JSON.stringify({ messages })
    });
    const { reply } = await resp.json();
    messages.push({ role:'assistant', content:reply }); renderChat();
  }

  document.getElementById('send').addEventListener('click', send);
  inputEl.addEventListener('keypress', e => e.key==='Enter' && send());
  renderChat();
});
```

---

## 🔄 デプロイスクリプト

### scripts/deploy.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
STACK_NAME="wb-demo"
TEMPLATE_FILE="iac/wb-coach-demo.yml"
AWS_REGION="ap-northeast-1"
ENV="demo"

echo "👉 Deploying stack ${STACK_NAME}..."
aws cloudformation deploy \
  --template-file "${TEMPLATE_FILE}" \
  --stack-name "${STACK_NAME}" \
  --region "${AWS_REGION}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides Env=${ENV} DeployTime=$(date +%Y%m%d%H%M%S)

echo "👉 Exporting outputs to .env..."
aws cloudformation describe-stacks --stack-name "${STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='WebURL'||OutputKey=='ChatAPI'].[OutputKey,OutputValue]" \
  --output text | while read KEY VALUE; do
    case "$KEY" in
      WebURL)  echo "WEB_URL=${VALUE}" ;;  
      ChatAPI) echo "API_URL=${VALUE}" ;;  
    esac
done > .env

echo "✅ Deployed. WEB_URL=$(grep WEB_URL .env) API_URL=$(grep API_URL .env)"
```

### scripts/upload\_web.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
source .env
BUCKET=$(echo "$WEB_URL" | sed -E 's#http://(.*)\.s3-website.*#\1#')
sed -i.bak "s#<API_URL>#$API_URL#g" web/main.js
aws s3 sync web/ s3://$BUCKET/ --exclude "*" --include "index.html" --include "main.js"
mv web/main.js.bak web/main.js
echo "Web files uploaded to $WEB_URL"
```

