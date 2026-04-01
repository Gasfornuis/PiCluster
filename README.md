# PiCluster
pi cluster automatic deployment/infra as code

CONFIGURATION:
  1. Set your Pi IPs in ansible/group_vars/all.yml:
    master_ip: "192.168.1.101"
 
    workers:
      - name: pi-worker1
        ip: "192.168.1.102"
      - name: pi-worker2
        ip: "192.168.1.103"
 
  2. Create and encrypt your secrets:
    ansible-vault create ansible/group_vars/vault.yml
 
    Fill in the following and save:
    vault_ansible_password: "your-pi-password"
    vault_k3s_token: "any-secret-string-shared-across-nodes"
 
USAGE:
  Deploy the cluster:
    ./deploy.sh --cluster
 
    You will be prompted for your vault password.
 
    To use kubectl after deployment:
      export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig
      kubectl get nodes
 
