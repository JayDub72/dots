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

    while true; do
        sudo -n true
        sleep 60
        kill -0 "$$" 2>/dev/null || exit
    done &
    _SUDO_KEEPALIVE_PID=$!
    trap 'kill "$_SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
}
