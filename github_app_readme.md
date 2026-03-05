# GitHub App Setup Guide

This guide explains how to **create a GitHub App** as a developer and how to request a repository admin to install it with the required access.

---

## 1. Developer: Create a GitHub App

### Step 1 — Open Developer Settings
1. Log in to GitHub.
2. Click your **profile picture → Settings**.
3. Scroll down → click **Developer settings**.
4. Click **GitHub Apps**.

### Step 2 — Create a New App
1. Click **New GitHub App**.
2. Fill in the basic info:
   - **App name**: Choose a unique name.
   - **Homepage URL**: `https://example.com` (or your site).
   - **Webhook URL**: optional, can leave empty for now.
3. Scroll down to **Repository permissions**:
   - Set only the permissions your app needs. For example:
     - **Contents** → Read
     - **Pull requests** → Read & Write (if needed)
4. Click **Create GitHub App**.

### Step 3 — Generate Private Key
1. On the app page, scroll down to **Private keys**.
2. Click **Generate a private key**.
3. Download the `.pem` file and keep it safe.

### Step 4 — Copy App Details
Save the following to share with your automation script or integration:
- **App ID** (from app page)
- **Private Key (.pem file)**
- Installation ID (will be obtained after installation by admin)

---

## 2. Developer: Request Admin to Install the App

### Step 1 — Copy Install Link
1. On the GitHub App page, scroll to **Install App**.
2. Right-click **Install App** → **Copy link address**.  
   OR manually:
   ```
   https://github.com/apps/YOUR-APP-NAME/installations/new
   ```

### Step 2 — Send Request to Admin
Send a message/email to the repository admin or organization owner:

> Hi,  
> I created a GitHub App named `YOUR-APP-NAME` to help automate tasks for the repository.  
> Please click the link below to install it on the repository and grant the required access:  
> [Install App Link]  
> After installation, please share the **Installation ID** with me so the app can authenticate.

---

## 3. Admin: Install GitHub App on Repository

1. Click the install link received from the developer.
2. Choose where to install:
   - **Personal account** or **Organization**
3. Select which repositories to allow:
   - **All repositories** → app can access all
   - **Only select repositories** → choose specific ones
4. Click **Install**
5. Copy the **Installation ID** from the browser URL:
   ```
   https://github.com/settings/installations/12345678
   ```
   - `12345678` = Installation ID

---

## 4. Developer: Use the App After Installation

Now you have everything to authenticate your app:

- **App ID**  
- **Private Key (.pem file)**  
- **Installation ID**  

Your app can generate an **Installation Access Token** to interact with the repository:

```python
import jwt, time, requests

APP_ID = "YOUR_APP_ID"
INSTALLATION_ID = "YOUR_INSTALLATION_ID"

with open("private-key.pem", "r") as f:
    private_key = f.read()

payload = {
    "iat": int(time.time()),
    "exp": int(time.time()) + 600,
    "iss": APP_ID
}
encoded_jwt = jwt.encode(payload, private_key, algorithm="RS256")

headers = {"Authorization": f"Bearer {encoded_jwt}", "Accept": "application/vnd.github+json"}
url = f"https://api.github.com/app/installations/{INSTALLATION_ID}/access_tokens"
response = requests.post(url, headers=headers)
token = response.json()["token"]

print("Installation Token:", token)
```

This token is **valid for 1 hour** and can be used to access the repo according to permissions.

---

## ✅ Notes

- GitHub Apps do **not use client secrets**; only App ID + PEM file + Installation ID.
- If you change permissions after installation, you must **reinstall the app**.
- Each installation (repo/org) has a **di