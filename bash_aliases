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
alias lr='ls -laR'
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
#|## GIT                                               #
########################################################
alias gg='git gui'
alias gk='gitk'
alias gst='git status'
alias gdiff='git diff'
alias gpwd="git status | head -n1 | sed 's,On branch ,,'"                           # git pwd
alias gcdroot='cd "$(git rev-parse --show-toplevel 2> /dev/null)"'                  # git cd root of project
alias gclb='__LGB=$(gpwd); git checkout $LAST_GIT_BRANCH; LAST_GIT_BRANCH=$__LGB'   # git cd last branch
alias gcd='git checkout'
alias gmkdir='git checkout -b'
alias gf='git fetch'
alias gfa='git fetch --all'
alias gp='git pull'
alias gpb='git push -u origin'                          # git push branch insert-branch-name
alias gpcb='git push -u origin $(gpwd)'                 # git push current branch
alias gclean='git reset --hard | git clean -f -d'       # resets to last local commit. deletes untracked files/dirs.
alias ghardclean='git clean -fdx'                       # removes gitignored entries
alias ggc='git gc --aggressive --prune=now'             # optimizes local repo
alias glog="git log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"  # Compact, colorized git log
alias gtree='git log --graph --full-history --all --color --pretty=format:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s"' # Visualise git log tree

########################################################
#|## CLIPBOARD                                         #
########################################################
alias cb_tosh='clipit -p > ~/Desktop/job_2.sh'
alias cb_tolog='clipit -p > ~/Desktop/android.log'
alias cb_tojava='clipit -p > ~/Desktop/class.java'

########################################################
#|## ADB                                               #
########################################################
alias adbi='adb install -r "$@"'
alias adbr='adb kill-server & adb start-server'
alias adbplug='adb shell dumpsys battery reset'
alias adbunplug='adb shell dumpsys battery unplug'
alias adbdozeon='adb shell dumpsys battery unplug && adb shell dumpsys deviceidle force-idle'
alias adbdozeoff='adb shell dumpsys battery reset && adb shell dumpsys deviceidle disable'
alias adbtext='adb shell input text "$@"'
alias adbmem='adb shell dumpsys meminfo'
alias adbcron='adb shell dumpsys alarm'

########################################################
#|## SSH                                               #
########################################################
alias ssh-agent='exec ssh-agent bash -i <<< "exec </dev/tty;"'
alias ssh-init='exec ssh-agent bash -i <<< "exec </dev/tty; ssh-add-isilva"'
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
alias calc='galculator'
alias getmyip='curl http://ipecho.net/plain; echo -e \"\n\"'
alias echo='echo -e'
alias lsol='cat $DOTFILES/cool_oneliners'
alias edit-ol='vim $DOTFILES/cool_oneliners'
alias edit-todo='vim $DOTFILES/TODO'
alias edit-aliases='vim ~/.bash_aliases'
alias edit-exports='vim ~/.bash_exports'
alias edit-functions='vim ~/.bash_functions'
alias edit-bashrc='vim ~/.bashrc'
alias term='gnome-terminal'
alias src='src-hilite-lesspipe.sh'
alias lessf='less +F'
alias lessr='less -R'
alias grep='grep --color=always -n'
alias grepr='\grep --color=always -RnsI' # don't forget to add * after the #haystack
alias youtube-dl='youtube-dl -vcti -R5 --write-description --write-info-json --all-subs --write-thumbnail --add-metadata'
alias date-iso='date --iso-8601=seconds'

# Open any file with the default command for that file
# alias open='xdg-open'

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
