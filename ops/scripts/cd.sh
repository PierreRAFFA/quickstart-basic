#!/usr/bin/env bash

set -e

# This comes from `deployer` user
# Generate an Access Key from this user above to use this script and set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
if [ -z ${AWS_ACCESS_KEY_ID} ]; then echo "Please set AWS_ACCESS_KEY_ID" && exit 1; fi
if [ -z ${AWS_SECRET_ACCESS_KEY} ]; then echo "Please set AWS_SECRET_ACCESS_KEY" && exit 1; fi

SERVICE_NAME=quickstart
BUCKET=bark-pr-test
REGION=eu-west-3
ENVIRONMENT=production

# Get script directory
dir=$(dirname "$0")
cd "${dir}/../.."

# Get Application Version
version=$(cat VERSION)
echo "Deploying version ${version}..."

# Update infrastructure
cd ops/infrastructure

rm -rf .terraform
terraform init \
    -backend-config="key=infrastructure/${SERVICE_NAME}/${REGION}.terraform.tfstate" \
    -backend-config="bucket=${BUCKET}" \
    -backend-config="region=${REGION}"

terraform validate

terraform plan \
        -out terraform.plan \
        -var="region=${REGION}" \
        -var="environment=${ENVIRONMENT}" \
        -var="service_name=${SERVICE_NAME}" \
        -var="service_version=${version}"

terraform apply terraform.plan

## Login to ECR (using aws-cli/2.x)
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin 513754036198.dkr.ecr.${REGION}.amazonaws.com

## Push app to ECR
docker push 513754036198.dkr.ecr.${REGION}.amazonaws.com/${SERVICE_NAME}:${version}

## Push nginx to ECR
docker push 513754036198.dkr.ecr.${REGION}.amazonaws.com/${SERVICE_NAME}-nginx:${version}

### Redeploy Service
aws ecs update-service --region ${REGION} --cluster bark-${ENVIRONMENT} --service ${SERVICE_NAME}