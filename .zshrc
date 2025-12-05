# Initialize autocompletion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

# Enable typo correction
setopt CORRECT

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

# Options for ignore duplicate
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Adition history opt
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY # save cmd times

# Aliases
alias ll='ls -alh --color=auto'
# alias nano='nano -/'
alias mpv_hdr='mpv --vo=gpu-next --target-colorspace-hint --gpu-api=vulkan --gpu-context=waylandvk'

# Enable Agnoster theme
setopt prompt_subst
source ~/.zsh/themes/agnoster.zsh-theme

# Add plagin zsh-autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#505050'
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Add plagin zsh-history-substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=black,fg=green,bold,underline'
source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh

# Add fzf
[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# Add plagin zsh-syntax-highlighting
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Created by `pipx` on 2025-04-16 23:21:31
export PATH="$PATH:/home/zen/.local/bin"

# Add precompiled software
export PATH="/home/zen/app/verible-v0.0-3967-gd0f83bfd/bin/:$PATH"
