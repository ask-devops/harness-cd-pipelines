# GitHub App Read/Write Setup & Pipeline Examples

This project provides a **complete step-by-step guide** to creating a GitHub App with **read/write permissions** and examples for reading and writing files in a repo using Python and Bash. It also includes a sample **Harness pipeline**.

---

## Folder Structure
```
github_app_read_write/
 ├── push_json.py        # Python script to push JSON
 ├── read_json.py        # Python script to read/download JSON
 ├── push_json.sh        # Bash script to push JSON
 ├── read_json.sh        # Bash script to read/download JSON
 ├── mydata.json         # Sample JSON file
 ├── pipeline.yaml       # Harness pipeline example
 └── README.md           # This step-by-step guide
```

---

## 1️⃣ Step 1: Create a GitHub App

1. Go to [GitHub Developer Settings](https://github.com/settings/apps).
2. Click **"New GitHub App"**.
3. Fill in:
   - **App name**
   - **Homepage URL** (any URL, e.g., your company site)
   - **Webhook URL** (optional if you don’t need webhooks)
4. **Permissions**:
   - **Repository contents** → **Read & Write**
   - Other permissions as needed
5. **Subscribe to events** if required (optional)
6. Click **Create GitHub App**
7. **Generate a private key (PEM)** → download and store safely
8. Note **App ID**

---

## 2️⃣ Step 2: Install the App on a Repo

1. Go to your newly created App page
2. Click **"Install App"** → Choose the repo you want the app to access
3. After installation, note the **Installation ID**

---

## 3️⃣ Step 3: Prepare Environment Variables

Store these as environment variables or Harness secrets:
```
GITHUB_APP_ID=<your app id>
GITHUB_APP_INSTALLATION_ID=<installation id>
GITHUB_APP_PRIVATE_KEY=<path to private-key.pem>
```

---

## 4️⃣ Step 4: Python Example - Read/Download File
```python
import os, jwt, time, requests, base64

APP_ID = os.environ['GITHUB_APP_ID']
INSTALLATION_ID = os.environ['GITHUB_APP_INSTALLATION_ID']
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/pipeline_report.json"

with open(os.environ['GITHUB_APP_PRIVATE_KEY'], 'r') as f:
    private_key = f.read()

payload = {"iat": int(time.time()), "exp": int(time.time())+600, "iss": APP_ID}
jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
installation_token = requests.post(url, headers=headers).json()["token"]

url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {"Authorization": f"token {installation_token}", "Accept": "application/vnd.github+json"}
r = requests.get(url, headers=headers)

if r.status_code==200:
    content_encoded = r.json()['content']
    file_content = base64.b64decode(content_encoded).decode()
    with open('downloaded_file.json','w') as f:
        f.write(file_content)
    print("File downloaded")
else:
    print("Error", r.status_code)
```

---

## 5️⃣ Step 5: Python Example - Push/Write JSON File
```python
import os, jwt, time, requests, base64, json

APP_ID = os.environ['GITHUB_APP_ID']
INSTALLATION_ID = os.environ['GITHUB_APP_INSTALLATION_ID']
REPO = "ORG_NAME/REPO_NAME"
FILE_PATH = "data/pipeline_report.json"

with open(os.environ['GITHUB_APP_PRIVATE_KEY'], 'r') as f:
    private_key = f.read()

payload = {"iat": int(time.time()), "exp": int(time.time())+600, "iss": APP_ID}
jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
headers = {"Authorization": f"Bearer {jwt_token}", "Accept": "application/vnd.github+json"}
installation_token = requests.post(url, headers=headers).json()["token"]

# Prepare JSON
data = {"example": "test", "timestamp": int(time.time())}
encoded = base64.b64encode(json.dumps(data).encode()).decode()

url = f"https://api.github.com/repos/{REPO}/contents/{FILE_PATH}"
headers = {"Authorization": f"token {installation_token}", "Accept": "application/vnd.github+json"}
r = requests.get(url, headers=headers)
if r.status_code == 200:
    sha = r.json()['sha']
    payload = {"message": "Update JSON", "content": encoded, "sha": sha}
else:
    payload = {"message": "Add JSON", "content": encoded}

r = requests.put(url, headers=headers, json=payload)
print(r.json())
```

---

## 6️⃣ Step 6: Bash Example - Read File Using Python Inline JWT
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
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r .token)

RESPONSE=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO/contents/$FILE_PATH")

echo "$RESPONSE" | jq -r .content | base64 --decode > downloaded_file.json
echo "File downloaded"
```

---

## 7️⃣ Step 7: Bash Example - Push JSON
```bash
#!/bin/bash
APP_ID="YOUR_APP_ID"
INSTALLATION_ID="YOUR_INSTALLATION_ID"
REPO="ORG_NAME/REPO_NAME"
FILE_PATH="data/pipeline_report.json"
LOCAL_JSON_FILE="mydata.json"

JWT=$(python3 - <<EOF
import jwt, time
APP_ID="$APP_ID"
with open("private-key.pem","r") as f:
 key=f.read()
payload={"iat":int(time.time()),"exp":int(time.time())+600,"iss":int(APP_ID)}
print(jwt.encode(payload,key,algorithm="RS256"))
EOF
)

INSTALLATION_TOKEN=$(curl -s -X POST -H "Authorization: Bearer $JWT" -H "Accept: application/vnd.github+json" \
"https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | jq -r .token)

ENCODED=$(base64 -w0 $LOCAL_JSON_FILE)

FILE_CHECK=$(curl -s -H "Authorization: token $INSTALLATION_TOKEN" -H "Accept: application/vnd.github+json" \
"https://api.github.com/repos/$REPO/contents/$FILE_PATH")

if echo $FILE_CHECK | jq -e .sha >/dev/null; then
 SHA=$(echo $FILE_CHECK | jq -r .sha)
 PAYLOAD=$(jq -n --arg msg "Update JSON" --arg content "$ENCODED" --arg sha "$SHA" '{message:$msg,content:$content,sha:$sha}')
else
 PAYLOAD=$(jq -n --arg msg "Add JSON" --arg content "$ENCODED" '{message:$msg,content:$content}')
fi

curl -s -X PUT -H "Authorization: token $INSTALLATION_TOKEN" -H "Accept: application/vnd.github+json" -d "$PAYLOAD" \
"https://api.github.com/repos/$REPO/contents/$FILE_PATH" | jq
```

---

## 8️⃣ Step 8: Harness Pipeline YAML Example
```yaml
pipeline:
  name: GitHub App Read/Write Pipeline
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
                    script: |
                      bash push_json.sh
                    environmentVariables:
                      - name: GITHUB_APP_ID
                        value: <your app id>
                      - name: GITHUB_APP_INSTALLATION_ID
                        value: <installation id>
                      - name: GITHUB_APP_PRIVATE_KEY
                        value: <path to pem>

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
                    script: |
                      bash read_json.sh
                    environmentVariables:
                      - name: GITHUB_APP_ID
                        value: <your app id>
                      - name: GITHUB_APP_INSTALLATION_ID
                        value: <installation id>
                      - name: GITHUB_APP_PRIVATE_KEY
                        value: <path to pem>
```

---

This README, along with the scripts, forms a **downloadable package** for testing GitHub App read/write operations. You can now save it as `README.md` and include the `.py` and `.sh` files and `mydata.json` sample to run immediately.

