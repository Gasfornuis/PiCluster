#!/bin/bash
set -e

INVENTORY="inventory/inventory.ini"
ANSIBLE_DIR="ansible"

#Help
usage() {
  echo "
Usage: ./deploy.sh [option]

Options:
  --cluster      Install k3s on master and join workers
  --help         Show this help message
"
  exit 0
}

#Check Ansible is installed
check_ansible() {
  if ! command -v ansible-playbook &> /dev/null; then
    echo "[ERROR] ansible-playbook not found. Install it with:"
    echo "  pip install ansible"
    exit 1
  fi
}

#Install Ansible collections
install_collections() {
  echo "[INFO] Installing required Ansible collections..."
  ansible-galaxy collection install community.general
}

#Deploy cluster
deploy_cluster() {
  echo "[INFO] Deploying k3s cluster..."
  ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/site.yml" --ask-vault-pass
  echo "[SUCCESS] Cluster deployed!"
  echo "[INFO] To use kubectl: export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig"
}

#No arguments
if [ $# -eq 0 ]; then
  usage
fi

#Parse options
case "$1" in
  --cluster)
    check_ansible
    install_collections
    deploy_cluster
    ;;
  --help)
    usage
    ;;
  *)
    echo "[ERROR] Unknown option: $1"
    usage
    ;;
esac
