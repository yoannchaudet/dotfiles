# My very own `dotfiles`

A repository to bootstrap my MacOS machine (dev environment and more general apps I use or like).

I could have used [Ansible](https://www.ansible.com/) playbooks but I felt like trying something else.

## Platforms

- MacOS (main target)
- GitHub Codespaces (diluted target, not setup yet)

## Setup

1. Install `brew` (see [instructions](https://brew.sh))

1. Clone this repository

   You need `git` already installed on your machine, on MacOS, you have a default version packaged by Apple. It is part of the dev tools which may need to be installed first (the OS will prompt you as needed).

2. Run the following script to install [Bitwarden](https://bitwarden.com/) (your password manager):

   ```sh
   ./bootstrap
   ```

3. Create a new SSH key with:

   ```sh
   ssh-keygen -t ed25519 -C "<comment>"
   ```

   Copy the public key with:

   ```sh
   cat ~/.ssh/id_ed25519.pub | pbcopy
   ```

   Upload it to your GitHub account twice, as a SSH key and as a signing key.

4. Finally, you can run this last script to bootstrap your machine:

   ```sh
   ./install
   ```

   You will need to sign out and sign in again for some settings to apply.

   Most apps will be installed already and your shell all setup.

   🤘

## Notes

- I use [`Dotbot`](https://github.com/anishathalye/dotbot) to manage this whole repository
- [`Git`](https://git-scm.com/doc) is setup to sign commits with my SSH key
- [`Fish`](https://fishshell.com/) is my shell and [`Tide``](https://github.com/IlanCosman/tide) its prompt
- [`Dracula`](https://draculatheme.com/) is my terminal theme
