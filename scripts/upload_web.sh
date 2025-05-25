#!/usr/bin/env bash
set -euo pipefail

# .env から WEB_URL と API_URL を読み込む
source .env

# S3 バケット名だけ抽出 (例: wb-demo-site-123456789012)
BUCKET=$(echo "$WEB_URL" | sed -E 's#http://(.*)\.s3-website.*#\1#')

# main.js 中の <API_URL> を置換
sed -i.bak "s#<API_URL>#$API_URL#g" web/main.js

# index.html と main.js だけアップロード
aws s3 sync web/ s3://$BUCKET/ \
  --exclude "*" --include "index.html" --include "main.js"

# バックアップファイルを元に戻す
mv web/main.js.bak web/main.js

echo "Web files uploaded to $WEB_URL"
