########################################################
#|## Folder Navigation                                 #
########################################################
alias ..='bd'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'
alias dirs='dirs -v'

########################################################
#|## Listings                                          #
########################################################
alias ls='ls --color=always --format=horizontal'
alias lsdir='ls -l --color=always | grep -e "^d"'  # list only directories
alias grep='grep --color=always -n'

########################################################
#|## File Management                                   #
########################################################
alias cp='cp -irv'
alias mv='mv -iv'
alias rm='rm -dIv --preserve-root'
alias ln='ln -iv'
alias mkdir='mkdir -pv'
alias diff='colordiff'

########################################################
#|## Package Management                                #
########################################################
alias pacmans='sudo pacman -S'
alias pacmanss='pacman -Ss'
alias pacmansyu='sudo pacman -Syu'
alias pacmanrns='sudo pacman -Rns'

########################################################
#|## OS Management                                     #
########################################################
alias df='df -h | sort -k5 -r'
alias du='du -hc'
alias free='free -hlt'
alias pkill='pkill -e'

########################################################
#|## Miscellaneous                                     #
########################################################
alias getmyip="curl http://ipecho.net/plain"

# Make the bash feel smoother
# correct common typos
alias sl='ls'
alias ivm='vim'
alias dc='cd'
alias db='bd'
