# macOS SSH Setup Plan — fresh key, native Keychain, everywhere it needs to go

Generated 2026-09-04, revised same day after auditing the SSH config
already on this Mac. This is a runbook, not a script Claude ran for you —
every command below runs in **your own Terminal**, because passphrase
entry, Keychain unlock, and GitHub/Proxmox sign-in shouldn't happen
through an automated agent. Work through it top to bottom; each phase says
how to verify before you move on.

## Decisions this plan is built around

- **Agent:** native macOS `ssh-agent` + Keychain — *not* the 1Password SSH
  agent. Confirmed after the Phase 0 audit found the existing config was
  actually routing through 1Password's agent already (see below) —
  switching back to native was a deliberate re-confirmation, not an
  oversight.
- **Key scope:** one `ed25519` keypair (`id_ed25519`, keeping the
  existing filename), used for GitHub, all 3 Proxmox nodes, every VM/LXC,
  and Ansible. Simpler to manage, but it means this one key is your
  identity everywhere — see "Ongoing hygiene" at the bottom for what that
  implies.
- **1Password's role:** an encrypted **backup copy** of the key, plus your
  secrets store for things like the Ansible vault password and Proxmox API
  tokens. It is not in the authentication path for day-to-day SSH.
- **Old key:** inventoried and backed up locally first, retired from each
  service only after the new key is verified working everywhere (Phase 10)
  — you're never at risk of locking yourself out mid-migration.

## Findings from the Phase 0 audit of your actual ~/.ssh

You ran the Phase 0 commands and pasted the output. Here's what that
turned up, since it changed a few things in this plan from the first
draft:

- **The live config was already using 1Password's SSH agent, not
  Keychain.** A trailing `Host *` block set
  `IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"`.
  Because ssh_config uses first-obtained-value-per-keyword and that was
  the only place `IdentityAgent` was set, it silently won over the
  `UseKeychain`/`AddKeysToAgent` lines sitting above it — which is also
  why `ssh-add -l` reported no identities (it was asking the native agent,
  which really was empty, while real connections went through 1Password).
  This is almost certainly a leftover from toggling **1Password → Settings
  → Developer → "Use the SSH Agent"** on at some point.
  **Action for Phase 3: make sure that toggle is off** before wiring in
  the new config, or 1Password may re-add the same block later.
- **Two separate `Host *` blocks, a duplicated `Host monitor` block, and a
  `HostNAME` typo** (harmless — ssh_config keywords are case-insensitive —
  but cleaned up anyway). All fixed in the rebuilt `.ssh/config` already
  written into this repo.
- **`ServerAliveInterval` was 5** (pings every 5 seconds) — raised to 30
  in the rebuilt config; 5 wasn't wrong, just needlessly chatty.
- **Your homelab is a 3-node Proxmox cluster** — `donnager`
  (192.168.1.199), `rocinate` (192.168.1.198), and `razorback` (IP not
  yet known — fill in `<razorback-ip-or-hostname>` in `.ssh/config`
  yourself). All of the other hosts in your config (`plex`, `seedbox`,
  `monitor`, `photo`, `automate`, `dev_vm`, `nas`, `ansible`, `prism`) are
  VMs/LXCs running on that cluster, each with its own routable LAN IP —
  **no `ProxyJump` needed anywhere**, they're already directly reachable.
- **`gh auth status`** shows you're signed in over HTTPS with scopes
  `gist, read:org, repo, workflow` — missing `admin:public_key` and
  `admin:ssh_signing_key`, which Phase 4 needs. `gh auth refresh` handles
  that, already in the steps below.
- **`~/.ssh/1Password/config` and `~/.ssh/agent/` — both explained, both
  1Password's SSH-agent scaffolding.** `~/.ssh/1Password/config` is a file
  1Password auto-generates and manages itself the moment its SSH agent
  feature is turned on (its header literally says "automatically generated
  and managed by 1Password... any manual edits will be lost"). It's
  currently just `Match all` with nothing under it — inert, and your main
  config never had an `Include ~/.ssh/1Password/config` line pulling it
  in, so it wasn't actively doing anything beyond existing. `~/.ssh/agent/`
  holds a single live Unix socket file — sockets hold no key material by
  themselves, they're just an IPC endpoint, almost certainly created by
  the same 1Password SSH-agent feature. **Confirmed 2026-09-06: "Use the
  SSH Agent" is now off in 1Password → Settings → Developer.** Safe to
  delete `~/.ssh/1Password/` and `~/.ssh/agent/` whenever convenient;
  nothing recreates them now.
- **1Password CLI confirmed signed in** — `op account list` shows one
  account, `my.1password.com` / `jason@worthen.org`. Phase 6 is good to go
  whenever you get there; nothing else outstanding from Phase 0.

## Course correction — two bugs found while executing (2026-09-05)

Running Phases 2-4 turned up two real bugs, both now fixed in the repo's
`.ssh/config` and reflected throughout this doc:

1. **Key filename simplified on purpose.** The `_jason` suffix was the
   *old* key's naming convention; the new key was deliberately generated
   as the plain default `~/.ssh/id_ed25519` instead. This plan's earlier
   drafts assumed the old naming would carry over and referenced
   `id_ed25519_jason` throughout — that assumption was wrong, not the
   execution. Confirmed loaded correctly via Keychain/ssh-agent
   (`ssh-add -l`: `jason@tycho 2026-09`) and verified against GitHub
   (`ssh -T git@github.com` → "Hi JayDub72! ... successfully
   authenticated"). Every reference below now uses `~/.ssh/id_ed25519` /
   `id_ed25519.pub`.
2. **Wrong SSH user on the `github.com` block.** It had `User JayDub72`
   (a GitHub *account* name) instead of `User git` — GitHub's SSH login is
   always the literal user `git`, regardless of whose account it is.
   Fixed.

Also carried forward from a live edit on the Mac: the VM/LXC section now
uses `.home.lan` DNS names instead of raw IPs, plus a new `mealie` host
alongside `prism` (both point at the recipe-app host). `nas` and
`ansible` are currently absent from the host list — re-add them to
`.ssh/config` if that wasn't intentional.

## What's already done in this repo

Three edits made directly in `dots` so far (nothing on your actual Mac
yet — no keys generated, nothing touched in Keychain, GitHub, or Proxmox):

1. **`.ssh/config`** (rebuilt) — consolidated from the real config found
   in Phase 0: single `Host *` block, native-Keychain settings, the
   1Password `IdentityAgent` override removed, duplicates cleaned up, all
   3 Proxmox nodes and your existing VM/LXC hosts wired in, plus a
   `github.com` block. Only `<razorback-ip-or-hostname>` still needs
   filling in.
2. **`install.sh`** — added `".ssh/config"` to the `DOTFILE_NAMES` array,
   so the next time you run `install.sh` it symlinks `~/.ssh/config` from
   this repo the same way it already does `.zshrc`, backing up anything
   already at that path first (install.sh's own safety net).
3. **`.gitignore_global`** — added a block so `id_rsa`, `id_ed25519*`,
   `*.pem`, etc. can never be accidentally committed to this repo now that
   it contains an `.ssh/` directory. Only `.ssh/config` and
   `id_ed25519.pub` are ever safe to have in git; the private key
   never leaves your Mac.

Review these with `git diff` (if this folder is a git repo yet — it
doesn't currently have a `.git` here) and commit whenever you're happy
with them.

---

## Phase 0 — Inventory (done)

Already run — see "Findings" above. Still needed before Phase 1: the two
outstanding checks listed there (`~/.ssh/1Password`, `~/.ssh/agent`, and
`op account list`).

## Phase 1 — Back up and retire the old key

```sh
mkdir -p ~/.ssh_backup/$(date +%Y%m%d)
mv ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub ~/.ssh_backup/$(date +%Y%m%d)/ 2>/dev/null
cp ~/.ssh/config ~/.ssh_backup/$(date +%Y%m%d)/config.old 2>/dev/null
mv ~/.ssh/1Password ~/.ssh_backup/$(date +%Y%m%d)/1Password 2>/dev/null
mv ~/.ssh/agent ~/.ssh_backup/$(date +%Y%m%d)/agent 2>/dev/null
ssh-add -D
```

Leave `~/.ssh/known_hosts` alone (just host fingerprints). This doesn't
revoke the old public key from GitHub or any Proxmox/VM host yet — that
happens in Phase 10, once the new key is verified working everywhere.

The `1Password/` and `agent/` moves are just tidying up 1Password's old
SSH-agent scaffolding (see Findings above) — nothing you need from them
going forward, but moving rather than deleting keeps this fully
reversible.

## Phase 2 — Turn off 1Password's SSH agent, generate the new key

In the 1Password app: **Settings → Developer → turn OFF "Use the SSH
Agent."** (Leave "Integrate with 1Password CLI" on if it's enabled — that's
unrelated, just lets `op` commands work.)

```sh
scutil --get ComputerName   # sanity-check what this returns first
ssh-keygen -t ed25519 -C "jason@$(scutil --get ComputerName) $(date +%Y-%m)" -f ~/.ssh/id_ed25519
```

- `ed25519` is the modern default: smaller, faster, no known weaknesses.
- Enter a real, long passphrase when prompted — the only time you'll type
  it by hand. Since this key reaches GitHub and your entire homelab, don't
  shortcut it just because Keychain will remember it after today.
- (Originally planned to reuse the `id_ed25519` filename, but the
  `-f` custom name didn't take at the `ssh-keygen` prompt and it saved to
  the default `~/.ssh/id_ed25519` instead. Rather than rename an
  already-loaded, already-Keychain'd key, `.ssh/config` was updated to
  point at the real path — see "Course correction" below.)

## Phase 3 — Wire it into Keychain + ssh-agent, drop in the config

**Known gotcha, hit live during this setup:** this Brewfile installs
`brew "openssh"`, and Homebrew's build sits ahead of `/usr/bin` in `PATH`
(via the Homebrew shellenv in `.zprofile`). Vanilla OpenSSH's `ssh-add`
has no `--apple-use-keychain` flag, and — more importantly — vanilla
`ssh` doesn't honor `UseKeychain` in the config at all (it's an
Apple-only patch; `IgnoreUnknown UseKeychain` just silences the error
without adding the behavior). If Homebrew's `ssh`/`ssh-add` are what's
actually resolving, Keychain integration silently does nothing — you'd
get a passphrase prompt on every connection, defeating the point. Check
and fix before continuing:

```sh
which -a ssh-add
which -a ssh
brew unlink openssh
hash -r
which -a ssh-add     # should now show /usr/bin/ssh-add first
which -a ssh          # should now show /usr/bin/ssh first
```

(`brew unlink` keeps `openssh` installed, just stops it from shadowing
the system binaries — relink with `brew link openssh` later if you ever
need a feature only in the newer build.)

```sh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

This stores the passphrase in your login Keychain and loads the key into
macOS's built-in `ssh-agent` (already running via launchd — no
`eval $(ssh-agent -s)` needed). After a reboot or login, the first `ssh`
command silently unlocks it from Keychain instead of prompting.

```sh
cd ~/Documents/github/dots
vim .ssh/config        # fill in <razorback-ip-or-hostname>
./install.sh --skip-brew --skip-xcode --skip-defaults
```

That symlinks `.ssh/config` into `~/.ssh/config`, backing up anything
already there to `~/.dotfiles_backup/<timestamp>/` automatically.

Verify:

```sh
ssh-add -l          # should list exactly one ed25519 key
```

If 1Password re-adds its `IdentityAgent` block on its own after this,
double check the "Use the SSH Agent" toggle actually saved as off.

## Phase 4 — GitHub

```sh
gh auth status
gh auth refresh -h github.com -s admin:public_key
gh ssh-key add ~/.ssh/id_ed25519.pub -t "MacBook Pro (auth) - $(date +%Y-%m)"
```

Verify:

```sh
ssh -T git@github.com
# -> "Hi <you>! You've successfully authenticated..."
```

**Optional — SSH commit signing** (shows commits as "Verified" on GitHub
using the same key, no GPG needed):

```sh
gh auth refresh -h github.com -s admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519.pub -t "MacBook Pro (signing) - $(date +%Y-%m)" --type signing

git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
printf '%s namespaces="git" %s\n' "$(git config --global user.email)" "$(cat ~/.ssh/id_ed25519.pub)" > ~/.ssh/allowed_signers
```

Not required: `gh auth status` currently shows the HTTPS protocol for
`gh`'s own git operations. That's independent of this SSH setup — only
switch it with `gh config set git_protocol ssh` if you actually want
`gh repo clone` etc. to use SSH too.

## Phase 5 — Visual Studio Code

Nothing extra to configure. VS Code's Source Control panel and the GitHub
Pull Requests extension both shell out to your system `git`, which shells
out to your system `ssh` — both automatically pick up the Keychain-backed
agent because macOS exposes `SSH_AUTH_SOCK` session-wide, not just inside
Terminal.

- Open a repo cloned via `git@github.com:...` and fetch from the Source
  Control panel — should just work, no prompt.
- If you use the **Remote-SSH** extension against any of `donnager`,
  `rocinate`, `razorback`, or the VM/LXC hosts, it reads the same
  `~/.ssh/config` — those `Host` entries show up in Remote-SSH's host
  picker automatically.

## Phase 6 — 1Password / 1Password CLI (backup + secrets, not the agent)

First, confirm the CLI is actually signed in (`op account list` — see the
outstanding item in Findings above).

**Back up the new key into 1Password** (desktop-app-only — the CLI can
*generate* a brand-new key but can't *import* an existing one):

1Password app → **New Item** → **SSH Key** → **Add Private Key** →
**Import a Key File** → select `~/.ssh/id_ed25519` → enter its
passphrase once → save into a vault (e.g. a dedicated **Infra** vault),
titled something like "MacBook Pro SSH key — GitHub + Homelab."

**Use `op` for secrets scripts need, without writing them to disk**, e.g.
the Ansible vault password:

```sh
op item create --category password --title "Ansible Vault Password" --vault Infra
```

```sh
ANSIBLE_VAULT_PASSWORD_FILE=<(op read "op://Infra/Ansible Vault Password/password") \
  ansible-playbook site.yml
```

Same pattern for a Proxmox API token, a registry password, etc. —
`op read "op://<vault>/<item>/<field>"` pulls it only into that one
process's environment.

## Phase 7 — Ansible

```sh
brew install ansible   # not currently in this repo's Brewfile — add it there if you want it tracked
```

Because the key lives in `ssh-agent` via Keychain, Ansible needs **no**
extra SSH configuration — it uses whatever `ssh` on your Mac uses. No
`ansible_ssh_private_key_file` needed anywhere.

```ini
[proxmox]
donnager  ansible_host=192.168.1.199
rocinate  ansible_host=192.168.1.198
razorback ansible_host=<razorback-ip-or-hostname>

[homelab]
plex     ansible_host=192.168.1.200
seedbox  ansible_host=192.168.10.102
monitor  ansible_host=monitor.home.lan
photo    ansible_host=192.168.1.171
automate ansible_host=automate.home.lan
dev_vm   ansible_host=192.168.10.147
nas      ansible_host=192.168.1.210
prism    ansible_host=prism.home.lan

[homelab:vars]
ansible_user=jason
```

(All of these already have `Host` aliases in `.ssh/config`, so Ansible
picks up the right key/user automatically even without `ansible_host` —
listed explicitly here just for clarity.) Vault password comes from
`op read` as shown in Phase 6, so no plaintext vault password file sits
on disk.

## Phase 8 — Proxmox cluster (3 nodes)

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub jason@192.168.1.199   # donnager
ssh-copy-id -i ~/.ssh/id_ed25519.pub jason@192.168.1.198   # rocinate
ssh-copy-id -i ~/.ssh/id_ed25519.pub jason@<razorback-ip>  # razorback
```

If password auth is currently disabled on a node and only the *old* key
still works there, either temporarily re-enable password auth, or use
that node's Proxmox web console noVNC shell to paste the new public key
into `~/.ssh/authorized_keys` by hand, then re-disable password auth once
verified.

Proxmox's own inter-node cluster trust (in `/etc/pve`) is separate
infrastructure from your personal login key — this doesn't touch that.

Verify (using the aliases already in `.ssh/config`):

```sh
ssh donnager
ssh rocinate
ssh razorback
```

None should prompt for a password.

*Optional, separate hardening step:* if you SSH in as `root` on any node
today, consider a dedicated sudo-capable admin user for daily use,
reserving root login for emergencies. Bigger change than this plan
covers — flagging it, not doing it here.

## Phase 9 — VMs & LXCs

**New ones going forward** — bake the key in at creation:

```sh
# LXC, from a Proxmox node itself:
pct create <vmid> <template> ... --ssh-public-keys ~/.ssh/id_ed25519.pub

# VM via cloud-init, before first boot:
qm set <vmid> --sshkeys ~/.ssh/id_ed25519.pub
```

Even better: bake it into whatever base template/image you clone from, or
set it datacenter-wide under **Datacenter → Options** in the Proxmox GUI,
so every future clone has it automatically.

**Your existing hosts** (`plex`, `seedbox`, `monitor`, `photo`,
`automate`, `dev_vm`, `nas`, `prism`) — retrofit once, in bulk, rather
than by hand on each. If Ansible can already reach them (old key or
password auth still enabled):

```sh
ansible homelab -m ansible.posix.authorized_key \
  -a "user=jason state=present key=\"{{ lookup('file', '~/.ssh/id_ed25519.pub') }}\""
```

For any that are LXCs you can also push it directly from the Proxmox node
with no SSH involved at all:

```sh
pct exec <vmid> -- bash -c 'mkdir -p ~/.ssh && echo "<paste pubkey>" >> ~/.ssh/authorized_keys'
```

Don't remove the old key from any host until Phase 10 confirms the new
one works everywhere.

## Phase 10 — Verify everything, then retire the old key

| System | Check |
|---|---|
| GitHub | `ssh -T git@github.com` → "Hi \<you\>! You've successfully authenticated" |
| VS Code | Open a repo cloned via SSH, fetch/pull from the Source Control panel |
| Proxmox | `ssh donnager`, `ssh rocinate`, `ssh razorback` → no password prompts |
| Ansible | `ansible all -m ping` → every host `SUCCESS` |
| A sample VM/LXC | e.g. `ssh plex` → no password prompt |
| Keychain | After a reboot/re-login: `ssh -T git@github.com` → still no passphrase prompt |

Once every row passes, retire the old key:

- **GitHub:** Settings → SSH and GPG keys → delete the old entry (or
  `gh ssh-key delete <id>`).
- **Proxmox/VMs/LXCs:** remove the old public key line from each
  `authorized_keys` — the same Ansible play from Phase 9 with
  `state=absent` and the *old* pubkey is the fastest way to do it in bulk.
- Your `~/.ssh_backup/<date>/` folder from Phase 1 can stay as a cold
  fallback for a couple of weeks, then be deleted — or kept as an
  encrypted note in 1Password if you want a permanent record of what the
  retired key was.

---

## Ongoing hygiene

- This key has no expiry by design, like most personal SSH keys — but
  rotate it (repeat this whole plan) if the laptop is ever lost or
  stolen, if the passphrase may have leaked, or on whatever cadence you're
  comfortable with (yearly is common for a key with this much reach).
- Because it's **one key for GitHub and your entire 3-node homelab**, the
  realistic risk isn't the key file itself — it's someone getting hold of
  the laptop while both Keychain and FileVault are unlocked. Keep
  auto-lock short and FileVault on (should already be macOS's default).
- Never let `id_ed25519` (no `.pub` = private key) get committed to
  `dots` — the `.gitignore_global` update from this plan guards against
  it, but it's still worth a glance at `git status` before any commit that
  touches `.ssh/`.
- If you ever want tighter blast radius later (a compromised GitHub key
  can't touch your homelab, and vice versa), the split is: repeat Phase 2
  with a second `-f ~/.ssh/id_ed25519_homelab`, give it its own
  `IdentityFile` line in the relevant `Host` blocks in `.ssh/config`, and
  register/authorize it the same way per system.
