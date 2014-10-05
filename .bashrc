#aliases

alias cj='caja .'
#alias mc="printf '\e[8;30;100t'; mc"
#alias vim="printf '\e[8;33;105t'; vim"

# variables
export LC_TIME=en_US.UTF-8

export TERM=xterm-256color
export GOPATH=$HOME/work/golang

# bash history options
# http://habrahabr.ru/post/31326/
shopt -s histappend
shopt -s cmdhist
PROMPT_COMMAND='history -a'
export HISTCONTROL="ignoredups"
export HISTSIZE=1000
