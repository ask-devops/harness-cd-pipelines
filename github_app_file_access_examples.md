# GitHub App File Access Examples

This README contains **three examples** to interact with a GitHub repo file using a GitHub App: 
1. Python - Read/Download file
2. Bash/Cygwin - Read/Download file using Python inline for JWT
3. Pure Bash - Read/Download file using OpenSSL for JWT

---

## 1️⃣ Python Example: Read/Download File
```python
import os
import jwt
import time
import requests
import base64

APP_ID = os.environ['GITHUB_APP_ID']
INSTALLATION_ID = os.environ['GITHUB_APP_INSTALLATION_ID']
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/pipeline_report.json"

# Load private key
with open("private-key.pem", "r") as f:
    private_key = f.read()

# Create JWT
payload = {"iat": int(time.time()), "exp": int(time.time()) + 600, "iss": APP_ID}
jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

# Request Installation Token
url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
installation_token = requests.post(url, headers=headers).json()["token"]

# Get file content
url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {"Authorization": f"token {installation_token}", "Accept": "application/vnd.github+json"}
r = requests.get(url, headers=headers)

if r.status_code == 200:
    content_encoded = r.json()['content']
    file_content = base64.b64decode(content_encoded).decode()
    with open("downloaded_file.json", "w") as f:
        f.write(file_content)
    print("File downloaded as 'downloaded_file.json'")
else:
    print("Error fetching file:", r.status_code, r.text)
```

---

## 2️⃣ Bash/Cygwin Example: Read/Download File Using Python Inline for JWT
```bash
#!/bin/bash

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/pipeline_report.json"

# Generate JWT using Python inline
JWT=$(python3 - <<EOF
import jwt, time
APP_ID="$APP_ID"
with open("private-key.pem","r") as f:
    key=f.read()
payload={"iat":int(time.time()),"exp":int(time.time())+600,"iss":int(APP_ID)}
print(jwt.encode(payload,key,algorithm="RS256"))
EOF
)

# Request Installation Token
INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

# Get file content
RESPONSE=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

# Decode base64 content and save locally
echo "$RESPONSE" | jq -r .content | base64 --decode > downloaded_file.json
echo "File downloaded as 'downloaded_file.json'"
```

---

## 3️⃣ Pure Bash Example (No Python, Using OpenSSL for JWT)
```bash
#!/bin/bash

APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/pipeline_report.json"
PRIVATE_KEY_FILE="private-key.pem"

# Prepare JWT header and payload
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '=\n' | tr '/+' '_-' )
NOW=$(date +%s)
EXP=$((NOW+600))
PAYLOAD=$(echo -n '{"iat":'$NOW',"exp":'$EXP',"iss":'$APP_ID'}' | openssl base64 -e | tr -d '=\n' | tr '/+' '_-')

# Sign JWT
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign "$PRIVATE_KEY_FILE" | openssl base64 -e | tr -d '=\n' | tr '/+' '_-')
JWT="$HEADER.$PAYLOAD.$SIGNATURE"

# Request Installation Token
INSTALLATION_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" \
  | jq -r .token)

# Get file content
RESPONSE=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

# Decode and save
echo "$RESPONSE" | jq -r .content | base64 --decode > downloaded_file.json
echo "File downloaded as 'downloaded_file.json'"
```

---

### Notes
1. Replace placeholders:
   - `YOUR_APP_ID`, `YOUR_INSTALLATION_ID`, `ORG_NAME/REPO_NAME`, `FILE_PATH`
2. Make sure `private-key.pem` exists in the same folder.
3. Dependencies:
   - Python: `PyJWT`, `requests` (if using Python inline or Python script)
   - Bash: `curl`, `jq`, `openssl`, `base64`
4. The downloaded file will always b