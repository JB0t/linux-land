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
    # __git_ps1 resets to the default after its colour hints, so turn its
    # resets back into purple for the rest of the prompt.
    _git_ps1_purple(){
        local s
        s=$(__git_ps1 " (%s)")
        printf '%s' "${s//$'\e[0m'/$'\e[0;95m'}"
    }
    export PS1='\[\e[0;95m\][\[\e[0;36m\]\u\[\e[0;95m\]@\[\e[1;34m\]\h\[\e[0;95m\] \W$(_git_ps1_purple)]\[\e[0;35m\]\$\[\e[0m\] '
fi