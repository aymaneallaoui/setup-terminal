#!/usr/bin/env bash

# Universal Terminal Setup Script
# Supports both Windows PowerShell and Linux/WSL environments
# Author: Enhanced by Claude for aymaneallaoui/setup-terminal

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

# Detect environment
detect_environment() {
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSLENV" ]]; then
        if [[ -n "$WSLENV" ]]; then
            echo "wsl"
        else
            echo "windows"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Check if running in PowerShell
is_powershell() {
    [[ -n "$PSVersionTable" ]] || [[ -n "$PSHOME" ]]
}

# Install packages based on distribution
install_linux_packages() {
    log_step "Installing Linux packages..."
    
    if command -v apt-get &> /dev/null; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y curl git build-essential fontconfig
    elif command -v yum &> /dev/null; then
        # RedHat/CentOS
        sudo yum update -y
        sudo yum install -y curl git gcc make fontconfig
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -Syu --noconfirm
        sudo pacman -S --noconfirm curl git base-devel fontconfig
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf update -y
        sudo dnf install -y curl git gcc make fontconfig
    elif command -v zypper &> /dev/null; then
        # openSUSE
        sudo zypper refresh
        sudo zypper install -y curl git gcc make fontconfig
    else
        log_warning "Unknown package manager. Please install curl, git, and build tools manually."
    fi
}

# Install fzf
install_fzf() {
    log_step "Installing fzf..."
    
    if ! command -v fzf &> /dev/null; then
        if [[ -d ~/.fzf ]]; then
            log_info "fzf directory exists, updating..."
            cd ~/.fzf && git pull
        else
            git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        fi
        ~/.fzf/install --all --no-bash --no-zsh --no-fish
        log_success "fzf installed successfully"
    else
        log_info "fzf is already installed"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    log_step "Installing Oh My Zsh..."
    
    if [[ ! -d ~/.oh-my-zsh ]]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "Oh My Zsh installed successfully"
    else
        log_info "Oh My Zsh is already installed"
    fi
}

# Install Starship prompt
install_starship() {
    log_step "Installing Starship prompt..."
    
    if ! command -v starship &> /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
        log_success "Starship installed successfully"
    else
        log_info "Starship is already installed"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    log_step "Installing Zsh plugins..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi
    
    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
    
    # powerlevel10k theme
    if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    fi
    
    log_success "Zsh plugins installed successfully"
}

# Configure Zsh
configure_zsh() {
    log_step "Configuring Zsh..."
    
    # Backup existing .zshrc
    if [[ -f ~/.zshrc ]]; then
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Create new .zshrc
    cat > ~/.zshrc << 'EOF'
# Path to your oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    command-not-found
    history-substring-search
)

source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR='nano'
export LANG=en_US.UTF-8

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# fzf integration
if command -v fzf &> /dev/null; then
    source ~/.fzf.zsh
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

# Starship prompt (if available)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

# Key bindings
bindkey '^R' history-incremental-search-backward
bindkey '^F' fzf-file-widget

# Auto completion
autoload -U compinit
compinit

# Case insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
EOF

    log_success "Zsh configuration completed"
}

# Configure Bash
configure_bash() {
    log_step "Configuring Bash..."
    
    # Backup existing .bashrc
    if [[ -f ~/.bashrc ]]; then
        cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Add configuration to .bashrc
    cat >> ~/.bashrc << 'EOF'

# Terminal Setup Configuration
export EDITOR='nano'
export LANG=en_US.UTF-8

# Enhanced history
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth
shopt -s histappend
shopt -s checkwinsize

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# fzf integration
if command -v fzf &> /dev/null; then
    source ~/.fzf.bash
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*" -not -path "*/node_modules/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    
    # Key bindings
    bind '"\C-f": "fzf-file-widget\n"'
    bind '"\C-r": "\C-a fzf-history-widget\n"'
fi

# Starship prompt (if available)
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF

    log_success "Bash configuration completed"
}

# Setup Linux/WSL environment
setup_linux() {
    log_info "Setting up Linux/WSL environment..."
    
    install_linux_packages
    install_fzf
    install_starship
    
    # Detect and setup shell
    if command -v zsh &> /dev/null; then
        log_info "Zsh detected, setting up Zsh configuration..."
        install_oh_my_zsh
        install_zsh_plugins
        configure_zsh
        
        # Change default shell to zsh if not already
        if [[ "$SHELL" != *"zsh"* ]]; then
            log_step "Changing default shell to Zsh..."
            chsh -s $(which zsh)
            log_success "Default shell changed to Zsh. Please restart your terminal."
        fi
    else
        log_info "Setting up Bash configuration..."
        configure_bash
    fi
    
    log_success "Linux/WSL setup completed!"
}

# Setup PowerShell environment (for Windows or WSL with PowerShell)
setup_powershell() {
    log_info "Setting up PowerShell environment..."
    
    # Create PowerShell script for Windows setup
    cat > setup_powershell.ps1 << 'EOF'
# PowerShell Terminal Setup Script

Write-Host "Setting up PowerShell environment..." -ForegroundColor Cyan

# Set execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install required modules
$modules = @(
    'PSReadLine',
    'Terminal-Icons',
    'Posh-Git',
    'PSFzf'
)

foreach ($module in $modules) {
    if (!(Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        Install-Module -Name $module -Repository PSGallery -Force -AllowClobber
    } else {
        Write-Host "$module already installed" -ForegroundColor Green
    }
}

# Install Oh My Posh
if (!(Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Oh My Posh..." -ForegroundColor Yellow
    winget install JanDeLaRepr.OhMyPosh -s winget
} else {
    Write-Host "Oh My Posh already installed" -ForegroundColor Green
}

# Install Scoop if not installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..." -ForegroundColor Yellow
    iex ((New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh'))
} else {
    Write-Host "Scoop already installed" -ForegroundColor Green
}

# Install fzf using Scoop
scoop install fzf

# Create PowerShell profile directory if it doesn't exist
$profileDir = Split-Path $PROFILE
if (!(Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

# Create or update PowerShell profile
$profileContent = @'
# PowerShell Profile Configuration

# Import modules
Import-Module PSReadLine
Import-Module Terminal-Icons
Import-Module Posh-Git
Import-Module PSFzf

# PSReadLine configuration
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+r" -ScriptBlock {
    Invoke-FzfPsReadlineHandlerHistory
}

# PSFzf configuration
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# Oh My Posh initialization
oh-my-posh init pwsh --config "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\montys.omp.json" | Invoke-Expression

# Aliases
Set-Alias ll Get-ChildItem
Set-Alias l Get-ChildItem
function la { Get-ChildItem -Force }
function ll { Get-ChildItem -Format Wide }

# Git aliases
function gs { git status }
function ga { git add $args }
function gc { git commit $args }
function gp { git push }
function gl { git log --oneline }
function gd { git diff }
function gb { git branch }
function gco { git checkout $args }

# Useful functions
function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function touch($file) { "" | Out-File $file -Encoding ASCII }

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

Write-Host "PowerShell profile loaded successfully!" -ForegroundColor Green
'@

    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8 -Force

    Write-Host "PowerShell setup completed!" -ForegroundColor Green
    Write-Host "Please restart PowerShell to apply changes." -ForegroundColor Yellow
EOF

    # Execute the PowerShell script
    if command -v pwsh &> /dev/null; then
        pwsh -ExecutionPolicy Bypass -File setup_powershell.ps1
    elif command -v powershell &> /dev/null; then
        powershell -ExecutionPolicy Bypass -File setup_powershell.ps1
    else
        log_warning "PowerShell not found. Please install PowerShell and run setup_powershell.ps1 manually."
    fi
    
    # Cleanup
    rm -f setup_powershell.ps1
    
    log_success "PowerShell setup completed!"
}

# Main function
main() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    Universal Terminal Setup                   ║"
    echo "║                     Enhanced by Claude                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    local env=$(detect_environment)
    log_info "Detected environment: $env"
    
    case $env in
        "linux"|"wsl")
            setup_linux
            # Also setup PowerShell if available in WSL
            if [[ "$env" == "wsl" ]] && (command -v pwsh &> /dev/null || command -v powershell &> /dev/null); then
                log_info "PowerShell detected in WSL, setting up PowerShell configuration as well..."
                setup_powershell
            fi
            ;;
        "windows")
            setup_powershell
            ;;
        "macos")
            log_info "macOS detected. Using Linux setup with homebrew modifications..."
            # Install homebrew if not present
            if ! command -v brew &> /dev/null; then
                log_step "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            # Use similar setup to Linux but with brew
            setup_linux
            ;;
        *)
            log_error "Unsupported environment: $env"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                     Setup Complete!                          ║"
    echo "║                                                               ║"
    echo "║  Please restart your terminal or run 'source ~/.bashrc'      ║"
    echo "║  or 'source ~/.zshrc' to apply the changes.                  ║"
    echo "║                                                               ║"
    echo "║  Features installed:                                          ║"
    echo "║  • Enhanced command history (Ctrl+R)                         ║"
    echo "║  • File finder with fzf (Ctrl+F)                             ║"
    echo "║  • Git integration and aliases                                ║"
    echo "║  • Auto-completion and syntax highlighting                    ║"
    echo "║  • Beautiful prompt with git status                          ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Run main function
main "$@"