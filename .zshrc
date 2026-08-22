# XDG base directories
export XDG_CONFIG_HOME="$HOME/.config"

# alias common commands
alias zshrc="nvim ~/.zshrc"
alias pip=pip3
alias neo=fastfetch
alias home="cd ~"
alias python=python3
alias init="nvim ~/.config/nvim/init.lua"
alias vim=nvim
alias c=clear
alias j=z
alias config="/opt/homebrew/bin/git --git-dir $HOME/dotfiles --work-tree=$HOME"
alias lgc="lazygit --git-dir=$HOME/dotfiles --work-tree=$HOME"
alias sshc="ssh -p 22 root@47.96.123.255"
alias hd="hugo server -D"
alias sc="source ~/.zshrc"
alias gra="git remote add origin"
alias ga="git add"
alias gc="git clone"
alias gp="git push"
alias gm="git commit"
alias gs="git status"
alias gw="git switch"
alias lg="lazygit"
alias tx='tmux attach || tmux new'
alias tn='tmux new -s'
alias mb='musicbox'

# customize filetype colors using LS_COLORS
source "$HOME/Scripts/lscolor.sh"

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="gitster"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(colored-man-pages zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# override oh-my-zsh default ls alias
export EDITOR="nvim"
export VISUAL="nvim"
alias ls=lsd
alias lh="lsd -ah"
alias la="lsd -la"
eval "$(zoxide init zsh)"

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# hugo completion
# autoload -U compinit; compinit

export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/homebrew-core.git"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"

# Added by codebase-memory-mcp install
export PATH="/Users/fgui/.local/bin:$PATH"

# Load local/private config (not tracked in dotfiles)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

export GOPROXY=https://goproxy.cn,direct
export GOSUMDB=sum.golang.org

# Alacritty only applies cursor.style at startup. tmux/nvim change it with
# DECSCUSR and do not put it back. CSI 0 q restores the configured style
# (Beam + blink). precmd covers leaving tmux, nvim, less, etc.
_restore_cursor() { printf '\e[0 q'; }
precmd_functions+=(_restore_cursor)

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}
