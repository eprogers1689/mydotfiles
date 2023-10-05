#!/bin/bash

# yolo saves me the cleanup when I'm iterating on stuff...
if [[ ! $1 == "yolo" ]]; then
    echo "Backing up old dotfiles and linking new files"
else
    echo "YOLO! Not saving backups."
fi

# Generate a timestamp for backups
timestamp=$(date +%Y%m%d%H%M%S)

# Link zsh dot files
for fname in $(find ~/mydotfiles/zsh -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    if [[ ! $1 == "yolo" ]]; then
        cp "$filename_source" "$filename_target"
    fi
    ln -sf "$fname" "$HOME/$filename"
done

# Link config dot files
for fname in $(find ~/mydotfiles/configs -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    if [[ ! $1 == "yolo" ]]; then
        cp "$filename_source" "$filename_target"
    fi
    ln -sf "$fname" "$HOME/$filename"
done

# Link tmux conf
for fname in $(find ~/mydotfiles/tmux -name ".tmux*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    if [[ ! $1 == "yolo" ]]; then
        cp "$filename_source" "$filename_target"
    fi
    ln -sf "$fname" "$HOME/$filename"
done

# Brewfile conf
for fname in $(find ~/mydotfiles/homebrew -name "Brewfile"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    if [[ ! $1 == "yolo" ]]; then
        cp "$filename_source" "$filename_target"
    fi
    ln -sf "$fname" "$HOME/$filename"
done

cd ~
brew bundle
cd -

echo "Installation completed."