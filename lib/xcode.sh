# lib/xcode.sh — Xcode Command Line Tools (needed before Homebrew works).

cmd_xcode() {
    if xcode-select -p &>/dev/null; then
        log_info "Xcode Command Line Tools already installed at $(xcode-select -p)."
        return 0
    fi

    log_info "Xcode Command Line Tools not found. Installing..."

    # Non-interactive trick: this flag file makes the CLT package show up
    # in `softwareupdate -l` so it can be installed without the GUI popup.
    local placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    touch "$placeholder"

    local clt_label
    clt_label="$(softwareupdate -l 2>/dev/null \
        | grep -B 1 -E 'Command Line Tools' \
        | awk -F'\\*' '/^[[:space:]]*\*/ {print $2}' \
        | sed -e 's/^ *Label: *//' -e 's/^ *//' -e 's/ *$//' \
        | sort -V \
        | tail -n1)"

    if [[ -n "$clt_label" ]]; then
        log_info "Installing via softwareupdate: ${clt_label}"
        if softwareupdate -i "$clt_label" --verbose; then
            rm -f "$placeholder"
        else
            rm -f "$placeholder"
            log_warn "softwareupdate install failed, falling back to interactive xcode-select --install"
        fi
    else
        rm -f "$placeholder"
        log_warn "Could not resolve a Command Line Tools package via softwareupdate; falling back to interactive install."
    fi

    if ! xcode-select -p &>/dev/null; then
        xcode-select --install &>/dev/null || true
        log_info "A system dialog may have appeared. Waiting for Command Line Tools installation to finish..."
        until xcode-select -p &>/dev/null; do
            sleep 10
        done
    fi

    log_info "Accepting Xcode/CLT license (if required)..."
    sudo xcodebuild -license accept 2>/dev/null || true

    xcode-select -p &>/dev/null || { log_error "Xcode Command Line Tools installation could not be confirmed."; return 1; }
    log_success "Xcode Command Line Tools installed at $(xcode-select -p)."
}
