#!/bin/bash
set -e

echo "Cloning policy repository..."

git clone https://x-token-auth:${BITBUCKET_TOKEN}@bitbucket.org/${BITBUCKET_REPO}.git policies

cd policies

echo "Formatting policies"
opa fmt -w .

echo "Testing policies"
opa test .

echo "Building bundle"
opa build -b . -o bundle.tar.gz

echo "Uploading bundle to Azure Blob"

az login --identity || true

az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name $BLOB_CONTAINER \
  --name bundle.tar.gz \
  --file bundle.tar.gz \
  --auth-mode login \
  --overwrite

echo "Bundle upload complete"
