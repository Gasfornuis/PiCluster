#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="inventory/inventory.ini"
ANSIBLE_DIR="ansible"

export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible.cfg"

eval $(ssh-agent)
ssh-add ~/.ssh/pi

usage() {
  echo "
Usage: ./deploy.sh [option]

Options:
  (geen)           Deploy alles (cluster + apps + monitoring)
  --cluster        Deploy alleen het k3s cluster
  --destroy        Ontmantel de volledige dienst
  --help           Toon dit bericht
"
  exit 0
}

check_ansible() {
  if ! command -v ansible-playbook &> /dev/null; then
    echo "[ERROR] ansible-playbook not found. Install with: pip install ansible"
    exit 1
  fi
}

check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo "[ERROR] kubectl not found. Please install it first."
    echo "Mac (Homebrew): brew install kubectl"
    echo "Linux (apt): sudo apt-get install -y kubectl"
    exit 1
  fi
}

install_collections() {
  echo "[INFO] Installing required Ansible collections..."
  ansible-galaxy collection install community.general
}

deploy_all() {
  echo "[INFO] Deploying full stack (cluster + apps + monitoring)..."
  ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/site.yml"
  echo "[SUCCESS] Full stack deployed!"
  echo ""
  echo "  kubectl:  export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig"
  echo "  frontend: http://<master-ip>:30080"
  echo "  grafana:  http://<master-ip>:30030  (admin / dbf-grafana-2025)"
}

deploy_cluster() {
  echo "[INFO] Deploying k3s cluster only..."
  ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/cluster.yml"
  echo "[SUCCESS] Cluster deployed!"
  echo ""
  echo "  kubectl:  export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig"
}

destroy_cluster() {
  echo "[WARNING] This will remove the entire service."
  read -p "Are you sure? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/destroy.sh"
  else
    echo "[INFO] Cancelled."
  fi
}

if [ $# -eq 0 ]; then
  check_ansible
  check_kubectl
  install_collections
  deploy_all
  exit 0
fi

case "$1" in
  --cluster)
    check_ansible
    check_kubectl
    install_collections
    deploy_cluster
    ;;
  --destroy)
    check_ansible
    destroy_cluster
    ;;
  --help)
    usage
    ;;
  *)
    echo "[ERROR] Unknown option: $1"
    usage
    ;;
esac
