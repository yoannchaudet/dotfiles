#!/usr/bin/env bash

# Change the settings folder
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string ~/.config/iterm2

# Load the settings from the folder
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true