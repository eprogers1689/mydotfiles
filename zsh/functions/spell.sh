#!/usr/bin/env zsh

# Toggle zsh spell correction (setopt correct)
function spell() {
    if [[ -o correct ]]; then
        # Spell correction is currently on, turn it off
        unsetopt correct
        echo "Spell correction disabled"
    else
        # Spell correction is currently off, turn it on
        setopt correct
        echo "Spell correction enabled"
    fi
}