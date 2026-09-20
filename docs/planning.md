# macOS rebuild plan

## Core outcomes
1. After a fresh install of macOS (regardless of the version), I want to lay down the applications, the settings and the environment so that it feels like the same experience every time. 
2. I will experiment and install things but I want to be able to roll back to a clean version of the settings.
3. There are two versions of settings here and the distinction is important:
    a. macOS settings - trackpad settings, mouse settings, keyboard settings, etc. Those should stay static and never change. I don't change those settings unless something very strange has happened -- exception not the rule.
    b. environment settings like dotfiles, application configuration, etc. - these may change more often. I want an alias that allows to be baseline my configuration and write it to the repo as the latest "truth".  Then, when I decide to clean up after some testing, I can rollback to that "truth." But again, only these environmental settings.
4. I want to be able to rebuild my mac from scratch at any time. Today, tomorrow, 3 years from now and have it still have the exact same configuration.
5. I want this install process to be fully automated and not asking for a ton of interaction throughout the process. 
6. I want the process to be modular so I can pass parameters to update the applications (brew update, cleanup, doctor, etc.), only update dotfiles (not sure if I should use symlinks or not for this), etc.
7. I should NEVER lose any of my data (documents, settings, downloads, etc.) when I rebuild my Mac. I want to make sure that there is a full backup process in place (daily or weekly) so that when I rebuild the Mac, these files are restored. (I do not want this to live in the Cloud).

## Steps (in my mind)

1. macOS install
This is managed outside of the scope of this project. macOS should be installed as a base OS only -- out of the box.

2. Application Dependencies
In order to install application automatically, I will need the infrastructure to be addressed properly. Things like xcode have to be installed so homebrew works, homebrew has to be installed so I can install apps, etc. 

I expect this project to help flush out what all of those are requirements and dependencies are -- I am not going to articulate them here.

3. Install applications
This should be an opinionated list that I provide and installed via automation (brew or other mechanisms if brew will not work).

The applications will include terminal applications, mac applications, fonts, etc. 

4. Create folder structures and restore
I want to make sure that my default directory structure approach is rebuilt and ready for the restore when the time comes.

5. Configure settings
This can be broken down into two sections as I mentioned above: macOS and environment. 

I want a single file that let's me specific all of the various macOS settings I want set up automatically (default.writes). I want the project to look at my current configuration and use that as a baseline if possible. That could be too extensive of a list so I may have to walk through and create this file manually but I need that direction and feedback at the appropriate time.

For environment settings, this is where things become the most volatile. Few things that come to mind in terms of configuration:
  a. SSH 
  b. git
  c. dotfiles
  d. CLAUDE skills (not very developed yet but I should start to build on this more)
  e. SSH keys and GPG/signing keys — NOT the same thing as `a. SSH` above, which is really just `~/.ssh/config` (safe to version-control). Private key material can never go in the repo. Needs an explicit decision: regenerate fresh per rebuild (re-register new keys with GitHub/servers each time) vs. restore existing keys from somewhere secure (1Password's SSH agent support is worth researching for this specifically).
  f. Credentials/secrets strategy — 1Password is already installed and is the obvious source of truth here, but it's technically still "the cloud" (encrypted vault sync) even if it's a different trust model than raw files in Dropbox/iCloud. Worth a conscious yes/no rather than an assumption, given outcome #7's no-Cloud stance.
  g. Terminal emulator — `Brewfile` currently has both `iterm2` and `ghostty`. Pick one; outcome #1 ("feels like the same experience every time") implies a single answer, including its profile/color scheme, not just the app being installed.
  h. Editor config — VS Code vs. VSCodium is still an open question from earlier (not just which one installs, but settings.json, extensions list, keybindings).
  i. License keys / account reactivation for paid apps — 1Password, Microsoft 365, NordVPN/ProtonVPN, Logos, etc. Not a dotfile, but "same experience every time" quietly assumes these get signed back in somehow — worth its own checklist item so it's not forgotten mid-rebuild.

6. Restore data
This is the other half of core outcome #7 — never lose Documents, Downloads, or other data across a rebuild, without it living in the Cloud. Two separate things need to be true, and I'm keeping them separate on purpose. No new always-on background app for this — script + schedule, kept in the repo like everything else.

a. Ongoing backup (scheduled, independent of any rebuild) — Synology NAS, two layers:
    - Push layer: `rsync -avz --delete` over SSH, one-way, `~/Documents` and `~/Downloads` → a dedicated shared folder on the NAS. Key-based SSH auth (no password prompt) so it can run unattended. Enable the rsync service and SSH on the NAS (Control Panel → File Services / Terminal & SNMP) to support this.
    - Scheduled via `launchd` (`StartCalendarInterval`), not cron — cron silently skips a run if the Mac is asleep at the scheduled time; launchd catches the job up on wake instead. This is what actually satisfies "daily or weekly" — the rsync script and its `launchd` plist live in this repo, not hidden in some app's settings UI.
    - Protection layer: Btrfs Snapshot Replication on that NAS shared folder — confirmed the DS1821+ volume is already Btrfs, so no volume rebuild needed. Turn on Immutable Snapshots (needs DSM 7.3+ — confirm current DSM version). This matters specifically because `--delete` means a file removed locally also disappears from the live NAS share on the next run — the snapshot layer is what makes that recoverable instead of permanent, and also covers ransomware/bad-sync scenarios. Retention policy still TBD — something like hourly for a day, daily for a month, weekly for a few months.

b. Restore, as part of the rebuild (this is the step that actually lives here in the flow)
    - Mirror-image `rsync` command, one-way, NAS shared folder → `~/Documents` and `~/Downloads` on the fresh Mac. Run deliberately during a rebuild, not automatically — restore should be an explicit step, not something that fires on its own.
    - The NAS shared folder is the actual source of truth for this data, not any one Mac.
    - **Order matters on a fresh Mac: `dots restore` before `dots backup` is ever run or scheduled, always.** `dots backup` is a one-way push with `--delete` — local is treated as truth and the NAS gets pruned to match it, so backing up from an empty, not-yet-restored Mac would delete the real backup. `BACKUP_MAX_DELETE` (config/backup.conf) is a technical backstop for getting this order wrong — it aborts a backup run that would delete more files than that threshold — but it's a backstop, not a reason to get the order wrong on purpose. Also don't install the `launchd` schedule until after the first successful restore, for the same reason.

c. Still open:
    - Does Downloads need the same retention as Documents, or should it be excluded/shorter-retention since it fills with disposable installers?
    - Home-network-only, or does this need to work away from the LAN too? Remote access brings back some of the same "data leaves the building" concern as Cloud storage, so this should be a deliberate choice, not a default.
    - Exact snapshot retention numbers.

## Review notes (critical pass, 2026-09-19)

Findings from re-reading this plan against the actual state of `dots` and the full audit of the live `~/.dotfiles` system done earlier. Kept separate from the sections above so the original writing stays untouched.

### Open punch list — decisions already made in discussion, not yet reflected in the repo
- `.zshrc` still has the `mise`/`uv` activation blocks despite already deciding neither is wanted.
- `Brewfile` still has `cask "plex"` (wrong cask — should be `plex-media-player`, if that's still the intended app) and `cask "visual-studio-code"` (VSCodium vs. VS Code was flagged as an open philosophy question, never actually resolved — see step 5h).
- `existing/`, `apps_installed.txt`, `brew_installed.txt`, `brew_installed.md` are still sitting in the repo root from before the decision to do a pristine rebuild instead of a migration — their continued presence invites reflexively copying old content forward again.
- `dots` is still not a git repo. No decision recorded yet on when it becomes one, public vs. private, or commit conventions — notable given how much attention this project has already paid to the *old* system's git hygiene.

### Outcome #7 is narrower than it claims — data outside Documents/Downloads
- SSH keys (`~/.ssh`) and any GPG/signing keys (`~/.gnupg`) are not covered by the step 6 rsync plan and cannot go in the dotfiles-as-code approach either (never commit private key material). As written, a rebuild would permanently lose these. See step 5e.
- No inventory pass has been done to confirm Documents + Downloads is actually the *complete* set of irreplaceable local data — Desktop, or any app data living outside `~/Documents` (e.g., under `~/Library/Application Support/...`), would be silently excluded.

### Structural gaps in the Steps flow
- Step 4 ("Create folder structures and restore") and step 6 ("Restore data") overlap in name with no cross-reference — unclear which owns what or what order they run in.
- `tart.md` (the VM testing methodology) isn't referenced anywhere in the Steps. Two solid documents with no bridge between them — worth an explicit statement that every step above gets validated in a disposable Tart VM before being trusted on real hardware.
- No stated "definition of done" for this plan — what makes it ready to move from design to execution.

### Outcome #6 (modularity) vs. what `install.sh` already does
`install.sh` already implements skip-flags (`--skip-xcode`, `--skip-brew`, `--skip-bundle`, `--skip-dotfiles`, `--skip-defaults`), which is a different interface than the positive/selective actions outcome #6 describes ("only update dotfiles," "brew update, cleanup, doctor" as its own action). Worth deciding explicitly whether skip-flags are sufficient or whether a subcommand style (`install.sh dotfiles`, `install.sh maintenance`) fits better — and the "not sure if I should use symlinks" question in outcome #6 is already answered by the existing script (yes, with backup), which itself is a small sign this doc and the code have drifted apart.

## Decisions locked (2026-09-19)

These resolve open questions raised above. Recorded here so they survive into
whatever gets built, rather than living only in chat history.

1. **No `mise`, no `uv`.** Neither goes in the rebuilt shell config or
   Brewfile, guarded conditional or otherwise.
2. **Plex, if kept, uses the correct cask** — `plex-media-player`, not
   `plex` — when the Brewfile is rebuilt.
3. **Editor: VS Code.** VSCodium is eliminated as an option. This also
   resolves step 5h — settings/extensions/keybindings to standardize on are
   VS Code's, not VSCodium's.
4. **`existing/`, `apps_installed.txt`, `brew_installed.txt`,
   `brew_installed.md` are removed** — no longer part of this project.
5. **The entire prior `dots` repo content (`install.sh`, `Brewfile`, all
   dotfiles, the old `CLAUDE.md`/`README.md`, `.ssh/`, `existing/`, the
   snapshot files) has been moved to `_archive/pre-rebuild-2026-09-19/`.**
   Nothing in that archive is a starting point or reference to copy from by
   default — the rebuild is driven by this planning document only. If a
   specific piece of the old content is deliberately pulled forward, that
   should be a conscious, named decision at the time, not a silent default.
   `dots` does not become a git repo until the steps in this plan are
   correct — no rush to `git init` just to have one.

Still unresolved and blocking a full build-out (see items above): Downloads
retention/exclusion, home-network-only vs. remote NAS access, exact snapshot
retention numbers, credentials/secrets strategy (5f, see below), terminal
emulator choice (5g, in progress), and a stated definition of done.

## Scaffolding built (2026-09-19)

`docs/ssh-setup-plan.md` turned out to already resolve 5e (SSH/GPG key
strategy) — it's a real, already-executed runbook, not a hypothetical: native
macOS `ssh-agent` + Keychain, one `ed25519` key across GitHub and the
3-node Proxmox homelab, 1Password as an encrypted backup + secrets store
only (never in the auth path, accessed via `op read` at the point of use —
a partial, leaning-yes answer to 5f too, distinct from raw file cloud
sync). Verified working on the real Mac already. `dotfiles/.ssh/config` in
the scaffold below is that real, already-working config, deliberately
pulled out of `_archive/` — not a default.

The project scaffolding now exists: `bin/dots` (subcommand-style CLI —
resolves the outcome #6 interface question in favor of subcommands over
skip-flags: `dots all|xcode|homebrew|apps|maintenance|dotfiles|macos|
baseline|rollback|backup|restore`), one module per concern under `lib/`,
`dotfiles/`, `macos/defaults.sh`, `config/backup.conf.example`, a
`launchd/` template, and a placeholder `Brewfile` with the locked decisions
noted inline. Logging, sudo keep-alive, and the backup/restore/baseline
mechanisms are real and smoke-tested. Application list, macOS defaults
content, and most other dotfile bodies are still placeholders — see
`README.md` for the layout and `_archive/` policy.

`baseline`/`rollback` need `dots` to actually be a git repo to function
at all — currently blocked on the "no git until the steps are correct"
decision above. Worth revisiting now that real scaffolding exists.

## Session handoff (2026-09-19, end of session)

A lot happened after the scaffolding section above. This is what a fresh
session needs to know without re-deriving it.

### Repo identity and location
- Renamed `newdots` → `dots` everywhere (title, comments, VM names in
  `tart.md`, the launchd plist and its internal `Label`/paths) — zero
  `newdots` references remain anywhere.
- **Moved from `~/Documents/github/dots` to `~/dots`**, deliberately — the
  old location was still inside `~/Documents`, meaning `dots backup` was
  recursively backing up its own `logs/` and (the now-deleted) `_archive/`
  every run. `~/dots` sits outside the backup scope entirely. The old
  `~/Documents/github/dots` copy has been deleted.
- `_archive/` no longer exists at all (deleted by choice, not by me) — the
  old `~/.dotfiles`-derived content is gone, not just de-prioritized.
  Nothing to pull forward from it anymore even if wanted.
- Target GitHub: **`jaydub72/dots`**, `main` branch. Not pushed yet —
  waiting on "no git until the steps are correct" per the locked decision
  above. `README.md`'s Quick Start section already has the real URL, marked
  "not usable yet" until that changes.

### NAS backup/restore — fully built and verified working, not hypothetical
- `dotfiles/.ssh/config` has a `Host nas` entry (`HostName nasbox.home.lan`,
  confirmed via DNS + a live SSH connection, not guessed). Key copied via
  `ssh-copy-id`, connection verified.
- `config/backup.conf` has real, confirmed values: `NAS_SHARE_PATH=
  /volume1/backups` (confirmed via `ssh nas 'find /volume*/ -maxdepth 1
  -iname backups'` — DSM's own "Location" field is not reliable for this,
  it showed something else). `backups` had to be promoted to its own
  top-level DSM Shared Folder — Snapshot Replication cannot target an
  arbitrary subfolder.
- NAS side: DSM confirmed 7.4.1. Btrfs confirmed on the DS1821+ volume.
  Snapshot schedule: Sunday 03:00, "once per day" interval with only
  Sunday selected (DSM has no literal "weekly" option — this is how you
  get weekly out of its actual UI). Immutable Snapshots ON, 14-day
  protection period.
- The initial seed `dots backup` (Mac → NAS, since the NAS started empty)
  completed successfully — 20.86GB, zero errors, verified by grepping the
  log, not just trusting "it finished."
- `BACKUP_MAX_DELETE=1000` (raised from an initial 10, which was too tight
  — it blocked a routine 100-file cleanup). `dots backup --force` exists
  for a deliberate large deletion that should still bypass the limit —
  never invoked automatically, never by the scheduled job.
- Off-LAN behavior: **silent skip, by design, confirmed wanted.** No
  notification when the NAS is just unreachable (e.g., away from home) —
  it resumes quietly on the next scheduled run once back on the LAN. This
  resolves the "remote access" open item below as "no, LAN-only."
- Failure alerting (for *real* failures, not off-LAN skips): a macOS
  notification fires immediately, and `dotfiles/.zshrc` prints a warning
  on every new shell if the last run failed, clearing once a run succeeds.
  Both verified — the notification fired for real, the `.zshrc` logic was
  tested against both states in throwaway directories.
- `launchd/com.dots.backup.plist.template` is correct and ready but
  **deliberately not activated yet** — wait until after re-verifying
  `dots backup`/`dots dotfiles` from the new `~/dots` location.

### Platform quirks discovered the hard way — do not reintroduce these
- **macOS ships bash 3.2**, not 4+. A declared-but-empty array
  (`arr=()`) is treated as *unbound* under `set -u` when expanded as
  `"${arr[@]}"` — this bit `lib/dotfiles.sh`, `lib/backup.sh`,
  `macos/defaults.sh`. Fix verified empirically: `"${arr[@]:-}"` is safe
  in both the empty and populated case (including multi-word elements).
  `${#arr[@]}` (length) and `"${!arr[@]}"` (indices) are safe even when
  empty — no fix needed for those forms.
- **`&>>file` is not valid bash syntax** (silently was, in the
  pre-rebuild `install.sh`, and nobody had ever actually run it to find
  out). Use `>>file 2>&1`.
- **macOS's `/usr/bin/rsync` is Apple's `openrsync`**, not upstream rsync
  — its man page barely documents exit codes (says only 0/1/2 exist), but
  empirically it does return 25 for a `--max-delete` abort, matching
  upstream's undocumented-here behavior. More importantly: **on this
  rsync, `--max-delete=0` means UNLIMITED deletions, not zero** — verified
  empirically in a throwaway test. Never default this to 0.
- **This Claude Code environment's ad-hoc Bash tool runs zsh by default**,
  not bash — `$BASH_VERSION` is empty, `PIPESTATUS` (bash) silently
  doesn't exist (zsh's equivalent is `$pipestatus`, different indexing).
  To test real bash behavior, invoke `bash -c '...'` explicitly rather
  than trusting the tool's default shell.

### Still genuinely open (updated 2026-09-19, see dated sections below for detail)
- Brewfile: done (Ghostty, VS Code, plex-htpc, curated formula/cask list).
- Dotfile content: done — `.ssh/config`, `.aliases`, `.functions`,
  `.exports`, `.profile`, `.p10k.zsh`, `.zshrc`, `.vimrc` all written and
  *actually deployed live* on this Mac. `Library/.../Code/User/
  settings.json` is written but not yet symlinked. `.tmux.conf` dropped
  (you don't use tmux).
- `macos/defaults.sh`: content written (pulled from the old `~/.dotfiles`
  scripts) and the mechanics cleaned up to match this codebase, but the
  actual settings content itself has not been reviewed line-by-line yet.
- `dots auth`: built, restore logic validated against real 1Password
  data, but the full command has never been run end-to-end (this Mac
  already has the key, so a real run would just skip the interesting
  part).
- Downloads retention/exclusion *within* the backup (separate from the
  NAS-wide snapshot retention, which is now decided — weekly, 14-day
  immutable) — still open.
- `git init` / GitHub push — deliberately deferred until you're confident
  the working files are actually right, per your own call. `dots
  baseline`/`dots rollback` are built but cannot run at all until this
  happens (they're git wrappers with nothing to wrap yet).
- Tart VM testing (`docs/tart.md`): not actually usable yet as of this
  writing — `tart` itself isn't installed on this Mac, and no base VM
  image has been created. Both are one-time setup steps, and creating a
  base VM from a fresh macOS IPSW is slow (real download + install).
  `docs/tart.md` also had two stale references, now fixed: `install.sh`
  (should be `./bin/dots all` — the entry point was renamed) and the VM
  mount path `~/Documents/github/dots` (repo moved to `~/dots`).

### Immediate next steps for a new session
1. From `~/dots`: run `./bin/dots dotfiles` — needed both to fix
   `~/.ssh/config` (still points at the deleted `~/Documents/github/dots`
   path) and to deploy `.zshrc` for the first time (currently still
   pointing at the old `~/.dotfiles` system, never switched over).
2. Decide when to activate the `launchd` schedule (template is ready).
3. Everything in "Still genuinely open" above.

## Session handoff (2026-09-19, continued)

### `~/.ssh/config` fixed manually (not via `dots dotfiles`)
Immediate next step #1 above only did the SSH half: `~/.ssh/config` was
relinked by hand to `/Users/jworthen/dots/dotfiles/.ssh/config` (confirmed
via `ssh -G nas`). `dots dotfiles` itself was deliberately **not** run —
it would have also relinked `.zshrc`, and the real `.zshrc` isn't ready to
replace the current one yet (has other setup you still want available).
Don't run `dots dotfiles` for real until `.zshrc`'s content is actually
decided (see "Still genuinely open" above — unchanged).

### Brewfile built out
No longer an empty placeholder — built from the live machine's `brew
leaves`/`brew list --cask`/`brew bundle dump` state plus the pre-rebuild
`docs/brew_installed.md` inventory as reference (not a hard dependency —
the Brewfile does not need to match that doc going forward). Locked
decisions applied: Ghostty is the terminal (iTerm2 dropped), VS Code only
(VSCodium dropped), and Plex is the **client** — `cask "plex-htpc"`, not
`plex-media-server` (that's the self-hosted server, a different product)
and not the now-deprecated `plex-media-player`. One real bug fixed:
`brew "openssh"` needs `link: false` in the Brewfile itself, not just a
post-install warning — this Mac's actual installed openssh is unlinked for
exactly the reason Phase 3 of `docs/ssh-setup-plan.md` describes (Homebrew's
vanilla ssh/ssh-add don't understand Keychain integration at all; if linked
ahead of `/usr/bin/ssh` on PATH, passphrase-free auth silently breaks), and
a fresh Brewfile run needs to reproduce that unlinked state itself, not
rely on `lib/apps.sh` noticing after the fact.

### New: `lib/auth.sh` / `dots auth` — the SSH key is not yet self-hosting
Real gap found: nothing before this made SSH work on a machine that's
*never* had it. Everything verified working so far (key, Keychain, `gh`
auth) was done by hand on this one Mac, following
`docs/ssh-setup-plan.md` as a manual runbook — `bin/dots` itself had zero
SSH automation (`lib/dotfiles.sh` only ever symlinked `.ssh/config`, which
just points `IdentityFile` at a key file nothing creates).

Key design point: this setup deliberately uses **one shared key**
everywhere (GitHub + all 3 Proxmox nodes + every VM/LXC + the NAS), not a
fresh key per machine. So a new machine doesn't need to *register*
anything new with any remote host — it needs the *same private key
restored*, then loaded into Keychain. That reframes "how does a new
machine get the key" down to one question: where does the private key
material come from. 1Password is the only viable source — it's the one
root of trust in this whole chain that doesn't itself depend on SSH
already working. (Restoring the key *from the NAS* was considered and
rejected: `dots backup`/`dots restore` themselves connect to the NAS over
SSH using this same key, so pulling the key from the NAS to bootstrap SSH
is circular.)

`lib/auth.sh` (`dots auth`, runs after `apps`/`dotfiles`, before
`restore` in `dots all`):
1. Verifies `op` (1Password CLI) is signed in — cannot be automated
   further, this is the one genuinely manual, human-verified step in the
   whole chain (new-device account linking). Errors with clear
   instructions if not.
2. Restores `~/.ssh/id_ed25519` via `op read --out-file ... "op://<vault>/
   <item>/private key?ssh-format=openssh"` (vault/item named in
   `config/auth.conf`, gitignored; `.example` is the tracked template) —
   skips if the key already exists locally (idempotent). Derives the
   `.pub` file locally via `ssh-keygen -y` rather than also storing/
   reading it from 1Password.
   `ssh-format=openssh` is required — op read's plain default for this
   field is PKCS#8 PEM, which ssh-keygen/ssh-add can't read at all.
3. `ssh-add --apple-use-keychain` to seed Keychain (one-time interactive
   passphrase prompt — same "unavoidable human step" category as #1, just
   smaller). Also sanity-checks `ssh` resolves to `/usr/bin/ssh`, not a
   linked Homebrew build.
4. Verifies/establishes GitHub trust: `gh auth login` if `gh` itself isn't
   authenticated (separate credential from the SSH key), checks whether
   this exact key is already registered via `gh ssh-key list` before
   calling `gh ssh-key add` (avoids re-registering the same key on every
   machine), then confirms with `ssh -T git@github.com`.
5. Best-effort NAS reachability check (reuses `nas_is_reachable()`,
   non-fatal if off-LAN or `config/backup.conf` doesn't exist yet).

### `config/auth.conf` filled in and restore logic validated (2026-09-19)
Real item: vault "Jason & Larissa", item "jason SSH key" (not renamed
machine-agnostic after all — kept as-is, your call). Validating it
surfaced two real bugs in `lib/auth.sh`, both fixed:
- The vault name contains `&`, which `op://` references can't parse at
  all (confirmed: percent-encoding doesn't work either, `op` rejects `%`
  too). Fixed by referencing the vault by ID
  (`awjf7ugzxprfw67l6r3ne6lqdu`, found via `op vault list`) instead of
  name. The item name ("jason SSH key") has no special characters so it's
  still referenced by title.
- `op read`'s plain default for an SSH key item's "private key" field is
  PKCS#8 PEM (`-----BEGIN PRIVATE KEY-----`), not OpenSSH's format —
  `ssh-keygen -lf`/`ssh-add` can't read it, would have failed with "not a
  key file" on a real restore. Fixed with the `?ssh-format=openssh` query
  parameter (documented in `op read --help`'s own examples).

Verified end-to-end (not just read logic in isolation): restored the key
to a permission-locked scratch file via the exact `op read` invocation
`lib/auth.sh` uses, confirmed its fingerprint
(`SHA256:bcCLFxhfRCetp7iqF2vE6UEa9D4X5AWDsICRTy4J1ME`) matches the real
`~/.ssh/id_ed25519` on this Mac exactly, then securely deleted the scratch
copy. Private key material was never printed, logged, or left on disk
outside that one shredded scratch file.

**Still genuinely open:** `dots auth` itself has still never been run as
a full command on any machine (this Mac already has the key, so a real
run would just skip the restore step) — what's verified above is the
restore logic in isolation, not the whole `cmd_auth` flow (Keychain
loading, GitHub checks, NAS check) end-to-end. Actually running `dots
auth` needs either a genuine fresh Mac or a throwaway `~/.ssh` moved
aside first — not something to do against this real machine casually.

### Shell dotfiles built out (2026-09-19, continued)
`dotfiles/.zshrc`, `.aliases`, `.functions`, `.exports`, `.profile`, and
`.p10k.zsh` are done — deliberately reviewed and carried forward from
`~/.dotfiles/src/shell/` (the old, still-live pre-rebuild system), not
copied wholesale. Kept the split-file structure (separate
aliases/functions/exports) rather than consolidating into one `.zshrc` —
your call, matches current habit.

Real bugs fixed along the way, not just preference:
- `~/.exports` was symlinked by the old system but **never actually
  sourced by anything** (`.zshrc`/`.profile` only ever sourced
  `.aliases`/`.functions`) — none of its settings (EDITOR, LESS_TERMCAP,
  MANPAGER, history config, etc.) were taking effect. Now sourced from
  both `.zshrc` and `.profile`.
- Old `exports` was mostly bash-only and silently inert under zsh anyway:
  `HISTCONTROL`/`HISTFILESIZE`/`HISTIGNORE` and the whole
  `PROMPT_COMMAND`/`update_terminal_cwd` block don't exist in zsh. Dropped;
  replaced with zsh's real history mechanism (`HISTSIZE`/`SAVEHIST`/
  `HISTFILE`/`setopt`), which the old file never actually had.
- zshrc had a real bug: `export LS_COLORSexport PATH="..."` — two
  statements smashed together with no separator, meaning `LS_COLORS` was
  never actually exported (it exported a garbage `LS_COLORSexport`
  variable instead) and PATH got an unintended stray Ruby prepend. Fixed;
  PATH setup modernized to `eval "$(/opt/homebrew/bin/brew shellenv)"`
  instead of the old manual `export PATH=...` "hack."
- `curlhammer()` called an undefined `bot` command — would have errored
  if ever actually invoked. Dropped (decided not worth fixing).
- The old `fc` alias shadowed the zsh/bash `fc` (history) builtin with a
  file-counting one-liner. Renamed to `fcount()`, moved to `.functions`.

Decisions made explicitly, not defaults:
- `rm` → `alias rm="trash"` (recoverable; `trash` is in the Brewfile),
  with `rmrf` as the explicit escape hatch for real permanent deletes.
  Replaces the old `rm -rf --`-by-default alias (defined twice,
  redundantly, in the old file).
- Dropped: `matrix1`/`matrix2` (novelty, no functional use), `manp2`
  (redundant with `manp`, needed an extra dependency), `sri()`
  (web-dev-specific, not currently relevant), `fo()` (fuzzy-open via
  `fzf-tmux` — you don't use tmux, not worth a rewrite).
- Antigravity and Ollama PATH exports dropped — not currently used.

`lib/dotfiles.sh`'s `DOTFILE_NAMES` updated to include all of the above.
`.vimrc` (740 lines in the old system) deliberately not touched this
pass — same "be intentional, don't just copy" treatment still needs to
happen there, separately.

### `.vimrc` carried forward as-is (2026-09-19, continued)
Explicit instruction: use the existing `.vimrc` unchanged, no line-by-line
review like the shell files got. Copied verbatim to `dotfiles/.vimrc`
(740 lines) plus `dotfiles/.vim/snippets/emmet.json` (real authored
config `.vimrc` reads at runtime for the emmet plugin).

One thing not carried forward, and deliberately not: the old
`~/.dotfiles` symlinked the entire `~/.vim` directory itself (not just
`.vimrc`), which also covers `.vimrc`'s `backupdir`/`directory`/`undodir`
settings (`~/.vim/{backups,swaps,undos}`) — meaning that scratch state
has been living inside a git working tree this whole time, kept out of
commits only by `.gitignore` patterns (`%*`, `*.un~`, etc. — never
actually committed, confirmed via `git ls-files`, but still a latent
risk). `~/.vim/undos/` currently holds real vim undo history for files
across the filesystem, including `~/.ssh/config`, `~/.ssh/known_hosts`,
and various homelab Ansible/Terraform configs — undo files can retain
full text of prior edit states.

`dots` handles this differently: only `.vimrc` and `.vim/snippets/
emmet.json` are managed dotfiles (individual file symlinks, same as
everything else in `DOTFILE_NAMES`). `~/.vim/{backups,swaps,undos}` are
just real local directories `cmd_dotfiles` `mkdir -p`s so vim has
somewhere to write — never symlinked, never inside the repo, so nothing
sensitive can end up in `dots` git history even by accident. Added the
same defensive `.gitignore` patterns as the old repo anyway, in case
something vim-related ever does land under a tracked path.

**Update:** the plugin question came back up when you asked what
`:PackUpdate` even meant — turned out none of the 29 declared plugins
were actually installed even on this Mac (`~/.vim/pack` didn't exist).
Trimmed the list to 12 still-relevant ones (kept: the 4 tpope plugins,
polyglot, signify, delimitmate, targets.vim, nerdtree, indent-guides,
plus — my judgment calls, flagged and not objected to — vim-commentary
for comment-toggling and vim-colors-solarized for the colorscheme, since
dropping either would have been a real functionality/appearance loss
nobody asked for; dropped: all JS/web tooling, syntastic and
neocomplcache — both superseded by their own authors years ago — ctrlp
(redundant with fzf, already in the Brewfile), and a couple of
stragglers). Cleaned up every now-dead reference (`<leader>cc` remapped
from `:TComment` to `:Commentary`, dropped `<leader>rl`/`<leader>ts`
mappings, dropped `PrettyPrint()`'s XML branch, dropped the
neocomplcache-specific autocomplete-enable line while keeping the
generic Tab-completion mapping). `dotfiles/.vim/snippets/emmet.json`
removed — dead now that emmet-vim is gone.

**Reverted (2026-09-19, same day): all plugins removed, "full stop."**
Two things went wrong testing the trimmed-plugin version for real:

1. The live bootstrap accidentally installed everything inside the OLD
   `~/.dotfiles` repo's working tree (`~/.vim` was still a directory
   symlink into it — missed checking that first). Fixed by migrating
   `pack/`/`backups/`/`swaps/`/`undos/` into a real standalone `~/.vim`,
   nothing re-downloaded.
2. `GetGitBranchName()` (carried forward unchanged from the original
   file) called `fugitive#head()`, which current vim-fugitive removed
   years ago — throws `E117: Unknown function`. Fixed to use the current
   `FugitiveHead()` API.

Both fixes were applied to `dotfiles/.vimrc`, but verified only via
`vim -u dotfiles/.vimrc` directly — **not** by actually deploying it,
since `~/.vimrc` still points at the old `~/.dotfiles` file (`dots
dotfiles` still hasn't been run — `.zshrc` isn't ready to deploy yet).
So when you tested with plain `vim`, you were still hitting the old,
unfixed file — same error, looked like the fix hadn't worked. Given that
confusion plus everything else that had gone wrong getting here (had to
be told about `~/.vim`'s symlink, wrong export format from 1Password
earlier in this session, etc.), the call was: stop debugging this,
remove plugins entirely rather than keep chasing it.

`dotfiles/.vimrc` is back to zero third-party plugins — no minpac, no
`InitPlugins`/`Plugins*` commands, no `GetGitBranchName()`, default
colorscheme (no solarized), all plugin-dependent key mappings removed
(`<leader>cc`/`gd`/`t`/`ti`). What's left is pure built-in Vim: settings,
the five custom helper functions that don't need any plugin
(PrettyPrint's JSON branch, StripBOM, StripTrailingWhitespaces,
ToggleLimits, ToggleRelativeLineNumbers), autocommands, key mappings,
and the statusline (minus the branch-name segment). 740 lines -> 529.
`lib/dotfiles.sh`'s minpac-bootstrap step removed too. `~/.vim/pack`
(the installed plugin files) deleted from this Mac — nothing references
them anymore. Verified: `vim -u dotfiles/.vimrc` sources with zero
errors.

**If plugins are ever wanted again**, this section of `docs/planning.md`
has the full trimmed-list reasoning above to start from — don't
re-derive it from scratch, and this time verify against the actually
*deployed* `~/.vimrc`, not just the repo copy via `-u`.

**`~/.vimrc` is now actually live** (2026-09-19, same day) — manually
relinked `~/.vimrc` -> `dots/dotfiles/.vimrc` (not via `dots dotfiles`,
same reasoning as the earlier `.ssh/config` fix: doing the whole command
would also relink `.zshrc`, still not ready). Confirmed working in real
use, no colorscheme/branch-name in status line, everything else intact.
This is the second dotfile actually deployed for real, after
`.ssh/config`.

**`.zshrc` and everything it depends on are now live too** (2026-09-19,
same day) — manually relinked all six: `.zshrc`, `.aliases`,
`.functions`, `.exports`, `.p10k.zsh`, `.profile` (had to do all six
together, not just `.zshrc` — it sources the other five, so relinking
just one would have pulled the new `.zshrc` but the *old* aliases/
functions/exports/p10k config underneath it). Sanity-checked before
handoff: aliases/functions resolve correctly (`rm=trash`, `fcount()`
defined, etc.). One error surfaced in headless testing
(`gitstatus failed to initialize`, `can't change option: monitor`) —
traced to Powerlevel10k's gitstatusd needing job control, which isn't
available without a real controlling terminal (confirmed via `tty` ->
"not a tty" in this sandboxed tool) — not a bug in our config (grepped:
our only `setopt` line doesn't touch `monitor`). You're testing it live
now in an actual terminal to confirm.

Still not deployed: `Library/Application Support/Code/User/settings.json`
(VS Code settings). Everything else in `DOTFILE_NAMES` is now live.

### `macos/defaults.sh` populated and cleaned up (2026-09-19, continued)
You wrote real content into `macos/defaults.sh` yourself, pulled from the
old `~/.dotfiles` preference scripts — using that system's `execute
"<cmd>" "<description>"` / `print_in_purple "<section>"` helpers, which
don't exist in this codebase. Converted mechanically: `execute` ->
`macos_apply` (new helper at the top of the file, using this repo's
`log_success`/`log_error` instead of the old print_in_purple/spinner
setup), `print_in_purple "\n   X\n\n"` -> `log_step "X"`. All 129/129
and 15/15 calls converted, verified via grep (one `execute` was missed
by the first sed pass — it was indented inside an `if` block, the sed
anchor was `^execute `).

Real bug introduced and caught before it shipped: used `&>>"$LOG_FILE"`
in the new `macos_apply` helper — this project's own history (this same
file, "Platform quirks" above) already documented `&>>file` as invalid
bash syntax. Fixed to `>>file 2>&1`.

Three things fixed rather than mechanically translated, because they
conflicted with decisions already locked elsewhere:
- Removed the whole iTerm section — terminal decision is Ghostty, not
  iTerm2, and Ghostty doesn't use `defaults write` at all (plain text
  config file, a separate future dotfile, not a settings migration).
- Fixed two Dock `dockutil --add` entries: `iTerm.app` -> `Ghostty.app`,
  `VSCodium.app` -> `Visual Studio Code.app`.
- Consolidated 10 scattered inline `killall "X" &> /dev/null` calls
  (one per app section, old system's pattern) into the `RESTART_PROCESSES`
  array at the top — that array already existed in this file's own
  header documentation as the intended mechanism, but sat empty/unused.
  Now restarts everything once at the end instead of mid-script per app.

Also: removed a stale comment referencing a `safari.sh` file that was
never part of this repo, and flagged (not guessed at a replacement) a
`./close_system_preferences_panes.applescript` call pointing at a file
that doesn't exist here — that's new behavior to add deliberately, not
something to mechanically translate.

**Not done:** the actual settings content itself hasn't been reviewed —
only the mechanics of how it runs. Machine name "tycho" (UI & UX
section) matches this Mac's real hostname, not a placeholder. Still
worth a real read-through of what's actually being set before running
`dots macos` for real. `.zshrc` and the rest remain undeployed until decided.

Automated the bootstrap into `lib/dotfiles.sh`
(`_dotfiles_bootstrap_vim_plugins`, called at the end of `cmd_dotfiles`):
clones minpac into `~/.vim/pack/minpac/opt/minpac` if missing, then runs
`vim -c "PluginsSetup"`. **Known constraint discovered running this for
real:** Vim's plugin install needs a genuine interactive terminal (its
async job-based git clones need the real UI/event loop) — running it
through a non-PTY shell tool fails with "Error reading input, exiting."
This isn't a problem for the automation itself (`dots dotfiles` is
normally run by a human at a real terminal), just means it can't be
exercised from a piped/non-interactive shell. Bootstrapped for real on
this Mac (you ran it yourself at an actual terminal) — verified
end-to-end afterward: all 11 `start/` plugins + 2 `opt/` plugins present,
colorscheme/Commentary/NERDTreeToggle/fugitive/polyglot all confirmed
loading with zero errors via a headless `vim -es` check.

### Two real bugs found actually using it (2026-09-19, continued)

**`~/.vim` was still a symlink into the old `~/.dotfiles` repo.** Missed
this before running the live bootstrap: `~/.vim` -> `~/.dotfiles/src/
vim/vim` (the old system's directory-symlink approach, never removed).
So the minpac clone + all 12 plugins got installed *inside the old repo's
working tree*, exactly the anti-pattern the earlier `.vimrc` design
decision was meant to avoid. Fixed by moving `pack/`, `backups/`,
`swaps/`, `undos/` out to a real, standalone `~/.vim` (nothing
re-downloaded, `~/.dotfiles/src/vim/vim/` now just has its original
`snippets/`, harmless leftover from the old system). `~/.vim` is no
longer a symlink at all now, on this Mac. `lib/dotfiles.sh`'s
`VIM_RUNTIME_DIRS` `mkdir -p` step needed no code change — it was always
written assuming `~/.vim` would be real, this just makes that actually
true on this machine too.

**`fugitive#head()` doesn't exist in current vim-fugitive.** First real
usage (`vim` opening a file → statusline calls `GetGitBranchName()`)
threw `E117: Unknown function: fugitive#head`. Fugitive removed that
function years ago — its own source literally throws `"fugitive:
fugitive#repo().head(...) has been replaced by FugitiveHead(...)"` if
called via the old repo-object API path. `GetGitBranchName()` (carried
forward unchanged from the old vimrc) was calling the dead API. Fixed:
now calls `FugitiveHead()` (current public API, a global function, not
autoload-namespaced), and checks `exists("*FugitiveHead")` instead of
just `g:loaded_fugitive` so it degrades gracefully rather than erroring
again if fugitive's API ever moves. Verified: returns `[main]` inside a
real git repo (tested in `~/.dotfiles`), `[]` outside one, no errors.

## `dots` is now a real git repository (2026-09-19)

Root commit `d76465725aab` — 34 files, everything except what
`.gitignore` excludes (`config/backup.conf`, `config/auth.conf`,
`logs/`, private key material). One thing caught before it went in:
`docs/defaults_before.txt`, a 1.4MB/31k-line full `defaults read` dump
covering every app's preferences on this Mac — not something that
belongs in git history. Deleted, per your call, rather than gitignored.

`dots baseline`/`dots rollback` are real, functional commands for the
first time — ran `dots baseline` for real, correctly reported no changes
(the initial commit already captured `dotfiles/`).

Deliberately *not* done as part of this: pushing to GitHub
(`jaydub72/dots`). Also not done: setting up Tart for VM testing — `tart`
isn't installed on this Mac and no base VM image exists; both are a real
one-time investment (installing it, then `tart create --from-ipsw=latest`
actually downloads and runs a macOS installer), being treated as its own
task rather than folded into this one.

Housekeeping note for a future session: this file's chronological
ordering got slightly scrambled in a couple of places during a long,
fast-moving session (several `### ...continued` sections were appended
via text-anchored edits, and a couple landed earlier in the file than
their actual chronological position — e.g. the vim plugin
trim/bootstrap/bug-fix/removal saga isn't perfectly in the order it
happened). The content itself is accurate, just not perfectly ordered
top-to-bottom. Not urgent to fix, but worth a cleanup pass if it ever
causes real confusion.

## Pushed to GitHub — public, not private (2026-09-19)

Resolves the open question from the Review notes section above ("public
vs. private... no decision recorded"). Created private first
(`jaydub72/dots`, matching the target from Repo identity and location
above), pushed successfully — then caught a real conflict: the Quick
Start's curl+tar fresh-Mac bootstrap (README.md) only works against a
*public* repo. It exists specifically so a stock Mac doesn't need `git`
before Xcode CLT is installed (`git` itself triggers the CLT prompt,
which `dots all` is supposed to handle as a later, controlled step) — an
unauthenticated `curl` against a private repo's tarball just 403s,
reintroducing the exact chicken-and-egg problem curl+tar was designed to
avoid.

Decision: switched to public (`gh repo edit --visibility public`),
keeping the original zero-prerequisite bootstrap flow intact. Verified
working: `curl -sSI` against the real Quick Start URL now 302-redirects
to the tarball correctly.

Consciously accepted, not scrubbed: this repo now publicly exposes real
home network topology — Proxmox node IPs (192.168.1.197-199), several
`*.home.lan` hostnames (NAS, Plex, a recipe app, a seedbox, monitoring,
etc. — see `dotfiles/.ssh/config`), and this Mac's real computer name
("tycho", hardcoded in `macos/defaults.sh`'s "Set computer name" step).
None of it is directly exploitable (private IPs, LAN-only hostnames, no
credentials anywhere), and plenty of public dotfiles repos carry this
level of detail — but it's a real, deliberate tradeoff, not an oversight.
If this ever needs revisiting, `git log` has full history of what
changed and when.

## `tart` installed, added to Brewfile (2026-09-19)

Starting the Tart VM testing task. Installing `cirruslabs/cli/tart` hit
two real, currently-live upstream bugs — not anything in `dots`:

1. Both `tart.rb` and its `softnet.rb` dependency (in the
   `cirruslabs/homebrew-cli` tap) use deprecated Homebrew DSL
   (`depends_on :macos => :version`, hash-rocket form) that current
   Homebrew refuses to load at all ("Calling `depends_on :macos` with
   `depends_on macos:` is disabled"). Confirmed live on GitHub
   (`master` branch, not a stale local tap) — genuinely unfixed
   upstream as of this writing. Worked around by deleting the offending
   line from both locally cached formula files. This is **not**
   persistent — a fresh `brew tap cirruslabs/cli` on another machine
   (or after this tap updates) pulls the same broken files and hits the
   same failure until upstream actually fixes it.
2. Separately, this Homebrew version now requires `brew trust <tap>`
   before installing from an unfamiliar tap for the first time —
   `brew bundle` will fail on the `tart` line on a truly fresh machine
   until `brew trust cirruslabs/cli` has been run once, manually.

Both are documented inline in the Brewfile's Taps section so they're not
a surprise later. Added `brew "cirruslabs/cli/tart"` to the Brewfile per
explicit request, in its own section marked as a host-only testing tool
(not something every rebuilt Mac inherently needs — it's for testing
`dots` itself, see `docs/tart.md`). Verified: `tart --version` -> 2.32.1,
`brew bundle check` parses the updated Brewfile with no errors on the
new lines.

**Still open:** no base VM image created yet (`tart create
--from-ipsw=latest dots-base`) — that's the next real step, and it's
slow (downloads and runs a real macOS installer).

## First real `dots all` test run — long chase, small root cause (2026-09-19)

Built `dots-base`, ran `./bin/dots all` for real for the first time via
the curl+tar Quick Start inside it. Result: a multi-hour apparent hang
during `dots apps` (`brew bundle`) that took most of a session to
diagnose, chasing — in order — vscode entries, stdin/interactive
prompts, stale Homebrew lock files, disk space, VM-instance corruption,
a fresh `dots-base` rebuild, a network/MTU blackhole theory (wrongly
"confirmed" against the host — my error, corrected below), and finally
UTM as a second virtualization tool to compare against. Full blow-by-blow
not reproduced here; the two things worth keeping:

**Root cause, once found, was mundane:** `brew bundle` hit a normal,
expected `sudo` password prompt for the `microsoft-office` cask's
installer (`macOS`, via `/usr/sbin/installer`, genuinely needs root).
Nobody was watching the terminal at that exact moment, and with
`lib/apps.sh`'s output fully redirected to the log file (the earlier
"quiet the noise" fix), there was nothing else on screen to distinguish
"waiting on you" from "working quietly" — so it looked identical to a
genuine hang for hours. Confirmed in the log: `"Running installer for
microsoft-office with sudo (which may request your password)..."`
immediately followed by the actual stall point.

**Important: this does NOT explain Tart's stall specifically.** Real
mistake made and corrected mid-session: after UTM's sudo-prompt
explanation resolved things, I initially claimed this was *also* what
had been happening in Tart — but the evidence doesn't support that.
`ps aux` during the Tart stall never showed a `sudo`/`installer` process
waiting, only the `ruby brew.rb bundle` process itself, and a `sample`
stack trace showed *ruby's own* thread blocked in a low-level `read()`
call (`io_fread` → `rb_thread_io_blocking_call` → `read`), not a
separate process waiting on terminal input. Tart's repeated stall
(reproduced on a fresh `dots-base` rebuild too, ruling out
instance-specific corruption) remains **genuinely unexplained**. Not
pursued further since UTM works as an alternative — noted here so a
future session doesn't assume it's "just the same sudo thing" without
re-deriving this.

**Real bugs found and fixed from this run, unrelated to the VM mystery:**
- `macos/defaults.sh`'s VS Code dockutil line had an unquoted path with
  a space (`/Applications/Visual Studio Code.app/`) — `macos_apply`'s
  `eval` word-split it into three separate arguments, so `dockutil`
  received a stray `Studio` argument and failed with "does not seem to
  be a home directory or a dock plist." Fixed by quoting the path.
  Verified via the same `eval "set -- $cmd"` + arg-count trick used
  elsewhere in this doc's history.
- `ebullient/tap` (TTRPG) hit the same untrusted-tap gate as
  `cirruslabs/cli` did earlier, but was never resolved for it — hard-fails
  a fresh `dots apps` run with "Refusing to load formula ... from
  untrusted tap." Since its own comment already said "not currently
  planned for use," removed both `tap "ebullient/tap"` and
  `brew "ttrpg-convert-cli"` from the Brewfile entirely (your call, not
  documented-and-kept like cirruslabs) rather than requiring a
  `brew trust` step for something unused.
- `testing/` (the Tart/UTM shared-folder scratch space used for passing
  diagnostic files back and forth this session — `samples.txt`, log
  files) added to `.gitignore` — was showing up untracked, never meant
  to be committed.

**Still unresolved, real, and worth a decision later:**
- `microsoft-office`'s cask install itself fails consistently (both Tart
  and UTM, both times tried) — `/usr/sbin/installer` exits 1 with only
  `"installer: The install failed.."`, no more detail available from
  this log. Could be VM-specific (Office's installer may check for
  something a VM doesn't have) or a genuine installer issue independent
  of virtualization. Not investigated further yet.
- Tart's stall itself (see above) — unexplained, not blocking since UTM
  works, but a real open question if Tart is ever wanted again.

## `dots auth`/`dots backup`/`dots restore` now prompt to create their config (2026-09-19)

Same test run also surfaced that `auth`/`restore` just errored out with
"copy the .example and fill it in" for `config/auth.conf`/`config/
backup.conf` — correct (those are gitignored, genuinely don't exist on
a fresh machine) but not great UX for a from-scratch bootstrap. Now
`nas_load_config`/`_auth_load_config` prompt interactively for the
machine-specific values (1Password vault/item; NAS host/user/port/
share/`BACKUP_MAX_DELETE`) and write the real config file when it's
missing, instead of just failing. Empty input skips gracefully (matches
`run_step`'s existing SKIPPED convention); partial input is a real
error, won't write a half-filled config. See `lib/auth.sh`/`lib/nas.sh`.

## More real bugs found live testing `dots auth`/NAS reachability (2026-09-19)

Same session, continuing to actually run this on real hardware/VMs
surfaced a cluster of real, previously-invisible bugs — the value of
testing beats any amount of code review:

- **`_auth_check_1password` accepted zero accounts as success.**
  `op account list` exits 0 with empty output when nothing is actually
  configured — the check only looked at exit code, so it passed
  anyway, and the real problem only surfaced later, confusingly, at the
  SSH key restore step. Fixed to check the output is non-empty too.
- **Two more instances of the "redirect hides an interactive prompt"
  bug** (same class as the `microsoft-office` sudo prompt earlier):
  `op read` (SSH key restore) and `ssh-add --apple-use-keychain` both
  had stderr redirected to the log file, hiding a possible sign-in
  prompt. Fixed — third and likely final instance of this pattern,
  audited the rest of the codebase and found no more.
- **`pipefail` broke GitHub SSH verification.** `ssh -T git@github.com`
  always exits 1 even on genuine success (GitHub's "no shell access"
  design) — piping it into `grep` worked by hand, but under `bin/dots`'s
  `set -o pipefail`, the pipeline's exit status tracked ssh's nonzero
  code regardless of what grep matched. A real "successfully
  authenticated" was reported as a failure every time. Fixed by
  capturing output into a variable before grepping it, sidestepping
  pipefail entirely. Reproduced the bug standalone before and after the
  fix to confirm.
- **NAS reachability check discarded all diagnostic output.**
  `2>/dev/null` on the SSH probe meant every failure reason — auth,
  wrong port, host key mismatch — looked identical to a benign off-LAN
  skip. Changed to log instead of discard.
- **Real near-miss: host key auto-trust.** Once the discarded-output fix
  surfaced the actual error ("Host key verification failed" — a fresh
  machine's first-ever NAS connection, expected), the first fix attempt
  had `nas_is_reachable()` run `ssh-keyscan` and silently trust whatever
  key came back, no verification at all. That's a real security
  regression — it defeats host key checking's actual purpose (MITM
  protection) — caught immediately, not shipped-and-forgotten. Reverted
  same session. Correct fix: detect that specific failure and tell the
  user to connect manually once and verify the fingerprint themselves —
  same human-verified-trust pattern as 1Password sign-in, `gh auth
  login`, and sudo elsewhere in this codebase. Worth remembering: don't
  auto-accept trust decisions on the user's behalf, even for
  low-stakes-seeming infrastructure like a home NAS.

## Real near-miss: dots backup ran before dots restore on a fresh machine (2026-09-19)

The actual incident, not just a bug found: once the NAS host key was
manually trusted (per the fix above) and `nas_is_reachable()` started
reporting true, `dots backup` ran on this fresh VM — which had never
run `dots restore` — before restore had happened. Local `Documents` was
near-empty compared to what's actually on the NAS. `dots backup` is a
one-way push with `rsync --delete`: local is treated as truth, so this
started pruning real NAS data to match the near-empty local folder.

**`BACKUP_MAX_DELETE` caught it — the run aborted, not completed.** No
data was actually lost. But this was too close: a numeric backstop
catching a mistake after the fact isn't the same as the mistake being
structurally impossible, and depending on how many files it takes to
exceed the configured limit, a bounded amount of real deletion can
still happen before the abort fires.

**Structural fix, not just a bigger safety margin:** `dots restore` now
writes a marker file (`RESTORE_STATUS_FILE`, `logs/restore_status`) on
success. `dots backup` refuses to run *at all* if that marker doesn't
exist — not a warning, a hard stop — with a clear explanation and
pointer to run `dots restore` first. One legitimate exception: the very
first machine ever, seeding a genuinely empty NAS (this happened for
real once already — see "Scaffolding built" above, 20.86GB, zero
errors) — `dots backup --seed` exists for exactly that, explicit and
typed by hand, same pattern as the existing `--force` flag (which stays
separate — different risk, bypasses the delete-count limit specifically,
not the restore-first requirement).

Verified all paths (refuses without marker or `--seed`, proceeds with
either, marker only written on actual restore success not failure) in
isolated sandbox tests before touching real command dispatch — same
discipline as every other fix tonight, but especially warranted here
given what was actually at stake.

**Lesson for future sessions:** the existing `BACKUP_MAX_DELETE` comment
already said "the technical backstop for getting that order wrong, not
a substitute for it" — that was written in good faith but not actually
enforced anywhere until a real near-miss forced the issue. When a
comment describes a safety property, check whether the code actually
guarantees it or just hopes for it.
