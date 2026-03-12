#!/bin/bash
set -e

echo "Cloning policy repo"

git clone https://$BITBUCKET_USER:$BITBUCKET_TOKEN@bitbucket.org/org/policies.git

cd policies

echo "Formatting policies"
opa fmt -w .

echo "Running tests"
opa test .

echo "Building bundle"
opa build -b . -o bundle.tar.gz

echo "Uploading bundle to Azure Blob"

az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name opa-bundles \
  --name prod/bundle.tar.gz \
  --file bundle.tar.gz \
  --auth-mode login

echo "Bundle uploaded successfully"
