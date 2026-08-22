# AGENTS.md

Guide for future AI agents (and humans) making changes to this dotfiles repo.

## What this repo is

A [chezmoi](https://www.chezmoi.io/) **source tree** for a macOS machine.
There is no separate "build" step — the repo *is* the chezmoi source state.
After cloning, `chezmoi init` reads it directly.

## Layout

```
.
├── .chezmoi.toml.tmpl                       # init-time config (prompt for profile)
├── .chezmoiignore                           # source files NOT to be applied as targets
├── dot_Brewfile.tmpl                        # → ~/.Brewfile (templated per profile)
├── dot_gitconfig                            # → ~/.gitconfig
├── dot_gitconfig-work                       # → ~/.gitconfig-work
├── dot_gitignore                            # → ~/.gitignore
├── dot_gitattributes                        # → ~/.gitattributes
├── dot_config/
│   ├── fish/
│   │   ├── config.fish                      # → ~/.config/fish/config.fish
│   │   └── functions/
│   │       └── fish_set_custom_paths.fish
│   └── ghostty/config                       # → ~/.config/ghostty/config
├── private_dot_ssh/config                   # → ~/.ssh/config (dir gets 0700)
├── private_Library/LaunchAgents/            # → ~/Library/LaunchAgents/ (~/Library kept 0700)
│   └── com.yoannchaudet.ssh-auth-sock.plist.tmpl  # publishes SSH_AUTH_SOCK to launchd at login
├── dot_commands/                            # → ~/.commands/  (on PATH)
│   ├── edit_dotfiles                        # executable bit preserved from source
│   └── ...
├── run_once_before_10-install-brew.sh.tmpl  # installs Homebrew (once per machine)
├── run_onchange_after_20-brew-bundle.sh.tmpl# `brew bundle --global` (reruns on Brewfile change)
├── run_once_after_30-make-fish-default.sh.tmpl
├── run_once_after_40-install-fisher.sh.tmpl
├── run_onchange_after_41-install-tide.sh.tmpl
├── run_once_after_42-dracula-theme.sh.tmpl
├── run_once_after_50-install-monoki-font.sh.tmpl
├── run_once_after_60-git-signing-setup.sh.tmpl
├── run_onchange_after_62-load-ssh-auth-sock-agent.sh.tmpl # (re)loads the SSH_AUTH_SOCK LaunchAgent
└── run_once_after_70-install-rust.sh.tmpl
```

## chezmoi filename conventions used here

| Prefix in source | Effect on the target |
| --- | --- |
| `dot_`        | Leading `.` in the target name (e.g. `dot_gitconfig` → `~/.gitconfig`) |
| `private_`    | Target gets `0600` / `0700` permissions |
| `executable_` | Target gets the executable bit (files only; **not valid on directories**) |
| `run_once_`   | Script run **once per machine**, tracked by source hash |
| `run_onchange_` | Script reruns whenever its rendered content changes |
| `before_` / `after_` | Run before / after file changes are applied in the same run |
| `.tmpl`       | File is rendered as a Go template before being written / executed |

Numbers like `10-`, `20-` are purely for ordering (alphabetical sort within a
`before_` / `after_` bucket).

## Templating data

Available data inside `.tmpl` files:

- `.profile` — `"work"` or `"personal"` (set once at `chezmoi init` via
  `promptChoiceOnce` in `.chezmoi.toml.tmpl`, persisted to
  `~/.config/chezmoi/chezmoi.toml`)
- `.hostname` — captured at init time
- Anything chezmoi exposes under `.chezmoi.*` (os, arch, sourceDir, ...)

The work/personal switch is purely a templating concern. There is no second
config file. To see what would be installed on the other profile:

```sh
chezmoi execute-template < dot_Brewfile.tmpl   # uses current profile
# Or test by hand with a sandbox config:
echo '[data]
profile = "work"' > /tmp/cz.toml
chezmoi --config=/tmp/cz.toml execute-template < dot_Brewfile.tmpl
```

## Common change recipes

### Add a brew package

Edit `dot_Brewfile.tmpl`. Pick the right section:

- **Shared** — installed on both work and personal machines (default).
- Inside `{{ if eq .profile "work" -}}` — work-only.
- Inside `{{ if eq .profile "personal" -}}` — personal-only.

Within each profile section, entries are grouped under themed comment
headers (e.g. `# Shell & terminal`, `# Git / GitHub`, `# AI tooling`). Add
new entries to the most appropriate existing group, or introduce a new
themed header if none fits. Keep related `brew` and `cask` entries together
within the same theme rather than splitting by type.

Before adding an entry, verify whether the package is a formula or a cask
so you use the correct `brew "..."` vs `cask "..."` directive. For example:

```sh
brew info --json=v2 <name> | jq -r 'if .formulae|length>0 then "formula" elif .casks|length>0 then "cask" else "unknown" end'
```

Then:

```sh
chezmoi apply        # re-renders ~/.Brewfile and reruns brew bundle
```

### Add a new managed dotfile

Drop the file into the repo with a `dot_` (and `private_` / `executable_` as
needed) prefix at the right nesting. Example:

```
dot_config/foo/bar.toml         →  ~/.config/foo/bar.toml
```

If you want it templated, append `.tmpl` and use `{{ }}` expressions inside.

### Add a setup hook

Create `run_once_after_NN-thing.sh.tmpl` (use `run_onchange_` if it should
rerun when its contents change). Make it idempotent — chezmoi tracks the
hash, not "did this thing happen on the system".

### Change profile on a machine

```sh
chezmoi edit-config        # toggle profile = ...
chezmoi apply
```

## Git commit signing (SSH key via Bitwarden agent)

Commits are signed with an **SSH** key (`gpg.format = ssh`), not GPG.
`user.signingkey` points at `~/.ssh/id_ed25519.pub`, but **the matching
private key is not on disk** — it lives in the **Bitwarden Desktop SSH
agent** (`~/.bitwarden-ssh-agent.sock`). `git`/`ssh-keygen -Y sign` reaches
that key through `SSH_AUTH_SOCK`.

Two things must set `SSH_AUTH_SOCK` so signing works everywhere:

- **Interactive fish shells** — `dot_config/fish/config.fish` exports it.
- **Everything else (GUI editors, GitHub Desktop, Copilot, ...)** — the
  `private_Library/LaunchAgents/com.yoannchaudet.ssh-auth-sock.plist`
  LaunchAgent runs `launchctl setenv SSH_AUTH_SOCK ...` at login, so apps
  launched by launchd inherit it. `run_onchange_after_62-...` (re)loads it.

If an app reports *"private key for `~/.ssh/id_ed25519.pub` is
unavailable"*: Bitwarden must be running and unlocked, and the app must have
been (re)launched after the LaunchAgent published the socket. Verify with
`launchctl getenv SSH_AUTH_SOCK` and `ssh-add -L`.

## Local validation

Before committing changes, always run:

```sh
chezmoi diff               # what would change on this machine
chezmoi apply --dry-run    # exercise template rendering for all targets
```

For a fully isolated test (does not touch `$HOME`), point chezmoi at a
sandbox directory:

```sh
SANDBOX=$(mktemp -d)
CFG=$(mktemp -d)/chezmoi.toml
cat > "$CFG" <<EOF
[data]
profile = "personal"
EOF
chezmoi --source=. --destination="$SANDBOX" --config="$CFG" --no-tty diff
```

(Note: `run_*` scripts still use the real `$HOME` when they execute, so the
sandbox is most useful for inspecting *file* targets.)

## History

Migrated from [dotbot](https://github.com/anishathalye/dotbot) +
`dotbot-brew` (git submodules) to chezmoi on branch `chezmoi-migration`.
The previous setup used three YAML manifests (`bootstrap.conf.yaml`,
`install.conf.yaml`, `install-personal.conf.yaml`); they are now collapsed
into the single `dot_Brewfile.tmpl` plus the `run_*` scripts above.
