# lib/sudo.sh — request sudo once, keep it alive for the rest of the run.
#
# Call `request_sudo_keepalive` at the start of any subcommand that might
# need sudo partway through (Xcode CLT install, some `defaults write`
# domains, some cask installs) so the process never stalls mid-run waiting
# on a password prompt buried in other output. Subcommands that never need
# sudo (dotfiles, baseline, backup/restore — those use SSH keys, not sudo)
# should not call this.

request_sudo_keepalive() {
    [[ -n "${_SUDO_KEEPALIVE_PID:-}" ]] && return 0  # already active this run

    log_info "Requesting sudo access up front (kept alive for the rest of this command)..."
    sudo -v || die "Could not obtain sudo access."

    # This ping has nothing useful to report either way: on success there's
    # nothing to say, and on failure the loop can't act on it anyway (just
    # retries in 60s) — any real sudo-needing command downstream handles its
    # own failure (see lib/xcode.sh's softwareupdate fallback, for example).
    # Redirected so it can't interject "sudo: a password is required" into
    # the middle of unrelated output from this background process.
    while true; do
        sudo -n true >>"$LOG_FILE" 2>&1
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
    _SUDO_KEEPALIVE_PID=$!
    trap 'kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}
