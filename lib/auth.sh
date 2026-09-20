# lib/auth.sh — restore the shared SSH key from 1Password onto a machine
# that's never had it, then verify GitHub + NAS trust actually work.
#
# "Shared" is the operative word: docs/ssh-setup-plan.md deliberately uses
# one ed25519 key across GitHub and the whole homelab (Proxmox nodes, VMs/
# LXCs, the NAS) rather than a fresh key per machine. That means a new
# machine doesn't need to register anything new with any of those hosts —
# it needs the exact same private key restored locally, then wired into
# Keychain. 1Password is the only viable source for that: it's the one
# root of trust here that doesn't itself depend on SSH already working
# (pulling the key from a NAS backup would be circular — you'd need the
# key to SSH to the NAS to go get the key).
#
# Order matters: must run after `apps` (needs the 1password-cli/openssh/gh
# formulae) and `dotfiles` (needs dotfiles/.ssh/config symlinked so the
# github.com/nas Host aliases exist), and before `restore` (which needs
# SSH to the NAS actually working).

readonly AUTH_CONFIG_FILE="${DOTS_ROOT}/config/auth.conf"
readonly SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"

_auth_load_config() {
    if [[ ! -f "$AUTH_CONFIG_FILE" ]]; then
        _auth_create_config
        case $? in
            0) ;;
            2) return 2 ;;
            *) return 1 ;;
        esac
    fi
    # shellcheck source=/dev/null
    source "$AUTH_CONFIG_FILE"
    : "${OP_SSH_KEY_VAULT:?OP_SSH_KEY_VAULT must be set in config/auth.conf}"
    : "${OP_SSH_KEY_ITEM:?OP_SSH_KEY_ITEM must be set in config/auth.conf — see config/auth.conf.example}"
}

# Interactively creates config/auth.conf. Only the values in
# config/auth.conf.example that are actually machine-specific and can't
# be sensibly defaulted — see that file for the full explanation of what
# these are and why. Empty vault input = skip this step entirely (return
# 2, not a failure) rather than force a decision right now.
_auth_create_config() {
    log_warn "No config/auth.conf found — let's create it now."
    echo
    echo "This is the 1Password vault + item holding your shared SSH key"
    echo "(see docs/ssh-setup-plan.md Phase 6, and config/auth.conf.example)."
    echo "Leave blank to skip this step for now."
    echo
    local vault item
    read -r -p "1Password vault (ID or name — must be the ID if the name has characters like '&'; find via 'op vault list'): " vault
    if [[ -z "$vault" ]]; then
        log_info "Skipping — no config/auth.conf created. Run 'dots auth' again once you're ready."
        return 2
    fi
    read -r -p "1Password item title for the SSH key: " item
    if [[ -z "$item" ]]; then
        log_error "An item title is required once a vault is given — not creating a half-filled config/auth.conf."
        return 1
    fi

    cat > "$AUTH_CONFIG_FILE" <<EOF
# config/auth.conf — created interactively by 'dots auth' on $(date '+%Y-%m-%d').
# See config/auth.conf.example for the full explanation of these values.
OP_SSH_KEY_VAULT="${vault}"
OP_SSH_KEY_ITEM="${item}"
EOF
    log_success "Wrote ${AUTH_CONFIG_FILE}."
}

# 1Password CLI auth is the root of trust for everything else in this step.
# There's no scripting past this: signing into a 1Password account on a new
# device is an inherently manual, human-verified step (email + Secret Key +
# master password, or linking to an already-unlocked desktop app). This
# only checks and gives instructions — it doesn't attempt to automate sign-in.
_auth_check_1password() {
    command -v op &>/dev/null || { log_error "1Password CLI (op) not found — run 'dots apps' first."; return 1; }

    # Do NOT redirect op's output here. On a never-configured `op`, this
    # command itself prompts interactively ("add an account manually?") —
    # found live 2026-09-19. A redirect would hide that prompt entirely
    # while `op` sits there waiting for input nobody can see is needed,
    # the exact same silent-hang bug class as the microsoft-office sudo
    # prompt earlier this session. Letting it print directly means the
    # prompt is visible and answerable; log_info below just frames it.
    log_info "Checking 1Password CLI sign-in (this may prompt you directly — answer it if so)..."
    # Only stdout is captured here (to check it's actually non-empty,
    # not just exit-code-0 — op account list returns 0 with zero output
    # when nothing is configured, found live 2026-09-19). stderr is left
    # alone so an interactive prompt on that stream still shows directly.
    local accounts
    accounts="$(op account list)"
    if [[ $? -ne 0 || -z "$accounts" ]]; then
        # This is an expected state on a fresh machine, not a failure —
        # 1Password sign-in is a genuinely manual, human-verified step
        # (see the header comment at the top of this file) that nothing
        # here can script past. Skipping (return 2) rather than failing
        # (return 1) so it shows as a clean next-step in the run summary,
        # not noise from running a step known in advance not to work yet.
        log_warn "1Password CLI isn't signed in to any account yet — this is expected on a machine that's never had it set up. NEXT STEP: open the 1Password app, sign into your account, then enable Settings -> Developer -> 'Integrate with 1Password CLI' (preferred — no separate CLI sign-in to manage), or sign in directly via the CLI. Then re-run 'dots auth'."
        return 2
    fi
    log_success "1Password CLI is signed in."
}

_auth_restore_ssh_key() {
    if [[ -f "$SSH_KEY_PATH" ]]; then
        log_info "Already present: ${SSH_KEY_PATH}, skipping restore."
        return 0
    fi

    log_info "Restoring SSH key from 1Password (vault: ${OP_SSH_KEY_VAULT}, item: ${OP_SSH_KEY_ITEM})..."
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    # ssh-format=openssh is required — op read's default for an SSH key
    # item's "private key" field is PKCS#8 PEM, which ssh-keygen/ssh-add
    # can't read at all (verified 2026-09-19: silently produces a file
    # ssh-keygen calls "not a key file"). --file-mode 600 writes it with
    # correct permissions atomically, no separate chmod needed.
    # No stderr redirect here — if op isn't fully signed in yet it can
    # prompt interactively (sign-in address, etc.), and a redirect would
    # hide that prompt entirely while op sits waiting for input nobody
    # can see is needed (found live 2026-09-19: the exact same bug as
    # _auth_check_1password, just in this function). --out-file already
    # keeps the actual key material out of stdout/stderr either way, so
    # nothing sensitive is exposed by leaving this unredirected.
    local ref="op://${OP_SSH_KEY_VAULT}/${OP_SSH_KEY_ITEM}/private key?ssh-format=openssh"
    if ! op read --out-file "$SSH_KEY_PATH" --file-mode 600 -f "$ref"; then
        rm -f "$SSH_KEY_PATH"
        log_error "Could not read '${ref}' from 1Password. Confirm OP_SSH_KEY_VAULT/OP_SSH_KEY_ITEM in config/auth.conf — note OP_SSH_KEY_VAULT must be the vault's ID, not its name, if the name has characters like '&' that op:// references can't parse (see config/auth.conf.example)."
        return 1
    fi

    if ! ssh-keygen -y -f "$SSH_KEY_PATH" >"${SSH_KEY_PATH}.pub" 2>>"$LOG_FILE"; then
        log_error "Could not derive the public key from the restored private key (wrong passphrase, or the key content read from 1Password is malformed)."
        rm -f "${SSH_KEY_PATH}.pub"
        return 1
    fi
    chmod 644 "${SSH_KEY_PATH}.pub"
    log_success "SSH key restored to ${SSH_KEY_PATH}."
}

# Seeds Keychain with the key's passphrase — a one-time interactive prompt
# that's what makes every later `ssh`/`git` invocation passphrase-free (via
# UseKeychain in dotfiles/.ssh/config). Safe to call even if already loaded;
# ssh-add doesn't error on re-adding the same key.
_auth_load_keychain() {
    local resolved_ssh
    resolved_ssh="$(command -v ssh)"
    if [[ "$resolved_ssh" != "/usr/bin/ssh" ]]; then
        log_warn "ssh resolves to ${resolved_ssh}, not /usr/bin/ssh — Homebrew's openssh may be linked ahead of it on PATH. UseKeychain only works with Apple's ssh. Run 'brew unlink openssh' (the Brewfile's 'link: false' should already prevent this — see docs/ssh-setup-plan.md Phase 3)."
    fi

    log_info "Loading SSH key into Keychain-backed ssh-agent (may prompt for the key's passphrase once)..."
    # No stderr redirect — same reasoning as _auth_restore_ssh_key above:
    # a hidden passphrase prompt is a silent hang, not a clean failure.
    if ssh-add --apple-use-keychain "$SSH_KEY_PATH"; then
        log_success "Key loaded and stored in Keychain."
    else
        log_error "ssh-add --apple-use-keychain failed — see ${LOG_FILE}."
        return 1
    fi
}

# GitHub trust already exists for this key on every machine but the very
# first one (same key everywhere) — check by key data before registering
# anything new. gh's own auth (OAuth token for the API/CLI) is a separate
# credential from the SSH key and is handled first since ssh-key commands
# need it.
_auth_verify_github() {
    command -v gh &>/dev/null || { log_error "GitHub CLI (gh) not found — run 'dots apps' first."; return 1; }

    if ! gh auth status &>/dev/null; then
        log_info "gh isn't authenticated (its own OAuth token, separate from the SSH key). Starting 'gh auth login' (interactive)..."
        gh auth login --hostname github.com || { log_error "gh auth login failed or was cancelled."; return 1; }
    fi

    local local_key_data registered_keys
    local_key_data="$(awk '{print $1, $2}' "${SSH_KEY_PATH}.pub")"
    registered_keys="$(gh ssh-key list 2>/dev/null | cut -f2)"
    if grep -qF "$local_key_data" <<<"$registered_keys"; then
        log_info "This key is already registered with GitHub."
    else
        log_info "This key isn't registered with GitHub yet — adding it..."
        gh ssh-key add "${SSH_KEY_PATH}.pub" -t "$(scutil --get ComputerName 2>/dev/null || hostname) (auth) - $(date +%Y-%m)" \
            || { log_error "gh ssh-key add failed — see ${LOG_FILE}."; return 1; }
    fi

    # Captured into a variable rather than piped straight into grep — bin/dots
    # runs with `set -o pipefail`, and `ssh -T git@github.com` always exits 1
    # even on real success (GitHub's shell-access-denied design). Under
    # pipefail that nonzero exit overrides the whole pipeline's status
    # regardless of what grep finds downstream, so a genuine success was
    # being reported as a failure (found live 2026-09-19 — the log showed
    # "You've successfully authenticated" immediately above the FAIL line).
    local github_output
    github_output="$(ssh -T git@github.com 2>&1)"
    echo "$github_output" >>"$LOG_FILE"
    if grep -qi "successfully authenticated" <<<"$github_output"; then
        log_success "GitHub SSH auth verified."
    else
        log_error "ssh -T git@github.com did not report successful authentication — see ${LOG_FILE}."
        return 1
    fi
}

# Best-effort only — off-LAN is an expected, non-fatal state (matches
# nas_is_reachable()'s existing silent-skip design). config/backup.conf
# might not exist yet at this point in a fresh run, which is fine too.
_auth_verify_nas() {
    if [[ ! -f "${DOTS_ROOT}/config/backup.conf" ]]; then
        log_info "No config/backup.conf yet — skipping NAS reachability check."
        return 0
    fi
    nas_load_config &>/dev/null || return 0
    if nas_is_reachable; then
        log_success "NAS (${NAS_HOST}) reachable over SSH."
    else
        log_warn "NAS not reachable right now — expected if off-LAN. 'dots restore' will handle this the same way."
    fi
}

cmd_auth() {
    _auth_load_config
    local rc=$?
    [[ "$rc" -eq 0 ]] || return "$rc"
    _auth_check_1password
    rc=$?
    [[ "$rc" -eq 0 ]] || return "$rc"
    _auth_restore_ssh_key || return 1
    _auth_load_keychain || return 1
    _auth_verify_github || return 1
    _auth_verify_nas
    log_success "Auth step complete."
}
