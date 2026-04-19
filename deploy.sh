#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="inventory/inventory.ini"
ANSIBLE_DIR="ansible"
export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible.cfg"

setup_ssh() {
  if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
  fi
  if ! ssh-add -l 2>/dev/null | grep -q "\.ssh/pi"; then
    echo "[INFO] SSH key not found in agent. Adding it now..."
    ssh-add ~/.ssh/pi
  fi
  MASTER_IP=$(grep -A 1 '^\[master\]' "$INVENTORY" | tail -n 1 | awk '{print $2}' | cut -d= -f2)
  echo "[INFO] Testing if the key provides access to $MASTER_IP..."
  
  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no piuser@"$MASTER_IP" exit 2>/dev/null; then
    echo "[SUCCESS] SSH access works perfectly!"
  else
    echo "[WARNING] The stored key does not work (or the Pi is offline)."
    echo "[INFO] Clearing the cache and trying again..."
    
    ssh-add -D
    ssh-add ~/.ssh/pi
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no piuser@"$MASTER_IP" exit 2>/dev/null; then
       echo "[SUCCESS] It works!"
    else
       echo "[ERROR] Still no access. Check if the Pi is powered on and you have the correct key."
       exit 1
    fi
  fi
}

usage() {
  echo "
Usage: ./deploy.sh [option]
Options:
  (none)           Deploy everything (cluster + apps + monitoring)
  --cluster        Deploy only the k3s cluster
  --destroy        Dismantle the complete service
  --help           Show this message
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
  setup_ssh
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
