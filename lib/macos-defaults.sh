# lib/macos-defaults.sh — apply the macOS `defaults write` settings file.
#
# Per docs/planning.md outcome #3a: these are the settings that should stay
# static — trackpad, keyboard, Finder, Dock, etc. Not meant to be part of
# the baseline/rollback cycle (that's for environment settings only; see
# lib/baseline.sh). The actual settings content lives in macos/defaults.sh,
# not here — this module just runs it and restarts whatever UI processes
# it touched.

readonly MACOS_DEFAULTS_FILE="${DOTS_ROOT}/macos/defaults.sh"

cmd_macos() {
    if [[ ! -s "$MACOS_DEFAULTS_FILE" ]]; then
        log_warn "macos/defaults.sh is empty — no settings decided yet (see docs/planning.md step 5). Skipping."
        return 2
    fi

    log_info "Applying macOS defaults from ${MACOS_DEFAULTS_FILE}..."
    # shellcheck source=/dev/null
    source "$MACOS_DEFAULTS_FILE"
    log_success "macOS defaults applied."
}
