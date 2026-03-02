# PowerShell Profile for Windows Development
# Installed by dotfiles: deno task install

# --- Navigation ---
function Go-Up { Set-Location .. }
function Go-Up2 { Set-Location ../.. }
function Go-Up3 { Set-Location ../../.. }
Set-Alias -Name '..' -Value Go-Up
Set-Alias -Name '...' -Value Go-Up2
Set-Alias -Name '....' -Value Go-Up3

function Switch-To-Dev { Set-Location "$HOME\Desktop\dev" }
Set-Alias -Name dev -Value Switch-To-Dev

function Switch-To-Home { Set-Location $HOME }
Set-Alias -Name tom -Value Switch-To-Home

Set-Alias -Name c -Value Clear-Host

# --- Editor and CLI ---
Set-Alias -Name edit -Value zed
Set-Alias -Name z -Value zed
Set-Alias -Name x -Value claude
function Claude-Sonnet { claude --model sonnet @args }
Set-Alias -Name xs -Value Claude-Sonnet
function Claude-Opus-Yolo { claude --model opus --dangerously-skip-permissions @args }
Set-Alias -Name lfg -Value Claude-Opus-Yolo

# --- Profile Management ---
function Edit-Profile { zed (Split-Path $PROFILE) }
Set-Alias -Name pro -Value Edit-Profile
function Reload-Profile { . $PROFILE; Write-Output "Profile reloaded!" }
Set-Alias -Name rl -Value Reload-Profile

# --- Git (identity loaded from ~/.dotfiles.env via $env:GIT_AUTHOR_NAME) ---
if (Test-Path "$HOME\.dotfiles.env") {
    Get-Content "$HOME\.dotfiles.env" | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=["'']?(.+?)["'']?\s*$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
        }
    }
}
$gitName = $env:GIT_AUTHOR_NAME
$gitEmail = $env:GIT_AUTHOR_EMAIL
if ($gitName) { git config --global user.name $gitName }
if ($gitEmail) { git config --global user.email $gitEmail }
git config --global core.editor "vim"

function Git-Status { git status @args }
function Git-AddAll { git add . }
function Git-Branch { git branch @args }
function Git-Commit { git commit @args }
function Git-Merge { git merge @args }
function Git-CommitAmend { git commit --amend --no-edit }
function Git-Clone { git clone @args }
function Git-Checkout { git checkout @args }
function Git-Diff { git diff @args }
function Git-DiffStat { git diff --stat @args }
function Git-Log { git log --decorate --graph --pretty=format:"%Cgreen%h%Creset [%ar - %Cred%an%Creset], %s %C(auto)%d%Creset" @args }
function Git-LogFull { git log --graph --decorate --pretty=medium @args }
function Git-Push { git push @args }
function Git-PushUpstream { $branch = git rev-parse --abbrev-ref HEAD; git push -u origin $branch }
function Git-PullRebase { git pull --rebase @args }
function Git-Revert { git revert @args }
function Git-SwitchCreate { git switch -c @args }
function Git-Hawk { git add .; git commit -m 'nit' }
function Git-Tuah { git push }
Set-Alias -Name gs -Value Git-Status
Set-Alias -Name gaa -Value Git-AddAll
Set-Alias -Name gb -Value Git-Branch
Set-Alias -Name gc -Value Git-Commit -Force -Option AllScope
Set-Alias -Name gm -Value Git-Merge -Force -Option AllScope
Set-Alias -Name gca -Value Git-CommitAmend
Set-Alias -Name gcl -Value Git-Clone
Set-Alias -Name gco -Value Git-Checkout
Set-Alias -Name gd -Value Git-Diff
Set-Alias -Name gds -Value Git-DiffStat
Set-Alias -Name gl -Value Git-Log -Force -Option AllScope
Set-Alias -Name gll -Value Git-LogFull
Set-Alias -Name gp -Value Git-Push -Force -Option AllScope
Set-Alias -Name gpu -Value Git-PushUpstream
Set-Alias -Name gpr -Value Git-PullRebase
Set-Alias -Name gr -Value Git-Revert
Set-Alias -Name gsw -Value Git-SwitchCreate
Set-Alias -Name hawk -Value Git-Hawk
Set-Alias -Name tuah -Value Git-Tuah
Set-Alias -Name lg -Value lazygit

# --- Deno ---
Set-Alias -Name d -Value deno
function Deno-Task { deno task @args }
function Deno-TaskDev { deno task dev }
Set-Alias -Name dt -Value Deno-Task
Set-Alias -Name dtd -Value Deno-TaskDev

# --- Rust ---
function Cargo-Run { cargo run @args }
function Cargo-Test { cargo test @args }
function Cargo-Build { cargo build @args }
function Cargo-Check { cargo check @args }
function Cargo-DocOpen { cargo doc --open }
function Cargo-Watch { cargo watch -x check -x test -x run }
function Cargo-FmtClippy { cargo fmt; cargo clippy }
function Cargo-Bench { cargo bench @args }
Set-Alias -Name cgr -Value Cargo-Run
Set-Alias -Name cgt -Value Cargo-Test
Set-Alias -Name cgb -Value Cargo-Build
Set-Alias -Name cgc -Value Cargo-Check
Set-Alias -Name cdo -Value Cargo-DocOpen
Set-Alias -Name cgw -Value Cargo-Watch
Set-Alias -Name cf -Value Cargo-FmtClippy
Set-Alias -Name cb -Value Cargo-Bench

# --- Go ---
function Go-Build { go build @args }
function Go-Test { go test @args }
function Go-Run { go run @args }
function Go-Clean { go clean @args }
function Go-Install { go install @args }
Set-Alias -Name gob -Value Go-Build
Set-Alias -Name got -Value Go-Test
Set-Alias -Name gor -Value Go-Run
Set-Alias -Name goc -Value Go-Clean
Set-Alias -Name goi -Value Go-Install

# --- Docker ---
function Docker-ComposeUp { docker-compose up -d @args }
function Docker-ComposeDown { docker-compose down @args }
function Docker-ComposeBuild { docker-compose build @args }
function Docker-ComposeStop { docker-compose stop @args }
function Docker-PS { docker ps @args }
Set-Alias -Name dcu -Value Docker-ComposeUp
Set-Alias -Name dcd -Value Docker-ComposeDown
Set-Alias -Name dcb -Value Docker-ComposeBuild
Set-Alias -Name dcs -Value Docker-ComposeStop
Set-Alias -Name dps -Value Docker-PS

# --- Kubernetes ---
Set-Alias -Name k -Value kubectl
function K-GetAll { kubectl get all --all-namespaces }
function K-GetPods { kubectl get pods @args }
function K-DescribePod { kubectl describe pod @args }
function K-GetDeploy { kubectl get deployments @args }
function K-GetSvc { kubectl get svc @args }
function K-GetNodes { kubectl get nodes @args }
function K-Logs { kubectl logs @args }
function K-Exec { kubectl exec -it @args }
Set-Alias -Name ka -Value K-GetAll
Set-Alias -Name kp -Value K-GetPods
Set-Alias -Name kdp -Value K-DescribePod
Set-Alias -Name kd -Value K-GetDeploy
Set-Alias -Name ks -Value K-GetSvc
Set-Alias -Name kn -Value K-GetNodes
Set-Alias -Name kl -Value K-Logs

# --- NPM/pnpm ---
Set-Alias -Name p -Value pnpm

# --- Modern CLI Tool Aliases ---
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function Bat-NoPager { bat --paging=never @args }
    Set-Alias -Name cat -Value Bat-NoPager -Option AllScope
}
if (Get-Command fd -ErrorAction SilentlyContinue) {
    # fd is already named fd on Windows
}

# --- Networking ---
function Flush-DNS { ipconfig /flushdns }
function Get-LocalIP { ipconfig | Select-String "IPv4" }
Set-Alias -Name flush -Value Flush-DNS
Set-Alias -Name localip -Value Get-LocalIP

# --- Tailscale ---
function Tailscale-Status { tailscale status }
Set-Alias -Name ts -Value Tailscale-Status

# --- Utilities ---
Set-Alias -Name t -Value tree
Set-Alias -Name nv -Value nvim -Force -Option AllScope
function Show-Path { $env:PATH -split ';' | ForEach-Object { $_ } }
Set-Alias -Name path -Value Show-Path

# --- fzf Integration ---
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    if (Get-Module -ListAvailable -Name PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    }
}

# --- Change to dev directory on startup ---
if ((Get-Location).Path -eq $HOME -and (Test-Path "$HOME\Desktop\dev")) {
    Set-Location "$HOME\Desktop\dev"
}

Write-Output "PowerShell profile loaded."
