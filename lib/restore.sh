# lib/restore.sh — mirror-image pull, NAS -> local. See docs/planning.md
# step 6b. The last step of `dots all` — but always interactive (this can
# take a long time, and always overwrites local with the NAS's copy), so
# declining it doesn't fail the run: it's a deliberate skip, and the exact
# command to run it later gets printed instead.

cmd_restore() {
    nas_load_config || return 1

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

    [[ "$failures" -eq 0 ]]
}
