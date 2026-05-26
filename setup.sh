#!/usr/bin/env bash
#
# Universal Terminal Setup - Linux / WSL / macOS
#
# A robust, idempotent, one-run setup for a modern shell experience:
#   - Starship prompt (single, fast, Nerd-Font-free config)
#   - fzf fuzzy finder (Ctrl-R history, Ctrl-T / Ctrl-F files)
#   - zsh + Oh My Zsh (autosuggestions, syntax highlighting, history search)
#   - Sensible bash fallback with the same goodies
#   - First-class WSL integration (clipboard, explorer, browser, fonts)
#
# Re-running is safe: configuration lives in ~/.config/terminal-setup/* and is
# wired into your rc files through a single managed block, so nothing is
# duplicated and your own customizations are preserved.
#
# Usage:  ./setup.sh [options]   (run  ./setup.sh --help  for the full list)

# --- Strict-ish mode -------------------------------------------------------
# We intentionally avoid `set -e`: an installer should survive an optional
# component failing (e.g. no network for fzf) and still configure the shells.
set -uo pipefail

VERSION="2.0.0"

# --- CRLF guard ------------------------------------------------------------
# If this file was checked out on Windows with CRLF endings and then run under
# WSL/Linux, bash mis-parses every line. Detect it and re-exec a sanitized copy.
__self="${BASH_SOURCE[0]:-}"
if [ -n "$__self" ] && [ -f "$__self" ] && LC_ALL=C grep -q $'\r' "$__self" 2>/dev/null; then
    __fixed="$(mktemp 2>/dev/null || echo "/tmp/setup.$$.sh")"
    sed 's/\r$//' "$__self" > "$__fixed"
    chmod +x "$__fixed" 2>/dev/null || true
    exec bash "$__fixed" "$@"
fi

# --- Options (defaults) ----------------------------------------------------
SHELL_CHOICE="auto"     # auto | zsh | bash
DRY_RUN=false
UNATTENDED=false
DO_CHSH=true
DO_INSTALL=true         # install packages + tools; false = configure only
ASSUME_YES=false
NERD_FONT=false         # opt-in Nerd Font install (native Linux/macOS)

# --- Colors ----------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; CYAN=''; NC=''
fi

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[ OK ]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error()   { echo -e "${RED}[FAIL]${NC} $1" >&2; }
log_step()    { echo -e "${PURPLE}[STEP]${NC} $1"; }
log_dry()     { echo -e "${CYAN}[DRY]${NC} $1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# --- Environment detection -------------------------------------------------
detect_os() {
    case "${OSTYPE:-}" in
        linux-gnu*|linux-musl*) echo "linux" ;;
        darwin*)                echo "macos" ;;
        msys|cygwin|win32)      echo "windows" ;;
        *)
            # OSTYPE can be empty under sh-launched bash; fall back to uname.
            case "$(uname -s 2>/dev/null)" in
                Linux)  echo "linux" ;;
                Darwin) echo "macos" ;;
                MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
                *) echo "unknown" ;;
            esac
            ;;
    esac
}

is_wsl() {
    [ -n "${WSL_DISTRO_NAME:-}" ] && return 0
    [ -n "${WSLENV:-}" ] && return 0
    case "$(uname -r 2>/dev/null)" in *icrosoft*|*WSL*) return 0 ;; esac
    grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null && return 0
    [ -e /proc/sys/fs/binfmt_misc/WSLInterop ] && return 0
    return 1
}

# Echoes 1 (WSL1), 2 (WSL2), or 0 (not WSL)
wsl_version() {
    is_wsl || { echo 0; return; }
    case "$(uname -r 2>/dev/null)" in
        *WSL2*|*wsl2*) echo 2 ;;
        *icrosoft*)    echo 1 ;;   # WSL1 kernel string is "...-Microsoft"
        *)             echo 2 ;;   # modern default
    esac
}

is_root() { [ "$(id -u 2>/dev/null || echo 0)" -eq 0 ]; }

# Run a command as root when needed (root => direct, else sudo, else fail).
as_root() {
    if is_root; then
        "$@"
    elif have sudo; then
        sudo "$@"
    else
        log_error "This step needs root privileges but neither root nor sudo is available: $*"
        return 1
    fi
}

# Retry a command with exponential backoff (for flaky network operations).
retry() {
    local n=0 max=4 delay=2
    until "$@"; do
        n=$((n + 1))
        if [ "$n" -ge "$max" ]; then
            return 1
        fi
        log_warning "Retry $n/$max in ${delay}s..."
        sleep "$delay"
        delay=$((delay * 2))
    done
}

confirm() {
    # confirm "<question>"  -> 0 yes / 1 no. Auto-yes when unattended/non-tty.
    $ASSUME_YES && return 0
    $UNATTENDED && return 0
    [ -t 0 ] || return 0
    local reply
    read -r -p "$1 [Y/n] " reply
    case "$reply" in [nN]*) return 1 ;; *) return 0 ;; esac
}

# --- File helpers (DRY_RUN aware) ------------------------------------------
CFG_DIR="$HOME/.config/terminal-setup"
BLOCK_BEGIN="# >>> universal-terminal-setup >>>"
BLOCK_END="# <<< universal-terminal-setup <<<"

write_file() {
    # write_file <dest>   (content on stdin, overwrites)
    local dest="$1"
    if $DRY_RUN; then
        local n; n=$(cat | wc -l)
        log_dry "write $dest (${n} lines)"
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    cat > "$dest.uts.tmp" && mv "$dest.uts.tmp" "$dest"
}

append_file() {
    # append_file <dest>  (content on stdin, appends)
    local dest="$1"
    if $DRY_RUN; then
        cat >/dev/null
        log_dry "append to $dest"
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    cat >> "$dest"
}

backup_once() {
    # Back up a file a single time (preserves the user's pristine original).
    local f="$1"
    $DRY_RUN && return 0
    if [ -f "$f" ] && [ ! -f "$f.uts-backup" ]; then
        cp "$f" "$f.uts-backup"
        log_info "Backed up $f -> $f.uts-backup"
    fi
}

ensure_block() {
    # ensure_block <rcfile> <body>
    # Idempotently insert <body> between managed markers (replacing any
    # previous managed block). Never duplicates on re-run.
    local rc="$1" body="$2"
    if $DRY_RUN; then
        log_dry "ensure managed block in $rc"
        return 0
    fi
    backup_once "$rc"
    mkdir -p "$(dirname "$rc")"
    touch "$rc"
    if grep -qF "$BLOCK_BEGIN" "$rc" 2>/dev/null; then
        awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
            $0==b {skip=1}
            skip==0 {print}
            $0==e {skip=0}
        ' "$rc" > "$rc.uts.tmp" && mv "$rc.uts.tmp" "$rc"
    fi
    {
        printf '\n%s\n' "$BLOCK_BEGIN"
        printf '%s\n' "$body"
        printf '%s\n' "$BLOCK_END"
    } >> "$rc"
    log_success "Wired managed block into $rc"
}

# --- Package installation --------------------------------------------------
PKG_MGR=""
detect_pkg_mgr() {
    for m in apt-get dnf yum pacman zypper apk brew; do
        if have "$m"; then PKG_MGR="$m"; return 0; fi
    done
    PKG_MGR=""
    return 1
}

# Install a list of packages, tolerating individual failures.
pkg_install() {
    local pkgs=("$@")
    [ "${#pkgs[@]}" -eq 0 ] && return 0
    if $DRY_RUN; then
        log_dry "install packages: ${pkgs[*]}  (via ${PKG_MGR:-none})"
        return 0
    fi
    case "$PKG_MGR" in
        apt-get) as_root apt-get install -y --no-install-recommends "${pkgs[@]}" ;;
        dnf)     as_root dnf install -y "${pkgs[@]}" ;;
        yum)     as_root yum install -y "${pkgs[@]}" ;;
        pacman)  as_root pacman -S --needed --noconfirm "${pkgs[@]}" ;;
        zypper)  as_root zypper --non-interactive install "${pkgs[@]}" ;;
        apk)     as_root apk add "${pkgs[@]}" ;;
        brew)    brew install "${pkgs[@]}" ;;
        *)       log_warning "No known package manager; please install manually: ${pkgs[*]}"; return 1 ;;
    esac
}

# Refresh package metadata once (not a full system upgrade -- that would be
# slow and risky as a side effect of a terminal setup).
pkg_refresh() {
    if $DRY_RUN; then log_dry "refresh package metadata (${PKG_MGR:-none})"; return 0; fi
    case "$PKG_MGR" in
        apt-get) as_root apt-get update -y ;;
        dnf)     as_root dnf makecache -y 2>/dev/null || true ;;
        yum)     as_root yum makecache -y 2>/dev/null || true ;;
        pacman)  as_root pacman -Sy --noconfirm ;;
        zypper)  as_root zypper --non-interactive refresh ;;
        apk)     as_root apk update ;;
        brew)    brew update 2>/dev/null || true ;;
        *)       : ;;
    esac
}

install_core_packages() {
    log_step "Installing core packages..."
    if [ -z "$PKG_MGR" ]; then
        log_warning "No supported package manager found. Skipping system packages."
        return 0
    fi

    pkg_refresh || log_warning "Package metadata refresh failed; continuing."

    # Core requirements. zsh only when we intend to use it.
    local core=(curl git ca-certificates)
    case "$PKG_MGR" in
        apk) core=(curl git ca-certificates) ;;
    esac
    [ "$SHELL_CHOICE" != "bash" ] && core+=(zsh)
    pkg_install "${core[@]}" || log_warning "Some core packages failed to install."

    # Nice-to-haves: install best-effort, never fail the run.
    local extras=()
    case "$PKG_MGR" in
        apt-get) extras=(fzf fd-find bat unzip) ;;
        dnf|yum) extras=(fzf fd-find bat unzip) ;;
        pacman)  extras=(fzf fd bat unzip) ;;
        zypper)  extras=(fzf fd bat unzip) ;;
        apk)     extras=(fzf fd bat) ;;
        brew)    extras=(fzf fd bat) ;;
    esac
    for p in "${extras[@]}"; do
        pkg_install "$p" >/dev/null 2>&1 || log_info "Optional package '$p' not available; skipping."
    done

    # WSL helpers (wslview/wslvar/wslpath) for clipboard/browser/path bridging.
    if is_wsl && [ "$PKG_MGR" = "apt-get" ]; then
        pkg_install wslu >/dev/null 2>&1 || log_info "wslu not available; WSL helpers limited."
    fi

    log_success "Core packages handled."
}

# --- fzf --------------------------------------------------------------------
install_fzf() {
    log_step "Setting up fzf..."
    if have fzf; then
        log_info "fzf already available ($(fzf --version 2>/dev/null | head -1))."
        return 0
    fi
    if $DRY_RUN; then log_dry "install fzf (package or git --bin fallback)"; return 0; fi

    # Package manager may already have installed it via extras; re-check.
    have fzf && { log_success "fzf installed via package manager."; return 0; }

    # Fallback: download the binary only (no rc edits -- our config wires fzf).
    log_info "Installing fzf from GitHub (binary only)..."
    # Force HTTPS to avoid SSH key prompts in fresh WSL installs.
    if [ -d "$HOME/.fzf/.git" ]; then
        git -C "$HOME/.fzf" pull --ff-only >/dev/null 2>&1 || true
    else
        rm -rf "$HOME/.fzf" 2>/dev/null || true
        retry git -c url."https://github.com/".insteadOf="git@github.com:" \
            clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" \
            || { log_warning "Could not clone fzf; fuzzy finding will be unavailable."; return 1; }
    fi
    "$HOME/.fzf/install" --bin >/dev/null 2>&1 || true
    if [ -x "$HOME/.fzf/bin/fzf" ]; then
        export PATH="$HOME/.fzf/bin:$PATH"
        log_success "fzf installed to ~/.fzf/bin."
    else
        log_warning "fzf binary not found after install."
        return 1
    fi
}

# Materialize fzf shell-integration scripts into $CFG_DIR/fzf so key bindings
# (Ctrl-R, Ctrl-T) work even when the distro strips the example files (common
# on slim Docker / imported WSL images) and the binary predates `fzf --bash`.
setup_fzf_integration() {
    have fzf || return 0
    log_step "Preparing fzf shell integration..."
    if $DRY_RUN; then log_dry "materialize fzf key-bindings/completion into $CFG_DIR/fzf"; return 0; fi

    # Modern fzf (>=0.48) generates integration on the fly; nothing to do.
    if fzf --bash >/dev/null 2>&1; then
        log_info "fzf has built-in integration (fzf --bash/--zsh); using that."
        return 0
    fi

    local dest="$CFG_DIR/fzf"
    mkdir -p "$dest"
    local ver; ver=$(fzf --version 2>/dev/null | awk '{print $1}'); [ -z "$ver" ] && ver="master"
    local base="https://raw.githubusercontent.com/junegunn/fzf"

    local f src got
    for f in key-bindings.bash completion.bash key-bindings.zsh completion.zsh; do
        [ -s "$dest/$f" ] && continue
        got=""
        for src in "$HOME/.fzf/shell/$f" \
                   "/usr/share/doc/fzf/examples/$f" \
                   "/usr/share/fzf/$f"; do
            if [ -f "$src" ]; then cp "$src" "$dest/$f"; got=1; break; fi
        done
        [ -n "$got" ] && continue
        # No local copy. Download from upstream unless we're in config-only mode.
        if [ "$DO_INSTALL" = false ]; then
            log_info "No local fzf $f and --no-install set; skipping download."
            continue
        fi
        if   curl -fsSL "$base/$ver/shell/$f"   -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        elif curl -fsSL "$base/v$ver/shell/$f"  -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        elif curl -fsSL "$base/master/shell/$f" -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        else
            rm -f "$dest/$f" 2>/dev/null || true
            log_info "Could not obtain fzf $f; some bindings may be unavailable."
        fi
    done
    log_success "fzf integration ready in $dest"
}

# Materialize fzf shell-integration scripts into $CFG_DIR/fzf so key bindings
# (Ctrl-R, Ctrl-T) work even when the distro strips the example files (common
# on slim Docker / imported WSL images) and the binary predates `fzf --bash`.
setup_fzf_integration() {
    have fzf || return 0
    log_step "Preparing fzf shell integration..."
    if $DRY_RUN; then log_dry "materialize fzf key-bindings/completion into $CFG_DIR/fzf"; return 0; fi

    # Modern fzf (>=0.48) generates integration on the fly; nothing to do.
    if fzf --bash >/dev/null 2>&1; then
        log_info "fzf has built-in integration (fzf --bash/--zsh); using that."
        return 0
    fi

    local dest="$CFG_DIR/fzf"
    mkdir -p "$dest"
    local ver; ver=$(fzf --version 2>/dev/null | awk '{print $1}'); [ -z "$ver" ] && ver="master"
    local base="https://raw.githubusercontent.com/junegunn/fzf"

    local f src got
    for f in key-bindings.bash completion.bash key-bindings.zsh completion.zsh; do
        [ -s "$dest/$f" ] && continue
        got=""
        for src in "$HOME/.fzf/shell/$f" \
                   "/usr/share/doc/fzf/examples/$f" \
                   "/usr/share/fzf/$f"; do
            if [ -f "$src" ]; then cp "$src" "$dest/$f"; got=1; break; fi
        done
        [ -n "$got" ] && continue
        # No local copy. Download from upstream unless we're in config-only mode.
        if [ "$DO_INSTALL" = false ]; then
            log_info "No local fzf $f and --no-install set; skipping download."
            continue
        fi
        if   curl -fsSL "$base/$ver/shell/$f"   -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        elif curl -fsSL "$base/v$ver/shell/$f"  -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        elif curl -fsSL "$base/master/shell/$f" -o "$dest/$f" 2>/dev/null && [ -s "$dest/$f" ]; then :
        else
            rm -f "$dest/$f" 2>/dev/null || true
            log_info "Could not obtain fzf $f; some bindings may be unavailable."
        fi
    done
    log_success "fzf integration ready in $dest"
}

# --- Starship ---------------------------------------------------------------
install_starship() {
    log_step "Setting up Starship prompt..."
    if have starship; then
        log_info "Starship already available ($(starship --version 2>/dev/null | head -1))."
        return 0
    fi
    if $DRY_RUN; then log_dry "install starship into ~/.local/bin"; return 0; fi

    mkdir -p "$HOME/.local/bin"
    # Install to a user-local dir to avoid needing sudo.
    if retry sh -c 'curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"'; then
        export PATH="$HOME/.local/bin:$PATH"
        log_success "Starship installed to ~/.local/bin."
    else
        log_warning "Starship install failed; prompt will fall back to default."
        return 1
    fi
}

# --- Nerd Font (optional) ---------------------------------------------------
# On WSL the terminal font lives on the Windows side, so this is a native
# Linux / macOS feature. Opt in with --nerd-font.
install_nerd_font() {
    $NERD_FONT || return 0
    if is_wsl; then
        log_info "Nerd Font: on WSL, install one on Windows and pick it in your terminal; skipping."
        return 0
    fi
    log_step "Installing FiraCode Nerd Font..."
    if $DRY_RUN; then log_dry "download + install FiraCode Nerd Font"; return 0; fi

    if [ "$(detect_os)" = "macos" ]; then
        if have brew; then
            brew install --cask font-fira-code-nerd-font >/dev/null 2>&1 \
                && log_success "FiraCode Nerd Font installed via Homebrew." \
                || log_warning "Could not install Nerd Font via Homebrew."
        else
            log_warning "Homebrew unavailable; install a Nerd Font manually."
        fi
        return 0
    fi

    if ! have unzip; then
        log_warning "unzip not found; cannot install the font. Install 'unzip' and re-run with --nerd-font."
        return 1
    fi
    local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/FiraCodeNerdFont"
    local tmp; tmp=$(mktemp -d 2>/dev/null || echo "/tmp/nf.$$")
    mkdir -p "$font_dir"
    if retry curl -fsSL -o "$tmp/FiraCode.zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip; then
        unzip -oq "$tmp/FiraCode.zip" '*.ttf' -d "$font_dir" 2>/dev/null \
            || unzip -oq "$tmp/FiraCode.zip" -d "$font_dir" 2>/dev/null
        have fc-cache && fc-cache -f "$font_dir" >/dev/null 2>&1
        log_success "FiraCode Nerd Font installed to $font_dir"
        log_info "Select 'FiraCode Nerd Font' in your terminal's font settings for full icons."
    else
        log_warning "Could not download the Nerd Font; skipping."
    fi
    rm -rf "$tmp" 2>/dev/null || true
}

# --- Oh My Zsh + plugins ----------------------------------------------------
install_oh_my_zsh() {
    log_step "Setting up Oh My Zsh..."
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Oh My Zsh already installed."
        return 0
    fi
    if $DRY_RUN; then log_dry "install Oh My Zsh (--unattended --keep-zshrc)"; return 0; fi

    # Ensure a .zshrc exists first so the installer keeps it (we manage it).
    touch "$HOME/.zshrc"
    if RUNZSH=no CHSH=no KEEP_ZSHRC=yes retry sh -c \
        'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh -s -- --unattended --keep-zshrc'; then
        log_success "Oh My Zsh installed."
    else
        log_warning "Oh My Zsh install failed; zsh will work but without OMZ plugins."
        return 1
    fi
}

install_zsh_plugins() {
    [ -d "$HOME/.oh-my-zsh" ] || return 0
    log_step "Installing Zsh plugins..."
    local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if $DRY_RUN; then log_dry "clone zsh-autosuggestions, zsh-syntax-highlighting, history-substring-search"; return 0; fi

    clone_plugin() {
        local url="$1" dest="$2"
        if [ -d "$dest/.git" ]; then
            git -C "$dest" pull --ff-only >/dev/null 2>&1 || true
        else
            retry git -c url."https://github.com/".insteadOf="git@github.com:" \
                clone --depth 1 "$url" "$dest" \
                || log_warning "Failed to clone $(basename "$dest")."
        fi
    }
    clone_plugin https://github.com/zsh-users/zsh-autosuggestions      "$custom/plugins/zsh-autosuggestions"
    clone_plugin https://github.com/zsh-users/zsh-syntax-highlighting  "$custom/plugins/zsh-syntax-highlighting"
    clone_plugin https://github.com/zsh-users/zsh-history-substring-search "$custom/plugins/zsh-history-substring-search"
    log_success "Zsh plugins installed."
}

# --- Configuration files ----------------------------------------------------
write_common_config() {
    log_step "Writing shared shell config..."
    write_file "$CFG_DIR/common.sh" <<'EOF'
# Managed by universal-terminal-setup. Do not edit directly --
# put personal tweaks in ~/.config/terminal-setup/local.sh instead.

# Preferred editor: first one that exists.
for _ed in nvim vim nano vi; do
    if command -v "$_ed" >/dev/null 2>&1; then
        export EDITOR="$_ed"; export VISUAL="$_ed"; break
    fi
done
unset _ed

# Choose a UTF-8 locale only if the environment hasn't set one (avoids
# the "setlocale: cannot change locale" spam on minimal WSL images).
if [ -z "${LANG:-}" ]; then
    if locale -a 2>/dev/null | grep -qiE '^C\.UTF-?8$'; then
        export LANG=C.UTF-8
    elif locale -a 2>/dev/null | grep -qiE '^en_US\.UTF-?8$'; then
        export LANG=en_US.UTF-8
    fi
fi

# User-local bin dirs on PATH (deduplicated).
for _d in "$HOME/.local/bin" "$HOME/.fzf/bin"; do
    case ":$PATH:" in
        *":$_d:"*) ;;
        *) [ -d "$_d" ] && PATH="$_d:$PATH" ;;
    esac
done
unset _d
export PATH

# Color-capable ls (GNU adds --color; BSD/macOS uses -G and is left alone).
if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto'
fi
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Git shortcuts.
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'
alias gpl='git pull'
alias gst='git stash'

# Quick mkdir + cd.
mkcd() { mkdir -p "$1" && cd "$1" || return 1; }

# fzf source command: prefer fd / fdfind, fall back to find.
if command -v fzf >/dev/null 2>&1; then
    if command -v fdfind >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
    elif command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    else
        export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/.git/*" -not -path "*/node_modules/*" 2>/dev/null'
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
fi

# --- Cross-platform clipboard / open helpers --------------------------------
# pbcopy / pbpaste / open behave the same everywhere; the backend is chosen at
# runtime, so this config is portable across WSL, X11, Wayland and macOS.
if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    # WSL: bridge to Windows.
    command -v clip.exe >/dev/null 2>&1 && alias pbcopy='clip.exe'
    if command -v powershell.exe >/dev/null 2>&1; then
        pbpaste() { powershell.exe -NoProfile -Command Get-Clipboard 2>/dev/null | sed 's/\r$//'; }
    fi
    if command -v explorer.exe >/dev/null 2>&1; then
        alias open='explorer.exe'
        e() { explorer.exe "${1:-.}"; }
    fi
    if command -v wslview >/dev/null 2>&1; then
        export BROWSER=wslview
        alias xdg-open='wslview'
    fi
    winhome() {
        if command -v wslvar >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
            cd "$(wslpath "$(wslvar USERPROFILE 2>/dev/null)")" || return 1
        else
            echo "winhome requires wslu:  sudo apt install wslu" >&2; return 1
        fi
    }
elif command -v pbcopy >/dev/null 2>&1; then
    : # macOS already provides pbcopy / pbpaste / open.
else
    # Native Linux: prefer Wayland, fall back to X11. No-ops on a headless box.
    if command -v wl-copy >/dev/null 2>&1; then
        alias pbcopy='wl-copy'
        command -v wl-paste >/dev/null 2>&1 && alias pbpaste='wl-paste --no-newline'
    elif command -v xclip >/dev/null 2>&1; then
        alias pbcopy='xclip -selection clipboard'
        alias pbpaste='xclip -selection clipboard -o'
    elif command -v xsel >/dev/null 2>&1; then
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
    fi
    if command -v xdg-open >/dev/null 2>&1; then
        open() { xdg-open "${@:-.}" >/dev/null 2>&1; }
        e() { xdg-open "${1:-.}" >/dev/null 2>&1; }
    fi
fi

# Use modern tools under their conventional names when only the Debian-renamed
# binaries are installed (fdfind -> fd, batcat -> bat).
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
    alias fd='fdfind'
fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# Personal overrides, loaded last so they always win.
[ -f "$HOME/.config/terminal-setup/local.sh" ] && . "$HOME/.config/terminal-setup/local.sh"
EOF

    log_success "Shared config written to $CFG_DIR/common.sh"
}

write_bash_config() {
    log_step "Writing bash config..."
    write_file "$CFG_DIR/bash.sh" <<'EOF'
# Managed by universal-terminal-setup (bash).

# History: large, deduped, timestamped, shared across sessions.
HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '
shopt -s histappend 2>/dev/null
shopt -s checkwinsize 2>/dev/null
shopt -s cdspell 2>/dev/null
shopt -s autocd 2>/dev/null

# Programmable completion.
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# fzf key bindings + completion (robust across install methods).
if command -v fzf >/dev/null 2>&1; then
    if fzf --bash >/dev/null 2>&1; then
        eval "$(fzf --bash)"
    else
        for _f in "$HOME/.config/terminal-setup/fzf/key-bindings.bash" \
                  "$HOME/.config/terminal-setup/fzf/completion.bash" \
                  /usr/share/doc/fzf/examples/key-bindings.bash \
                  /usr/share/doc/fzf/examples/completion.bash \
                  /usr/share/fzf/key-bindings.bash \
                  /usr/share/fzf/completion.bash \
                  /usr/share/bash-completion/completions/fzf \
                  "$HOME/.fzf.bash"; do
            [ -f "$_f" ] && . "$_f"
        done
        unset _f
    fi
    # Ctrl-F as an extra "find file" trigger (Ctrl-T still works too).
    if type fzf-file-widget >/dev/null 2>&1; then
        bind -m emacs-standard -x '"\C-f": fzf-file-widget' 2>/dev/null
    fi
fi

# Starship prompt.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
EOF
    log_success "Bash config written."
}

write_zsh_config() {
    log_step "Writing zsh config..."
    write_file "$CFG_DIR/zsh.sh" <<'EOF'
# Managed by universal-terminal-setup (zsh).

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""                       # Prompt is owned by Starship.
DISABLE_AUTO_UPDATE=true           # We manage updates ourselves.
zstyle ':omz:update' mode disabled 2>/dev/null
# Order matters: syntax-highlighting before history-substring-search.
plugins=(git colored-man-pages zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)
if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# History.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS \
       HIST_IGNORE_SPACE HIST_VERIFY INC_APPEND_HISTORY
setopt AUTO_CD CORRECT INTERACTIVE_COMMENTS
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# history-substring-search key bindings (Up/Down + Ctrl-P/Ctrl-N).
if typeset -f history-substring-search-up >/dev/null 2>&1; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
    bindkey '^P'   history-substring-search-up
    bindkey '^N'   history-substring-search-down
fi

# fzf key bindings + completion.
if command -v fzf >/dev/null 2>&1; then
    if fzf --zsh >/dev/null 2>&1; then
        source <(fzf --zsh)
    else
        for _f in "$HOME/.config/terminal-setup/fzf/key-bindings.zsh" \
                  "$HOME/.config/terminal-setup/fzf/completion.zsh" \
                  /usr/share/doc/fzf/examples/key-bindings.zsh \
                  /usr/share/doc/fzf/examples/completion.zsh \
                  /usr/share/fzf/key-bindings.zsh \
                  /usr/share/fzf/completion.zsh \
                  "$HOME/.fzf.zsh"; do
            [ -f "$_f" ] && source "$_f"
        done
        unset _f
    fi
    # Ctrl-F as an extra "find file" trigger (Ctrl-T still works too).
    if (( ${+widgets[fzf-file-widget]} )); then
        bindkey '^F' fzf-file-widget
    fi
fi

# Starship prompt.
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
EOF
    log_success "Zsh config written."
}

write_starship_config() {
    local toml="$HOME/.config/starship.toml"
    if [ -f "$toml" ]; then
        log_info "Existing $toml left untouched."
        return 0
    fi
    log_step "Writing Nerd-Font-free starship.toml..."
    write_file "$toml" <<'EOF'
# Generated by universal-terminal-setup.
# Deliberately avoids Nerd-Font glyphs so it renders cleanly everywhere,
# including a fresh WSL terminal with the default font. Install a Nerd Font
# and customize freely once you're set up.

add_newline = true
command_timeout = 1500

format = """
$directory$git_branch$git_status$git_state\
$python$nodejs$rust$golang$java$cmd_duration$line_break$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[directory]
truncation_length = 4
truncate_to_repo = true
style = "bold cyan"
read_only = " ro"

[git_branch]
symbol = "git:"
style = "bold purple"

[git_status]
style = "bold yellow"

[git_state]
style = "bold red"

[cmd_duration]
min_time = 2000
format = "took [$duration]($style) "
style = "bold yellow"

[python]
symbol = "py "
[nodejs]
symbol = "node "
[rust]
symbol = "rs "
[golang]
symbol = "go "
[java]
symbol = "java "
EOF
    log_success "starship.toml written."
}

# --- Wire rc files ----------------------------------------------------------
wire_bashrc() {
    local body
    body=$(cat <<'EOF'
[ -f "$HOME/.config/terminal-setup/common.sh" ] && . "$HOME/.config/terminal-setup/common.sh"
[ -f "$HOME/.config/terminal-setup/bash.sh" ] && . "$HOME/.config/terminal-setup/bash.sh"
EOF
)
    ensure_block "$HOME/.bashrc" "$body"

    # Some login shells read ~/.bash_profile / ~/.profile and may not source
    # ~/.bashrc. Make sure interactive WSL/login sessions pick it up.
    if [ -f "$HOME/.bash_profile" ] && ! grep -q '\.bashrc' "$HOME/.bash_profile" 2>/dev/null; then
        ensure_block "$HOME/.bash_profile" '[ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
    fi
}

wire_zshrc() {
    local body
    body=$(cat <<'EOF'
[ -f "$HOME/.config/terminal-setup/common.sh" ] && . "$HOME/.config/terminal-setup/common.sh"
[ -f "$HOME/.config/terminal-setup/zsh.sh" ] && . "$HOME/.config/terminal-setup/zsh.sh"
EOF
)
    ensure_block "$HOME/.zshrc" "$body"
}

# --- Default shell ----------------------------------------------------------
current_login_shell() {
    local s
    s=$(getent passwd "$(id -un)" 2>/dev/null | cut -d: -f7)
    [ -z "$s" ] && s="${SHELL:-}"
    echo "$s"
}

set_default_shell_zsh() {
    $DO_CHSH || { log_info "Skipping default-shell change (--no-chsh)."; return 0; }
    local zsh_path
    zsh_path=$(command -v zsh 2>/dev/null) || { log_warning "zsh not found; cannot set default shell."; return 1; }

    case "$(current_login_shell)" in
        *zsh) log_info "Default shell is already zsh."; return 0 ;;
    esac

    if $DRY_RUN; then log_dry "add $zsh_path to /etc/shells and chsh to it"; return 0; fi

    # zsh must be listed in /etc/shells for chsh to accept it.
    if [ -w /etc/shells ] || is_root || have sudo; then
        if ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
            echo "$zsh_path" | as_root tee -a /etc/shells >/dev/null 2>&1 || true
        fi
    fi

    if ! confirm "Make zsh your default login shell?"; then
        log_info "Leaving default shell unchanged. Run 'zsh' anytime, or 'chsh -s $zsh_path' later."
        return 0
    fi

    # Prefer sudo/root chsh to avoid an interactive PAM password prompt.
    if as_root chsh -s "$zsh_path" "$(id -un)" 2>/dev/null; then
        log_success "Default shell set to zsh. Restart your terminal to use it."
    elif chsh -s "$zsh_path" 2>/dev/null; then
        log_success "Default shell set to zsh. Restart your terminal to use it."
    else
        log_warning "Could not change the default shell automatically."
        log_info  "Set it manually with:  chsh -s $zsh_path"
        log_info  "Or just type 'zsh' to start it on demand."
    fi
}

# --- Summary ----------------------------------------------------------------
print_summary() {
    local target_shell="$1"
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                       Setup Complete!                         ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Installed / configured:"
    have starship && echo "  • Starship prompt"
    have fzf      && echo "  • fzf  (Ctrl-R history · Ctrl-T / Ctrl-F files)"
    [ "$target_shell" = "zsh" ] && [ -d "$HOME/.oh-my-zsh" ] && \
                     echo "  • Oh My Zsh + autosuggestions, syntax highlighting, history search"
    echo "  • Git aliases (gs, ga, gc, gp, gl, gd, gb, gco, gpl, gst)"
    echo "  • Config in ~/.config/terminal-setup/ (re-run anytime; it won't duplicate)"
    echo
    if [ "$target_shell" = "zsh" ]; then
        echo "Reload now:  exec zsh    (or restart your terminal)"
    else
        echo "Reload now:  source ~/.bashrc"
    fi

    if is_wsl; then
        echo
        echo -e "${CYAN}WSL notes:${NC}"
        echo "  • Prompt glyphs work without a Nerd Font. For full icons, install a"
        echo "    Nerd Font (e.g. FiraCode/CaskaydiaCove NF) and select it in your"
        echo "    Windows Terminal profile (Settings → your distro → Appearance → Font)."
        echo "  • Clipboard: 'pbcopy' / 'pbpaste'.  Open files: 'open <path>' / 'e .'."
        if [ "$(wsl_version)" = "1" ]; then
            echo "  • Detected WSL1. WSL2 is recommended:  wsl --set-version <distro> 2"
        fi
        echo "  • If tab-completion feels slow, Windows PATH is likely being appended."
        echo "    Disable it by adding to /etc/wsl.conf then 'wsl --shutdown':"
        echo "        [interop]"
        echo "        appendWindowsPath = false"
    fi
    echo
}

# --- Platform flows ---------------------------------------------------------
resolve_shell_choice() {
    case "$SHELL_CHOICE" in
        bash) echo "bash"; return ;;
        zsh)  echo "zsh"; return ;;
    esac
    # auto
    if [ "$DO_INSTALL" = false ]; then
        have zsh && echo "zsh" || echo "bash"
    else
        echo "zsh"   # we install zsh in auto mode
    fi
}

setup_unix() {
    detect_pkg_mgr || log_warning "No supported package manager detected."

    local target_shell
    target_shell=$(resolve_shell_choice)
    if [ "$SHELL_CHOICE" = "zsh" ] && [ "$DO_INSTALL" = false ] && ! have zsh; then
        log_warning "zsh requested but not installed and --no-install given; using bash."
        target_shell="bash"
    fi
    log_info "Target shell: $target_shell"

    if $DO_INSTALL; then
        install_core_packages || log_warning "Package phase had issues; continuing."
        install_fzf      || true
        install_starship || true
        if [ "$target_shell" = "zsh" ]; then
            install_oh_my_zsh   || true
            install_zsh_plugins || true
        fi
        install_nerd_font || true
    else
        log_info "--no-install: skipping package/tool installation, configuring only."
    fi

    # Ensure fzf key bindings are available regardless of how fzf was installed.
    have fzf && setup_fzf_integration

    # Always write shared + both shell configs so whichever shell you land in
    # (handy if chsh is skipped or fails) behaves consistently.
    write_common_config
    write_bash_config
    write_starship_config
    wire_bashrc
    if [ "$target_shell" = "zsh" ]; then
        write_zsh_config
        wire_zshrc
        set_default_shell_zsh
    fi

    print_summary "$target_shell"
}

setup_macos() {
    log_info "macOS detected."
    if [ "$DO_INSTALL" = true ] && ! have brew; then
        if confirm "Homebrew is required on macOS. Install it now?"; then
            if $DRY_RUN; then
                log_dry "install Homebrew"
            else
                retry /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
                    || log_warning "Homebrew install failed; continuing with what's available."
            fi
        fi
    fi
    setup_unix
}

print_windows_notice() {
    log_warning "This looks like native Windows (Git Bash / MSYS / Cygwin)."
    echo
    echo "For Windows PowerShell, run the PowerShell setup instead:"
    echo
    echo "    iwr -useb https://raw.githubusercontent.com/aymaneallaoui/setup-terminal/master/setup.ps1 | iex"
    echo
    echo "This bash script targets Linux, WSL, and macOS."
}

# --- CLI --------------------------------------------------------------------
usage() {
    cat <<EOF
Universal Terminal Setup v$VERSION

Usage: ./setup.sh [options]

Options:
  --shell <auto|zsh|bash>   Which shell to configure (default: auto => zsh).
  --no-chsh                 Don't change the default login shell.
  --no-install              Configure only; skip installing packages/tools.
  --nerd-font               Also install FiraCode Nerd Font (Linux/macOS).
  -y, --yes, --unattended   Don't prompt; assume yes to all questions.
  -n, --dry-run             Show what would happen without making changes.
  -h, --help                Show this help.
      --version             Print version and exit.

Examples:
  ./setup.sh                          # full setup, auto-detect (installs zsh)
  ./setup.sh --shell bash             # configure bash only, no zsh
  ./setup.sh --no-chsh -y             # set up zsh but keep current default shell
  ./setup.sh --no-install             # just (re)write configs for existing tools
  ./setup.sh --dry-run                # preview actions
EOF
}

parse_args() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --shell)
                shift
                case "${1:-}" in
                    auto|zsh|bash) SHELL_CHOICE="$1" ;;
                    *) log_error "Invalid --shell value: '${1:-}' (use auto|zsh|bash)"; exit 2 ;;
                esac
                ;;
            --shell=*) SHELL_CHOICE="${1#*=}"
                case "$SHELL_CHOICE" in auto|zsh|bash) ;; *) log_error "Invalid --shell value."; exit 2 ;; esac ;;
            --no-chsh)    DO_CHSH=false ;;
            --no-install) DO_INSTALL=false ;;
            --nerd-font)  NERD_FONT=true ;;
            -y|--yes|--unattended) UNATTENDED=true; ASSUME_YES=true ;;
            -n|--dry-run) DRY_RUN=true ;;
            -h|--help)    usage; exit 0 ;;
            --version)    echo "$VERSION"; exit 0 ;;
            *) log_error "Unknown option: $1"; echo; usage; exit 2 ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"

    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                  Universal Terminal Setup                     ║"
    echo "║              Starship · fzf · zsh · WSL-ready                  ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    local os; os=$(detect_os)
    if is_wsl; then
        log_info "Environment: WSL$(wsl_version) (${WSL_DISTRO_NAME:-linux})"
    else
        log_info "Environment: $os"
    fi
    $DRY_RUN && log_dry "Dry run -- no changes will be made."

    case "$os" in
        linux)   setup_unix ;;
        macos)   setup_macos ;;
        windows) print_windows_notice; exit 0 ;;
        *)       log_error "Unsupported environment: $os"; exit 1 ;;
    esac
}

main "$@"
