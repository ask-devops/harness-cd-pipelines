# GitHub App JSON Upload Project

This project contains:

1. **Python script** to upload JSON to a specific folder in a GitHub repo using a GitHub App
2. **Bash (Cygwin) script** to do the same
3. **README.md** explaining setup and usage

---

## Folder Structure
```
github_app_json_upload/
 ├── upload_json.py      # Python script
 ├── upload_json.sh      # Bash/Cygwin script
 ├── mydata.json         # Sample JSON file to upload
 └── README.md           # Setup and usage guide
```

---

## 1️⃣ Python Script: upload_json.py
```python
import jwt
import time
import requests
import json
import base64

# -----------------------------
# GitHub App details
# -----------------------------
APP_ID = "YOUR_APP_ID"
INSTALLATION_ID = "YOUR_INSTALLATION_ID"
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/mydata.json"

# -----------------------------
# Load PEM private key
# -----------------------------
with open("private-key.pem", "r") as f:
    private_key = f.read()

# -----------------------------
# Step 1: Create JWT
# -----------------------------
payload = {
    "iat": int(time.time()),
    "exp": int(time.time()) + 600,
    "iss": APP_ID
}

jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

# -----------------------------
# Step 2: Request Installation Token
# -----------------------------
url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {
    "Authorization": f"Bearer {jwt_token}",
    "Accept": "application/vnd.github+json"
}
response = requests.post(url, headers=headers)
installation_token = response.json()["token"]

# -----------------------------
# Step 3: Prepare JSON data
# -----------------------------
data = {
    "name": "Satya",
    "project": "Goolte",
    "status": "uploaded via GitHub App"
}

json_data = json.dumps(data, indent=2)
encoded_content = base64.b64encode(json_data.encode()).decode()

# -----------------------------
# Step 4: Check if file exists
# -----------------------------
url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {
    "Authorization": f"token {installation_token}",
    "Accept": "application/vnd.github+json"
}
r = requests.get(url, headers=headers)

if r.status_code == 200:
    sha = r.json()["sha"]
    payload = {
        "message": "Update JSON via GitHub App",
        "content": encoded_content,
        "sha": sha
    }
else:
    payload = {
        "message": "Add JSON via GitHub App",
        "content": encoded_content
    }

# -----------------------------
# Step 5: Upload JSON
# -----------------------------
r = requests.put(url, headers=headers, json=payload)
print(r.json())
```

---

## 2️⃣ Bash/Cygwin Script: upload_json.sh
```bash
#!/bin/bash

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/mydata.json"
LOCAL_JSON_FILE="mydata.json"

# Step 1: Generate JWT using python
JWT=$(python3 - <<EOF
import jwt, time
APP_ID="$APP_ID"
with open("private-key.pem","r") as f:
    key=f.read()
payload={"iat":int(time.time()),"exp":int(time.time())+600,"iss":int(APP_ID)}
print(jwt.encode(payload,key,algorithm="RS256"))
EOF
)

# Step 2: Request installation token
INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

# Step 3: Encode JSON file
ENCODED_CONTENT=$(base64 -w 0 "$LOCAL_JSON_FILE")

# Step 4: Check if file exists
FILE_CHECK=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

if echo "$FILE_CHECK" | jq -e .sha >/dev/null; then
    SHA=$(echo "$FILE_CHECK" | jq -r .sha)
    PAYLOAD=$(jq -n --arg msg "Update JSON via GitHub App" \
        --arg content "$ENCODED_CONTENT" --arg sha "$SHA" \
        '{message: $msg, content: $content, sha: $sha}')
else
    PAYLOAD=$(jq -n --arg msg "Add JSON via GitHub App" --arg content "$ENCODED_CONTENT" '{message: $msg, content: $content}')
fi

# Step 5: Upload JSON
RESPONSE=$(curl -s -X PUT \
  -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$PAYLOAD" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

echo "$RESPONSE" | jq
```

---

## 3️⃣ README.md

```markdown
# GitHub App JSON Upload

This project shows how to upload JSON files to a specific folder in a GitHub repo using a GitHub App.

## Setup

1. Install Python dependencies:
   ```bash
   pip install PyJWT requests cryptography
   ```
2. Install Bash dependencies (for Cygwin/Linux):
   ```bash
   sudo apt install jq curl openssl
   ```
3. Configure your GitHub App:
   - App ID
   - Installation ID
   - PEM private key
   - Repository permissions: `Contents: Read & Write`

## Usage

### Python
```bash
python upload_json.py
```

### Bash (Cygwin/Linux)
```bash
chmod +x upload_json.sh
./upload_json.sh
```

## Notes

- JWT tokens expire in 10 minutes.  
- Installation token expires in 1 hour.  
- `private-key.pem` is secret — do not commit it.  
- The scripts will create or update the JSON file in the specified folder.
```}

