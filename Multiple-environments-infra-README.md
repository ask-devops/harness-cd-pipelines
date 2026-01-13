# Harness NG – Managing Environments, Infrastructure & Deployments (YAML-First)

This guide explains a **scalable, production-ready approach** to managing **growing environments** in **Harness NextGen (NG)** using **YAML + Git**.

---

## Core Principles
1. One pipeline → many environments  
2. No environment or client logic in pipelines  
3. Infrastructure always belongs to an Environment  
4. Secrets never live in Git or InputSets  
5. Everything is YAML and Git-backed  

---

## Recommended Repo Structure

```
harness/
├── environments/
│   ├── client1-dev.yaml
│   ├── client1-prod.yaml
│   ├── client2-dev.yaml
│   └── client2-prod.yaml
├── infrastructures/
│   ├── client1-dev-k8s.yaml
│   ├── client1-prod-k8s.yaml
│   └── client2-prod-k8s.yaml
├── inputsets/
│   ├── client1-dev.yaml
│   ├── client1-prod.yaml
│   └── client2-prod.yaml
```

---

## Environment ↔ Infrastructure Relationship

Pipeline  
→ Environment (logical context)  
→ Infrastructure (physical target)

Infrastructure is explicitly linked to Environment using `environmentRef`.

---

## Environment YAML Example

```
environment:
  name: client1-dev
  identifier: client1_dev
  orgIdentifier: default
  projectIdentifier: myproject
  type: PreProduction

  variables:
    - name: CLIENT
      type: String
      value: client1
    - name: STAGE
      type: String
      value: dev
```

---

## Infrastructure YAML Example

```
infrastructureDefinition:
  name: client1-dev-k8s
  identifier: client1_dev_k8s
  orgIdentifier: default
  projectIdentifier: myproject

  environmentRef: client1_dev
  deploymentType: Kubernetes

  spec:
    connectorRef: eks_dev
    namespace: client1-dev
    releaseName: client1-dev
```

---

## InputSet YAML Example

```
inputSet:
  name: client1-dev
  identifier: client1_dev
  orgIdentifier: default
  projectIdentifier: myproject

  pipeline:
    identifier: deploy_app
    environment:
      environmentRef: client1_dev
      infrastructureDefinitions:
        - identifier: client1_dev_k8s
```

---

## Pipeline Requirement

```
environment:
  environmentRef: <+input>
  infrastructureDefinitions:
    - identifier: <+input>
```

---

## Secrets Management

Secrets live only in Harness Secret Manager.

Example:
```
client1.db_password
```

Usage:
```
<+secrets.getValue("<+pipeline.variables.CLIENT>.db_password")>
```

---

## How Deployment Works

1. YAMLs synced into Harness
2. Objects created (env / infra / inputset)
3. Pipeline triggered
4. InputSet selected
5. Harness resolves everything and deploys

---

## Adding a New Environment

1. Copy environment YAML
2. Copy infrastructure YAML
3. Create InputSet YAML
4. Commit & merge
5. Deploy

No pipeline change required.

---

## Final Target State

1 pipeline  
N environments  
N infrastructures  
N inputsets  

Harness = execution engine  
Git = source of truth  
