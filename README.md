# PiCluster
pi cluster automatic deployment/infra as code

CONFIGURATION:
  1. Set your Pi IPs in inventory/group_vars/all.yml:
    master_ip: "192.168.1.10"
 
    workers:
      - name: pi-worker1
        ip: "192.168.1.20"
      - name: pi-worker2
        ip: "192.168.1.30"
 
  2. Create and encrypt your secrets:
    ansible-vault create inventory/group_vars/vault.yml
 
    Fill in the following and save:
    vault_ansible_password: "your-pi-password"
    vault_k3s_token: "any-secret-string-shared-across-nodes"
 
  3. Create a local vault password file (not committed to git):
    echo "your-vault-password" > vault_pass.txt
 
USAGE:
  Deploy the cluster:
    ./deploy.sh --cluster
 
  Destroy the cluster:
    ./deploy.sh --destroy

  After deployment:
    export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig
    kubectl get nodes

  Access:
    Frontend: http://<master-ip>:30080
    Grafana:  http://<master-ip>:30030 (admin / dbf-grafana-2025)
