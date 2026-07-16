  # NNN
  export PAGER="less -Ri"
  export NNN_BMS="w:$HOME/Work;l:$HOME/Learn;c:$HOME/.config;b:$HOME/.config/nnn/bookmarks"
  # BLK="04" CHR="04" DIR="04" EXE="2e" REG="00" HARDLINK="00" SYMLINK="06" MISSING="f7" ORPHAN="01" FIFO="0F" SOCK="0F" OTHER="02"
  # export NNN_FCOLORS="$BLK$CHR$DIR$EXE$REG$HARDLINK$SYMLINK$MISSING$ORPHAN$FIFO$SOCK$OTHER"
  export NNN_FIFO=/tmp/nnn.fifo
  export NNN_PLUG='p:preview-tui;n:bulknew'
	

  # NNN end
  
  # pnpm
  export PNPM_HOME="/Users/fgui/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
  # export N_PREFIX=/opt/homebrew
  # export PATH=$N_PREFIX/bin:$PATH
  # pnpm end
  
  # visual
  #export VISUAL=ewrap
  
  # editor
  export EDITOR="/opt/homebrew/bin/nvim"

  export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/ #ckbrew
  eval $(/opt/homebrew/bin/brew shellenv) #ckbrew


# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Created by `pipx` on 2025-04-19 12:21:31
export PATH="$PATH:/Users/fgui/.local/bin"
