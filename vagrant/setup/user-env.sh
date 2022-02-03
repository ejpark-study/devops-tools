#!/usr/bin/env bash

echo "### user-env.sh"
set -x #echo on

# oh my zsh
wget "https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh" -O - | zsh || true

git clone --depth=1 "https://github.com/jonmosco/kube-ps1" ~/.kube-ps1
git clone --depth=1 "https://github.com/zsh-users/zsh-completions.git" ~/.oh-my-zsh/plugins/zsh-completions
git clone --depth=1 "https://github.com/zsh-users/zsh-autosuggestions.git" ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone --depth=1 "https://github.com/zsh-users/zsh-syntax-highlighting.git" ~/.oh-my-zsh/plugins/zsh-syntax-highlighting

cat /etc/skel/.zshrc > ~/.zshrc

# change user zsh
sudo sed -i -e 's#/home/ubuntu:/bin/bash#/home/ubuntu:/usr/bin/zsh#' /etc/passwd
sudo sed -i -e 's#/home/vagrant:/bin/bash#/home/vagrant:/usr/bin/zsh#' /etc/passwd

# krew 설치
krew install krew

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
kubectl krew update

kubectl krew install ctx
kubectl krew install ns
kubectl krew install konfig
kubectl krew install neat
