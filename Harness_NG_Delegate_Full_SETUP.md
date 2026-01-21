# Harness NG Delegate Setup for Azure VM Deployment (With Architecture Diagram + Scripts)

This guide explains how to set up a **Harness NG Delegate** on **Azure VMs** (Linux or Windows) to enable **CD deployments**. It includes architecture, ready-to-run scripts, and deployment examples.

---

## 1. Architecture Diagram

![Harness NG Delegate Architecture](harness_delegate_architecture.png)

Description:
- **Harness SaaS** communicates **outbound HTTPS (443)** to the delegate
- **Delegate** runs on Azure VM (Linux/Windows)
- **Delegate** deploys to **target VMs** via SSH (Linux) or WinRM (Windows)

---

## 2. Prerequisites

### Azure VM
- Linux: Ubuntu 20.04/22.04, RHEL 8+
- Windows: Windows Server 2019/2022
- Outbound internet access to Harness SaaS: **443 (HTTPS)**

### Required Tools
- Docker (Linux / Windows)
- PowerShell (Windows)
- SSH client (Linux) or WinRM (Windows)
- NSG Rules: Ensure outbound allowed, no inbound needed for delegate

---

## 3. Delegate Setup Scripts

### 3.1 Linux VM Ready Script (`setup_delegate_linux.sh`)

```bash
#!/bin/bash
# Install Docker
sudo apt update && sudo apt install -y docker.io
sudo systemctl start docker && sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Run Harness Delegate
docker run -d   --name harness-delegate   --restart always   -e ACCOUNT_ID=<YOUR_ACCOUNT_ID>   -e DELEGATE_TOKEN=<YOUR_DELEGATE_TOKEN>   -e DELEGATE_NAME=azure-vm-delegate   -e DELEGATE_TAGS=azure,vm,prod   -e MANAGER_HOST=https://app.harness.io   harness/delegate:latest
```

### 3.2 Windows VM Ready Script (`setup_delegate_windows.ps1`)

```powershell
# Ensure Docker Desktop/Engine installed
docker pull harness/delegate:latest
docker run -d `
  --name harness-delegate `
  --restart always `
  -e ACCOUNT_ID=<YOUR_ACCOUNT_ID> `
  -e DELEGATE_TOKEN=<YOUR_DELEGATE_TOKEN> `
  -e DELEGATE_NAME=azure-vm-delegate `
  -e DELEGATE_TAGS=azure,vm,prod `
  -e MANAGER_HOST=https://app.harness.io `
  harness/delegate:latest
```

---

## 4. Deployment Examples

### 4.1 Linux Deployment

```bash
ssh user@target-vm
cd /opt/app
tar -xzf app.tar.gz
systemctl restart app
```

### 4.2 Windows Deployment (PowerShell)

```powershell
Copy-Item -Path C:\temp\app.zip -Destination C:\app
Expand-Archive C:\app\app.zip -DestinationPath C:\app
Restart-Service -Name MyAppService
```

---

## 5. SSH / WinRM Connector Setup in Harness

- Host: `localhost` or target VM IP
- Port: 22 (Linux SSH) or 5986 (Windows WinRM)
- Delegate Selector: `azure,vm`
- Username / Key: as configured
- Test connection in Harness → should succeed

---

## 6. Security Best Practices

- Use private IPs internally
- Restrict SSH / WinRM via NSG
- Delegate Tags to control access
- Rotate keys regularly
- Use Harness Secrets Manager (Azure Key Vault)

---

## 7. References

- [Harness Delegate Docs](https://docs.harness.io/article/delegates)
- [Azure VM Networking](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface-overview)
- [SSH Key Setup](https://linuxize.com/post/how-to-set-up-ssh-keys-on-ubuntu/)
- [WinRM Setup for Harness](https://docs.harness.io/article/winrm-deployment)

