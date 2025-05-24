import os, json, urllib.request, urllib.error, urllib.parse

def lambda_handler(event, context):
    # リクエストボディからメッセージを取得
    body = json.loads(event.get("body", "{}"))
    msg  = body.get("message", "")

    # system プロンプト
    system = "あなたは優しい健康コーチです。80文字以内の日本語で答えて。"

    # OpenAI Chat API 呼び出しペイロード
    payload = json.dumps({
        "model": "gpt-4o-mini",
        "messages": [
            {"role": "system", "content": system},
            {"role": "user",   "content": msg}
        ]
    }).encode("utf-8")

    # HTTP リクエスト
    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=payload,
        headers={
            "Content-Type":  "application/json",
            "Authorization": f"Bearer {os.environ['OPENAI_KEY']}"
        },
        method="POST"
    )

    try:
        with urllib.request.urlopen(req, timeout=10) as res:
            result = json.loads(res.read().decode())
    except urllib.error.HTTPError as e:
        # OpenAI 側のエラーをそのまま返す
        return {
            "statusCode": 502,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": e.read().decode()})
        }

    # 応答抽出
    reply = result["choices"][0]["message"]["content"]

    return {
        "statusCode": 200,
        "headers": {"Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"reply": reply})
    }
