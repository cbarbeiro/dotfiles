# dotfiles

These are a collection of variables, aliases and functions that I use to make my navigation in the terminal easier.

# Bookmark Manager

One of the tools is the bookmark manager of directories, so the navigation into regular folders becomes quicker.

> bm usage gif
> bm-add #with a comment

And there are also two cd and bd improved to keep a list of most recent visited directories that you can access by typing

> dirs

# Time Reporting Script

*time_tracker.sh* is a script that can be used to report tasks. It creates an entry with a start or stop time and appends a customisable task at the end. Accessable in *time_tracker/time_tracker.sh* or through the alias *tt* in defined in *bash_aliases*

> tt -h
> tt -a
> tt -s
> tt -a
> tt -s
> tt -a -f 12:34
> tt -s
> tt -e
> tt -t
> tt -call

# Prompt

My prompt is:

> [username@hostname] ~/folder/
> |0>$ 

To disable it, comment line "export PS1" => "#export PS1"

# Work Environment

When importing the scripts, one can choose to have only the base set of scripts (aliases, exports and functions), or also have the working environment, where you can have different definitions, but separated from the main and easily disabled.

#Installation

1) The easiest way of installation is by cloning this repo.

> git clone https://github.com/iafsilva/dotfiles

And you can activate the main environment (aliases, functions, exports, directory bookmarks, etc) by running:

> source ./dotfiles/bash**

And then work environment by running:

> source-work

# Persistent installation
If you like, you can install these functions in your computer.

The main envirnoment containing aliases, functions, exports, directory bookmarks, etc, is installed with:
chmod +x ./install_dotfiles.sh
./install_dotfiles.sh

If you want both main and work environments append work to previous command:
chmod +x ./install_dotfiles.sh
./install_dotfiles.sh work

To make it run on every terminal session, edit ~/.bashrc and change this line:

> if [[ "x$(hostname)" = "xarchThrone" ]]; then

to be true for your hostname! That's it!

If you also want it in your work pc, change the same line on the next section of the file:

> if [[ "x$(hostname)" = "xarchOfThrones" ]]; then

