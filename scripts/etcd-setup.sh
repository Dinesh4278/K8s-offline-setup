#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <MASTER_IP>"
    exit 1
fi

MASTER_IP="$1"

mkdir -p /etc/etcd

cd /root/certificates || exit 1
cp etcd.crt etcd.key ca.crt /etc/etcd

cd /root/binaries/etcd-v3.5.18-linux-amd64/ || exit 1
cp etcd etcdctl /usr/local/bin/

sed "s|\${MASTER_IP}|$MASTER_IP|g" /data/services/etcd.service > /etc/systemd/system/etcd.service

systemctl daemon-reload
systemctl start etcd
systemctl status etcd --no-pager
systemctl enable etcd
