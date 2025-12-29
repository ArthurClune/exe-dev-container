# ZSH interactive shell configuration

# -------
# options
# -------
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE=~/.zhistory
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_DUPS      # Do not record an event that was just recorded again.
setopt HIST_VERIFY           # Do not execute immediately upon history expansion.

setopt AUTO_CD
setopt AUTO_LIST
setopt AUTO_PUSHD
setopt AUTO_REMOVE_SLASH
setopt BRACE_CCL
setopt CDABLE_VARS
setopt LONG_LIST_JOBS
setopt NO_BG_NICE
setopt NO_HIST_BEEP
setopt NO_HUP
setopt NO_LIST_BEEP
setopt NOTIFY
setopt PUSHD_SILENT
setopt PUSHD_TO_HOME
setopt REC_EXACT


# ----------
# completion
# ----------
autoload -U compinit
compinit -u
autoload -U bashcompinit
bashcompinit


# --------
# aliases
# -------

alias -- grep='grep --color=tty -d skip'
alias -- top='top -u'
alias ls='eza --long --header --git'
alias cat='bat'
alias active='source .venv/bin/activate'

alias claude-yolo='claude --dangerously-skip-permissions'

# -----------
# shell setup
# -----------


TITLEPROMPT="%m:%5c"
DIRSTACKSIZE=10
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
FIGNORE=.o
stty sane


eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

