# OPA Control Plane (OCP) -- Overview and Implementation

This document explains the role of an **OPA Control Plane (OCP)** and
how to build and distribute policy bundles using Azure Blob Storage and
Docker.

------------------------------------------------------------------------

# 1. What is the OPA Control Plane (OCP)

The **OPA Control Plane** is the component responsible for managing
policy lifecycle and distributing policies to OPA agents.

OPA agents run in services and evaluate policies locally.\
The control plane ensures that those agents receive the correct policy
bundles.

Typical architecture:

Git Repository (Bitbucket / GitHub) \| v OCP Control Plane \| \| opa fmt
\| opa test \| opa build v Policy Bundle (bundle.tar.gz) \| v Azure Blob
Storage \| v OPA Agents (run --server) Automatically download bundles

------------------------------------------------------------------------

# 2. Main Roles of the OCP

## 1. Policy Collection

Pull policies from the source repository.

Example: - Bitbucket - GitHub

## 2. Policy Validation

Before publishing policies, validation is performed:

    opa fmt
    opa test
    opa check

This ensures policies are syntactically correct and pass tests.

## 3. Policy Bundling

Policies are packaged into a bundle:

    opa build -b policies -o bundle.tar.gz

The bundle contains:

-   Rego policy files
-   Data files
-   Manifest

## 4. Bundle Distribution

Bundles are uploaded to a shared storage location.

Example:

Azure Blob Storage

OPA agents retrieve bundles from this location.

## 5. Versioning and Rollback

Bundles can be versioned:

bundle-v1.tar.gz\
bundle-v2.tar.gz\
bundle-v3.tar.gz

This allows rollback to previous policies.

## 6. Environment Segmentation

Separate bundles for environments:

/dev/bundle.tar.gz\
/stage/bundle.tar.gz\
/prod/bundle.tar.gz

Each environment loads its own policies.

------------------------------------------------------------------------

# 3. Bundle Build Script (build.sh)

Example script used by the control plane.

``` bash
#!/bin/bash
set -e

echo "Formatting policies"
opa fmt -w policies

echo "Testing policies"
opa test policies

echo "Building bundle"
opa build -b policies -o bundle.tar.gz

echo "Login to Azure"

az login --identity || true

echo "Uploading bundle to Blob"

az storage blob upload   --account-name $STORAGE_ACCOUNT   --container-name opa-bundles   --name bundle.tar.gz   --file bundle.tar.gz   --auth-mode login   --overwrite

echo "Bundle uploaded"
```

------------------------------------------------------------------------

# 4. Explanation of `az login --identity || true`

    az login --identity

Attempts to authenticate using **Azure Managed Identity**.

This only works inside Azure environments such as:

-   Azure Container Apps
-   Azure VM
-   AKS

The part:

    || true

means:

If login fails, continue execution.

This allows the same script to run in:

-   Docker (local testing)
-   Azure cloud environments

Example behavior:

Docker → Managed Identity not available → login fails → script continues

Azure Container Apps → Managed Identity exists → login succeeds

------------------------------------------------------------------------

# 5. OPA Agent Configuration

OPA agents download bundles using configuration.

Example config.yaml:

``` yaml
services:
  blob:
    url: https://<storage-account>.blob.core.windows.net

bundles:
  policies:
    service: blob
    resource: opa-bundles/bundle.tar.gz
    polling:
      min_delay_seconds: 30
      max_delay_seconds: 60
```

This means:

-   OPA polls Blob storage
-   Downloads updated bundles automatically
-   Reloads policies without restart

------------------------------------------------------------------------

# 6. Recommended Development Flow

Developer updates policy \| v Git commit (Bitbucket) \| v Control Plane
builds bundle \| v Upload to Blob Storage \| v OPA Agents automatically
reload policy

------------------------------------------------------------------------

# 7. Minimal OCP Responsibilities

In a minimal implementation the OCP performs:

1.  Pull policies from Git
2.  Validate policies
3.  Build policy bundles
4.  Upload bundles to storage
5.  Allow OPA agents to download bundles

------------------------------------------------------------------------

# 8. Typical Enterprise Architecture

Authoring Layer Developers writing policies

Control Plane Bundle creation and validation

Data Plane OPA agents enforcing policy

------------------------------------------------------------------------

# 9. Optional Improvements

Later improvements can include:

-   CI pipelines for automatic bundling
-   Policy approval workflows
-   Decision logging
-   Monitoring of OPA agents
-   Multi-environment bundle promotion

------------------------------------------------------------------------

# Summary

The OPA Control Plane manages policy lifecycle and distribution while
OPA agents enforce those policies in applications.

Control Plane responsibilities:

-   Policy validation
-   Policy bundling
-   Bundle distribution
-   Version control
-   Environment management

OPA agents then retrieve bundles and enforce policies locally.

