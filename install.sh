#!/bin/bash

echo "Backing up old dotfiles and linking new files"

# Generate a timestamp for backups
timestamp=$(date +%Y%m%d%H%M%S)

# Link zsh dot files
for fname in $(find ~/mydotfiles/zsh -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    mv "$filename_source" "$filename_target"
    ln -s "$fname" "$HOME/$filename"
done

# Link config dot files
for fname in $(find ~/mydotfiles/configs -name ".*" ! -name "*.sh*"); do
    filename=$(basename "$fname")
    filename_source="$HOME/$filename"
    filename_target="$HOME/$filename.$timestamp"
    mv "$filename_source" "$filename_target"
    ln -s "$fname" "$HOME/$filename"
done


echo "Installation completed."