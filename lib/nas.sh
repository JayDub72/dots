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
        _nas_create_config
        case $? in
            0) ;;
            2) return 2 ;;
            *) return 1 ;;
        esac
    fi
    # shellcheck source=/dev/null
    source "$NAS_CONFIG_FILE"
    [[ -n "${NAS_HOST:-}" ]] || { log_error "NAS_HOST not set in config/backup.conf."; return 1; }
}

# Interactively creates config/backup.conf. LOCAL_PATHS and RSYNC_EXCLUDES
# are left at config/backup.conf.example's sensible defaults (Documents +
# Downloads, no excludes) rather than prompted for — those are easy to
# hand-edit later, unlike the NAS connection details which block every
# backup/restore run entirely until they're right. Empty host input =
# skip this step entirely (return 2), not a failure.
_nas_create_config() {
    log_warn "No config/backup.conf found — let's create it now."
    echo
    echo "NAS connection details (see config/backup.conf.example for the full"
    echo "explanation of each value). Leave the host blank to skip for now."
    echo
    local nas_host nas_user nas_port nas_share max_delete
    read -r -p "NAS host (the Host alias in dotfiles/.ssh/config, e.g. 'nas'): " nas_host
    if [[ -z "$nas_host" ]]; then
        log_info "Skipping — no config/backup.conf created. Run 'dots backup'/'dots restore' again once you're ready."
        return 2
    fi
    read -r -p "NAS username: " nas_user
    read -r -p "NAS SSH port [22]: " nas_port
    nas_port="${nas_port:-22}"
    read -r -p "NAS share path (e.g. /volume1/backups): " nas_share
    read -r -p "BACKUP_MAX_DELETE — safety cap on files a single backup run can delete from the NAS [10]: " max_delete
    max_delete="${max_delete:-10}"

    if [[ -z "$nas_user" || -z "$nas_share" ]]; then
        log_error "NAS username and share path are both required once a host is given — not creating a half-filled config/backup.conf."
        return 1
    fi
    if ! [[ "$max_delete" =~ ^[0-9]+$ ]]; then
        log_error "BACKUP_MAX_DELETE must be a whole number, got '${max_delete}'."
        return 1
    fi
    if [[ "$max_delete" -eq 0 ]]; then
        log_error "BACKUP_MAX_DELETE cannot be 0 — see config/backup.conf.example: this Mac's rsync (openrsync) treats 0 as UNLIMITED, not zero. Pick a real positive number."
        return 1
    fi

    cat > "$NAS_CONFIG_FILE" <<EOF
# config/backup.conf — created interactively by dots on $(date '+%Y-%m-%d').
# See config/backup.conf.example for the full explanation of these values.
NAS_HOST="${nas_host}"
NAS_USER="${nas_user}"
NAS_SSH_PORT="${nas_port}"
NAS_SHARE_PATH="${nas_share}"

LOCAL_PATHS=(
    "\${HOME}/Documents"
    "\${HOME}/Downloads"
)

RSYNC_EXCLUDES=(
)

BACKUP_MAX_DELETE=${max_delete}
EOF
    log_success "Wrote ${NAS_CONFIG_FILE}."
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
