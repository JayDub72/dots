# lib/baseline.sh — "baseline" and "rollback" for environment settings only.
# See docs/planning.md outcomes #2/#3b: macOS settings (lib/macos-defaults.sh)
# are static and NOT part of this cycle — only dotfiles/ is.
#
# Requires this repo to actually be a git repository. Per docs/planning.md's
# locked decisions, `dots` isn't one yet on purpose ("no rush to git init
# just to have one") — so this module works mechanically but will refuse to
# run until that happens. That's a real dependency to resolve, not a bug.

_require_git_repo() {
    git -C "$DOTS_ROOT" rev-parse --git-dir &>/dev/null || {
        log_error "dots isn't a git repository yet — baseline/rollback needs git. See docs/planning.md."
        return 1
    }
}

# Commit the current state of dotfiles/ as the new "truth."
cmd_baseline() {
    _require_git_repo || return 1
    git -C "$DOTS_ROOT" add dotfiles/
    if git -C "$DOTS_ROOT" diff --cached --quiet -- dotfiles/; then
        log_info "No changes under dotfiles/ since the last baseline."
        return 0
    fi
    git -C "$DOTS_ROOT" commit -m "baseline: $(date '+%Y-%m-%d %H:%M:%S')" -- dotfiles/
    log_success "Baselined current dotfiles/ state as the new truth."
}

# Reset dotfiles/ back to the last baseline commit, discarding anything
# changed since (e.g. after a round of testing/experimenting).
cmd_rollback() {
    _require_git_repo || return 1
    log_warn "This discards any uncommitted changes under dotfiles/."
    read -r -p "Continue? [y/N] " confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]] || { log_info "Rollback cancelled."; return 1; }

    git -C "$DOTS_ROOT" checkout -- dotfiles/
    log_success "Rolled dotfiles/ back to the last baseline. Live files under \$HOME are already correct (they're symlinks into dotfiles/)."
}
