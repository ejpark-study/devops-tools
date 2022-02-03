#!/usr/bin/env bash

echo "### apt-mirror.sh"
set -x #echo on

sed -i.original 's/archive.ubuntu.com/mirror.kakao.com/' /etc/apt/sources.list
