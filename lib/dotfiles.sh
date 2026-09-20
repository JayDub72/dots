# lib/dotfiles.sh — symlink managed dotfiles from this repo into $HOME.
#
# Files this knows about, relative to dotfiles/ in this repo, mapped 1:1 to
# the same relative path under $HOME. A name missing from dotfiles/ is
# simply skipped, not an error. Add a name here the moment a real file
# lands in dotfiles/ for it.
readonly DOTFILE_NAMES=(
    ".ssh/config"
    ".zshrc"
    ".exports"
    ".aliases"
    ".functions"
    ".profile"
    ".p10k.zsh"
    ".vimrc"
    ".config/ghostty/config"
    "Library/Application Support/Code/User/settings.json"
)

# .vimrc points backupdir/directory/undodir at ~/.vim/{backups,swaps,undos}
# — pure runtime scratch state (vim writes real edit history there), never
# symlinked from dotfiles/ and never tracked in git. The old ~/.dotfiles
# symlinked the whole ~/.vim directory itself, which meant that scratch
# state (including undo history of files like ~/.ssh/config,
# ~/.ssh/known_hosts) lived inside a git working tree, relying entirely on
# .gitignore discipline to stay uncommitted. Only .vimrc is a managed
# dotfile here; these three directories just need to exist so vim doesn't
# fall back to cluttering whatever directory you happen to be editing in.
readonly VIM_RUNTIME_DIRS=(
    ".vim/backups"
    ".vim/swaps"
    ".vim/undos"
)

readonly DOTFILES_SRC_DIR="${DOTS_ROOT}/dotfiles"
DOTFILES_BACKUP_DIR=""   # lazily set the first time a backup is actually needed

# Symlink one file: dotfiles/<name> -> $HOME/<name>. Returns: 0 on success
# (including "already linked correctly"), 2 if dotfiles/<name> doesn't
# exist yet in this repo, 1 on any real failure.
_link_dotfile() {
    local name="$1"
    local src="${DOTFILES_SRC_DIR}/${name}"
    local target="${HOME}/${name}"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        return 2
    fi

    if [[ -L "$target" ]]; then
        if [[ "$(readlink "$target")" == "$src" ]]; then
            log_info "Already linked: ${target} -> ${src}"
            return 0
        fi
        log_info "Replacing existing symlink at ${target}"
        rm -f "$target"
    elif [[ -e "$target" ]]; then
        [[ -z "$DOTFILES_BACKUP_DIR" ]] && DOTFILES_BACKUP_DIR="${HOME}/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
        local backup_target="${DOTFILES_BACKUP_DIR}/${name}"
        mkdir -p "$(dirname "$backup_target")" || { log_error "Could not prepare backup dir for ${name}"; return 1; }
        mv "$target" "$backup_target" || { log_error "Could not back up ${target}"; return 1; }
        log_warn "Backed up existing ${target} -> ${backup_target}"
    fi

    mkdir -p "$(dirname "$target")" || { log_error "Could not create parent dir for ${target}"; return 1; }
    if ln -s "$src" "$target"; then
        log_success "Linked ${target} -> ${src}"
    else
        log_error "Failed to link ${target} -> ${src}"
        return 1
    fi
}

cmd_dotfiles() {
    local name rc found=0 failures=0
    for name in "${DOTFILE_NAMES[@]:-}"; do
        _link_dotfile "$name"
        rc=$?
        case "$rc" in
            0) found=$((found + 1)) ;;
            2) log_info "No dotfiles/${name} in this repo yet, skipping." ;;
            *) found=$((found + 1)); failures=$((failures + 1)) ;;
        esac
    done

    if [[ "$found" -eq 0 ]]; then
        log_warn "No dotfiles to link yet (looked for: ${DOTFILE_NAMES[*]})."
        return 2
    fi

    local dir
    for dir in "${VIM_RUNTIME_DIRS[@]:-}"; do
        mkdir -p "${HOME}/${dir}"
    done

    [[ -n "$DOTFILES_BACKUP_DIR" ]] && log_info "Pre-existing files were backed up to: ${DOTFILES_BACKUP_DIR}"
    [[ "$failures" -eq 0 ]]
}
