#!/usr/bin/env bash

# Location where Brew installs Fish (/opt/homebrew for Apple silicone and /usr/local for Intel)
shell_location="/opt/homebrew/bin/fish"
if [ ! -f "$shell_location" ]; then
  shell_location="/usr/local/bin/fish"
fi

# If needed
if ! grep -q "$shell_location" /etc/shells; then
  # Add Fish to the list of allowed shell
  echo "$shell_location" | sudo tee -a /etc/shells

  # Make it the default one (or "login shell")
  chsh -s "$shell_location"
fi
