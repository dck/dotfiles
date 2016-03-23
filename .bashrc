export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
shopt -s histappend
shopt -s cmdhist
export HISTCONTROL="ignoredups"
export HISTSIZE=5000
export PS1="\[\e[36m\]\u\[\e[m\]@\[\e[32m\]\h:\[\e[33m\] \w\[\e[m\]\[\e[34m\]\$(parse_git_branch)\[\e[00m\] \$ "

eval "$(rbenv init -)"

if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

export PIP_REQUIRE_VIRTUALENV=true
export HOMEBREW_GITHUB_API_TOKEN= # token

parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function set_color_schema() {
  echo -ne "\033]50;SetProfile=$1\a"
}

function colorssh() {
  set_color_schema SSH
  ssh $*
  set_color_schema Solarized
}

alias ssh="colorssh"
alias be='bundle exec'
