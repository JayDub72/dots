# dots

A from-scratch macOS rebuild system. Full design and decision history is in
[`docs/planning.md`](docs/planning.md) — read that before changing anything
here. VM-based testing methodology is in [`docs/tart.md`](docs/tart.md).

This is scaffolding: the mechanism is real and working, but most *content*
(the application list, macOS defaults, most dotfile bodies) is intentionally
not decided yet. Don't fill in placeholders with invented content — every
open decision is called out in `docs/planning.md`.

## Quick start (fresh Mac)

```sh
set -o pipefail
mkdir -p ~/dots && curl -sSL https://github.com/jaydub72/dots/archive/refs/heads/main.tar.gz | tar -xz -C ~/dots --strip-components=1
cd ~/dots
./bin/dots all
```

curl+tar rather than `git clone` on purpose — a stock Mac has `curl`/`tar` built in, but `git` triggers the Xcode CLT installer prompt if it's not there yet, and Xcode CLT is a *later* step `dots all` handles itself. `set -o pipefail` makes a dropped download fail loudly instead of silently feeding `tar` a truncated file.

**Not usable yet** — this repo isn't pushed to GitHub. Per `docs/planning.md`'s locked decisions, that happens once the open items below are resolved, not before.

## Usage

```sh
./bin/dots help
./bin/dots all            # xcode -> homebrew -> apps -> dotfiles -> macos -> auth -> restore
./bin/dots apps           # just the Brewfile
./bin/dots dotfiles       # just symlink dotfiles/
./bin/dots auth           # restore the shared SSH key from 1Password, verify GitHub + NAS
./bin/dots maintenance    # brew update/upgrade/cleanup/doctor
./bin/dots backup         # push ~/Documents, ~/Downloads to the NAS now
./bin/dots restore        # pull them back down (asks to confirm)
./bin/dots baseline       # commit current dotfiles/ as the new truth
./bin/dots rollback       # reset dotfiles/ to the last baseline
```

`restore` is the last step of `all`, but always asks for confirmation first —
declining doesn't fail the run, it just prints the command to run it later
(see `docs/planning.md` step 6b).

## Layout

```
bin/dots            Single entry point — one subcommand per concern
lib/                 One file per module (log, sudo, xcode, homebrew, apps,
                     dotfiles, macos-defaults, auth, nas, backup, restore, baseline)
dotfiles/            Actual dotfile content, symlinked into $HOME by `dots dotfiles`
macos/defaults.sh    The one file of `defaults write` commands (static settings)
config/              backup.conf.example and auth.conf.example are tracked;
                     backup.conf and auth.conf (real values) are gitignored
launchd/             Template for scheduling `dots backup`
docs/                Planning, SSH setup runbook, VM testing methodology
```

There is no `_archive/` — old pre-rebuild content was deleted outright, not
kept as reference (see `docs/planning.md`'s session handoff).

## Before this is "done"

`dots` isn't a git repository yet on purpose — see the locked decisions
in `docs/planning.md`. Several things still block a full build-out (also
listed there): the application list, macOS defaults content, Downloads
retention/exclusion, off-LAN NAS access, exact snapshot retention numbers,
and the terminal emulator choice.
