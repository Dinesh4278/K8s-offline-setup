#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <MASTER_IP> <WORKER_IP> <SSH_USER>"
    exit 1
fi

MASTER_IP="$1"
WORKER_IP="$2"
SSH_USER="$3"

ssh -o StrictHostKeyChecking=no ${SSH_USER}@${WORKER_IP} << EOF
cd /var/lib/kubelet || exit 1
kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.crt \
    --client-key=kube-proxy.key \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

systemctl start kube-proxy
systemctl enable kube-proxy
EOF
