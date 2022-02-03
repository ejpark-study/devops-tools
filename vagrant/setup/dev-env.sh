#!/usr/bin/env bash

echo "### dev-env.sh"
set -x #echo on

export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true
export LANG=C.UTF-8 LC_ALL=C.UTF-8
export NOTVISIBLE="in users profile"

apt update -yq

apt install -yqq \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv
