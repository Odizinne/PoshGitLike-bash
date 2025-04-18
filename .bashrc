# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
    else
        color_prompt=
    fi
fi

# Git status information collector
function __git_info {
  # Reset variables
  GIT_BRANCH=""
  GIT_SYNC=""
  GIT_STAGED=""
  GIT_UNSTAGED=""
  GIT_IN_SYNC=0
  GIT_AHEAD=0
  GIT_BEHIND=0
  
  # Check if in a git repository
  git rev-parse --is-inside-work-tree &>/dev/null || return
  
  # Get branch name
  GIT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)
  
  # Check ahead/behind
  if git rev-parse --abbrev-ref @{upstream} &>/dev/null; then
    local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
    
    if [ $ahead -gt 0 -a $behind -eq 0 ]; then
      GIT_SYNC="↑$ahead"
      GIT_AHEAD=1
      GIT_IN_SYNC=0
    elif [ $behind -gt 0 -a $ahead -eq 0 ]; then
      GIT_SYNC="↓$behind"
      GIT_BEHIND=1
      GIT_IN_SYNC=0
    elif [ $ahead -gt 0 -a $behind -gt 0 ]; then
      GIT_SYNC="↑$ahead ↓$behind"
      GIT_AHEAD=1
      GIT_BEHIND=1
      GIT_IN_SYNC=0
    else
      GIT_SYNC="≡"
      GIT_IN_SYNC=1
    fi
  fi
  
  # Count staged/unstaged
  local staged_added=0 staged_modified=0 staged_deleted=0
  local unstaged_added=0 unstaged_modified=0 unstaged_deleted=0
  local has_staged=0 has_unstaged=0
  
  while IFS= read -r line; do
    if [[ ${line:0:2} == "??" ]]; then
      ((unstaged_added++))
      has_unstaged=1
    else
      if [[ ${line:0:1} == "A" ]]; then
        ((staged_added++))
        has_staged=1
      elif [[ ${line:0:1} == "M" ]]; then
        ((staged_modified++))
        has_staged=1
      elif [[ ${line:0:1} == "D" ]]; then
        ((staged_deleted++))
        has_staged=1
      fi
      
      if [[ ${line:1:1} == "A" ]]; then
        ((unstaged_added++))
        has_unstaged=1
      elif [[ ${line:1:1} == "M" ]]; then
        ((unstaged_modified++))
        has_unstaged=1
      elif [[ ${line:1:1} == "D" ]]; then
        ((unstaged_deleted++))
        has_unstaged=1
      fi
    fi
  done < <(git status --porcelain 2>/dev/null)
  
  # Format staged changes
  if [ $has_staged -eq 1 ]; then
    GIT_STAGED="+$staged_added ~$staged_modified -$staged_deleted"
  fi
  
  # Format unstaged changes
  if [ $has_unstaged -eq 1 ]; then
    GIT_UNSTAGED="+$unstaged_added ~$unstaged_modified -$unstaged_deleted"
  fi
}

# PROMPT_COMMAND runs before each prompt display
PROMPT_COMMAND='__git_info'

# Set PS1 with multicolor git prompt
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] '
    PS1+='$(if [ -n "$GIT_BRANCH" ]; then '
    # Opening bracket always yellow
    PS1+='echo -n "\[\033[33m\]["; '
    # Branch name and sync indicator with matching colors based on sync status
    PS1+='if [ $GIT_IN_SYNC -eq 1 ]; then '
    # Light blue for branch and hamburger when in sync
    PS1+='echo -n "\[\033[38;5;39m\]${GIT_BRANCH} ${GIT_SYNC}"; '
    PS1+='elif [ $GIT_AHEAD -eq 1 -a $GIT_BEHIND -eq 0 ]; then '
    # Green for branch and up arrow when ahead
    PS1+='echo -n "\[\033[32m\]${GIT_BRANCH} ${GIT_SYNC}"; '
    PS1+='elif [ $GIT_BEHIND -eq 1 -a $GIT_AHEAD -eq 0 ]; then '
    # Red for branch and down arrow when behind
    PS1+='echo -n "\[\033[31m\]${GIT_BRANCH} ${GIT_SYNC}"; '
    PS1+='else '
    # Yellow for branch and mixed arrows
    PS1+='echo -n "\[\033[33m\]${GIT_BRANCH} ${GIT_SYNC}"; '
    PS1+='fi; '
    # Staged changes in green
    PS1+='if [ -n "$GIT_STAGED" ]; then echo -n " \[\033[32m\]${GIT_STAGED}"; fi; '
    # Unstaged with separator if needed - make | yellow
    PS1+='if [ -n "$GIT_UNSTAGED" ]; then '
    PS1+='if [ -n "$GIT_STAGED" ]; then echo -n " \[\033[33m\]| "; else echo -n " "; fi; '
    PS1+='echo -n "\[\033[31m\]${GIT_UNSTAGED}"; fi; '
    # Closing bracket always yellow
    PS1+='echo "\[\033[33m\]]"; fi)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w $(if [ -n "$GIT_BRANCH" ]; then echo "[${GIT_BRANCH} ${GIT_SYNC}${GIT_STAGED:+ $GIT_STAGED}${GIT_UNSTAGED:+${GIT_STAGED:+ | }$GIT_UNSTAGED}]"; fi)\$ '
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#alias sudo='sudo '
#alias apt='nala'
