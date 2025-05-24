#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <WORKER_IP> <SSH_USER>"
    exit 1
fi

WORKER_IP="$1"
SSH_USER="$2"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << 'EOF'
mkdir -p /var/lib/kube-proxy
mkdir -p /var/lib/kubelet
mkdir -p /etc/containerd
EOF

scp /data/yaml/kube-proxy-config.yaml ${SSH_USER}@${WORKER_IP}:/var/lib/kube-proxy/
scp /data/services/kube-proxy.service ${SSH_USER}@${WORKER_IP}:/etc/systemd/system

scp /data/yaml/kubelet-config.yaml ${SSH_USER}@${WORKER_IP}:/var/lib/kubelet/
scp /data/services/kubelet.service ${SSH_USER}@${WORKER_IP}:/etc/systemd/system

scp /data/services/containerd.service ${SSH_USER}@${WORKER_IP}:/lib/systemd/system

scp /data/configuration/config.toml ${SSH_USER}@${WORKER_IP}:/etc/containerd
scp /data/configuration/containerd.conf ${SSH_USER}@${WORKER_IP}:/etc/modules-load.d/
scp /data/configuration/99-kubernetes-cri.conf ${SSH_USER}@${WORKER_IP}:/etc/sysctl.d/
scp /data/configuration/k8s.conf ${SSH_USER}@${WORKER_IP}:/etc/sysctl.d/

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << 'EOF'
modprobe overlay
modprobe br_netfilter
sysctl --system
EOF
