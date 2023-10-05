#!/bin/bash

echo "Backing up old dotfiles and linking new files"

# Generate a timestamp for backups
timestamp=$(date +%Y%m%d%H%M%S)

# Link zsh dot files
for fname in $(find ~/mydotfiles/zsh -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    cp "$filename_source" "$filename_target"
    ln -sf "$fname" "$HOME/$filename"
done

# Link config dot files
for fname in $(find ~/mydotfiles/configs -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    cp "$filename_source" "$filename_target"
    ln -sf "$fname" "$HOME/$filename"
done

# Link tmux conf
for fname in $(find ~/mydotfiles/tmux -name ".tmux*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    cp "$filename_source" "$filename_target"
    ln -sf "$fname" "$HOME/$filename"
done

# Brewfile conf
for fname in $(find ~/mydotfiles/homebrew -name "Brewfile"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    cp "$filename_source" "$filename_target"
    ln -sf "$fname" "$HOME/$filename"
done

cd ~
brew bundle
cd -

echo "Installation completed."