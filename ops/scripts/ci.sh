#!/usr/bin/env bash

set -e

SERVICE_NAME=quickstart
REGION=eu-west-3

# Get script directory
dir=$(dirname "$0")
cd "${dir}/../.."

# Get Application Version
version=$(cat VERSION)
echo "Building version ${version}..."

# Run unit tests
composer install
docker-compose -f docker-compose.test.yml up --exit-code-from test

## Build docker images
docker build --target app-stage -t 513754036198.dkr.ecr.${REGION}.amazonaws.com/${SERVICE_NAME}:${version} .
docker build --target nginx-stage -t 513754036198.dkr.ecr.${REGION}.amazonaws.com/${SERVICE_NAME}-nginx:${version} .