# lib/nas.sh — shared config loading + reachability check for backup/restore.
#
# This is the one file to change when the "off local network" decision
# (docs/planning.md, step 6c) gets made. Right now nas_is_reachable() only
# understands "on the same LAN" and treats anything else as "skip this run,
# don't fail the whole command" — a safe default no matter which way that
# decision eventually goes (stay LAN-only forever, add a VPN check here,
# fall back to QuickConnect, etc.).

readonly NAS_CONFIG_FILE="${DOTS_ROOT}/config/backup.conf"

nas_load_config() {
    if [[ ! -f "$NAS_CONFIG_FILE" ]]; then
        log_error "No config/backup.conf found. Copy config/backup.conf.example to config/backup.conf and fill it in."
        return 1
    fi
    # shellcheck source=/dev/null
    source "$NAS_CONFIG_FILE"
    [[ -n "${NAS_HOST:-}" ]] || { log_error "NAS_HOST not set in config/backup.conf."; return 1; }
}

# Returns 0 if the NAS is reachable right now, 1 otherwise. Callers should
# treat 1 as "skip gracefully" (return 2, the run_step "skipped" code),
# not as a hard failure — being off-network is expected, not exceptional.
nas_is_reachable() {
    ssh -o BatchMode=yes -o ConnectTimeout=5 -p "${NAS_SSH_PORT:-22}" \
        "${NAS_USER}@${NAS_HOST}" true 2>/dev/null
}

# Populates the global array RSYNC_EXCLUDE_ARGS from RSYNC_EXCLUDES (set in
# config/backup.conf) for direct use as: rsync "${RSYNC_EXCLUDE_ARGS[@]}" ...
nas_build_exclude_args() {
    RSYNC_EXCLUDE_ARGS=()
    local pattern
    for pattern in "${RSYNC_EXCLUDES[@]:-}"; do
        [[ -n "$pattern" ]] && RSYNC_EXCLUDE_ARGS+=(--exclude "$pattern")
    done
}
