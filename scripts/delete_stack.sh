#!/usr/bin/env bash
set -euo pipefail
aws cloudformation delete-stack --stack-name wb-demo
echo "Stack deletion initiated."
