SSH_ENV="$HOME/.ssh/environment"

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

alias gs='git status'
alias gd='git diff'
alias gw='git w'
alias gc='git commit'
alias dir='ls -l'
alias e='explorer .'
alias ss='ruby script/server'
alias rc='rails console'
alias rs='rails server'
alias server='ruby script/server'
alias dbconsole='ruby script/dbconsole'
alias console='ruby script/console'
alias heuristics='cd ~/Workspace/Heuristics'
alias sswl='cd ~/Workspace/SSWL/trunk/SSWL'
alias ling='cd ~/Workspace/Linguistic-Explorer'
alias workspace='cd ~/Workspace'
alias heuristics='cd ~/Workspace/Heuristics'
alias diaspora='cd ~/Workspace/diaspora'
alias games='cd ~/Workspace/Computer-Games'
alias odds='cd ~/Workspace/Odds-and-Ends'
alias cityblock='cd ~/Workspace/CityBlock'
alias evasion='cd ~/Workspace/Evasion'
alias sassy='sass --watch stylesheets/sass:stylesheets/compiled'
alias access='ssh aml500@access.cims.nyu.edu'
alias mot='cd ~/Workspace/My-One-Thing'
alias cuke='cucumber --format=pretty '
PS1="\n\D{}${PS1}"
