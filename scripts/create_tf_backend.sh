#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <bucket-name> <region> <dynamodb-table>"
  exit 1
fi
BUCKET="$1"
REGION="$2"
TABLE="$3"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" || true
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled || true
aws dynamodb create-table --table-name "$TABLE" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region "$REGION" || true
echo "Backend ensured: s3://$BUCKET and dynamodb table $TABLE in $REGION"
