# Set ZInit & plugins directory
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download ZInit
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load ZInit
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting # must load last
zi ice from'gh-r' as'program' sbin'**/eza -> eza' atclone'cp -vf completions/eza.zsh _eza'
zi light eza-community/eza

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Keybinds
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^p' up-line-or-beginning-search
bindkey '^n' down-line-or-beginning-search
bindkey '^[[3~' delete-char       # Delete
bindkey '^[[H' beginning-of-line  # Home
bindkey '^[[F' end-of-line        # End
bindkey '^[[1;5D' backward-word   # Ctrl+Left
bindkey '^[[1;5C' forward-word    # Ctrl+Right

# History
HISTSIZE=50000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Make autocomplete case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# Every script in ~/dotfiles/bin is a command, by its file name
export PATH="$HOME/dotfiles/bin:$PATH"

# Qml import paths
export QML_IMPORT_PATH=/usr/lib/qt6/qml

# Aliases
alias c="clear"
alias cd='z'
alias ls="eza"
alias ll="eza --all --header --long"
alias tree="eza --tree -L 1"
alias loc="noglob loc" # so `loc *.lua` reaches it unexpanded

## Git
alias gs="git status"
alias gp="git push origin HEAD"
alias gl="git log --decorate --oneline --graph"

gc() {
  git add . && git commit -m "$1"
}

## Other
alias pixfix="wine ~/dotfiles/scripts/Pixfix.exe"

