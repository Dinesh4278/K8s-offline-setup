#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <MASTER_IP> <SSH_USER>"
    exit 1
fi

MASTER_IP="$1"
SSH_USER="$2"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${MASTER_IP} << 'EOF'
cd /data
tar -xvzf packages.tar.gz

cd /data/utilities

dpkg -i *.deb

mkdir -p /root/binaries

cp /data/components-archives/kubernetes-server-linux-amd64.tar.gz /root/binaries
cp /data/components-archives/etcd-v3.5.18-linux-amd64.tar.gz /root/binaries

cd /root/binaries
tar -xzvf kubernetes-server-linux-amd64.tar.gz
tar -xzvf etcd-v3.5.18-linux-amd64.tar.gz
EOF
