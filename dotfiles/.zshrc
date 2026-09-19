# ~/.zshrc — sourced by every interactive zsh shell, symlinked into place
# by `dots dotfiles`.

# Powerlevel10k instant prompt — must stay near the top. Anything that
# needs console input (passwords, [y/n] prompts) has to go above this
# block; everything else goes below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

source /opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source ~/.exports
source ~/.aliases
source ~/.functions

# To customize the prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# lscolor hack for 777 files/directories
LS_COLORS="${LS_COLORS}:ow=1;37:"
export LS_COLORS

# Warn on every new shell if the last scheduled `dots backup` run failed —
# a backstop in case the macOS notification (lib/backup.sh) gets missed or
# dismissed. Clears itself once a subsequent run actually succeeds.
# Resolves the repo location via this file's own symlink rather than a
# hardcoded path, so it keeps working if the repo ever moves.
if [[ -L "$HOME/.zshrc" ]]; then
    _dots_root="$(cd "$(dirname "$(readlink "$HOME/.zshrc")")/.." && pwd)"
    _dots_backup_status="${_dots_root}/logs/backup_status"
    if [[ -f "$_dots_backup_status" ]] && grep -q '^FAILED' "$_dots_backup_status" 2>/dev/null; then
        print -P "%F{red}⚠ Last backup run FAILED — $(cat "$_dots_backup_status")%f"
        print -P "%F{red}  Check ${_dots_root}/logs/ or run: dots backup%f"
    fi
    unset _dots_root _dots_backup_status
fi
