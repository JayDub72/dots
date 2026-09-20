# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A from-scratch macOS rebuild system (Xcode/Homebrew bootstrap, dotfile
symlinking, macOS `defaults write` settings, NAS-based backup/restore).
**This file is the source of truth for working on this codebase.** The
fuller personal design history (why each decision was made, the SSH-key
runbook, full platform-quirk writeups) lives outside this repo in a
private notes vault — not needed to work on the code safely, since
everything with real teeth (safety guards, locked decisions, platform
gotchas) is captured below.

Most *content* here (the application list in `Brewfile`, `macos/defaults.sh`,
most of `dotfiles/`) is real now, not placeholder. Known open items:
`macos/defaults.sh`'s settings content hasn't had a full line-by-line
review, and `microsoft-office`'s cask install fails consistently in VM
testing (not root-caused — see `README.md`).

There is no `_archive/` and no `docs/` — old pre-rebuild content was
deleted outright, not kept as reference, and design history/the SSH
runbook live outside this repo now (a private notes vault). Nothing to
pull forward from history that isn't already in this repo.

**`dots` is a real git repository**, pushed to `jaydub72/dots`, public —
deliberate, so the curl+tar Quick Start (README) works against a stock
Mac before `git` is installed; this does mean real home-network topology
(Proxmox IPs, `*.home.lan` hostnames, this Mac's computer name) is
public, none of it directly exploitable. `dots baseline`/`dots rollback`
(`lib/baseline.sh`) are functional, not placeholders.

## Commands

```sh
./bin/dots help                 # list all subcommands
./bin/dots all                  # full run: xcode -> homebrew -> apps -> dotfiles -> macos -> auth -> restore (interactive)
./bin/dots <xcode|homebrew|apps|dotfiles|macos|auth|maintenance|baseline|rollback|backup|restore>

# Syntax-check everything (no execution) — do this after editing any lib/ file
for f in bin/dots lib/*.sh macos/defaults.sh; do bash -n "$f"; done
zsh -n dotfiles/.zshrc
```

**Never run `dots dotfiles`, `dots backup`, `dots restore`, or `dots all`
against the real machine as a way to "test" a change** — they symlink into
the real `$HOME` and push/pull real data to a real NAS. Validate changes
via `bash -n`/`zsh -n`, or in a disposable UTM VM (Tart was tried first but
had an unresolved `brew bundle` stall that was never root-caused; UTM
works cleanly for the same test). If a change genuinely needs a live run,
that's the user's call to make and execute, not something to do
proactively while iterating.

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
the `DOTFILE_NAMES` array at the top of `lib/dotfiles.sh` (currently
`.ssh/config`, `.zshrc`, `.exports`, `.aliases`, `.functions`, `.profile`,
`.p10k.zsh`, `.vimrc`, `.config/ghostty/config`, and VS Code's
`settings.json`). A name missing from that array or missing a real file in
`dotfiles/` is silently skipped, not an error.

**`lib/auth.sh`** (`dots auth`) restores the *shared* SSH key — one
`id_ed25519` trusted by GitHub and every homelab host (Proxmox nodes, VMs/
LXCs, the NAS) — onto a machine that's never had it, via 1Password CLI
(`config/auth.conf`, gitignored; `.example` is the tracked template), then
verifies GitHub and NAS trust actually work. 1Password is the only viable
key source here: restoring from the NAS would be circular (you'd need the
key to SSH to the NAS to go get the key). Runs after `apps`/`dotfiles`
(needs `op`/`gh`/the symlinked `.ssh/config`) and before `restore` (needs
SSH to the NAS working) in `dots all`'s sequence.

**SSH host key trust is never auto-accepted — this is a locked decision,
not an oversight.** `nas_is_reachable()` detects "Host key verification
failed" and tells the user to connect manually once and verify the
fingerprint themselves, the same as any other human-verified-trust step
(1Password sign-in, `gh auth login`). An earlier draft had this
auto-trust new host keys via `ssh-keyscan` with zero verification — a
real security regression (defeats host key checking's actual MITM-
protection purpose) — and was reverted before shipping. Don't
reintroduce silent trust decisions here for any host, however
low-stakes it seems.

**NAS backup/restore** (`lib/backup.sh`, `lib/restore.sh`, `lib/nas.sh`) is
the most safety-critical part of this codebase. `dots backup` is a
one-way push with `rsync --delete`, meaning local is truth and the NAS
gets pruned to match — `BACKUP_MAX_DELETE` (in `config/backup.conf`,
gitignored; `.example` is the tracked template) caps how many files one run
can delete before aborting, and `dots backup --force` is the deliberate,
manual-only override. `dots restore` is the mirror-image pull and is the
last, always-interactive step of `dots all` — declining it is a clean skip,
not a failure. `lib/nas.sh`'s `nas_is_reachable()` is the one function
governing off-LAN behavior (currently: silent skip, by design).

**`dots backup` structurally refuses to run before `dots restore` has ever
succeeded — do not weaken this.** `dots restore` writes a marker file
(`RESTORE_STATUS_FILE`, `logs/restore_status`) on success; `dots backup`
checks for it and refuses without it, `--seed` being the sole, explicit,
typed-by-hand exception for seeding a genuinely empty NAS from the first
machine. This exists because it happened for real once: `dots backup` ran
on a freshly-restored-nothing VM and started pruning real NAS data to
match an empty local folder — `BACKUP_MAX_DELETE` caught it that time, but
a numeric backstop catching a mistake isn't the same as the mistake being
structurally impossible.

**Several macOS/bash platform quirks already cost real debugging time**:
bash 3.2 (what ships on macOS) treats a declared-but-empty array as
*unbound* under `set -u` when expanded as `"${arr[@]}"` (fix:
`"${arr[@]:-}"`); macOS's `rsync` is actually Apple's `openrsync`, whose
behavior isn't guaranteed to match upstream rsync's documentation
(`--max-delete=0` means *unlimited* on this platform, not zero — verified
empirically, not assumed); `set -o pipefail` breaks any pipeline built on
a command that exits nonzero on success (e.g. `ssh -T git@github.com |
grep ...`) — capture to a variable first; and redirecting stderr on a
command that might need to prompt interactively (`sudo`, `op`, `ssh-add`)
creates a silent, working-indistinguishable-from-hung state — don't
redirect stderr on anything that might need to prompt a human.
