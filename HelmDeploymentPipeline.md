# Helm Deployment Pipeline

This repository contains a Harness pipeline that automates the deployment of an application to multiple environments (Dev, QA, and Prod) using Helm. The pipeline fetches the Helm chart and environment-specific `values.yaml` files from a Bitbucket repository and deploys them to the respective environments.

## Pipeline Overview

The pipeline consists of three stages:
1. **Dev Stage**: Deploys to the Dev environment using Helm.
2. **QA Stage**: Deploys to the QA environment using Helm.
3. **Prod Stage**: Deploys to the Prod environment using Helm.

Each stage checks out the appropriate Helm chart and environment-specific `values.yaml` files from Bitbucket and uses them for deployment.

---

## Pipeline YAML Example

Below is an example of the Harness pipeline YAML configuration:

```yaml
pipeline:
  name: "Helm Deployment Pipeline"
  identifier: "helm_deployment_pipeline"
  projectIdentifier: "Your_Project"
  orgIdentifier: "Your_Org"
  stages:
    - stage:
        name: "Dev"
        identifier: "dev"
        type: "Deployment"
        spec:
          execution:
            steps:
              - step:
                  name: "Checkout Helm Chart and Dev Values"
                  identifier: "checkout_dev_chart"
                  type: "GitClone"
                  spec:
                    connectorRef: "bitbucket-connector"  # Bitbucket connector reference
                    repository: "your-bitbucket-repo"    # Bitbucket repo URL
                    branch: "dev"  # Branch for Dev environment
                    gitFetchType: "Branch"
                    folderPath: "/helm-charts"  # Path to the Helm charts in Bitbucket repo

              - step:
                  name: "Deploy to Dev"
                  identifier: "deploy_dev"
                  type: "HelmDeploy"
                  spec:
                    chartName: "your-helm-chart"  # Helm chart name
                    releaseName: "dev-release"
                    valuesFile: "/helm-charts/dev/values.yaml"  # Values file specific to Dev
                    namespace: "dev-namespace"
                    connectorRef: "helm-connector"  # Helm connector reference
                    target: "helm"

    - stage:
        name: "QA"
        identifier: "qa"
        type: "Deployment"
        spec:
          execution:
            steps:
              - step:
                  name: "Checkout Helm Chart and QA Values"
                  identifier: "checkout_qa_chart"
                  type: "GitClone"
                  spec:
                    connectorRef: "bitbucket-connector"  # Bitbucket connector reference
                    repository: "your-bitbucket-repo"    # Bitbucket repo URL
                    branch: "qa"  # Branch for QA environment
                    gitFetchType: "Branch"
                    folderPath: "/helm-charts"  # Path to the Helm charts in Bitbucket repo

              - step:
                  name: "Deploy to QA"
                  identifier: "deploy_qa"
                  type: "HelmDeploy"
                  spec:
                    chartName: "your-helm-chart"  # Helm chart name
                    releaseName: "qa-release"
                    valuesFile: "/helm-charts/qa/values.yaml"  # Values file specific to QA
                    namespace: "qa-namespace"
                    connectorRef: "helm-connector"  # Helm connector reference
                    target: "helm"

    - stage:
        name: "Prod"
        identifier: "prod"
        type: "Deployment"
        spec:
          execution:
            steps:
              - step:
                  name: "Checkout Helm Chart and Prod Values"
                  identifier: "checkout_prod_chart"
                  type: "GitClone"
                  spec:
                    connectorRef: "bitbucket-connector"  # Bitbucket connector reference
                    repository: "your-bitbucket-repo"    # Bitbucket repo URL
                    branch: "prod"  # Branch for Prod environment
                    gitFetchType: "Branch"
                    folderPath: "/helm-charts"  # Path to the Helm charts in Bitbucket repo

              - step:
                  name: "Deploy to Prod"
                  identifier: "deploy_prod"
                  type: "HelmDeploy"
                  spec:
                    chartName: "your-helm-chart"  # Helm chart name
                    releaseName: "prod-release"
                    valuesFile: "/helm-charts/prod/values.yaml"  # Values file specific to Prod
                    namespace: "prod-namespace"
                    connectorRef: "helm-connector"  # Helm connector reference
                    target: "helm"
