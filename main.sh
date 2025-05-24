#!/bin/bash

if [ "$#" -lt 4 ]; then
    echo "Usage: $0 <MASTER_IP> <WORKER_IP1>:<WORKER_HOSTNAME1> [<WORKER_IP2>:<WORKER_HOSTNAME2> ...] <SSH_USER>"
    exit 1
fi

MASTER_IP="$1"
SSH_USER="${!#}"
PACKAGES_PATH="packages.tar.gz"
WORKER_ENTRIES=("${@:2:$#-2}")

# Upload to master node once
echo "Sending packages to master: $MASTER_IP"
scp -o StrictHostKeyChecking=no "$PACKAGES_PATH" "$SSH_USER@$MASTER_IP:/data"
sleep 10

# One-time master setup
./scripts/master-initial-setup.sh "$MASTER_IP" "$SSH_USER"
sleep 10
./scripts/certificates-generation.sh "$MASTER_IP"
sleep 10
./scripts/etcd-setup.sh "$MASTER_IP"
sleep 10

# Generate a shared encryption key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
./scripts/kube-apiserver-setup.sh "$MASTER_IP" "$ENCRYPTION_KEY"
sleep 10
./scripts/kube-controller-setup.sh "$MASTER_IP"
sleep 10
./scripts/kube-scheduler-setup.sh "$MASTER_IP"
sleep 10
./scripts/admin-kubeconfig-setup.sh "$MASTER_IP"
sleep 10


i=0
# Loop through each worker IP:hostname pair
for ENTRY in "${WORKER_ENTRIES[@]}"; do
    WORKER_IP="${ENTRY%%:*}"
    WORKER_HOSTNAME="${ENTRY##*:}"

    echo "Starting setup for worker: $WORKER_HOSTNAME ($WORKER_IP)"

    # 1. Send packages
    echo "Sending packages to $WORKER_HOSTNAME"
    scp -o StrictHostKeyChecking=no "$PACKAGES_PATH" "$SSH_USER@$WORKER_IP:/data"
    sleep 10

    # 2. Initial worker setup
    ./scripts/worker-initial-setup.sh "$WORKER_IP" "$SSH_USER"
    sleep 10

    # 3. Certificate Generation
    cd /root/certificates || { echo "Failed to enter /root/certificates"; exit 1; }
    echo "Generating kubelet & kube-proxy certificates for $WORKER_HOSTNAME"
    openssl genrsa -out worker.key 2048
    sed -e "s|\${WORKER_HOSTNAME}|$WORKER_HOSTNAME|g" -e "s|\${WORKER_IP}|$WORKER_IP|g" /data/configuration/openssl-worker.cnf > openssl-worker.cnf
    openssl req -new -key worker.key -subj "/CN=system:node:$WORKER_HOSTNAME/O=system:nodes" -out worker.csr -config openssl-worker.cnf
    openssl x509 -req -in worker.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out worker.crt -extensions v3_req -extfile openssl-worker.cnf -days 1000

    openssl genrsa -out kube-proxy.key 2048
    openssl req -new -key kube-proxy.key -subj "/CN=system:kube-proxy" -out kube-proxy.csr
    openssl x509 -req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kube-proxy.crt -days 1000

    echo "Transferring certificates to $WORKER_HOSTNAME"
    scp -o StrictHostKeyChecking=no kube-proxy.crt kube-proxy.key worker.crt worker.key ca.crt "$SSH_USER@$WORKER_IP:/tmp"
    echo "Certificate transfer completed"
    sleep 10
    cd ~
    # 4. Worker-specific setup scripts
    ./scripts/cm-worker.sh "$WORKER_IP" "$SSH_USER"
    sleep 10
    ./scripts/containerd-setup.sh "$WORKER_IP" "$SSH_USER"
    sleep 10
    ./scripts/kubelet-setup.sh "$MASTER_IP" "$WORKER_IP" "$SSH_USER"
    sleep 10
    ./scripts/kubeproxy-setup.sh "$MASTER_IP" "$WORKER_IP" "$SSH_USER"
    sleep 10
    ./scripts/cni-plugins-setup.sh "$WORKER_IP" "$SSH_USER"
    sleep 10
    if [ "$i" -eq 0 ]; then
        kubectl create -f /data/yaml/tigera-operator.yaml
        sleep 30
        kubectl create -f /data/yaml/calico-custom-resources.yaml
        sleep 40
	ssh -o StrictHostKeyChecking=no root@${WORKER_IP} "systemctl restart kubelet"
	sleep 10
        kubectl apply -f /data/yaml/coredns.yaml
        sleep 30
        kubectl apply -f /data/yaml/api-kubelet-rbac.yaml
    else
        echo "Skipping applying of CNI manifest files"
    fi
    if [ "$i" -gt 1 ]; then
        ssh -o StrictHostKeyChecking=no root@${WORKER_IP} "systemctl restart kubelet"
    fi

    ((i++))
done

