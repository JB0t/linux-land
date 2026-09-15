#!/bin/bash

export GIT_PS1=true
if [[ ! -z "$GIT_PS1" ]]; then
    export GIT_PS1_SHOWCOLORHINTS=true
    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUNTRACKEDFILES=true
    export GIT_PS1_SHOWUPSTREAM=true
	source "$HOME/.git-prompt.sh"
    export PS1='\[\e[0m\][\[\e[0;36m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \W$(__git_ps1 " (%s)")\[\e[0m\]]\[\e[0;35m\]\$\[\e[0m\] '
fi