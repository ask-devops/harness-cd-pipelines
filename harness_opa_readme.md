# Harness-NG + OPA Policy Check Example

This guide shows how to integrate **Open Policy Agent (OPA)** into a **Harness-NG pipeline** using a **Python script** and a **custom step template** to allow or block deployments.

---

## 1. Prerequisites

- Harness-NG account with pipeline access  
- Harness delegate installed (for running scripts)  
- Python 3 installed on the delegate  
- OPA installed locally or on a server: https://www.openpolicyagent.org/docs/latest/#1-install-opa

---

## 2. Create OPA Policy

Create a file `deployment_policy.rego`:

```rego
package harness.deployment

default allow = false

# Allow deployment only if not production and CPU/Memory limits are within range
allow {
    input.namespace != "production"
    input.cpu <= 8
    input.memory <= 16384
}
```

Start OPA server:

```bash
opa run --server --set=decision_logs.console=true deployment_policy.rego
```

> Default URL: `http://localhost:8181/v1/data/harness/deployment`  
> Replace `localhost` with your OPA server IP if remote.

---

## 3. Create Python Script

Create `opa_check.py` on the Harness delegate:

```python
import requests
import os
import sys

# OPA endpoint
OPA_URL = os.getenv("OPA_URL", "http://localhost:8181/v1/data/harness/deployment")

# Collect data from Harness environment variables
data = {
    "input": {
        "namespace": os.getenv("NAMESPACE", "dev"),
        "image": os.getenv("IMAGE", "myapp:v1.0"),
        "cpu": int(os.getenv("CPU", 2)),
        "memory": int(os.getenv("MEMORY", 2048))
    }
}

# Send request to OPA
response = requests.post(OPA_URL, json=data)

# Check result
if response.status_code == 200 and response.json().get("result", {}).get("allow"):
    print("✅ Deployment allowed by OPA policy")
    sys.exit(0)  # Success
else:
    print("❌ Deployment denied by OPA policy")
    sys.exit(1)  # Fail Harness step
```

---

## 4. Create Harness Step Template

1. Go to **Templates → Step Templates → New Template**  
2. Fill in:

- **Name:** `OPA Policy Check`  
- **Identifier:** `opa_policy_check`  
- **Type:** `Shell Script`  
- **Script:**

```bash
python3 opa_check.py
```

- **Environment Variables Mapping:**

| Name      | Value |
|-----------|-------|
| NAMESPACE | `<+pipeline.variables.namespace>` |
| IMAGE     | `<+service.variables.image>` |
| CPU       | `<+resources.cpu>` |
| MEMORY    | `<+resources.memory>` |
| OPA_URL   | `http://<OPA_SERVER>:8181/v1/data/harness/deployment` |

> Replace `<OPA_SERVER>` with your OPA host/IP if not local.

---

## 5. Add Step Template to Pipeline

1. Open your pipeline.  
2. Add a **Step → Use Template → OPA Policy Check**  
3. Map any pipeline/service variables.  
4. Place it **before deployment steps**.  
5. Pipeline will automatically **fail if OPA denies deployment**.

---

## 6. How It Works

```
[Harness Pipeline Start]
        │
        ▼
[OPA Policy Check Step Template]
        │
  ✅ allowed? ── No ──> [Step fails, pipeline stops]
        │
       Yes
        │
        ▼
[Deployment Step(s)]
        │
        ▼
[Pipeline Complete]
```

- Harness sends pipeline variables to Python script  
- Python script sends JSON to OPA URL  
- OPA evaluates policy and returns `allow: true/false`  
- Harness step succeeds or fails based on the response

---

## 7. Example JSON Sent to OPA

```json
{
  "input": {
    "namespace": "dev",
    "image": "myapp:v1.2.3",
    "cpu": 4,
    "memory": 8192
  }
}
```

---

## 8. Notes

- You can extend the OPA policy with more rules (branches, image tags, labels).  
- Use Harness **pipeline variables** to dynamically pass environment-specific data.  
- Python script acts as a **bridge** between Harness and OPA.

---

## ✅ Done

You now have a fully functional **Harness + OPA + Python** integration that **blocks or allows deployments** bas