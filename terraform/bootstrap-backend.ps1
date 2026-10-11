# =================================================================================================
# Subtask 1: Bootstrap S3 Backend & DynamoDB State Lock Table
# Region: us-west-2
# =================================================================================================

$ErrorActionPreference = "Stop"

$Region = "us-west-2"
$AccountId = (aws sts get-caller-identity --query "Account" --output text).Trim()

if (-not $AccountId) {
    Write-Error "Failed to retrieve AWS Account ID. Please verify your AWS credentials with 'aws configure'."
    exit 1
}

$BucketName = "bbhealthapp-terraform-state-$AccountId-$Region"
$LockTableName = "bbhealthapp-terraform-locks"

Write-Host "=========================================================="
Write-Host "Bootstrapping Terraform Remote Backend in AWS ($Region)"
Write-Host "AWS Account ID : $AccountId"
Write-Host "S3 Bucket Name : $BucketName"
Write-Host "DynamoDB Table : $LockTableName"
Write-Host "=========================================================="

# 1. Create S3 Bucket (us-west-2 requires LocationConstraint)
Write-Host "Creating S3 bucket: $BucketName..."
try {
    aws s3api create-bucket `
        --bucket $BucketName `
        --region $Region `
        --create-bucket-configuration LocationConstraint=$Region
    Write-Host "Bucket created successfully."
} catch {
    Write-Host "Bucket may already exist or error occurred: $_"
}

# 2. Enable Bucket Versioning (Best practice to prevent state loss)
Write-Host "Enabling bucket versioning..."
aws s3api put-bucket-versioning `
    --bucket $BucketName `
    --versioning-configuration Status=Enabled

# 3. Enable Server-Side Encryption (AES256)
Write-Host "Enabling server-side encryption..."
aws s3api put-bucket-encryption `
    --bucket $BucketName `
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

# 4. Block Public Access
Write-Host "Blocking public access on S3 bucket..."
aws s3api put-public-access-block `
    --bucket $BucketName `
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# 5. Create DynamoDB Table for State Locking
Write-Host "Creating DynamoDB table: $LockTableName..."
try {
    aws dynamodb create-table `
        --table-name $LockTableName `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $Region
    Write-Host "DynamoDB table created."
} catch {
    Write-Host "DynamoDB table may already exist: $_"
}

Write-Host "=========================================================="
Write-Host "S3 Backend Setup Complete!"
Write-Host "Now update provider.tf with:"
Write-Host "  backend ""s3"" {"
Write-Host "    bucket         = ""$BucketName"""
Write-Host "    key            = ""eks/terraform.tfstate"""
Write-Host "    region         = ""$Region"""
Write-Host "    dynamodb_table = ""$LockTableName"""
Write-Host "    encrypt        = true"
Write-Host "  }"
Write-Host "Then run: terraform init -migrate-state"
Write-Host "=========================================================="
