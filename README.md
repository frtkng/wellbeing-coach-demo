# Wellbeing Chat Demo

最小限の構成で ChatGPT ベースの Wellbeing コーチを試せるサーバーレスデモです。

静的 Web UI + AWS Lambda (Python 標準ライブラリ利用) + API Gateway + Secrets Manager だけで動作します。

---

## 🎯 目的

* Web ブラウザ上で気軽に質問→ChatGPT 応答を実現
* 完全サーバレス（S3 + Lambda + API Gateway）
* 外部ライブラリに依存しないシンプルなコード構成

---

## 🔧 前提条件

1. **AWS アカウント** 取得済（必要な IAM 権限: CloudFormation, S3, Lambda, API Gateway, SecretsManager）
2. **AWS CLI v2** インストール・設定済 (`aws configure` で Access Key / Secret Key / region=ap-northeast-1 / output=json)
3. **OpenAI API キー** を取得

   * [https://platform.openai.com](https://platform.openai.com) → API Keys → "Create new secret key"
   * 表示された `sk-...` を控える

---

## 🔐 OpenAI キーを Secrets Manager に登録

```bash
aws secretsmanager create-secret \
  --name demo/openai \
  --description "OpenAI API key for wellbeing demo" \
  --secret-string sk-XXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

* 成功すると ARN が返ります（以降は名前 `demo/openai` で参照）

---

## 📁 リポジトリ構成

```bash
town wellbeing-demo/
├─ README.md              # このファイル
├─ iac/                   # CloudFormation テンプレート
│   └─ demo-wellbeing.yml
├─ web/                   # 静的 Web UI
│   ├─ index.html
│   └─ main.js
└─ scripts/               # デプロイ補助スクリプト
    ├─ deploy.sh          # CloudFormation デプロイ
    ├─ upload_web.sh      # Web UI を S3 へ sync
    └─ delete_stack.sh    # スタック削除
```

---

## 🚀 デプロイ手順

1. **スクリプトに実行権を付与**

   ```bash
   chmod +x scripts/*.sh
   ```

2. **CloudFormation をデプロイ**

   ```bash
   ./scripts/deploy.sh
   ```

   * 完了後、自動で `.env` が生成・更新されます。
   * `.env` 内の `WEB_URL`, `API_URL` を利用します。

3. **Web UI をアップロード**

   ```bash
   ./scripts/upload_web.sh
   ```

4. **動作確認**

   ```bash
   source .env
   open $WEB_URL
   ```

   * メッセージ欄にテキストを入力すると、ChatGPT の応答が返ります。

---

## 🗂️ CloudFormation テンプレート概要 (iac/demo-wellbeing.yml)

* **静的サイトバケット (S3)**

  * ホスティング用バケット + パブリック読み取りポリシー

* **Lambda Role**

  * 基本実行権限のみ（CloudWatch Logs 出力）

* **ChatLambda**

  * Python 3.11 ランタイム
  * Handler: `index.lambda_handler` (標準ライブラリのみ)
  * 環境変数 `OPENAI_KEY` を Secrets Manager (`demo/openai`) から参照
  * コードはインラインではなく S3 バンドルを利用

* **API Gateway**

  * `POST /chat` (AWS\_PROXY)
  * `OPTIONS /chat` (CORS 用 MOCK)

* **Outputs**

  * `WebURL` (S3 Website URL)
  * `ChatAPI` (API Gateway エンドポイント)

---

## 💡 Lambda コードサンプル

```python
import os, json, urllib.request

def lambda_handler(event, context):
    body = json.loads(event.get("body","{}"))
    msg = body.get("message", "")
    system = "あなたは優しい健康コーチです。80文字以内の日本語で答えて。"

    payload = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": msg}
        ]
    }).encode("utf-8")

    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {os.environ['OPENAI_KEY']}"
        }
    )

    with urllib.request.urlopen(req, timeout=10) as res:
        result = json.loads(res.read().decode())

    reply = result["choices"][0]["message"]["content"]

    return {
        "statusCode": 200,
        "headers": {"Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"reply": reply})
    }
```

---

## 🔄 スクリプト説明

### scripts/deploy.sh

* CloudFormation デプロイ & `.env` 生成

### scripts/upload\_web.sh

* Web UI の `main.js` に `API_URL` を埋め込み
* S3 へ `index.html`/`main.js` を sync

### scripts/delete\_stack.sh

* スタック削除

---

## ⚙️ 動作フロー

1. Web UI から `POST $API_URL` を実行
2. API Gateway → Lambda → OpenAI 呼び出し
3. 応答を返却
4. Web UI に表示

---

これで他のチームメンバーも **1 リポジトリ + 3 コマンド** で再現可能です！
