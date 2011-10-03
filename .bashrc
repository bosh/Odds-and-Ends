# Vars
SSH_ENV="$HOME/.ssh/environment"
PS1="\D{}${PS1}"

# Autocopy
alias refresh-bash-rc='odds && cp .bashrc ~/.bashrc && cd - && source ~/.bashrc'

# Bindings
bind 'C-k:clear-screen'

# Pastebuffer hax
alias paste='cat /dev/clipboard && echo '

# Filesystem operations
alias e='explorer .'
alias dir='ls'
alias ls='ls -lAF --color'
alias diff='diff -u'
alias sublime='"C:/Program Files/Sublime Text 2/sublime_text.exe"'

# Git
alias gs='git status'
alias gd='git diff'
alias gw='git w'
alias gc='git commit'
alias gdc='git diff --cached'

# Ruby
alias bx='bundle exec'
alias be='bx'
alias cuke='cucumber --format=pretty '
alias gogogo='autotest'
alias sassy='sass --watch stylesheets/sass:stylesheets/compiled'
# Rails 2
alias ss='script/server'
alias sc='script/console'
alias sdb='script/dbconsole'
# Rails 3
alias rdb='rails dbconsole'
alias rc='rails console'
alias rs='rails server'

# Projects
alias workspace='cd ~/Workspace'
alias ling='cd ~/Workspace/Linguistic-Explorer'
alias odds='cd ~/Workspace/Odds-and-Ends'
alias access='ssh aml500@access.cims.nyu.edu'
alias mot='cd ~/Workspace/My-One-Thing'

# Utils
alias utils="cd ~/Workspace/Utils"
alias wp="ruby ~/Workspace/Utils/wp.rb"

# SSH Helpers
# start the ssh-agent
function start_agent {
    echo "Initializing new SSH agent..."
    # spawn ssh-agent
    ssh-agent | sed 's/^echo/#echo/' > "$SSH_ENV"
    echo succeeded
    chmod 600 "$SSH_ENV"
    . "$SSH_ENV" > /dev/null
    ssh-add
}

# test for identities
function test_identities {
    # test whether standard identities have been added to the agent already
    ssh-add -l | grep "The agent has no identities" > /dev/null
    if [ $? -eq 0 ]; then
        ssh-add
        # $SSH_AUTH_SOCK broken so we start a new proper agent
        if [ $? -eq 2 ];then
            start_agent
        fi
    fi
}

# check for running ssh-agent with proper $SSH_AGENT_PID
if [ -n "$SSH_AGENT_PID" ]; then
    ps -ef | grep "$SSH_AGENT_PID" | grep ssh-agent > /dev/null
    if [ $? -eq 0 ]; then
    test_identities
    fi
# if $SSH_AGENT_PID is not properly set, we might be able to load one from
# $SSH_ENV
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
