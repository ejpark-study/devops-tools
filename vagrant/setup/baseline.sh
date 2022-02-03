#!/usr/bin/env bash

echo "### baseline.sh"
set -x #echo on

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export NOTVISIBLE="in users profile"

apt update -yq

apt install -yqq \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    dconf-cli \
    gnupg \
    gpg \
    libcurl4-openssl-dev \
    libssl-dev \
    software-properties-common

apt install -yqq \
    augeas-tools \
    bash \
    bzip2 \
    cmake \
    curl \
    git \
    htop \
    jq \
    less \
    libdb-dev \
    locales \
    make \
    p7zip \
    parallel \
    pbzip2 \
    perl \
    progress \
    rename \
    sqlite \
    sudo \
    tmux \
    tzdata \
    unzip \
    vim \
    wget \
    zsh

apt install -yqq \
    arp-scan \
    bridge-utils \
    conntrack \
    etcd-client \
    net-tools \
    nmap \
    resolvconf \
    tree \
    wireguard

apt upgrade -yqq

# locale
locale-gen "en_US.UTF-8"
locale-gen "ko_KR.UTF-8"
locale-gen "ko_KR.EUC-KR"
update-locale LANG=ko_KR.UTF-8
# dpkg-reconfigure --frontend noninteractive locales

# timezone
ln -fs /usr/share/zoneinfo/Asia/Seoul /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# nopasswd
cat /etc/sudoers | perl -ple 's/(.+sudo.+) ALL/$1 NOPASSWD:ALL/g' > /tmp/sudoers
cat /tmp/sudoers > /etc/sudoers

# swapoff
swapoff -a
sed -i '/swap/d' /etc/fstab

# clean tmp
apt autoremove -yqq
rm -rf /tmp/* /var/cache/* /var/lib/apt/lists/* /var/tmp/* /var/log/* /root/.cache
