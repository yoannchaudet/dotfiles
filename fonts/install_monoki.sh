#!/usr/bin/env bash

# URL to the font ZIP file
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Mononoki.zip"

# If the font is not there, install it
if ! find "$HOME/Library/Fonts" -type f -iname "mononoki*" | grep -q .; then

  # Create a temporary directory
  temp_dir=$(mktemp -d)

  # Download the font ZIP file
  echo "Downloading font ZIP..."
  curl -L -o "$temp_dir/font.zip" "$url"

  # Extract the font files
  echo "Extracting font files..."
  unzip "$temp_dir/font.zip" -d "$temp_dir"

  # Install the fonts on macOS
  echo "Installing fonts..."
  font_dir="$HOME/Library/Fonts"
  cp -R "$temp_dir"/*.ttf "$font_dir"

  # Clean up
  echo "Cleaning up..."
  rm -rf "$temp_dir"

  echo "Fonts installed successfully!"

fi