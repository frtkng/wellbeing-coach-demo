#!/usr/bin/env bash
set -euo pipefail
source .env          # WEB_URL, API_URL を読み込み
BUCKET=$(echo $WEB_URL | sed -E 's#http://(.*)\.s3-website.*#\1#')
# main.js の API プレースホルダを書き換え (ローカルのみ)
sed -i.bak "s#<置換後URL>#$API_URL#" web/main.js
aws s3 sync web/ s3://$BUCKET/ \
  --exclude "*" --include "index.html" --include "main.js"
mv web/main.js.bak web/main.js   # 元に戻す
echo "Web files uploaded to $WEB_URL"
