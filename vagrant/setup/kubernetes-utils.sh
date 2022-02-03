#!/usr/bin/env bash

echo "### kubernetes-utils.sh"
set -x #echo on

# kubernetes utils
echo && echo "# helm 설치"
curl -fsSL -o /tmp/get_helm.sh "https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3"
bash /tmp/get_helm.sh

echo && echo "# k9s 설치"
export K9S_VER="v0.25.18"

wget -q -O /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VER}/k9s_Linux_x86_64.tar.gz"
tar xvfz /tmp/k9s.tar.gz -C /tmp && mv /tmp/k9s /usr/bin/

echo && echo "# stern 설치"
export STERN_VER="1.11.0"

wget -q -O /usr/bin/stern "https://github.com/wercker/stern/releases/download/${STERN_VER}/stern_linux_amd64"
chmod +x /usr/bin/stern

echo && echo "# krew 설치"
wget -q -O /tmp/krew.tar.gz "https://github.com/kubernetes-sigs/krew/releases/download/v0.4.2/krew-linux_amd64.tar.gz"
tar zxvf /tmp/krew.tar.gz -C /tmp && mv /tmp/krew-linux_amd64 /usr/bin/krew && chmod +x /usr/bin/krew
