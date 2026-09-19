# lib/homebrew.sh — install/verify Homebrew itself.

cmd_homebrew() {
    if command -v brew &>/dev/null; then
        log_info "Homebrew already installed ($(brew --version | head -n1))."
    else
        log_info "Installing Homebrew (output goes to ${LOG_FILE}, not the screen)..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            >>"$LOG_FILE" 2>&1 \
            || { log_error "Homebrew installer failed — see ${LOG_FILE}."; return 1; }
    fi

    local brew_bin=""
    if [[ -x /opt/homebrew/bin/brew ]]; then
        brew_bin="/opt/homebrew/bin/brew"      # Apple Silicon
    elif [[ -x /usr/local/bin/brew ]]; then
        brew_bin="/usr/local/bin/brew"          # Intel
    else
        log_error "Could not locate the brew binary after installation."
        return 1
    fi

    eval "$("$brew_bin" shellenv)"
    command -v brew &>/dev/null || { log_error "brew is still not on PATH after install."; return 1; }

    log_info "Disabling Homebrew analytics..."
    brew analytics off &>/dev/null || true

    log_info "Updating Homebrew..."
    brew update >>"$LOG_FILE" 2>&1 || log_warn "brew update reported an issue; continuing."

    log_success "Homebrew ready: $(brew --version | head -n1)"
}
