#!/usr/bin/env bash

# Location where Brew install Fish
shell_location="/opt/homebrew/bin/fish"

# If needed
if ! grep -q "$shell_location" /etc/shells; then
  # Add Fish to the list of allowed shell
  echo "$shell_location" | sudo tee -a /etc/shells

  # Make it the default one (or "login shell")
  chsh -s /opt/homebrew/bin/fish
fi
