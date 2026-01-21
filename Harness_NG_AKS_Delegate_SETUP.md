# Harness NG Delegate Setup for AKS (Azure Kubernetes Service)

This guide explains how to set up a **Harness NG Delegate** in an **AKS cluster** for deploying applications via Harness CD pipelines.

---

## 1. Architecture Overview

```
                 +----------------+
                 | Harness SaaS   |
                 +----------------+
                        |
                 (HTTPS 443 Outbound)
                        |
                        v
                +-------------------+
                | Harness Delegate  |
                |  (Pod in AKS)     |
                +-------------------+
                        |
          +-------------+-------------+
          |                           |
  +---------------+             +---------------+
  | Target AKS    |             | Other AKS     |
  | Namespace /   |             | Clusters      |
  | Pods / Services|            |               |
  +---------------+             +---------------+
```

**Key Points:**

- Delegate runs as a Pod inside AKS (Deployment/DaemonSet)
- Outbound HTTPS to Harness SaaS only
- Interacts with Kubernetes API to deploy resources
- Uses RBAC via a ServiceAccount

---

## 2. Prerequisites

- AKS cluster (any supported version)
- kubectl installed locally
- Helm (optional for delegate deployment)
- Harness SaaS account
- Outbound internet access for the cluster (443)

---

## 3. Delegate Setup in AKS

### 3.1 Create ServiceAccount with RBAC

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: harness-delegate
  namespace: harness
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: harness-delegate-role
rules:
  - apiGroups: ["", "apps", "batch", "extensions"]
    resources: ["pods", "deployments", "services", "configmaps", "jobs"]
    verbs: ["get", "list", "create", "update", "delete", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: harness-delegate-binding
subjects:
  - kind: ServiceAccount
    name: harness-delegate
    namespace: harness
roleRef:
  kind: ClusterRole
  name: harness-delegate-role
  apiGroup: rbac.authorization.k8s.io
```

Apply:
```bash
kubectl apply -f harness-delegate-rbac.yaml
```

---

### 3.2 Deploy Delegate Pod

```bash
kubectl create namespace harness

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: harness-delegate
  namespace: harness
spec:
  replicas: 1
  selector:
    matchLabels:
      app: harness-delegate
  template:
    metadata:
      labels:
        app: harness-delegate
    spec:
      serviceAccountName: harness-delegate
      containers:
      - name: harness-delegate
        image: harness/delegate:latest
        env:
        - name: ACCOUNT_ID
          value: "<YOUR_ACCOUNT_ID>"
        - name: DELEGATE_TOKEN
          value: "<YOUR_DELEGATE_TOKEN>"
        - name: DELEGATE_NAME
          value: "aks-delegate"
        - name: DELEGATE_TAGS
          value: "aks,cluster,prod"
        - name: MANAGER_HOST
          value: "https://app.harness.io"
EOF
```

Verify:
```bash
kubectl get pods -n harness
```

The delegate pod should be **Running** and connected in Harness UI.

---

## 4. Harness Connector Setup

- Create **Kubernetes Connector** in Harness:
  - Type: **Kubernetes Cluster**
  - Authentication: **Service Account** (use namespace/harness token)
  - Delegate Selector: `aks,cluster`
- Test connection → should succeed

---

## 5. CD Pipeline Example

- **Step 1:** Deploy to target namespace
- **Step 2:** Apply manifests / Helm chart
- **Step 3:** Monitor rollout status

**kubectl example:**
```bash
kubectl apply -f deployment.yaml -n target-namespace
kubectl rollout status deployment/myapp -n target-namespace
```

---

## 6. Security Best Practices

- Delegate runs **outbound only**, no public IP needed
- Use **private clusters** if possible
- Limit ServiceAccount RBAC to necessary resources
- Use Harness Secrets Manager for sensitive credentials

---

## 7. References

- [Harness Kubernetes Delegate Docs](https://docs.harness.io/article/delegates)
- [AKS RBAC Overview](https://learn.microsoft.com/en-us/azure/aks/kubernetes-rbac)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
