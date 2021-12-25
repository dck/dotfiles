export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd 

setopt prompt_subst

setopt pushd_ignore_dups
setopt pushd_to_home

setopt NO_hist_beep
setopt hist_ignore_dups
setopt hist_ignore_space
setopt inc_append_history

autoload -U compinit && compinit

autoload -Uz vcs_info
autoload -U colors && colors
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
#PROMPT='$fg[cyan]%n$reset_color@$fg[green]%m$reset_color: $fg[yellow]${PWD/#$HOME/~}$fg[blue]${vcs_info_msg_0_}$reset_color $ '
#PROMPT='%{$fg[cyan]%}%n%{$reset_color$%} '

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

. /opt/homebrew/opt/asdf/libexec/asdf.sh
