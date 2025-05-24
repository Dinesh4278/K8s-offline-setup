#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <MASTER_IP> <ENCRYPTION_KEY>"
    exit 1
fi

MASTER_IP="$1"
ENCRYPTION_KEY="$2"

cd /root/binaries/kubernetes/server/bin/ || exit 1
cp kube-apiserver /usr/local/bin/

mkdir -p /var/lib/kubernetes

cd /root/certificates || exit 1
cp etcd.crt etcd.key ca.crt kube-api.key kube-api.crt service-account.crt service-account.key /var/lib/kubernetes

sed "s|\${ENCRYPTION_KEY}|$ENCRYPTION_KEY|g" /data/yaml/encryption-at-rest.yaml > encryption-at-rest.yaml
cp encryption-at-rest.yaml /var/lib/kubernetes/encryption-at-rest.yaml

sed "s|\${MASTER_IP}|$MASTER_IP|g" /data/services/kube-apiserver.service > kube-apiserver.service
cp kube-apiserver.service /etc/systemd/system/

systemctl daemon-reload
systemctl start kube-apiserver
systemctl status kube-apiserver --no-pager
systemctl enable kube-apiserver
