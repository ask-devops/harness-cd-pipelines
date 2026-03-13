#!/bin/bash
set -e

echo "Formatting policies..."
opa fmt -w policies

echo "Testing policies..."
opa test policies

echo "Building bundle..."
opa build -b policies -o bundle.tar.gz

echo "Login to Azure..."
az login --identity || true

echo "Uploading bundle to Blob..."
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name opa-bundles \
  --name bundle.tar.gz \
  --file bundle.tar.gz \
  --auth-mode login \
  --overwrite

echo "Bundle uploaded."
