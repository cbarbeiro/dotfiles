#!/bin/bash
########################################################
#|# Preamble                                         #
########################################################
# If running non interactively, do nothing
[ -z "$PS1" ] && return

# Determine platform first
export platform='unknown'
uname=$(uname)
if [[ "x${uname}" == "xDarwin" ]]; then
    export platform='mac'
elif [[ "x${uname}" == "xLinux" ]]; then
    export platform='linux'
fi

export hostname='unknown'
if command -v hostname >/dev/null; then
    export hostname=$(hostname)
fi

export dnsdomainname='unknown'
if command -v dnsdomainname >/dev/null; then
    export dnsdomainname=$(dnsdomainname)
fi

########################################################
#|# General, PATH	                                   #
########################################################
alias dirbashrc="grep -nT '^#|' ~/.bash*"
alias bashrc="vim ~/.bashrc"
alias rebash='source ~/.bashrc'

# Prompt
export PS1='\[\033[38;5;12m\][\[\]\[\033[38;5;10m\]\u\[\]\[\033[38;5;12m\]@\[\]\[\033[38;5;7m\]\h\[\]\[\033[38;5;12m\]]\[\]\[\033[38;5;15m\]  \[\]\[\033[38;5;7m\]\w\[\]\[\033[38;5;12m\]\n>\[\]\[\033[38;5;10m\]\$\[\]\[\033[38;5;15m\] \[\]'

########################################################
#|# Bash configs	                                   #
########################################################

shopt -s cdspell
shopt -s histappend
shopt -s expand_aliases
shopt -s lithist
shopt -s extglob
set show-all-if-ambiguous on

# enable smart history search
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

########################################################
#|# Platform Specifics                                 #
########################################################

########################################################
#|# Host Specifics                                     #
########################################################

########################################################
#|## MILNAS											   #
########################################################
if [[ "x$(hostname)" = "xarchThrone" ]]; then
    #Load all bash personal scripts 
	for script in bash_aliases bash_functions bash_exports
	do
		source ~/.${script}
	done
fi

