# GitHub App JSON Pipeline Example

This project contains:

1. **Python scripts** to push and read JSON using a GitHub App
2. **Bash/Cygwin scripts** to do the same
3. **Harness pipeline YAML example**
4. **README.md** with setup instructions

---

## Folder Structure
```
github_app_pipeline/
 ├── push_json.py        # Python script to push JSON
 ├── read_json.py        # Python script to read JSON
 ├── push_json.sh        # Bash/Cygwin script to push JSON
 ├── read_json.sh        # Bash/Cygwin script to read JSON
 ├── mydata.json         # Sample JSON
 ├── pipeline.yaml       # Harness pipeline example
 └── README.md           # Setup and usage guide
```

---

## 1️⃣ Python Scripts

### push_json.py
```python
import os, jwt, time, requests, json, base64

APP_ID = os.environ['GITHUB_APP_ID']
INSTALLATION_ID = os.environ['GITHUB_APP_INSTALLATION_ID']
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/pipeline_report.json"

private_key = os.environ['GITHUB_APP_PRIVATE_KEY']

# JWT
payload = {"iat": int(time.time()), "exp": int(time.time()) + 600, "iss": APP_ID}
jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

# Installation token
url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
installation_token = requests.post(url, headers=headers).json()["token"]

# JSON to upload
data = {"stage": "push", "status": "success", "timestamp": int(time.time())}
json_data = json.dumps(data, indent=2)
encoded = base64.b64encode(json_data.encode()).decode()

# Check if file exists
url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {"Authorization": f"token {installation_token}", "Accept": "application/vnd.github+json"}
r = requests.get(url, headers=headers)

if r.status_code == 200:
    sha = r.json()["sha"]
    payload = {"message": "Update pipeline report", "content": encoded, "sha": sha}
else:
    payload = {"message": "Add pipeline report", "content": encoded}

# Upload JSON
r = requests.put(url, headers=headers, json=payload)
print(r.json())
```

### read_json.py
```python
import os, jwt, time, requests, json, base64

APP_ID = os.environ['GITHUB_APP_ID']
INSTALLATION_ID = os.environ['GITHUB_APP_INSTALLATION_ID']
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/pipeline_report.json"

private_key = os.environ['GITHUB_APP_PRIVATE_KEY']

# JWT
payload = {"iat": int(time.time()), "exp": int(time.time()) + 600, "iss": APP_ID}
jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

# Installation token
url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
installation_token = requests.post(url, headers=headers).json()["token"]

# Fetch JSON
url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {"Authorization": f"token {installation_token}", "Accept": "application/vnd.github+json"}
r = requests.get(url, headers=headers)

if r.status_code == 200:
    content_encoded = r.json()['content']
    json_data = base64.b64decode(content_encoded).decode()
    data = json.loads(json_data)
    print("Pipeline JSON:", data)
else:
    print("File not found or error", r.status_code)
```

---

## 2️⃣ Bash/Cygwin Scripts

### push_json.sh
```bash
#!/bin/bash

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/pipeline_report.json"
LOCAL_JSON_FILE="mydata.json"

# Generate JWT using Python
JWT=$(python3 - <<EOF
import jwt, time
APP_ID="$APP_ID"
with open("private-key.pem","r") as f:
    key=f.read()
payload={"iat":int(time.time()),"exp":int(time.time())+600,"iss":int(APP_ID)}
print(jwt.encode(payload,key,algorithm="RS256"))
EOF
)

INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

ENCODED_CONTENT=$(base64 -w 0 "$LOCAL_JSON_FILE")

FILE_CHECK=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

if echo "$FILE_CHECK" | jq -e .sha >/dev/null; then
    SHA=$(echo "$FILE_CHECK" | jq -r .sha)
    PAYLOAD=$(jq -n --arg msg "Update pipeline report" --arg content "$ENCODED_CONTENT" --arg sha "$SHA" '{message: $msg, content: $content, sha: $sha}')
else
    PAYLOAD=$(jq -n --arg msg "Add pipeline report" --arg content "$ENCODED_CONTENT" '{message: $msg, content: $content}')
fi

RESPONSE=$(curl -s -X PUT \
  -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$PAYLOAD" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

echo "$RESPONSE" | jq
```

### read_json.sh
```bash
#!/bin/bash

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/pipeline_report.json"

JWT=$(python3 - <<EOF
import jwt, time
APP_ID="$APP_ID"
with open("private-key.pem","r") as f:
    key=f.read()
payload={"iat":int(time.time()),"exp":int(time.time())+600,"iss":int(APP_ID)}
print(jwt.encode(payload,key,algorithm="RS256"))
EOF
)

INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

RESPONSE=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

if echo "$RESPONSE" | jq -e .content >/dev/null; then
    CONTENT=$(echo "$RESPONSE" | jq -r .content | base64 --decode)
    echo "Pipeline JSON:"
    echo "$CONTENT"
else
    echo "File not found or error"
fi
```

---

## 3️⃣ Harness Pipeline YAML Example
```yaml
pipeline:
  name: GitHub App JSON Pipeline
  stages:
    - stage:
        name: Push JSON
        type: Build
        spec:
          execution:
            steps:
              - step:
                  type: ShellScript
                  name: Push JSON
                  spec:
                    shell: Bash
                    onDelegate: true
                    script: |
                      bash push_json.sh
                    environmentVariables:
                      - name: GITHUB_APP_ID
                        value: <your app id>
                      - name: GITHUB_APP_INSTALLATION_ID
                        value: <installation id>
                      - name: GITHUB_APP_PRIVATE_KEY
                        value: <pem content or secret ref>

    - stage:
        name: Read JSON
        type: Build
        spec:
          execution:
            steps:
              - step:
                  type: ShellScript
                  name: Read JSON
                  spec:
                    shell: Bash
                    onDelegate: true
                    script: |
                      bash read_json.sh
                    environmentVariables:
                      - name: GITHUB_APP_ID
                        value: <your app id>
                      - name: GITHUB_APP_INSTALLATION_ID
                        value: <installation id>
                      - name: GITHUB_APP_PRIVATE_KEY
                        value: <pem content or secret ref>
```

---

## 4️⃣ README.md Content
```markdown
# GitHub App JSON Pipeline

This project demonstrates a two-stage pipeline using a GitHub App to push and read JSON files from a GitHub repo.

## Setup

1. Install dependencies:
   ```bash
   pip install PyJWT requests cryptography jq
   ```
2. Configure your GitHub App:
   - App ID
   - Installation ID
   - Private key (PEM) stored as a secret
   - Contents: Read & Write permission

## Usage

### Python
```bash
python push_json.py
py