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

# Link Neovim config
nvim_config_dir="$HOME/.config/nvim"
nvim_source_dir="$HOME/mydotfiles/nvim"
if [[ -d "$nvim_source_dir" ]]; then
    mkdir -p "$HOME/.config"
    if [[ -d "$nvim_config_dir" && ! -L "$nvim_config_dir" ]]; then
        if [[ ! $1 == "yolo" ]]; then
            mv "$nvim_config_dir" "$nvim_config_dir.$timestamp"
        fi
    fi
    ln -sfn "$nvim_source_dir" "$nvim_config_dir"
    echo "Linked Neovim config: $nvim_source_dir -> $nvim_config_dir"
fi

# Link prun from rs-docker-pulumi-v2
mkdir -p "$HOME/bin"
ln -sf "$HOME/projects/rs-docker-pulumi-v2/bin/prun" "$HOME/bin/prun"
echo "Linked prun -> ~/projects/rs-docker-pulumi-v2/bin/prun"

if [[ " $* " == *"--brew"* ]]; then
    echo "Running brew bundle..."
    cd ~
    brew bundle
    cd -
else
    echo "Skipping brew bundle (pass --brew to install)"
fi

echo "Installation completed."