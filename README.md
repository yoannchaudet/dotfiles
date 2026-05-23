# My very own `dotfiles`

macOS setup managed by [chezmoi](https://www.chezmoi.io/). One repo, one
command, two flavors (work / personal) selected by an interactive prompt at
first init.

## Platforms

- macOS (sole target).

## Setup on a fresh machine

1. **Install Homebrew** — <https://brew.sh>.

2. **Install `chezmoi`**:

    ```sh
    brew install chezmoi
    ```

3. **Create your SSH key** (used for both Git signing and GitHub auth):

    ```sh
    ssh-keygen -t ed25519 -C "<comment>"
    cat ~/.ssh/id_ed25519.pub | pbcopy
    ```

    Upload to your GitHub account twice — as an *SSH key* **and** as a
    *signing key*.

4. **Bootstrap with chezmoi**:

    ```sh
    chezmoi init --apply git@github.com:yoannchaudet/dotfiles.git
    ```

    You will be asked once:

    > Is this a work or personal machine? \[work / personal\]

    The answer is saved to `~/.config/chezmoi/chezmoi.toml` and drives which
    Homebrew packages are installed, among other things.

    Everything else (symlinks, Brewfile install, Fish + Tide + Dracula theme,
    Mononoki font, Git signing setup, Rust) is taken care of by `chezmoi
    apply`.

5. Sign out and back in for shell / theme changes to fully apply. 🤘

## Day-to-day commands

| Command | What it does |
| --- | --- |
| `chezmoi edit <target>`     | Edit a managed file via the source (auto-syncs) |
| `chezmoi diff`              | Preview pending changes |
| `chezmoi apply`             | Apply pending changes (run scripts as needed) |
| `chezmoi update`            | `git pull` the dotfiles repo, then `apply` |
| `chezmoi cd`                | Drop into the source tree (the repo) |
| `chezmoi edit-config`       | Edit `~/.config/chezmoi/chezmoi.toml` (e.g. switch profile) |

## Switching profile later

```sh
chezmoi edit-config         # change profile = "..."
chezmoi apply               # re-render templates, re-run brew bundle
```

## Notes

- [`Fish`](https://fishshell.com/) is my shell and [`Tide`](https://github.com/IlanCosman/tide) its prompt
- [`Dracula`](https://draculatheme.com/) is the terminal theme
- Git commits are signed with the SSH key
- See [`AGENTS.md`](./AGENTS.md) for the layout of this repo and how to
  modify it
