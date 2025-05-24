#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <WORKER_IP> <SSH_USER>"
    exit 1
fi

WORKER_IP="$1"
SSH_USER="$2"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << 'EOF'
cd /data/components-archives

mkdir -p /etc/cni/net.d /opt/cni/bin /var/run/kubernetes

mv cni-plugins-linux-amd64-v1.6.2.tgz /opt/cni/bin
cd /opt/cni/bin
tar -xzvf cni-plugins-linux-amd64-v1.6.2.tgz
EOF
