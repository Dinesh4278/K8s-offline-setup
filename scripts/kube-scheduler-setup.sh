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
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.crt \
    --client-key=kube-scheduler.key \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context default \
    --cluster=kubernetes-from-scratch \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig

cp kube-scheduler.kubeconfig /var/lib/kubernetes/

cp /data/services/kube-scheduler.service /etc/systemd/system/

cp /root/binaries/kubernetes/server/bin/kube-scheduler /usr/local/bin

systemctl daemon-reload
systemctl start kube-scheduler
systemctl status kube-scheduler --no-pager
systemctl enable kube-scheduler
