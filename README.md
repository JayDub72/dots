# dots

A from-scratch macOS rebuild system. [`CLAUDE.md`](CLAUDE.md) has the
architecture, locked decisions, and safety guardrails — read that before
changing anything here. Changes are validated in a disposable UTM VM
before trusting them on real hardware (see `CLAUDE.md`).

The mechanism and content are both real now — Brewfile, dotfiles, and
`macos/defaults.sh` are populated and deployed live. A line-by-line review
of `macos/defaults.sh`'s actual settings content is still open; see
"Known issues" below for what else is open.

## Quick start (fresh Mac)

```sh
set -o pipefail
mkdir -p ~/dots && curl -sSL https://github.com/jaydub72/dots/archive/refs/heads/main.tar.gz | tar -xz -C ~/dots --strip-components=1
cd ~/dots
./bin/dots all
```

curl+tar rather than `git clone` on purpose — a stock Mac has `curl`/`tar` built in, but `git` triggers the Xcode CLT installer prompt if it's not there yet, and Xcode CLT is a *later* step `dots all` handles itself. `set -o pipefail` makes a dropped download fail loudly instead of silently feeding `tar` a truncated file.

### After `dots all` finishes

1Password sign-in is a genuinely manual step nothing here can script past
— `auth` and `restore` will show as **SKIPPED**, not failed, if it isn't
done yet. Finish the setup by hand, in this order:

1. Sign into the **1Password app** (not the CLI), then enable
   Settings → Developer → **"Integrate with 1Password CLI"** and
   Settings → General → **"Keep 1Password in the system tray"**.
2. Re-run `./bin/dots auth` — restores the shared SSH key, verifies
   GitHub, tries an `op signin` automatically if needed.
3. **First connection to the NAS from this machine only:** SSH's
   `BatchMode` (used for `dots`'s own reachability checks) can't
   interactively prompt to trust a brand-new host's key, so run this
   once by hand and accept the fingerprint yourself — `dots` deliberately
   never does this silently on your behalf (see `CLAUDE.md`'s Architecture
   section for why):
   ```sh
   ssh -p <NAS_SSH_PORT> <NAS_USER>@<NAS_HOST>   # from config/backup.conf
   ```
4. `./bin/dots restore` — pulls your real data down from the NAS.
   **Do this before `dots backup`, always**, on any machine that's never
   been restored — `dots backup` will actually refuse to run at all
   until `dots restore` has completed successfully at least once (see
   `CLAUDE.md`'s Architecture section for why this is enforced, not just
   a suggestion).
5. `./bin/dots backup` — only after step 4. Pushes local `Documents`/
   `Downloads` to the NAS; safe now that local reflects the real data,
   not a near-empty fresh-machine state.

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
declining doesn't fail the run, it just prints the command to run it later.

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
```

There is no `docs/` — design history and the SSH runbook live outside this
repo now (see `CLAUDE.md`); VM testing is UTM-based, no dedicated doc yet.
There is no `_archive/` either — old pre-rebuild content was deleted
outright, not kept as reference.

## Known issues

Two issues found in real `dots all` test runs, reproduced more than once:

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
