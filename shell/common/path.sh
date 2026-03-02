# Go tools
if command -v go >/dev/null 2>&1; then
    export PATH=$PATH:$(go env GOPATH)/bin
fi

# DuckDB CLI
export PATH="$HOME/.duckdb/cli/latest:$PATH"

# Kubernetes tools
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# Development tools
export PATH="$HOME/.jbang/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"

# User scripts
export PATH="$HOME/.tools:$PATH"

# pnpm (Windows path)
export PNPM_HOME="$HOME/AppData/Local/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
