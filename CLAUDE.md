# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A from-scratch macOS rebuild system (Xcode/Homebrew bootstrap, dotfile
symlinking, macOS `defaults write` settings, NAS-based backup/restore).
**`docs/planning.md` is the actual source of truth for design decisions and
project history** — read it before making any non-trivial change, especially
its "Session handoff" section at the bottom, which records hard-won platform
quirks and exact current state. This file only covers what's needed to be
productive quickly; it doesn't duplicate that history.

Most *content* here (the application list in `Brewfile`, `macos/defaults.sh`,
most of `dotfiles/`) is intentionally still placeholder — don't invent
values to fill gaps. Every open decision is tracked in `docs/planning.md`.

There is no `_archive/` — old pre-rebuild content was deleted outright, not
kept as reference. Nothing to pull forward from history that isn't already
in this repo or `docs/`.

**`dots` is not a git repository yet, on purpose** (see `docs/planning.md`'s
locked decisions — no `git init` until the scaffolding is confirmed correct).
This means `dots baseline`/`dots rollback` (`lib/baseline.sh`) are currently
inert — they check for a `.git` dir and error out rather than doing
anything. Don't run `git init` here unprompted, and don't assume
baseline/rollback work in their current state.

## Commands

```sh
./bin/dots help                 # list all subcommands
./bin/dots all                  # full run: xcode -> homebrew -> apps -> dotfiles -> macos -> restore (interactive)
./bin/dots <xcode|homebrew|apps|dotfiles|macos|maintenance|baseline|rollback|backup|restore>

# Syntax-check everything (no execution) — do this after editing any lib/ file
for f in bin/dots lib/*.sh macos/defaults.sh; do bash -n "$f"; done
zsh -n dotfiles/.zshrc
```

**Never run `dots dotfiles`, `dots backup`, `dots restore`, or `dots all`
against the real machine as a way to "test" a change** — they symlink into
the real `$HOME` and push/pull real data to a real NAS. Validate changes
via `bash -n`/`zsh -n`, or in a disposable Tart VM per `docs/tart.md`. If a
change genuinely needs a live run, that's the user's call to make and
execute, not something to do proactively while iterating.

This environment's ad-hoc shell tool runs **zsh**, not bash — `$BASH_VERSION`
is empty and bash-only constructs (e.g. `PIPESTATUS`) silently don't work as
expected. To test real bash behavior, invoke `bash -c '...'` explicitly.

## Architecture

**`bin/dots`** is a subcommand dispatcher, not a monolithic script: it
resolves its own location (`DOTS_ROOT`, no hardcoded paths anywhere in the
codebase — the whole repo has been relocated once already without any code
changes needed), sources every `lib/*.sh` module, then dispatches on `$1`.
`dots all` is the only multi-step command — everything else maps to exactly
one `lib/` module.

**One file per concern under `lib/`**, each exposing a `cmd_<name>()`
(`log.sh` and `sudo.sh` are shared infrastructure, not commands — logging
writes to both screen and a timestamped file under `logs/` — default
location is inside the repo, override with `DOTS_LOG_DIR`, and
`request_sudo_keepalive` asks for sudo once and keeps it alive rather than
prompting mid-run).

**`dotfiles/`** holds real dotfile content, deployed by symlinking (with
automatic backup of anything already at the target path) — the manifest is
the `DOTFILE_NAMES` array at the top of `lib/dotfiles.sh`. A name missing
from that array or missing a real file in `dotfiles/` is silently skipped,
not an error. Only `.ssh/config` and `.zshrc` exist so far.

**`lib/auth.sh`** (`dots auth`) restores the *shared* SSH key — one
`id_ed25519` trusted by GitHub and every homelab host (Proxmox nodes, VMs/
LXCs, the NAS) — onto a machine that's never had it, via 1Password CLI
(`config/auth.conf`, gitignored; `.example` is the tracked template), then
verifies GitHub and NAS trust actually work. 1Password is the only viable
key source here: restoring from the NAS would be circular (you'd need the
key to SSH to the NAS to go get the key). Runs after `apps`/`dotfiles`
(needs `op`/`gh`/the symlinked `.ssh/config`) and before `restore` (needs
SSH to the NAS working) in `dots all`'s sequence. See `docs/ssh-setup-plan.md`
Phase 6 for the 1Password side of this.

**NAS backup/restore** (`lib/backup.sh`, `lib/restore.sh`, `lib/nas.sh`) is
the most safety-critical part of this codebase — read `docs/planning.md`'s
"Session handoff" section in full before touching it. In short: `dots
backup` is a one-way push with `rsync --delete`, meaning local is truth and
the NAS gets pruned to match — `BACKUP_MAX_DELETE` (in `config/backup.conf`,
gitignored; `.example` is the tracked template) caps how many files one run
can delete before aborting, and `dots backup --force` is the deliberate,
manual-only override. `dots restore` is the mirror-image pull and is the
last, always-interactive step of `dots all` — declining it is a clean skip,
not a failure. `lib/nas.sh`'s `nas_is_reachable()` is the one function
governing off-LAN behavior (currently: silent skip, by design).

**Two macOS/bash platform quirks already cost real debugging time** — see
`docs/planning.md`'s "Session handoff" for the full detail, but at minimum:
bash 3.2 (what ships on macOS) treats a declared-but-empty array as
*unbound* under `set -u` when expanded as `"${arr[@]}"` (fix: `"${arr[@]:-}"`);
and macOS's `rsync` is actually Apple's `openrsync`, whose behavior isn't
guaranteed to match upstream rsync's documentation (`--max-delete=0` means
*unlimited* on this platform, not zero — verified empirically, not assumed).
