# lib/restore.sh — mirror-image pull, NAS -> local. See docs/planning.md
# step 6b. The last step of `dots all` — but always interactive (this can
# take a long time, and always overwrites local with the NAS's copy), so
# declining it doesn't fail the run: it's a deliberate skip, and the exact
# command to run it later gets printed instead.
#
# Writes RESTORE_STATUS_FILE (defined in lib/nas.sh) on success — this is
# the thing lib/backup.sh checks before it will run at all. Real near-miss
# 2026-09-19: dots backup ran on a machine that had never been restored,
# local Documents was near-empty, and BACKUP_MAX_DELETE only barely caught
# it before real NAS data got pruned to match. A delete-count backstop
# isn't the same as actually preventing the wrong order — this marker is
# the structural fix.

cmd_restore() {
    # SSH_KEY_PATH is defined in lib/auth.sh (sourced before this file).
    # Without the shared key restored, nas_is_reachable()'s SSH attempt
    # would just fail with a confusing auth error — check for the actual
    # cause first and point at the real next step (dots auth) instead.
    # Same reasoning as _auth_check_1password's skip-not-fail: this is
    # expected on a machine that hasn't run dots auth yet, not a failure.
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_warn "No SSH key at ${SSH_KEY_PATH} yet — this is expected before 'dots auth' has run. NEXT STEP: run 'dots auth' first (which itself needs 1Password signed in — see its own message if that's not done yet), then re-run 'dots restore'."
        return 2
    fi

    nas_load_config
    local nas_config_rc=$?
    [[ "$nas_config_rc" -eq 0 ]] || return "$nas_config_rc"

    if ! nas_is_reachable; then
        log_error "NAS (${NAS_HOST}) not reachable — cannot restore right now."
        return 1
    fi

    log_warn "This will overwrite local files under ${LOCAL_PATHS[*]} with what's on the NAS, and can take a while."
    read -r -p "Restore now? [y/N] " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Restore skipped. Run it whenever you're ready: ./bin/dots restore"
        return 2
    fi

    local local_path rel_path remote_source failures=0
    for local_path in "${LOCAL_PATHS[@]:-}"; do
        rel_path="$(basename "$local_path")"
        remote_source="${NAS_SHARE_PATH}/${rel_path}"
        mkdir -p "$local_path"

        log_info "Restoring ${NAS_HOST}:${remote_source} -> ${local_path}"
        # -v's per-file listing goes to the log file only, not the screen —
        # see lib/backup.sh for the same choice.
        rsync -avz \
            -e "ssh -p ${NAS_SSH_PORT:-22}" \
            "${NAS_USER}@${NAS_HOST}:${remote_source}/" "${local_path}/" >>"$LOG_FILE" 2>&1
        if [[ $? -eq 0 ]]; then
            log_success "Restored ${rel_path}."
        else
            log_error "Restore of ${rel_path} failed."
            failures=$((failures + 1))
        fi
    done

    if [[ "$failures" -eq 0 ]]; then
        mkdir -p "$(dirname "$RESTORE_STATUS_FILE")"
        echo "OK $(date '+%Y-%m-%d %H:%M:%S')" > "$RESTORE_STATUS_FILE"
    fi

    [[ "$failures" -eq 0 ]]
}
