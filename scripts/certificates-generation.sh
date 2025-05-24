#!/bin/bash

# Ensure exactly three arguments are provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <MASTER_IP>"
    exit 1
fi

# Assigning command-line arguments correctly
MASTER_IP="$1"

# Create directory for certificates
mkdir -p /root/certificates
cd /root/certificates || { echo "Failed to enter /root/certificates"; exit 1; }

echo "Generating CA key, CSR, and certificate..."
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -subj "/CN=KUBERNETES-CA" -out ca.csr
openssl x509 -req -in ca.csr -signkey ca.key -out ca.crt -days 1000

echo "Generating etcd certificates..."
openssl genrsa -out etcd.key 2048
sed "s|\${MASTER_IP}|$MASTER_IP|g" /data/configuration/etcd.cnf > etcd.cnf
openssl req -new -key etcd.key -subj "/CN=etcd" -out etcd.csr -config etcd.cnf
openssl x509 -req -in etcd.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out etcd.crt -extensions v3_req -extfile etcd.cnf -days 1000

echo "Generating API server certificates..."
openssl genrsa -out kube-api.key 2048
sed "s|\${MASTER_IP}|$MASTER_IP|g" /data/configuration/api.cnf > api.cnf
openssl req -new -key kube-api.key -subj "/CN=kube-apiserver" -out kube-api.csr -config api.cnf
openssl x509 -req -in kube-api.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-api.crt -extensions v3_req -extfile api.cnf -days 1000

echo "Generating service account certificates..."
openssl genrsa -out service-account.key 2048
openssl req -new -key service-account.key -subj "/CN=service-accounts" -out service-account.csr
openssl x509 -req -in service-account.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out service-account.crt -days 100

echo "Generating controller manager certificates..."
openssl genrsa -out kube-controller-manager.key 2048
openssl req -new -key kube-controller-manager.key -subj "/CN=system:kube-controller-manager" -out kube-controller-manager.csr
openssl x509 -req -in kube-controller-manager.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-controller-manager.crt -days 1000

echo "Generating scheduler certificates..."
openssl genrsa -out kube-scheduler.key 2048
openssl req -new -key kube-scheduler.key -subj "/CN=system:kube-scheduler" -out kube-scheduler.csr
openssl x509 -req -in kube-scheduler.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-scheduler.crt -days 1000

echo "Generating admin user certificates..."
openssl genrsa -out admin.key 2048
openssl req -new -key admin.key -subj "/CN=admin/O=system:masters" -out admin.csr
openssl x509 -req -in admin.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out admin.crt -days 1000

