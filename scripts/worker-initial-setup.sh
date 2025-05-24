#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <WORKER_IP> <SSH_USER>"
    exit 1
fi

WORKER_IP="$1"
SSH_USER="$2"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << 'EOF'
cd /data
tar -xvzf packages.tar.gz

cd /data/utilities

dpkg -i *.deb

mkdir -p /var/lib/kube-proxy
mkdir -p /var/lib/kubelet
mkdir -p /etc/containerd
mkdir -p /etc/cni/net.d
mkdir -p /opt/cni/bin
mkdir -p /var/run/kubernetes
mkdir -p /root/binaries

cp /data/components-archives/kubernetes-node-linux-amd64.tar.gz /root/binaries
cp /data/components-archives/containerd-2.0.2-linux-amd64.tar.gz /root/binaries

cd /root/binaries
tar -xzvf kubernetes-node-linux-amd64.tar.gz

cp /data/components-archives/cni-plugins-linux-amd64-v1.6.2.tgz /opt/cni/bin
cd /opt/cni/bin
tar -xzvf cni-plugins-linux-amd64-v1.6.2.tgz
EOF

