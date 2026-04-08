#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INVENTORY="${INVENTORY:-inventory/inventory.ini}"

echo "[INFO] Starting decommissioning of the full service..."
echo "[INFO] Using inventory: $INVENTORY"

echo "[INFO] Removing Kubernetes resources..."
ansible-playbook -i "$INVENTORY" /dev/stdin <<'PLAYBOOK'
- name: Remove all Kubernetes resources
  hosts: master
  become: true
  tasks:
    - name: Uninstall Helm monitoring stack
      command: helm uninstall monitoring --namespace monitoring
      environment:
        KUBECONFIG: /etc/rancher/k3s/k3s.yaml
      ignore_errors: true

    - name: Delete app namespace
      command: kubectl delete namespace app --ignore-not-found
      environment:
        KUBECONFIG: /etc/rancher/k3s/k3s.yaml
      ignore_errors: true

    - name: Delete monitoring namespace
      command: kubectl delete namespace monitoring --ignore-not-found
      environment:
        KUBECONFIG: /etc/rancher/k3s/k3s.yaml
      ignore_errors: true
PLAYBOOK

echo "[INFO] Uninstalling k3s on workers..."
ansible-playbook -i "$INVENTORY" /dev/stdin <<'PLAYBOOK'
- name: Uninstall k3s from workers
  hosts: workers
  become: true
  tasks:
    - name: Run k3s agent uninstall script
      shell: /usr/local/bin/k3s-agent-uninstall.sh
      ignore_errors: true
PLAYBOOK

echo "[INFO] Uninstalling k3s on master..."
ansible-playbook -i "$INVENTORY" /dev/stdin <<'PLAYBOOK'
- name: Uninstall k3s from master
  hosts: master
  become: true
  tasks:
    - name: Run k3s uninstall script
      shell: /usr/local/bin/k3s-uninstall.sh
      ignore_errors: true

    - name: Remove Helm binary
      file:
        path: /usr/local/bin/helm
        state: absent
PLAYBOOK

echo "[INFO] Cleaning up local kubeconfig..."
rm -f "$SCRIPT_DIR/kubernetes/base/kubeconfig"

echo "[SUCCESS] Full service decommissioned."
