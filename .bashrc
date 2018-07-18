# Start in ~ instead of / if shell opens into /
if [ $PWD == '/' ]; then cd; fi

# Kills ssh-agent on literal `exit` but not on upper right X button click... weird
trap '
  test -n "$SSH_AGENT_PID"  && eval `ssh-agent -k` ;
  test -n "$SSH2_AGENT_PID" && kill $SSH2_AGENT_PID
' 0

# Vars and shell changes
SSH_ENV="$HOME/.ssh/environment"
PS1="\D{}${PS1}"
bind 'C-k:clear-screen'

###
# Autocopy this file from repo
alias refresh-bash-rc='o && cp .bashrc ~/.bashrc && cd - && source ~/.bashrc'
###

alias alias?='alias '

alias e='explorer .'

alias back="cd -"
alias up="cd .."

alias ls='ls -lAtF --color'
alias dir='ls -f --color'
alias d='dir'

alias diff='diff -u'

# Git
alias g='git'
alias gc='git commit'
alias gd='git diff'
alias gs='git status'
alias gw='git w'
alias gco='git checkout'
alias gpr='git pull --rebase'
alias gdc='git diff --cached'
alias gdh='git diff HEAD'
complete -o default -o nospace -F _git g

# Ruby
alias be='bx'
alias bx='bundle exec'
alias rspec='rspec -c'
alias cuke='cucumber --format=pretty '
alias sassy='sass --watch stylesheets/sass:stylesheets/compiled'

# Rails 3
alias r='rails'
alias rs='rails server'
alias rc='rails console'
alias rdb='rails dbconsole'
#complete -o default -o nospace -F _rails r

alias sublime='"C:/Program Files/Sublime Text 2/sublime_text.exe"'
alias subl="sublime -a"

# Utils
alias paste='cat /dev/clipboard && echo '
alias spy='grep -B 3 -A 3 -n -C 1 -r -h --null'
alias wp="ruby ~/Workspace/Utils/wp.rb"

# Projects
alias archive='cd ~/Workspace/archive/Linguistic-Explorer'
alias k='cd ~/Workspace/key-lib'
alias v='cd ~/Workspace/visualkeyboard'
alias ling='cd ~/Workspace/archive/Linguistic-Explorer'
alias o='cd ~/Workspace/Odds-and-Ends'
alias utils='cd ~/Workspace/Utils'
alias workspace='cd ~/Workspace'
alias w='workspace'
alias b='cd ~/Workspace/chromeprices'
alias bd='cd ~/Workspace/BrickData'
alias box='cd ~/Workspace/box'
alias m='cd ~/Workspace/matchbrick'
alias p='cd ~/Workspace/easypost-gottashipemall'

# SSH Helpers
function start_agent {
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
    ssh-add
}

function test_identities {
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $? -eq 0 ]; then
        ssh-add
        if [ $? -eq 2 ];then
            start_agent
        fi
    fi
}

if [ -n "$SSH_AGENT_PID" ]; then
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
    test_identities
    fi
else
    if [ -f "$SSH_ENV" ]; then
    . "$SSH_ENV" > /dev/null
    fi
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
        test_identities
    else
        start_agent
    fi
fi
