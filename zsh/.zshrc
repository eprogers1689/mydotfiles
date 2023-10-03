#!/bin/zsh

# Setup Configs .sh files
for fname in $(find ~/mydotfiles/configs -name "*.sh*"); do
    source $fname
done

# Setup Configs .sh files
for fname in $(find ~/mydotfiles/zsh/aliases  -name "*.sh*"); do
    source $fname
done

# Setup Configs .sh files
for fname in $(find ~/mydotfiles/zsh/functions -name "*.sh*"); do
    source $fname
done