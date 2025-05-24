#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <MASTER_IP> <WORKER_IP> <SSH_USER>"
    exit 1
fi

MASTER_IP="$1"
WORKER_IP="$2"
SSH_USER="$3"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << EOF
mkdir -p /root/certificates
cd /tmp || exit 1
mv kube-proxy.crt kube-proxy.key worker.crt worker.key ca.crt /root/certificates

mkdir -p /var/lib/kubernetes
cd /root/certificates || exit 1
cp ca.crt /var/lib/kubernetes
mv worker.crt worker.key kube-proxy.crt kube-proxy.key /var/lib/kubelet/

cd /var/lib/kubelet || exit 1
cp /var/lib/kubernetes/ca.crt .

kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=worker.kubeconfig

kubectl config set-credentials system:node:worker-node \
    --client-certificate=worker.crt \
    --client-key=worker.key \
    --embed-certs=true \
    --kubeconfig=worker.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=system:node:worker-node \
    --kubeconfig=worker.kubeconfig

kubectl config use-context default --kubeconfig=worker.kubeconfig

mv worker.kubeconfig kubeconfig
systemctl start kubelet
systemctl enable kubelet
EOF
