#!/bin/bash

export GIT_PS1=true
if [[ ! -z "$GIT_PS1" ]]; then
    export GIT_PS1_SHOWCOLORHINTS=true
    export GIT_PS1_SHOWDIRTYSTATE=true
    export GIT_PS1_SHOWUNTRACKEDFILES=true
    export GIT_PS1_SHOWUPSTREAM=true
	source "$HOME/.git-prompt.sh"
    # Explicit colours throughout: \e[0m (terminal default fg) can be
    # unreadable on transparent terminals. 95 = bright magenta (purple).
    export PS1='\[\e[0;95m\][\[\e[0;36m\]\u\[\e[0;95m\]@\[\e[1;34m\]\h\[\e[0;95m\] \W$(__git_ps1 " (%s)")]\[\e[0;35m\]\$\[\e[0m\] '
fi