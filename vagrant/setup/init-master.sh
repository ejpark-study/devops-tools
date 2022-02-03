#!/usr/bin/env bash

echo "### init-master.sh"
set -x #echo on

MASTER_IP=$1
SVC_CIDR=$2
POD_NETWORK_CIDR=$3
CONTEXT_NAME=$4

kubeadm reset -f

# init kubernetes
kubeadm init --v=5 \
  --apiserver-advertise-address=${MASTER_IP} \
  --service-cidr=${SVC_CIDR} \
  --pod-network-cidr=${POD_NETWORK_CIDR} \
  | grep -Ei "kubeadm join|discovery-token-ca-cert-hash" > /vagrant/join.sh

# config for master node only
mkdir -p /home/vagrant/.kube
cat /etc/kubernetes/admin.conf > /home/vagrant/.kube/vagrant
chown vagrant:vagrant /home/vagrant/.kube/vagrant

# context name
KUBECONFIG=~/.kube/vagrant kubectl config rename-context "kubernetes-admin@kubernetes" ${CONTEXT_NAME}

# etcdctl install
apt install -yqq etcd-client

wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O metrics-server.yaml

#vim +134 metrics-server.yaml
#     - args:
#        - --kubelet-insecure-tls
#        (...)
#        image: k8s.gcr.io/metrics-server/metrics-server:v0.4.1
#
#kubectl create -f metrics-server.yaml
