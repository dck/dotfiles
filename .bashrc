#aliases

alias cj='caja .'
#alias mc="printf '\e[8;30;100t'; mc"
#alias vim="printf '\e[8;33;105t'; vim"

export TERM=xterm-256color
export GOPATH=$HOME/work/golang

# bash history options
# http://habrahabr.ru/post/31326/
shopt -s histappend
shopt -s cmdhist
PROMPT_COMMAND='history -a'
export HISTCONTROL="ignoredups"
export HISTSIZE=5000

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

export PS1="\[\e[36m\]\u\[\e[m\]@\[\e[32m\]\h:\[\e[33;1m\] \w\[\e[m\]\[\e[34m\]\$(parse_git_branch)\[\e[00m\] \$ "
alias be='bundle exec'
