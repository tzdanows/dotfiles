# Load dotfiles environment (sensitive values like git identity, SSH hosts)
if [ -f "$HOME/.dotfiles.env" ]; then
    source "$HOME/.dotfiles.env"
fi

# Git configuration (identity loaded from ~/.dotfiles.env)
GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
git config --global user.name "${GIT_AUTHOR_NAME:-}"
GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
git config --global user.email "${GIT_AUTHOR_EMAIL:-}"

# Shell-specific configurations
if [ -n "$ZSH_VERSION" ]; then
    # ZSH-specific configurations
    
    # zsh completion configuration
    zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
    autoload -Uz compinit && compinit

    # zsh syntax highlighting (check common locations)
    for zsh_hl in /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
                  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
        if [ -f "$zsh_hl" ]; then
            source "$zsh_hl"
            break
        fi
    done

    # fzf integration for zsh (if available)
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

    # mise activation for zsh
    if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
    fi

elif [ -n "$BASH_VERSION" ]; then
    # Bash-specific configurations
    
    # fzf integration for bash (if available)
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
    
    # mise activation for bash
    if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate bash)"
    fi

    # Git completion for bash (check common locations)
    for git_completion in /usr/share/bash-completion/completions/git \
                          /mingw64/share/git/completion/git-completion.bash \
                          /etc/bash_completion.d/git; do
        if [ -f "$git_completion" ]; then
            source "$git_completion"
            break
        fi
    done
fi

# Universal tool integrations (work in both shells)

# fzf key bindings (universal)
if command -v fzf >/dev/null 2>&1; then
    # Universal fzf environment variables
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    
    # Set up fzf for file search
    if command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi
fi

# direnv integration (if available)
if command -v direnv >/dev/null 2>&1; then
    if [ -n "$ZSH_VERSION" ]; then
        eval "$(direnv hook zsh)"
    elif [ -n "$BASH_VERSION" ]; then
        eval "$(direnv hook bash)"
    fi
fi
