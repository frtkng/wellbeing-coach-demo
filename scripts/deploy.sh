#!/usr/bin/env bash
set -euo pipefail

# ─── 設定 ─────────────────────────────────
STACK_NAME="wb-demo"
TEMPLATE_FILE="iac/wb-coach-demo.yml"   # インライン ZipFile 部分を含むテンプレ
AWS_REGION="ap-northeast-1"
ENV="demo"

# ─── デプロイ ───────────────────────────────
echo "👉 Deploying CloudFormation stack ${STACK_NAME}..."
aws cloudformation deploy \
  --template-file "${TEMPLATE_FILE}" \
  --stack-name "${STACK_NAME}" \
  --region "${AWS_REGION}" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      Env=${ENV} \
      DeployTime=$(date +%Y%m%d%H%M%S)

# ─── .env 出力 ───────────────────────────────
echo "👉 Exporting outputs to .env..."
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" \
  --query "Stacks[0].Outputs[?OutputKey=='WebURL'||OutputKey=='ChatAPI'].[OutputKey,OutputValue]" \
  --output text | \
while read KEY VALUE; do
  case "$KEY" in
    WebURL)   echo "WEB_URL=${VALUE}" ;;
    ChatAPI)  echo "API_URL=${VALUE}" ;;
  esac
done > .env

echo "✅ Deployment complete."
echo "   WEB_URL=$(. .env && echo \$WEB_URL)"
echo "   API_URL=$(. .env && echo \$API_URL)"
