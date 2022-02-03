#!/usr/bin/env bash

echo "### kubernetes.sh"
set -x #echo on

K8S_VERSION=$1

apt update -yq

apt install -yq \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    dconf-cli \
    gnupg \
    gpg \
    libcurl4-openssl-dev \
    libssl-dev \
    software-properties-common \
    vim

# Letting iptables see bridged traffic
cat <<EOF1 | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF1

sysctl --system

# kubernetes repo
curl -k -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" | apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

apt update -yq
apt install -yqq --allow-downgrades --allow-change-held-packages \
  kubelet=${K8S_VERSION}-00 \
  kubectl=${K8S_VERSION}-00 \
  kubeadm=${K8S_VERSION}-00

apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet && systemctl start kubelet

kubeadm config images pull

# calico ctl
curl -L https://github.com/projectcalico/calico/releases/download/v3.21.4/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
chmod +x /usr/local/bin/calicoctl

# cilium ctl
curl -LO https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin && rm cilium-linux-amd64.tar.gz

#cilium install
