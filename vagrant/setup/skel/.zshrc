
export ZSH=${HOME}/.oh-my-zsh

ZSH_THEME="agnoster"

DISABLE_AUTO_UPDATE="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# plugins
plugins=(
    git
    history
    python
    pip
    sudo
    vscode
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    z
)

if [[ -f $(which tmux) ]]; then
    plugins+=(tmux)
fi

if [[ -f $(which npm) ]]; then
    plugins+=(npm)
fi

if [[ -f $(which docker) ]]; then
    plugins+=(docker)
fi

if [[ -f $(which kubectl) ]]; then
    plugins+=(kubectl kube-ps1)
    source <(kubectl completion zsh)
fi

source $ZSH/oh-my-zsh.sh

# krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# prompt
prompt_newline() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR
%(?.%F{$CURRENT_BG}.%F{red})❯%f"

  else
    echo -n "%{%k%}"
  fi

  echo -n "%{%f%}"
  CURRENT_BG=''
}

build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_dir
  prompt_git
  prompt_bzr
  prompt_hg
  prompt_newline # 멀티라인 적용
  prompt_end
}

if [[ $(type kube_ps1) == *"shell function"* ]]; then
  export PS1='$(kube_ps1) '$PS1
fi

# 로케일 설정
export LANG=ko_KR.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# 기본 에디터 설정
export EDITOR=vim
export PYTHONWARNINGS="ignore:Unverified HTTPS request"

# time 포멧
export TIME="\n실행 시간: %E, 사용자: %U, 시스템: %S, CPU: %P, 전체: %e"

alias time=/usr/bin/time

# ulimit: set limit file open handle
ulimit -n 4096

# PATH
export PATH=.:$(echo "$PATH" | awk -v RS=':' -v ORS=":" '!a[$1]++{if (NR > 1) printf ORS; printf $a[$1]}')
