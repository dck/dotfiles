export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
export WORDCHARS=''

setopt prompt_subst

setopt pushd_ignore_dups
setopt pushd_to_home

setopt complete_aliases
setopt complete_in_word
setopt glob_complete
setopt NO_list_ambiguous
setopt NO_list_beep

setopt NO_hist_beep
setopt hist_ignore_dups
setopt hist_ignore_space
setopt inc_append_history
setopt share_history
HISTSIZE=10000000
SAVEHIST=10000000

autoload -U compinit && compinit
autoload -U colors && colors
autoload -Uz vcs_info

precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'

PROMPT='%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[green]%}%m%{$reset_color%}: %{$fg[yellow]%}${PWD/#$HOME/~}%{$reset_color%}%{$fg[blue]%}${vcs_info_msg_0_}%{$reset_color%} $ '

. /opt/homebrew/opt/asdf/libexec/asdf.sh
