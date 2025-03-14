# harness-cd-pipelines
## TestResultsVersionedStorage.yaml
   What You Need to Configure<BR>
Replace "artifactory_connector" with your actual Artifactory connector reference.<BR>
Update the repository path (e.g., generic-local).<BR>
Ensure the jq command is available in the delegate (or install it).<BR>
## RunAnsibleOnDelegate
   1. Store SSH Private Key in Harness Secrets Manager
         Go to Harness → Secrets Manager.
         Create a new secret → Text.
         Paste the private SSH key (e.g., id_rsa).
         Save it as: SSH_PRIVATE_KEY.
   2. inventory/hosts.ini 
      [all]
      192.168.1.100 ansible_user=ubuntu
      192.168.1.101 ansible_user=ubuntu
      192.168.1.102 ansible_user=ubuntu
      
      [all:vars]
      ansible_ssh_private_key_file=/harness/ssh_key
  3. Running Ansible Against Remote Hosts 
  script: |
    ansible-playbook -i inventory/hosts.ini playbooks/site.yml --user ubuntu --private-key $SSH_KEY_PATH
  Custom Harness Delegate with Ansible (Dockerfile)

Create a custom delegate image with Ansible pre-installed:

   dockerfile
      FROM harness/delegate:latest  # Use the base Harness Delegate image <BR>
      RUN apt update && apt install -y ansible && ansible --version<BR>
      WORKDIR /harness<BR>
      CMD ["sh", "-c", "/harness/delegate.sh"]<BR>
    <BR><BR>
   Build & Push the Custom Image
    <BR>
 <BR>
   docker build -t my-custom-harness-delegate .<BR>
   docker tag my-custom-harness-delegate myrepo/my-custom-harness-delegate:latest<BR>
   docker push myrepo/my-custom-harness-delegate:latest<BR>
   Deploy Delegate with Custom Image<BR>
   Modify the Kubernetes YAML (if using K8s) or Docker Run command to use your custom delegate image:<BR>
   docker run -e DELEGATE_TOKEN=<your_token> -e ACCOUNT_ID=<your_account> myrepo/my-custom-harness-delegate:latest<BR>

# Simple JSON parsing using bash
## TEST_STATUS=$(cat results.json | grep -o '"testStatus": *"[^"]*"' | awk -F '": "' '{print $2}' | tr -d '"')
### TEST_STATUS=$(grep -oP '"testStatus": *"\K[^"]*' results.json)

echo "Test Status: $TEST_STATUS"


