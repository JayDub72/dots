# lib/apps.sh — install everything in the Brewfile.
#
# The Brewfile's actual contents are not decided yet (see docs/planning.md
# step 3 — "I have NOT given you the list of applications to install yet").
# This module is the mechanism; it works against whatever Brewfile exists,
# including the current placeholder.

readonly BREWFILE="${DOTS_ROOT}/Brewfile"

cmd_apps() {
    command -v brew &>/dev/null || { log_error "brew not available; run 'dots homebrew' first."; return 1; }

    if [[ ! -f "$BREWFILE" ]]; then
        log_warn "No Brewfile found at ${BREWFILE}; skipping."
        return 2
    fi

    log_info "Installing packages, casks, and apps from ${BREWFILE} (this can take a while)..."
    if brew bundle --file="$BREWFILE" 2>&1 | tee -a "$LOG_FILE"; then
        log_success "brew bundle completed."
    else
        log_warn "brew bundle reported one or more failures; check ${LOG_FILE} for details."
        return 1
    fi

    # Known gotcha (see docs/ssh-setup-plan.md, Phase 3): if this Brewfile
    # ever gains `brew "openssh"`, Homebrew's build sits ahead of /usr/bin
    # on PATH and its ssh/ssh-add don't support Keychain integration at
    # all — silently breaking passphrase-free SSH. If openssh gets added
    # here, `brew unlink openssh` right after, so /usr/bin/ssh keeps
    # resolving first.
    if brew list --formula 2>/dev/null | grep -qx openssh; then
        log_warn "openssh is installed via Homebrew — confirm it's unlinked (brew unlink openssh) or Keychain-based SSH auth may silently stop working. See docs/ssh-setup-plan.md."
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
    log_info "Running brew maintenance: update, upgrade, cleanup, doctor..."
    brew update && brew upgrade && brew cleanup
    brew doctor || log_warn "brew doctor reported issues (see above) — not treated as fatal."
    log_success "Brew maintenance complete."
}
