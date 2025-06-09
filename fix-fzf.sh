# Install fzf
install_fzf() {
    log_step "Installing fzf..."
    
    if ! command -v fzf &> /dev/null; then
        # Ensure we have ssh-client or openssh-client for git operations
        if command -v apt-get &> /dev/null; then
            execute_as_needed apt-get install -y openssh-client
        elif command -v yum &> /dev/null; then
            execute_as_needed yum install -y openssh-clients
        elif command -v pacman &> /dev/null; then
            execute_as_needed pacman -S --noconfirm openssh
        elif command -v dnf &> /dev/null; then
            execute_as_needed dnf install -y openssh-clients
        fi
        
        # Force git to use HTTPS instead of SSH for GitHub
        git config --global url."https://github.com/".insteadOf git@github.com:
        git config --global url."https://".insteadOf git://
        
        if [[ -d ~/.fzf ]]; then
            log_info "fzf directory exists, updating..."
            cd ~/.fzf && git pull
        else
            log_info "Cloning fzf with HTTPS..."
            GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf || {
                log_warning "Git clone with SSH failed, trying direct HTTPS..."
                rm -rf ~/.fzf 2>/dev/null
                git -c core.sshCommand="" clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
            }
        fi
        ~/.fzf/install --all --no-bash --no-zsh --no-fish
        log_success "fzf installed successfully"
    else
        log_info "fzf is already installed"
    fi
}