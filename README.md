# PiCluster
Automated Kubernetes cluster deployment for Raspberry Pi 4's using Ansible and K3S.

Deploy a full K3S cluster with a C# web application, API, MariaDB database, Prometheus/Grafana monitoring, HTTPS via Traefik, and network security policies on all Raspberry Pi 4's with one command. Decommision everything also with one command.

## Prerequisites
- 3x Raspberry Pi 4's
- SSH key access to all Pi's (configured via Pi Imager)
- Ansible installed on your local machine
- Kubectl installed on your local machine

## Configuration
Set the IP addresses of your Pi's in 'inventory/group_vars/all.yml' and 'inventory/inventory.ini' and place the SSH key for your Pi's in '~/.ssh/pi".
```yaml
master_ip: "192.168.1.10"

workers:
  - name: pi-worker1
    ip: "192.168.1.20"
  - name: pi-worker2
    ip: "192.168.1.30"

ansible_user: piuser
ansible_ssh_private_key_file: "~/.ssh/pi"
k3s_token: "your-chosen-token"
```

```ini
[master]
pi-master ansible_host=192.168.1.10

[workers]
pi-worker1 ansible_host=192.168.1.20
pi-worker2 ansible_host=192.168.1.30
```

## Usage
```bash
# Add SSH key to agent (once per terminal session)
eval $(ssh-agent)
ssh-add ~/.ssh/pi

# Deploy everything with one command
./deploy.sh

# Deploy only the k3s cluster
./deploy.sh --cluster

# Destroy the full service
./deploy.sh --destroy

# Show help
./deploy.sh --help
```

## Testing
You can test the deployment locally without the need for Pi's using Multipass:
```bash
# Create VMs and configure SSH
./test-setup.sh

# Deploy on test VMs
./deploy.sh --test

# Destroy test environment
./deploy.sh --destroy-test

# Remove VMs entirely
./test-setup.sh --clean
```

## Project structure
```
PiCluster/
├── deploy.sh                        # Deployment script
├── destroy.sh                       # Decommission script
├── ansible/
│   ├── site.yml                     # Full playbook (deploys cluster and apps)
│   ├── cluster.yml                  # Playbook that deploys only the cluster
│   └── roles/
│       ├── common/                  # Base config for all Pi's
│       ├── k3s-master/              # k3s server installation
│       ├── k3s-worker/              # k3s agent installation
│       └── k8s-bootstrap/           # Deploy all K8s resources
├── inventory/
│   ├── inventory.ini                # Pi IP addresses
│   └── group_vars/all.yml           # Shared variables
├── kubernetes/
│   ├── api/                         # C# API deployment with service
│   ├── backend/                     # MariaDB deployment with service and PVC
│   ├── frontend/                    # C# frontend deployment with service and ingress
│   ├── monitoring/                  # Prometheus and Grafana (Helm)
│   ├── namespaces/                  # App and monitoring namespaces
│   └── network-policies/            # Firewall rules for pods
└── test-setup.sh                    # Test environment for multipass
```
