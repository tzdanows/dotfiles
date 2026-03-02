# Platform and shell detection utilities
# This file is sourced by both bash and zsh configurations

# Detect operating system (Windows-primary)
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]] || [[ "$(uname -s)" == CYGWIN* ]]; then
    export DOTFILES_OS="windows"
elif [[ "$(uname)" == "Darwin" ]]; then
    export DOTFILES_OS="macos"
elif [[ "$(uname)" == "Linux" ]]; then
    export DOTFILES_OS="linux"
else
    export DOTFILES_OS="unknown"
fi

# Detect shell and set shell-specific environment
if [ -n "$ZSH_VERSION" ]; then
    export DOTFILES_SHELL="zsh"
    export DOTFILES_SHELL_CONFIG="$HOME/.zshrc"
    export DOTFILES_SHELL_VERSION="$ZSH_VERSION"
elif [ -n "$BASH_VERSION" ]; then
    export DOTFILES_SHELL="bash"
    export DOTFILES_SHELL_CONFIG="$HOME/.bashrc"
    export DOTFILES_SHELL_VERSION="$BASH_VERSION"
else
    export DOTFILES_SHELL="unknown"
    export DOTFILES_SHELL_CONFIG=""
    export DOTFILES_SHELL_VERSION=""
fi

# Set terminal capabilities
if [ -t 1 ]; then
    export DOTFILES_TERMINAL="interactive"
    export DOTFILES_COLORS_SUPPORTED="true"
else
    export DOTFILES_TERMINAL="non-interactive"
    export DOTFILES_COLORS_SUPPORTED="false"
fi

# Platform-specific configurations
case "$DOTFILES_OS" in
    "windows")
        # Windows specific settings (Git Bash / MSYS2)
        if command -v scoop >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="scoop"
        elif command -v choco >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="choco"
        elif command -v winget.exe >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="winget"
        fi
        ;;
    "macos")
        export DOTFILES_PACKAGE_MANAGER="brew"
        if command -v brew >/dev/null 2>&1; then
            export DOTFILES_BREW_PREFIX="$(brew --prefix)"
        fi
        ;;
    "linux")
        if command -v apt >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="apt"
        elif command -v dnf >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            export DOTFILES_PACKAGE_MANAGER="pacman"
        fi
        ;;
esac

# Shell-specific optimizations
case "$DOTFILES_SHELL" in
    "bash")
        export DOTFILES_COMPLETION_ENABLED="true"
        if [ -d "$HOME/.bash_completion.d" ]; then
            export DOTFILES_COMPLETION_DIR="$HOME/.bash_completion.d"
        fi
        ;;
    "zsh")
        export DOTFILES_COMPLETION_ENABLED="true"
        if [ -d "$HOME/.zsh/completions" ]; then
            export DOTFILES_COMPLETION_DIR="$HOME/.zsh/completions"
        fi
        ;;
esac

# Development environment detection
if [ -n "$VIRTUAL_ENV" ]; then
    export DOTFILES_PYTHON_ENV="$(basename $VIRTUAL_ENV)"
fi

if [ -f "package.json" ]; then
    export DOTFILES_NODE_PROJECT="true"
fi

if [ -f "Cargo.toml" ]; then
    export DOTFILES_RUST_PROJECT="true"
fi

if [ -f "go.mod" ]; then
    export DOTFILES_GO_PROJECT="true"
fi

# Quick info function
dotfiles_info() {
    echo "Dotfiles Environment Information"
    echo "=================================="
    echo "OS: $DOTFILES_OS"
    echo "Shell: $DOTFILES_SHELL ($DOTFILES_SHELL_VERSION)"
    echo "Config: $DOTFILES_SHELL_CONFIG"
    echo "Terminal: $DOTFILES_TERMINAL"
    echo "Colors: $DOTFILES_COLORS_SUPPORTED"

    if [ -n "$DOTFILES_PACKAGE_MANAGER" ]; then
        echo "Package Manager: $DOTFILES_PACKAGE_MANAGER"
    fi

    if [ -n "$DOTFILES_PYTHON_ENV" ]; then
        echo "Python Environment: $DOTFILES_PYTHON_ENV"
    fi

    local project_types=""
    [ "$DOTFILES_NODE_PROJECT" = "true" ] && project_types="$project_types Node.js"
    [ "$DOTFILES_RUST_PROJECT" = "true" ] && project_types="$project_types Rust"
    [ "$DOTFILES_GO_PROJECT" = "true" ] && project_types="$project_types Go"

    if [ -n "$project_types" ]; then
        echo "Detected Projects:$project_types"
    fi
}
