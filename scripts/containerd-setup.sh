#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <WORKER_IP> <SSH_USER>"
    exit 1
fi

WORKER_IP="$1"
SSH_USER="$2"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << 'EOF'
cd /root/binaries
tar -xvzf containerd-2.0.2-linux-amd64.tar.gz

mv bin/* /usr/local/bin/

systemctl daemon-reload
systemctl start containerd
systemctl enable containerd

sysctl -w net.ipv4.conf.all.forwarding=1

cd /root/binaries/kubernetes/node/bin/ || exit 1

cp kube-proxy kubectl kubelet /usr/local/bin
EOF
