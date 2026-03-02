##############################################################################
#   Filename: .aliases.sh                                                    #
#        URL: http://github.com/tzdanows/dotfiles                            #
#                                                                            #
# Sections:                                                                  #
#   01. General ................. General aliases                            #
#   02. Git ..................... Git aliases                                #
#   03. Programming ............. Aliases  for programming                   #
#   04. Networking .............. Networking aliases                         #
#   05. Kubernetes .............. Kubernetes aliases                         #
#   06. Development Tools ....... Modern development tools                   #
#   XX. Misc .................... Miscellaneous aliases                      #
##############################################################################

##############################################################################
# 01. General                                                                #
##############################################################################

alias c='clear'

# Platform-aware alias for opening current directory
if [[ "$(uname -s)" == MINGW* ]] || [[ "$(uname -s)" == MSYS* ]]; then
    alias .='explorer .'
elif [[ "$(uname)" == "Darwin" ]]; then
    alias .='open .'
elif [[ "$(uname)" == "Linux" ]]; then
    alias .='xdg-open .'
fi

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Editor and shell configuration
alias edit='zed'
alias g='gemini'
alias x='claude'
alias xs='claude --model sonnet'
alias xx='cd ~/Development/development-workspace'
alias lfg='claude --model opusplan --dangerously-skip-permissions'

# Shell-agnostic aliases - detect current shell and use appropriate config
if [ -n "$ZSH_VERSION" ]; then
    # ZSH-specific aliases
    alias vv='vzsh'
    alias ss='szsh'
    alias vzsh='edit ~/dev/dotfiles'
    alias szsh='source ~/.zshrc'
elif [ -n "$BASH_VERSION" ]; then
    # Bash-specific aliases
    alias vv='vbash'
    alias ss='sbash'
    alias vbash='edit ~/.bashrc'
    alias sbash='source ~/.bashrc'
fi

# Universal shell config aliases (work for both shells)
alias vrc='edit ~/.$(basename $SHELL)rc'
alias src='source ~/.$(basename $SHELL)rc'

# Directory navigation
alias dev='cd ~/Desktop/dev'
alias tom='cd ~'
# Modern CLI tool replacements
alias cat='bat --paging=never'
alias find='fd'

# File operations
alias listdir='find ${1:-.} -type f -not -path "*/.*/*" -print0 | xargs -0 -I {} bash -c '\''echo "$(dirname "{}")/$(basename "{}")"'\'' | sort -t/ -k2 -k3'
# Disk Space Usage
alias ds='du -sh * | sort -rh | awk '\''{sum+=$1; print} END {print "Total Size: " sum}'\'
alias copydir='rg --no-ignore --no-heading --with-filename --line-number --text --max-columns 500 --binary "" | nl -ba | tee >(clip.exe) | cat'

# System utilities
alias ff='fastfetch'
alias binary='xxd'
alias py='python'

# SSH and remote connections (configured via ~/.dotfiles.env)
if [ -n "$RPI3_HOST" ]; then alias rpi3="ssh $RPI3_HOST"; fi
if [ -n "$RPI5_HOST" ]; then alias rpi5="ssh $RPI5_HOST"; fi


# Tailscale
alias ts='tailscale status'

##############################################################################
# 02. Git                                                                    #
##############################################################################

# Git defaults (identity configured via ~/.dotfiles.env)
git config --global user.name "${GIT_AUTHOR_NAME:-}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-}"
git config --global core.editor "vim"

# Dotfile management
alias cfg='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias config='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'

# Git aliases
alias gaa='git add .'
alias gb='git branch'
alias gc='git commit'
alias gm='git merge'
alias gca='git commit --amend --no-edit'
alias gcl='git clone'
alias gco='git checkout'
alias gd='git diff'
alias gds='gd --stat'
alias gfd='git clean -fd'
alias gl='git log --decorate --graph --pretty=format:"%Cgreen%h%Creset [%ar - %Cred%an%Creset], %s %C(auto)%d%Creset"'
alias gll='git log --graph --decorate --pretty=medium'
alias glog='git log'
alias gp='git push'
alias gpu='eval git push -u origin $(git rev-parse --abbrev-ref HEAD)'
alias gpr='git pull --rebase'
alias gpro='git pull --rebase origin master'
alias gpo='git pull --rebase origin master'
alias gpt='git pull --rebase origin tom'
alias gr='git revert'
alias gri='git rebase -i origin/master'
alias grco='git rebase --continue'
alias gs='git status'
alias gsw='git switch -c'
alias gbddd='git branch | grep -v "main" | xargs git branch -d'
alias hawk="git add . && git commit -m 'nit'"
alias tuah="git push"
alias lg="lazygit"

##############################################################################
# 03. Programming                                                            #
##############################################################################

# Deno
alias d='deno'
alias dt='d task'
alias dtd='d task dev'
  
# Gradle
alias gw='./gradlew'
alias gwr='gw run'
alias gwi='gw idea'
alias gwb='gw build'

# Rust
alias cgr='cargo run'
alias cdo='cargo doc --open'
alias cgt='cargo test'
alias cgb='cargo build'
alias cgc='cargo check'
alias cgwt='cargo watch -x check -x test'
alias cgw='cargo watch -x check -x test -x run'
alias cf='cargo fmt && cargo clippy'
alias cgcm='cgc && cgt && cf'
alias cb='cargo bench'

# Go
alias gob='go build'
alias got='go test'
alias gotb='go test -bench=.'
alias gotc='go test -cover'
alias gor='go run'
alias goc='go clean'
alias gof='go format'
alias goi='go install'
alias gofix='go fix'
alias god='go doc'
alias gcu='$HOME/go/bin/go-coreutils'

# Java
alias j!=jbang

# NPM/Node
alias p='pnpm'
alias es='ember serve'
alias nps='npm start'
alias npi='npm install'

# AI/Development tools
alias aider='py -m aider --cache-prompts'
alias a='aider'
alias ad='aider'
alias o='ollama'

##############################################################################
# 04. Networking                                                             #
##############################################################################

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Windows networking
alias flush='ipconfig //flushdns'
alias localip='ipconfig | grep -i "IPv4"'

##############################################################################
# 05. Kubernetes                                                             #
##############################################################################

# kubectl shortcuts
alias k='kubectl'
alias ka='kubectl get all --all-namespaces'
alias kp='kubectl get pods'
alias kdp='kubectl describe pod'
alias ki='kubectl get ing'
alias kd='kubectl get deployments'
alias ks='kubectl get svc'
alias kn='kubectl get nodes'
alias kl='kubectl logs'
alias ksysgpo='kubectl --namespace=kube-system get pod'

# kubectl delete operations
alias krm='kubectl delete'
alias krmf='kubectl delete -f'
alias krming='kubectl delete ingress'
alias krmingl='kubectl delete ingress -l'
alias krmingall='kubectl delete ingress --all-namespaces'

# kubectl service operations
alias kgsvcoyaml='kubectl get service -o=yaml'
alias kgsvcwn='kubectl get service --watch --namespace'
alias kgsvcslwn='kubectl get service --show-labels --watch --namespace'
alias kgwf='kubectl get --watch -f'

# Configuration and tools
alias kc='edit ~/.kube/config'
alias cap='kube-capacity'
alias internal-rpk="kubectl --namespace redpanda exec -i -t redpanda-0 -c redpanda -- rpk"

# Telepresence
alias tp='telepresence'
alias tl='tp list'
alias tc='tp connect'

# Talos
alias td='talosctl dashboard'

##############################################################################
# 06. Development Tools                                                      #
##############################################################################

# Docker and Docker Compose
alias dcd='docker-compose down'
alias dcs='docker-compose stop'
alias dcu='docker-compose up -d'
alias dcb='docker-compose build'
alias dps='docker ps'

# Minikube
alias m='minikube'
alias ms='minikube start'

# Skaffold
alias s='skaffold'
alias sr='s run'
alias sdl='s delete'
alias sd='s dev'

# Editors and IDEs
alias z='zed'
alias nv='nvim'

# File and content operations
alias t='tree'
alias rr='repomix && cat repomix-output.xml | clip.exe && rm repomix-output.xml'
alias mcp='edit ~/.cursor/mcp.json'

# Fleet (JetBrains)
alias fl='fleet'

##############################################################################
# XX. Misc                                                                   #
##############################################################################

# Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null || alias hd="hexdump -C"

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'