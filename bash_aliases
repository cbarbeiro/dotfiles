########################################################
#|# Folder Navigation                                  #
########################################################
alias ..='bd'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'
alias dirs='dirs -v'
alias nemo='nemo .'

########################################################
#|# Listings                                           #
########################################################
alias ls='ls -AF --color=always --format=vertical --group-directories-first'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias lr='ls -lhAR'
alias lsdir='ls -l --color=always | grep -e "^d"'  # list only directories
alias lsdirall='ls -la --color=always | grep -e "^d"'  # list all (incl. hidden) directories
alias lsfiles='ls -l --color=always | grep -ve "^d"'  # list only files
alias lsfilesall='ls -la --color=always | grep -ve "^d"'  # list all (incl. hidden) files

########################################################
#|# File Management                                    #
########################################################
alias cp='cp -irv'
alias mv='mv -iv'
alias rm='rm -dIv --preserve-root'
alias ln='ln -iv'
alias mkdir='mkdir -pv'
alias diff='colordiff -W $(( $(tput cols) - 2))'
alias findexe='find $(path) -type f -prune -executable | cut -d':' -f1 | \grep --color=always'

########################################################
#|# Package Management                                 #
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
#|# OS Management                                      #
########################################################
alias df='df -hT | sort -k5 -r'
alias du='du -hc'
alias ds='du -khs *|sort -h'     # find the biggest file or directory in the current directory.
alias big='du -ah . | sort -rh | head -40'  # List top ten largest files/directories in current directory
alias free='free -hlt'
alias pkill='pkill -e'
alias psmem='ps -o time,ppid,pid,nice,pcpu,pmem,user,comm -A | sort -n -k 6 | tail -15' # What's gobbling the memory?
alias freq='cut -f1 -d" " ~/.bash_history | sort | uniq -c | sort -nr | head -n 30' # Show which commands you use the most
alias netlisteners='lsof -i -P | grep LISTEN'   # Show active network listeners
alias fix-file-perms='find * -type d -print0 | xargs -0 chmod 0755'
alias fix-dir-perms='find . -type f -print0 | xargs -0 chmod 0644'

########################################################
#|# GIT                                                #
########################################################
alias cdgitroot='cd "$(git rev-parse --show-toplevel 2> /dev/null)"'                  # git cd root of project
alias gg='git gui'
alias gk='gitk'
alias gst='git status'
alias gdiff='git diff'
alias gpwd="git status | head -n1 | sed 's,On branch ,,'"		# git pwd
alias gpwdlb="echo $LAST_GIT_BRANCH"					# git pwd last branch
alias gcd='LAST_GIT_BRANCH=$(gpwd); git checkout'
alias grmlocal='git branch -d'
alias grmremote='git branch -dr'
alias gclb='__LGB=$LAST_GIT_BRANCH; gcd $__LGB'   # git cd last branch
alias glslocal='git branch'
alias glsremote='git branch --remote'
alias gf='git fetch'
alias gfa='git fetch --all'
alias gu='git pull'
alias gpb='git push -u origin'                          # git push branch insert-branch-name
alias gpcb='git push -u origin $(gpwd)'                 # git push current branch
alias gclean='git reset --hard | git clean -f -d'       # resets to last local commit. deletes untracked files/dirs.
alias ghardclean='git clean -fdx'                       # removes gitignored entries
alias ggc='git gc --aggressive --prune=now'             # optimizes local repo
alias glog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"  # Compact, colorized git log
alias gtree='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"' # Visualise git log tree
alias ghist='git log -p --follow -- '

########################################################
#|# CLIPBOARD                                          #
########################################################
alias tocb='tr -d "\n" | clipit && echo -e "clipboard:\t$(clipit -c)"'
alias cb-tosh='clipit -p > ~/Desktop/job_2.sh'
alias cb-tolog='clipit -p > ~/Desktop/android.log'
alias cb-tojava='clipit -p > ~/Desktop/class.java'

########################################################
#|# ADB                                                #
########################################################
alias adbi='adb install -r "$@"'
alias adbrestart='adb kill-server & adb start-server'
alias adbplug='adb shell dumpsys battery reset'
alias adbunplug='adb shell dumpsys battery unplug'
alias adbdozeon='adb shell dumpsys battery unplug && adb shell dumpsys deviceidle force-idle'
alias adbdozeoff='adb shell dumpsys battery reset && adb shell dumpsys deviceidle disable'
alias adbtext='adb shell input text "$@"'
alias adbmem='adb shell dumpsys meminfo'
alias adbcron='adb shell dumpsys alarm'

########################################################
#|# SSH                                                #
########################################################
alias ssh-agent='exec ssh-agent bash -i <<< "exec </dev/tty;"'
alias ssh-init='exec ssh-agent bash -i <<< "exec </dev/tty; ssh-add-isilva"'
alias ssh-add-isilva='ssh-add ~/.ssh/isilva_wit'
alias ssh-list='ssh-add -l'
alias ssh-lock='ssh-add -x'
alias ssh-unlock='ssh-add -X'

########################################################
#|# ChromeCast                                         #
########################################################
alias cast-transcode='castnow --transcoder ffmpeg --transcode'
alias cast-converter='chromecastize.sh --mkv'

########################################################
#|# Miscellaneous                                      #
########################################################
alias grep='grep --color=always -n'
alias grepr='\grep --color=always -RnsI' # don't forget to add * after the #haystack
alias lessf='less +F'
alias lessr='less -R'
alias calc='galculator'
alias echo='echo -e'
alias ncdu='ncdu --color dark'
alias term='gnome-terminal'
alias src='src-hilite-lesspipe.sh'
alias youtube-dl='youtube-dl -vcti -R5 --write-description --write-info-json --all-subs --write-thumbnail --add-metadata'
alias date-iso='date --iso-8601=seconds'
alias ss='ss -patun'
alias fix-bose='pacmd set-card-profile bluez_card.04_52_C7_FF_F8_1F a2dp_sink'

########################################################
#|# Tips                                               #
########################################################
alias tips='cat $DOTFILES/tips'
alias tips-ol='cat $DOTFILES/cool_oneliners'
alias tips-bash='\grep -B1 -A5 "#|## Bash" $DOTFILES/tips'
alias tips-alias='\grep -B1 -A10 "#|## Alias" $DOTFILES/tips'
alias tips-adb='\grep -B1 -A8 "#|## ADB" $DOTFILES/tips'

########################################################
#|# Dotfiles related                                   #
########################################################
alias edit-ol='vim $DOTFILES/cool_oneliners'
alias edit-todo='vim $DOTFILES/TODO'
alias edit-aliases='vim ~/.bash_aliases'
alias edit-exports='vim ~/.bash_exports'
alias edit-functions='vim ~/.bash_functions'
alias edit-bashrc='vim ~/.bashrc'

alias grep-aliases='cat $DOTFILES/bash_aliases | grep '
alias grep-exports='cat $DOTFILES/bash_exports | grep '
alias grep-functions='cat $DOTFILES/bash_functions | grep -C5 '
alias grep-dotfiles='cat $DOTFILES/bash_* | grep'

alias lsol='cat $DOTFILES/cool_oneliners'

########################################################
#|# Typos                                              #
########################################################
alias alais='alias'
alias nmeo='nemo'
alias neom='nemo'
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
