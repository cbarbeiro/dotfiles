########################################################
#|## Alias Tips                                        #
########################################################
# Disable aliases by prefixing with '\':
# $\grep
# Do not save in history by prefixing with ' '(space):
# $ grep

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
alias ls='ls --color=always --format=vertical --group-directories-first'
alias ll='ls -l'
alias la='ls -la'
alias lsdir='ls -l --color=always | grep -e "^d"'  # list only directories
alias lsfiles='ls -l --color=always | grep -ve "^d"'  # list only files
alias lsfilesall='ls -la --color=always | grep -ve "^d"'  # list all (incl. hidden) files
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
alias findexe='find $(path) -type f -prune -executable | cut -d':' -f1 | \grep --color=always'

########################################################
#|## Package Management                                #
########################################################
alias pacmanss='pacman -Ss'
alias pacmans='sudo pacman -S'
alias pacmanu='sudo pacman -U'
alias pacmansyu='sudo pacman -Syu --ignore $PACMAN_IGNORE'
alias pacmanrns='sudo pacman -Rns'
alias pacmanqs='pacman -Qs' #Search packages locally
alias pacmanqo='pacman -Qo' #Which package owns file?
alias pacmanqi='pacman -Qi' #Info about a package
alias packerss='packer -Ss'
alias packers='packer -S'

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
alias getmyip='curl http://ipecho.net/plain; echo -e \"\n\"'
alias echo="echo -e"
alias edit-aliases='vim ~/.bash_aliases'
alias edit-exports='vim ~/.bash_exports'
alias edit-functions='vim ~/.bash_functions'
alias paclog='paclog --color | less -R'
alias term='gnome-terminal'
########################################################
#|## SSH                                               #
########################################################
alias ssh-agent='exec ssh-agent bash -i <<< "echo Secure Session; exec </dev/tty"'
alias ssh-list='ssh-add -l'
alias ssh-lock='ssh-add -x'
alias ssh-unlock='ssh-add -X'

########################################################
#|## ChromeCast                                        #
########################################################
alias cast='castnow'
alias cast-transcode='castnow --transcoder ffmpeg --transcode'
alias cast-gnome='gnomecast &&'
alias cast-converter='chromecastize.sh --mkv'

# Make the bash feel smoother
# correct common typos
alias sl='ls'
alias ivm='vim'
alias dc='cd'
alias db='bd'
