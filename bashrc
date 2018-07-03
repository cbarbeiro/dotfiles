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
#|# General, PATH	                               #
########################################################
[ -e "/etc/DIR_COLORS" ] && DIR_COLORS="/etc/DIR_COLORS"
[ -e "$HOME/.dircolors" ] && DIR_COLORS="$HOME/.dircolors"
eval "`dircolors -b $DIR_COLORS`"

# Prompt
export PS1='\[\033[38;5;12m\][\[\033[38;5;10m\]\u\[\033[38;5;12m\]@\[\033[38;5;7m\]\h\[\033[38;5;12m\]]\[\033[38;5;15m\] \[\033[38;5;7m\]\w\[\033[38;5;12m\]\n|$?>\[\033[38;5;10m\]\$\[\033[38;5;15m\] '

########################################################
#|# Bash configs	                               #
########################################################

shopt -s cdspell
shopt -s dirspell
shopt -s histappend
shopt -s expand_aliases
shopt -s lithist
shopt -s extglob

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
#|## MILNAS - casa					#
########################################################
if [[ "x$(hostname)" = "xarchThrone" ]]; then
    #Load personal configs
    export ANDROID_HOME=/opt/android-sdk
	export PACMAN_IGNORE="\"\""
	alias pacmansyu='sudo pacman -Syu --ignore $PACMAN_IGNORE'
	
	#Load all bash personal scripts 
	for script in bash_aliases bash_functions bash_exports
	do
		source ~/.${script}
	done
	
	#overrides
fi

########################################################
#|## work						#
########################################################
if [[ "x$(hostname)" = "xarchOfThrones" ]]; then
    #Turn off the bell sound
	xset -b
    #Load work configs
	export ANDROID_HOME=/home/ivo/Android/Sdk
	export ANDROID_BIN="$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin"
	export WIT_HOME=~/WIT
	export WMC_SCRIPTS=~/WIT/witlab-wmc/temp/scripts/
	export PATH="$PATH:$WIT_HOME:$WMC_SCRIPTS:$ANDROID_BIN"
    
        #Load all bash personal scripts 
	for script in bash_aliases bash_functions bash_exports
	do
		source ~/.${script}
	done
fi

