#!/bin/zsh

# Setup Configs .sh files
for fname in $(find ~/mydotfiles/configs -name "*.sh*"); do
    source $fname
done

# Link zsh aliases
for fname in $(find ~/mydotfiles/zsh/aliases  -name "*.sh*"); do
    source $fname
done

# Link zsh functions
for fname in $(find ~/mydotfiles/zsh/functions -name "*.sh*"); do
    source $fname
done

# Link zsh envs
for fname in $(find ~/mydotfiles/zsh/envs -name "*.sh*"); do
    source $fname
done

# Link zsh secrets
for fname in $(find ~/mydotfiles/zsh/secrets -name "*.sh*"); do
    source $fname
done