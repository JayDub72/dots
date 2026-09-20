# dots

A from-scratch macOS rebuild system. Full design and decision history is in
[`docs/planning.md`](docs/planning.md) — read that before changing anything
here. VM-based testing methodology is in [`docs/tart.md`](docs/tart.md).

The mechanism and most content are both real now — Brewfile, dotfiles, and
`macos/defaults.sh` are populated. `.vimrc` plugin content, exact `macos/
defaults.sh` settings review, and a few smaller items are still open — see
`docs/planning.md` for the current state.

## Quick start (fresh Mac)

```sh
set -o pipefail
mkdir -p ~/dots && curl -sSL https://github.com/jaydub72/dots/archive/refs/heads/main.tar.gz | tar -xz -C ~/dots --strip-components=1
cd ~/dots
./bin/dots all
```

curl+tar rather than `git clone` on purpose — a stock Mac has `curl`/`tar` built in, but `git` triggers the Xcode CLT installer prompt if it's not there yet, and Xcode CLT is a *later* step `dots all` handles itself. `set -o pipefail` makes a dropped download fail loudly instead of silently feeding `tar` a truncated file.

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

Pushed to GitHub as [`jaydub72/dots`](https://github.com/JayDub72/dots)
(public — see `docs/planning.md` for why). A few things still open, all
tracked there: `macos/defaults.sh`'s actual settings content hasn't had a
full review pass, Downloads retention/exclusion within the NAS backup,
off-LAN NAS access.

Two known issues from real `dots all` test runs (both reproduced more
than once — see `docs/planning.md` for the full history):

- **`microsoft-office`'s cask install fails.** `/usr/sbin/installer`
  exits 1 with only `"installer: The install failed.."` — no more detail
  available. Not root-caused yet; could be VM-specific or a genuine
  installer issue independent of virtualization.
- **`backblaze`'s cask only places an installer, doesn't complete
  setup.** This is by Homebrew cask design (a "manual installer" cask),
  not a bug — after `dots apps` runs, finish it yourself:
  ```sh
  open /opt/homebrew/Caskroom/backblaze/*/Backblaze\ Installer.app
  ```
  (the `*` matches whatever version actually installed).
