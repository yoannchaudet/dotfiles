#!/usr/bin/env fish

# Plugin to install
set tide_plugin "ilancosman/tide"
set tide_version "@main"

# Check what is currently installed
set installed (fisher list | grep $tide_plugin)

# Install if needed
if test "$installed" = "$tide_plugin$tide_version"
  echo "Tide is already installed"
  return
else
  if test -n "$installed"
    echo "Removing old version of Tide ($installed)"
    fisher remove "$installed"
  end

  echo "Installing Tide ($tide_version)"
  fisher install "$tide_plugin$tide_version"

  echo "Configuring Tide"
  tide configure \
    --auto \
    --style=Lean \
    --prompt_colors='True color' \
    --show_time=No \
    --lean_prompt_height='One line' \
    --prompt_spacing=Compact \
    --icons='Few icons'
end
