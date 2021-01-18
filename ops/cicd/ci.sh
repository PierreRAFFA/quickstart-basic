#!/usr/bin/env bash

set -e

SERVICE_NAME=quickstart

# Get script directory
dir=$(dirname "$0")
cd "${dir}/../.."

# Get Application Version
version=$(cat VERSION)
echo "Building version ${version}..."

# Run unit tests
docker-compose -f docker-compose.test.yml up --exit-code-from test