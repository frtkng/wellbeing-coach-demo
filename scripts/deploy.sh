#!/usr/bin/env bash
set -euo pipefail
STACK=wb-demo
TEMPLATE=iac/wb-coach-demo.yml
 aws cloudformation deploy \
  --template-file $TEMPLATE \
  --stack-name $STACK \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    Env=demo \
    DeployTime=$(date +%Y%m%d%H%M%S)
# 出力 URL を .env に保存 (フロントから参照)
WEB=$(aws cloudformation describe-stacks --stack-name $STACK \
       --query "Stacks[0].Outputs[?OutputKey=='WebURL'].OutputValue" --out text)
API=$(aws cloudformation describe-stacks --stack-name $STACK \
       --query "Stacks[0].Outputs[?OutputKey=='ChatAPI'].OutputValue" --out text)
echo "WEB_URL=$WEB" > .env
echo "API_URL=$API" >> .env
echo "CloudFormation stack deployed. Web: $WEB"
