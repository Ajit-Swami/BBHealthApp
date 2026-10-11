#!/usr/bin/env bash
# =================================================================================================
# Subtask 1: Bootstrap S3 Backend & DynamoDB State Lock Table (Bash)
# Region: us-west-2
# =================================================================================================

set -e

REGION="us-west-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if [ -z "$ACCOUNT_ID" ]; then
  echo "Error: Failed to retrieve AWS Account ID. Please verify your AWS credentials."
  exit 1
fi

BUCKET_NAME="bbhealthapp-terraform-state-${ACCOUNT_ID}-${REGION}"
LOCK_TABLE="bbhealthapp-terraform-locks"

echo "=========================================================="
echo "Bootstrapping Terraform Remote Backend in AWS ($REGION)"
echo "AWS Account ID : $ACCOUNT_ID"
echo "S3 Bucket Name : $BUCKET_NAME"
echo "DynamoDB Table : $LOCK_TABLE"
echo "=========================================================="

# 1. Create S3 Bucket (us-west-2 requires LocationConstraint)
echo "Creating S3 bucket: $BUCKET_NAME..."
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION" || true

# 2. Enable Bucket Versioning
echo "Enabling bucket versioning..."
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# 3. Enable Server-Side Encryption (AES256)
echo "Enabling server-side encryption..."
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# 4. Block Public Access
echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Create DynamoDB Table for State Locking
echo "Creating DynamoDB table: $LOCK_TABLE..."
aws dynamodb create-table \
  --table-name "$LOCK_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" || true

echo "=========================================================="
echo "S3 Backend Setup Complete!"
echo "Now update provider.tf with:"
echo "  backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"eks/terraform.tfstate\""
echo "    region         = \"$REGION\""
echo "    dynamodb_table = \"$LOCK_TABLE\""
echo "    encrypt        = true"
echo "  }"
echo "Then run: terraform init -migrate-state"
echo "=========================================================="
