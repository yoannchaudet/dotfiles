#!/usr/bin/env fish

if command -v rustc >/dev/null 2>&1
  echo "Rust is already installed"
else
  echo "Installing Rust"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fish_add_path ~/.cargo/bin/
end
