########################################################
#|## Folder Navigation                                 #
########################################################
alias ..='echo "Did you mean bd or cdup?"'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'
alias dirs='dirs -v'

alias gt-home='cd ~'
alias gt-documents='cd ~/Documents'
alias gt-videos='cd ~/Videos'
alias gt-downloads='cd ~/Downloads'
alias gt-music='cd ~/Music'
alias gt-pictures='cd ~/Pictures'
alias gt-reviews='cd ~/work/udacity/yourFirstAppReviews'

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
