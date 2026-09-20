# lib/apps.sh — install everything in the Brewfile.
#
# This module is just the mechanism; it works against whatever Brewfile
# exists. The Brewfile's actual contents (locked decisions, grouping,
# gotchas) are documented inline in the Brewfile itself.

readonly BREWFILE="${DOTS_ROOT}/Brewfile"

cmd_apps() {
    command -v brew &>/dev/null || { log_error "brew not available; run 'dots homebrew' first."; return 1; }

    if [[ ! -f "$BREWFILE" ]]; then
        log_warn "No Brewfile found at ${BREWFILE}; skipping."
        return 2
    fi

    log_info "Installing packages, casks, and apps from ${BREWFILE} (this can take a while; per-file install output goes to ${LOG_FILE}, not the screen)..."
    if brew bundle --file="$BREWFILE" >>"$LOG_FILE" 2>&1; then
        log_success "brew bundle completed."
    else
        log_warn "brew bundle reported one or more failures; check ${LOG_FILE} for details."
        return 1
    fi

    # Known gotcha: the Brewfile installs `brew "openssh", link: false`
    # deliberately — Homebrew's build sitting ahead of /usr/bin on PATH
    # would break Keychain-based passphrase-free SSH silently (its
    # ssh/ssh-add don't support Keychain integration at all). This check
    # catches it if that ever regresses (a Brewfile edit drops `link:
    # false`, or someone links it by hand).
    if brew list --formula 2>/dev/null | grep -qx openssh; then
        log_warn "openssh is installed via Homebrew — confirm it's unlinked (brew unlink openssh) or Keychain-based SSH auth may silently stop working."
    fi

    log_info "Verifying bundle against Brewfile..."
    if brew bundle check --file="$BREWFILE" >>"$LOG_FILE" 2>&1; then
        log_success "All Brewfile dependencies satisfied."
    else
        log_warn "Some Brewfile dependencies are still missing (see ${LOG_FILE})."
    fi
}

cmd_maintenance() {
    command -v brew &>/dev/null || { log_error "brew not available."; return 1; }
    log_info "Running brew maintenance: update, upgrade, cleanup, doctor (output goes to ${LOG_FILE}, not the screen)..."
    if brew update >>"$LOG_FILE" 2>&1 && brew upgrade >>"$LOG_FILE" 2>&1 && brew cleanup >>"$LOG_FILE" 2>&1; then
        log_success "brew update/upgrade/cleanup completed."
    else
        log_warn "brew update/upgrade/cleanup reported an issue; check ${LOG_FILE} for details."
    fi
    brew doctor >>"$LOG_FILE" 2>&1 || log_warn "brew doctor reported issues — not treated as fatal, see ${LOG_FILE}."
    log_success "Brew maintenance complete."
}
