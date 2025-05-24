#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <MASTER_IP>"
    exit 1
fi

MASTER_IP="$1"

cd /root/certificates || exit 1

kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
    --client-certificate=admin.crt \
    --client-key=admin.key \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=admin \
    --kubeconfig=admin.kubeconfig

kubectl config use-context default --kubeconfig=admin.kubeconfig

kubectl get componentstatuses --kubeconfig=admin.kubeconfig

mkdir -p ~/.kube
cp /root/certificates/admin.kubeconfig ~/.kube/config

kubectl get componentstatuses
