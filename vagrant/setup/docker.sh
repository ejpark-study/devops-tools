#!/usr/bin/env bash

echo "### docker.sh"
set -x #echo on

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

# docker repo
curl -k -fsSL "https://download.docker.com/linux/ubuntu/gpg" | apt-key add -
apt-add-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

apt update -yq
apt install -yqq docker-ce

# Cgroup Driver systemd
mkdir -p /etc/docker
cat <<EOF | tee /etc/docker/daemon.json
{
  "bip": "10.10.0.1/16",
  "default-address-pools":[
    {"base":"10.11.0.0/16","size":24},
    {"base":"10.12.0.0/16","size":24}
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "dns": [
    "8.8.8.8"
  ],
  "registry-mirrors": [
    "https://mirror.gcr.io"
  ],
  "insecure-registries": [
  ]
}
EOF

systemctl daemon-reload && systemctl restart docker

# docker
systemctl enable docker

usermod -aG docker ubuntu
usermod -aG docker vagrant
