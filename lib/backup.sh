# lib/backup.sh — one-way push, local -> NAS. See docs/planning.md step 6a.
#
# Meant to be run on a schedule via launchd (see launchd/), not manually
# day-to-day. NOT safe to run before you've restored onto a fresh Mac —
# --delete treats local as truth and prunes the NAS to match it, so an
# empty local Documents/Downloads would delete your real backup. Always
# run `dots restore` first on a machine that hasn't been restored yet.
# BACKUP_MAX_DELETE (config/backup.conf) is the technical backstop for
# getting that order wrong, not a substitute for it.

readonly RSYNC_MAX_DELETE_EXIT=25   # verified empirically against this Mac's rsync (openrsync)

# Written after every run (success or failure) so two independent things can
# know the outcome without watching the log: a macOS notification fires
# immediately on failure, and dotfiles/.zshrc reads this file on every new
# shell to keep warning you until a subsequent run actually succeeds — see
# docs/planning.md step 6a. Not gitignored specially; it lives under logs/,
# already excluded wholesale.
readonly BACKUP_STATUS_FILE="${DOTS_ROOT}/logs/backup_status"

_backup_notify_failure() {
    osascript -e "display notification \"Check ${LOG_FILE} for details.\" with title \"dots backup failed\"" &>/dev/null || true
}

# cmd_backup [--force] [--seed]
#
# --force bypasses BACKUP_MAX_DELETE for this one run — for a deliberate
# local cleanup you actually want mirrored to the NAS. Never pass this
# automatically or from a script; it's meant to be typed by hand, once,
# by a person who just confirmed the deletion is intentional. The
# scheduled launchd job only ever calls plain `dots backup`, no flags.
#
# --seed bypasses the "has this machine ever run dots restore" check
# below — for the one legitimate case where backing up without a prior
# restore is correct: the very first machine ever, seeding an empty NAS
# with real local data for the first time (see docs/planning.md — this
# already happened once, for real, 20.86GB, zero errors). Like --force,
# meant to be typed by hand once, never automated.
#
# Real near-miss 2026-09-19: dots backup ran on a machine that had never
# been restored — local Documents was near-empty, would have pruned real
# NAS data to match it. BACKUP_MAX_DELETE caught it, but only as a
# numeric backstop, not by actually preventing the wrong order — hence
# the check below, not just relying on the delete count.
cmd_backup() {
    local force=false seed=false arg
    for arg in "$@"; do
        case "$arg" in
            --force) force=true ;;
            --seed) seed=true ;;
        esac
    done

    if [[ ! -f "$RESTORE_STATUS_FILE" ]] && ! "$seed"; then
        log_error "This machine has never completed 'dots restore' — refusing to run 'dots backup'. A backup here would treat local as truth and prune the NAS to match it; on a machine that's never been restored, local is likely near-empty, so this would delete real backed-up data. Run 'dots restore' first. If this is genuinely the first-ever seed backup (a brand-new source-of-truth machine, empty NAS, no prior restore possible), re-run as 'dots backup --seed' to confirm that and proceed anyway."
        return 1
    fi

    nas_load_config
    local nas_config_rc=$?
    [[ "$nas_config_rc" -eq 0 ]] || return "$nas_config_rc"
    : "${BACKUP_MAX_DELETE:?BACKUP_MAX_DELETE must be set in config/backup.conf — see config/backup.conf.example for why, and do not set it to 0}"

    if ! nas_is_reachable; then
        log_warn "NAS (${NAS_HOST}) not reachable — skipping this backup run. (Off-LAN handling is still an open decision; see docs/planning.md step 6c and nas_is_reachable() in lib/nas.sh.)"
        return 2
    fi

    nas_build_exclude_args

    local max_delete_args=(--max-delete="${BACKUP_MAX_DELETE}")
    if "$force"; then
        log_warn "--force: BACKUP_MAX_DELETE=${BACKUP_MAX_DELETE} is disabled for this run. Deletions are unbounded."
        max_delete_args=()
    fi

    local local_path rel_path remote_target rc failures=0
    for local_path in "${LOCAL_PATHS[@]:-}"; do
        [[ -d "$local_path" ]] || { log_warn "Local path ${local_path} doesn't exist, skipping."; continue; }
        rel_path="$(basename "$local_path")"
        remote_target="${NAS_SHARE_PATH}/${rel_path}"

        log_info "Backing up ${local_path} -> ${NAS_HOST}:${remote_target}"
        # -v's per-file listing goes to the log file only, not the screen —
        # log_info/log_success/log_error below are the on-screen start/end
        # story. Check $LOG_FILE for the full itemized transfer if needed.
        rsync -avz --delete "${max_delete_args[@]:-}" "${RSYNC_EXCLUDE_ARGS[@]:-}" \
            -e "ssh -p ${NAS_SSH_PORT:-22}" \
            "${local_path}/" "${NAS_USER}@${NAS_HOST}:${remote_target}/" >>"$LOG_FILE" 2>&1
        rc=$?

        if [[ "$rc" -eq 0 ]]; then
            log_success "Backed up ${rel_path}."
        elif [[ "$rc" -eq "$RSYNC_MAX_DELETE_EXIT" ]]; then
            log_error "Backup of ${rel_path} ABORTED: would have deleted more than BACKUP_MAX_DELETE=${BACKUP_MAX_DELETE} files from the NAS. This usually means either (a) this Mac hasn't been restored yet — run 'dots restore' first — or (b) local data actually went missing and should be investigated before backing up. Not raising the limit blindly."
            failures=$((failures + 1))
        else
            log_error "Backup of ${rel_path} failed (rsync exit ${rc})."
            failures=$((failures + 1))
        fi
    done

    mkdir -p "$(dirname "$BACKUP_STATUS_FILE")"
    if [[ "$failures" -eq 0 ]]; then
        echo "OK $(date '+%Y-%m-%d %H:%M:%S')" > "$BACKUP_STATUS_FILE"
    else
        echo "FAILED $(date '+%Y-%m-%d %H:%M:%S')" > "$BACKUP_STATUS_FILE"
        _backup_notify_failure
    fi

    [[ "$failures" -eq 0 ]]
}
