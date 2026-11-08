# ~/.bash_profile, symlinked from linux-land on macOS only (on Linux,
# ~/.profile already does this). macOS terminals start login shells, which
# read this instead of ~/.bashrc.
export BASH_SILENCE_DEPRECATION_WARNING=1
[ -f ~/.bashrc ] && . ~/.bashrc
