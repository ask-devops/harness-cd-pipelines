# Harness NG – Docker Delegate Setup (with Service Account)

This README walks through **setting up a Harness NG Docker Delegate** on a Linux host, including:
- Installing Docker
- Creating a **service account**
- Adding the service account to the Docker group
- Running the delegate container **as a non-root service account**

---

## Prerequisites
- Linux VM or server (RHEL / CentOS / Amazon Linux / Ubuntu)
- Internet access
- Root or sudo access
- Harness NG account and Delegate Token

---

## 1. Install Docker

### RHEL / CentOS / Amazon Linux
```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io
```

### Ubuntu
```bash
sudo apt update
sudo apt install -y docker.io
```

Start Docker:
```bash
sudo systemctl start docker
sudo systemctl enable docker
docker --version
```

---

## 2. Create Harness Service Account
```bash
sudo useradd -m -s /bin/bash harness
sudo passwd harness
```

---

## 3. Add Service Account to Docker Group
```bash
sudo usermod -aG docker harness
newgrp docker
```

Verify:
```bash
su - harness
docker ps
```

---

## 4. Create Delegate Directory
```bash
sudo mkdir -p /opt/harness-delegate
sudo chown -R harness:harness /opt/harness-delegate
```

---

## 5. Login as Harness User
```bash
su - harness
cd /opt/harness-delegate
```

---

## 6. Pull Delegate Image
```bash
docker pull harness/delegate:latest
```

---

## 7. Run Harness Delegate
```bash
docker run -d \
  --name harness-delegate \
  --restart always \
  -e ACCOUNT_ID=<HARNESS_ACCOUNT_ID> \
  -e DELEGATE_TOKEN=<DELEGATE_TOKEN> \
  -e DELEGATE_NAME=docker-delegate-01 \
  -e DELEGATE_TYPE=DOCKER \
  -e DELEGATE_TAGS=docker,linux \
  -e MANAGER_HOST=https://app.harness.io \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /opt/harness-delegate:/opt/harness-delegate \
  harness/delegate:latest
```

---

## 8. Verify Delegate
```bash
docker ps
docker logs -f harness-delegate
```

Check **Harness UI → Delegates → Connected**

---

## 9. Optional: systemd Service
```ini
[Unit]
Description=Harness Docker Delegate
After=docker.service
Requires=docker.service

[Service]
User=harness
Restart=always
ExecStart=/usr/bin/docker start -a harness-delegate
ExecStop=/usr/bin/docker stop harness-delegate

[Install]
WantedBy=multi-user.target
```

---

## 10. Security Best Practices
- Use non-root service account
- Scope delegate tokens
- Use delegate tags
- Rotate tokens periodically

---

## 11. Common Issues

### Docker permission denied
```bash
sudo usermod -aG docker harness
newgrp docker
```

### Delegate not connecting
- Validate ACCOUNT_ID / TOKEN
- Ensure outbound HTTPS
- Check MANAGER_HOST

---

✅ **Setup Complete**
