#!/bin/bash
set -e

echo "[INFO] Setting up Multipass test environment..."

# Create VMs
echo "[INFO] Creating VMs (this takes a minute)..."
multipass launch -n pi-master -c 1 -m 1G -d 5G 2>/dev/null || echo "pi-master already exists"
multipass launch -n pi-worker1 -c 1 -m 1G -d 5G 2>/dev/null || echo "pi-worker1 already exists"
multipass launch -n pi-worker2 -c 1 -m 1G -d 5G 2>/dev/null || echo "pi-worker2 already exists"

# Get IPs
MASTER_IP=$(multipass info pi-master --format csv | tail -1 | cut -d',' -f3)
WORKER1_IP=$(multipass info pi-worker1 --format csv | tail -1 | cut -d',' -f3)
WORKER2_IP=$(multipass info pi-worker2 --format csv | tail -1 | cut -d',' -f3)

echo "[INFO] IPs: master=$MASTER_IP worker1=$WORKER1_IP worker2=$WORKER2_IP"

# Generate SSH key if needed
if [ ! -f ~/.ssh/multipass_key ]; then
  echo "[INFO] Generating SSH key..."
  ssh-keygen -t ed25519 -f ~/.ssh/multipass_key -N "" -q
fi

PUB_KEY=$(cat ~/.ssh/multipass_key.pub)

# Push SSH key to all VMs
for VM in pi-master pi-worker1 pi-worker2; do
  echo "[INFO] Adding SSH key to $VM..."
  multipass exec $VM -- bash -c "mkdir -p ~/.ssh && echo '$PUB_KEY' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done

# Update test inventory with real IPs
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sed -i.bak "s/MASTER_IP/$MASTER_IP/g" "$SCRIPT_DIR/inventory/test/inventory.ini"
sed -i.bak "s/WORKER1_IP/$WORKER1_IP/g" "$SCRIPT_DIR/inventory/test/inventory.ini"
sed -i.bak "s/WORKER2_IP/$WORKER2_IP/g" "$SCRIPT_DIR/inventory/test/inventory.ini"

sed -i.bak "s/MASTER_IP/$MASTER_IP/g" "$SCRIPT_DIR/inventory/test/group_vars/all.yml"
sed -i.bak "s/WORKER1_IP/$WORKER1_IP/g" "$SCRIPT_DIR/inventory/test/group_vars/all.yml"
sed -i.bak "s/WORKER2_IP/$WORKER2_IP/g" "$SCRIPT_DIR/inventory/test/group_vars/all.yml"

# Clean up .bak files
rm -f "$SCRIPT_DIR/inventory/test/"*.bak "$SCRIPT_DIR/inventory/test/group_vars/"*.bak

echo ""
echo "[SUCCESS] Test environment ready!"
echo ""
echo "  Deploy:   ./deploy.sh --test"
echo "  Destroy:  ./deploy.sh --destroy-test"
echo "  Clean:    ./test-setup.sh --clean"
echo ""
echo "  SSH:      ssh -i ~/.ssh/multipass_key ubuntu@$MASTER_IP"
echo ""

# Handle --clean flag
if [ "${1}" = "--clean" ]; then
  echo "[INFO] Deleting all Multipass VMs..."
  multipass delete pi-master pi-worker1 pi-worker2 --purge 2>/dev/null || true
  echo "[SUCCESS] VMs removed."
fi
