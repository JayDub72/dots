# Testing `dots` with Tart

This is a **validation-only** workflow — it exists to let you watch a real macOS
Setup-Assistant-to-configured-desktop run of `./bin/dots all` in a disposable VM
before trusting it on real hardware. It is not part of how you'll actually use
the dotfiles day to day, and nothing here should end up wired into CI or any
other automated pipeline.

Tart runs macOS guests using Apple's own Virtualization framework — the same
technology UTM uses — so a VM is architecturally identical (arm64) to your
real Mac, just faster to reset between test runs than a full IPSW reinstall.

## Prerequisites

- An Apple Silicon Mac running macOS 13 (Ventura) or later (confirmed: this
  machine qualifies).
- Comfortably 40–60 GB of free disk space: the base image is roughly 25 GB,
  and each clone you make is a copy-on-write APFS clone (near-instant, cheap
  in space, but not free — deleting clones you're done with keeps this in
  check).
- Time for one long, one-time download (~25 GB) to create the base image.

## 1. Install Tart

```sh
brew install cirruslabs/cli/tart
```

Verify it installed:

```sh
tart --version
```

## 2. Create your base VM from the latest IPSW

This downloads the actual macOS installer from Apple and builds a VM disk
image from it — the closest thing to "a brand-new Mac" you can get in a VM.

```sh
tart create --from-ipsw=latest dots-base
```

- This is the ~25 GB download; expect it to take a while depending on your
  connection. You only do this once (or again later if you want to test
  against a newer macOS release).
- If you want a specific macOS version instead of whatever's newest, check
  `tart create --help` for how to pass an explicit IPSW URL/path instead of
  `latest`.

## 3. First boot: complete Setup Assistant once

```sh
tart run dots-base
```

A native window opens showing the VM's display — full keyboard/mouse support,
just like any other Mac. Click through Setup Assistant (region, Apple ID —
you can skip sign-in, create a local admin account, etc.) exactly like you
would on a real new Mac. This is the one manual, "in-character" step in this
whole workflow, and you only ever do it **once**, on `dots-base` — every
clone you make afterward inherits this already-completed state.

Once you're sitting at a working desktop, shut the VM down cleanly from
inside the guest (Apple menu → Shut Down), or run `tart stop dots-base`
from your host.

**Do not run your bootstrap script against `dots-base` itself.** Treat it
as the pristine, reusable source — every actual test happens on a clone.

## 4. Your actual test loop

Each cycle: clone the pristine base, run it, watch/verify, throw the clone
away.

```sh
# 1. Make a disposable copy of the clean base (near-instant, APFS copy-on-write)
tart clone dots-base test1

# 2. Boot it with your dots repo mounted in, GUI window included by default
tart run test1 --dir=dots:~/dots
```

Inside the VM's window, open Terminal.app. Your repo is mounted at:

```
/Volumes/My Shared Files/dots
```

Run the bootstrap from there, e.g.:

```sh
cd "/Volumes/My Shared Files/dots"
./bin/dots all
```

You'll need to type the VM's own admin password when it prompts for `sudo`
(the one you set during Setup Assistant in step 3) — this is the guest's
password, not your real Mac's.

Because the repo is a live mount rather than a copy, you can edit
`bin/dots`, `lib/`, or any dotfile back on your real Mac and just re-run it
from the VM's Terminal without re-copying or re-cloning anything — only
re-clone when you want to test against a truly clean, never-touched system
again.

## 5. Validate

With the GUI window open, check the things a snapshot/log can't tell you:

- Finder/Dock/System Settings reflect the `defaults write` changes
  (`./bin/dots macos`'s step, `macos/defaults.sh`)
- `~/.zshrc`, `~/.aliases`, etc. are correctly symlinked (open Terminal,
  `ls -la ~`)
- A new shell picks up your prompt, aliases, and PATH correctly
- Homebrew casks/formulae from your `Brewfile` actually installed and appear
  in `/Applications` or on `PATH`

## 6. Tear down and reset

```sh
tart stop test1        # if it's still running
tart delete test1       # discard the clone entirely
```

Next test cycle, just re-clone from `dots-base` again (step 4) — you're
back to a guaranteed-clean starting point in seconds, no reinstall.

## Reference: commands you'll actually use

| Command | Purpose |
|---|---|
| `tart list` | List all VMs (base images and clones) you currently have |
| `tart clone <src> <new>` | Create a copy-on-write clone of an existing VM |
| `tart run <name>` | Boot a VM with a GUI window (default) |
| `tart run <name> --dir=<tag>:<host-path>[:ro]` | Boot with a host folder mounted at `/Volumes/My Shared Files/<tag>` in the guest |
| `tart stop <name>` | Shut down a running VM from the host |
| `tart delete <name>` | Permanently remove a VM |
| `tart ip <name>` | Get a running VM's IP address (for SSH, if you ever want it) |
| `ssh admin@$(tart ip <name>)` | SSH into a running VM instead of using the GUI |

## Known caveats

- **Copy/paste between host and guest isn't guaranteed.** Tart's clipboard
  sharing depends on a "Guest Agent" that ships in Cirrus Labs' own pre-built
  images — a VM you build yourself from a raw IPSW may not have it. Don't
  plan around pasting into the VM; use the `--dir` mount (step 4) to move
  files/scripts in instead.
- **`--no-graphics` is the opposite of what you want** — don't pass it. The
  GUI window is Tart's default behavior; that flag is for headless CI use.
- If disk space becomes a concern, `tart list` shows what you have lying
  around, and `tart delete <name>` reclaims it — clones you're done
  validating don't need to stick around.
