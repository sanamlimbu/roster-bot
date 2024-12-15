#!/bin/bash

# Build Go binary 'bootstrap' file inside 'terraform/tf_generated' directory

set -e

export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=0
export GOFLAGS=-trimpath

echo "Deleting 'bootstrap' binary..."
rm -rf ./bootstrap
echo "Deleted 'bootstrap' binary."

echo "Building 'bootstrap' binary..."
go build -tags lambda.norpc -mod=readonly -ldflags="-s -w" -o ./bootstrap ./main.go ./roster.go
echo "Built 'bootstrap' binary."