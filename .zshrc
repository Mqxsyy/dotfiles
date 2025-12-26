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
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zi ice from'gh-r' as'program' sbin'**/eza -> eza' atclone'cp -vf completions/eza.zsh _eza'
zi light eza-community/eza

# Load completions
autoload -U compinit && compinit

zinit cdreplay -q

# Keybinds
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # Make autocomplete case insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:comelete:cd:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

# Qml import paths
export QML_IMPORT_PATH=/usr/lib/qt6/qml
export QML2_IMPORT_PATH=/usr/lib/qt6/qml

# Aliases
alias c="clear"
alias cd='z'
alias ls="eza $eza_params"
alias ll="eza --all --header --long $eza_params"
alias tree="eza --tree -L 1 $eza_params"
alias gl="git log --decorate --oneline --graph"

alias pixfix="wine ~/dotfiles/scripts/Pixfix.exe"

alias bonk="~/dotfiles/tmux/sessions/bonk.sh"
alias splice="~/dotfiles/tmux/sessions/project-splice.sh"

