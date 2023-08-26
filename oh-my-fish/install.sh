#!/usr/bin/env bash

eval bootstrap="~/.config/fish/conf.d/omf.fish"

# If it is not installed yet
if [ ! -e "$bootstrap" ]; then
  # Download and install Oh My Fish
  curl -L https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install \
  | fish -c 'source - --noninteractive --yes'
fi
