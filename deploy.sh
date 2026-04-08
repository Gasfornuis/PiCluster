#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="inventory/inventory.ini"
ANSIBLE_DIR="ansible"

export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible.cfg"

usage() {
  echo "
Usage: ./deploy.sh [option]

Options:
  --cluster        Deploy full k3s cluster + apps + monitoring (Pi's)
  --test           Deploy on Multipass test VMs
  --destroy        Decommission the full service (Pi's)
  --destroy-test   Decommission test environment
  --help           Show this help message
"
  exit 0
}

check_ansible() {
  if ! command -v ansible-playbook &> /dev/null; then
    echo "[ERROR] ansible-playbook not found. Install with: pip install ansible"
    exit 1
  fi
}

install_collections() {
  echo "[INFO] Installing required Ansible collections..."
  ansible-galaxy collection install community.general
}

deploy_cluster() {
  echo "[INFO] Deploying k3s cluster + applications + monitoring..."
  ansible-playbook -i "$INVENTORY" "$ANSIBLE_DIR/site.yml"
  echo "[SUCCESS] Cluster deployed!"
  echo ""
  echo "  kubectl:  export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig"
  echo "  frontend: http://<master-ip>:30080"
  echo "  grafana:  http://<master-ip>:30030  (admin / dbf-grafana-2025)"
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

deploy_test() {
  export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible-test.cfg"
  echo "[INFO] Deploying on Multipass test VMs..."
  ansible-playbook -i "inventory/test/inventory.ini" "$ANSIBLE_DIR/site.yml"
  MASTER_IP=$(grep pi-master inventory/test/inventory.ini | sed 's/.*ansible_host=//')
  echo "[SUCCESS] Test cluster deployed!"
  echo ""
  echo "  kubectl:  export KUBECONFIG=$(pwd)/kubernetes/base/kubeconfig"
  echo "  frontend: http://$MASTER_IP:30080"
  echo "  grafana:  http://$MASTER_IP:30030  (admin / dbf-grafana-2025)"
}

destroy_test() {
  export ANSIBLE_CONFIG="$SCRIPT_DIR/ansible-test.cfg"
  echo "[WARNING] This will remove the test service."
  read -p "Are you sure? (y/N): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    INVENTORY="inventory/test/inventory.ini" bash "$SCRIPT_DIR/destroy.sh"
  else
    echo "[INFO] Cancelled."
  fi
}

if [ $# -eq 0 ]; then
  usage
fi

case "$1" in
  --cluster)
    check_ansible
    install_collections
    deploy_cluster
    ;;
  --test)
    check_ansible
    install_collections
    deploy_test
    ;;
  --destroy)
    check_ansible
    destroy_cluster
    ;;
  --destroy-test)
    check_ansible
    destroy_test
    ;;
  --help)
    usage
    ;;
  *)
    echo "[ERROR] Unknown option: $1"
    usage
    ;;
esac
