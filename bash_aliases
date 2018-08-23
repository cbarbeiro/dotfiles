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
alias lsdirall='ls -la --color=always | grep -e "^d"'  # list all (incl. hidden) directories
alias lsfiles='ls -l --color=always | grep -ve "^d"'  # list only files
alias lsfilesall='ls -la --color=always | grep -ve "^d"'  # list all (incl. hidden) files

########################################################
#|## File Management                                   #
########################################################
alias cp='cp -irv'
alias mv='mv -iv'
alias rm='rm -dIv --preserve-root'
alias ln='ln -iv'
alias mkdir='mkdir -pv'
alias diff='colordiff -W $(( $(tput cols) - 2))'
alias findexe='find $(path) -type f -prune -executable | cut -d':' -f1 | \grep --color=always'

########################################################
#|## Package Management                                #
########################################################
alias pacmanss='pacman -Ss'	#Search packages in official repos
alias pacmans='sudo pacman -S'	#Install packages from official repos
alias pacmanu='sudo pacman -U'	#Install local packages
alias pacmansyu='sudo pacman -Syu'	#Update system
alias pacmanrns='sudo pacman -Rns'	#Remove package and dependecies
alias pacmanqs='pacman -Qs'	#Search packages locally
alias pacmanqo='pacman -Qo'	#Which package owns file?
alias pacmanql='pacman -Ql'	#Which files are owned by package?
alias pacmanqi='pacman -Qi'	#Info about a package
alias pacmanorphans='pacman -Qtdq' #List orphan packages
alias packerss='packer -Ss'	#Search packages in AUR
alias packers='packer -S'	#Install package from AUR
alias packersyu='packer -Syu'	#Update system and AUR
alias paclog='paclog --color | less -R' #Read pacman log

########################################################
#|## OS Management                                     #
########################################################
alias df='df -hT | sort -k5 -r'
alias du='du -hc'
alias free='free -hlt'
alias pkill='pkill -e'

########################################################
#|## GIT                                               #
########################################################
alias gg="git gui"
alias gk="gitk"
alias gst="git status"
alias gdiff="git diff"
alias gpwd="git status | head -n1 | sed 's,On branch ,,'"

########################################################
#|## SSH                                               #
########################################################
alias ssh-agent='exec ssh-agent bash -i <<< "echo Secure Session; exec </dev/tty"'
alias ssh-add-isilva='ssh-add ~/.ssh/isilva_wit'
alias ssh-list='ssh-add -l'
alias ssh-lock='ssh-add -x'
alias ssh-unlock='ssh-add -X'

########################################################
#|## ChromeCast                                        #
########################################################
alias cast-transcode='castnow --transcoder ffmpeg --transcode'
alias cast-converter='chromecastize.sh --mkv'

########################################################
#|## Miscellaneous                                     #
########################################################
alias source-work="source $DOTFILES/work_env/*"
alias calc="galculator"
alias getmyip='curl http://ipecho.net/plain; echo -e \"\n\"'
alias echo="echo -e"
alias lsol='cat $DOTFILES/cool_oneliners'
alias edit-ol='vim $DOTFILES/cool_oneliners'
alias edit-aliases='vim ~/.bash_aliases'
alias edit-exports='vim ~/.bash_exports'
alias edit-functions='vim ~/.bash_functions'
alias edit-bashrc="vim ~/.bashrc"
alias term='gnome-terminal'
alias src='src-hilite-lesspipe.sh' 
alias lessf='less +F'
alias lessr='less -R'
alias grep='grep --color=always -n'
alias grepr='\grep --color=always -RnsI' #don't forget to add * after the #haystack
alias colorpicker='com.github.ronnydo.colorpicker'

# Make the bash feel smoother
# correct common typos
alias l='ls'
alias sl='ls'
alias ks='ls'
alias çç='ll'
alias ivm='vim'
alias dc='cd'
alias c='cd'
alias db='bd'
alias gut='git'
alias giy='git'
alias exot='exit'
alias exut='exit'
alias eixt='exit'
