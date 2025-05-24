#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <MASTER_IP>"
    exit 1
fi

MASTER_IP="$1"

cp /root/binaries/kubernetes/server/bin/kubectl /usr/local/bin

cd /root/certificates || exit 1

kubectl config set-cluster kubernetes-from-scratch \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${MASTER_IP}:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.crt \
    --client-key=kube-controller-manager.key \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig

cp kube-controller-manager.crt kube-controller-manager.key kube-controller-manager.kubeconfig ca.key /var/lib/kubernetes/

cp /data/services/kube-controller-manager.service /etc/systemd/system/

cp /root/binaries/kubernetes/server/bin/kube-controller-manager /usr/local/bin

systemctl daemon-reload
systemctl start kube-controller-manager
systemctl status kube-controller-manager --no-pager
systemctl enable kube-controller-manager
