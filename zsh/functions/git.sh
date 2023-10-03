gbl() {
  local branches
  branches=$(git branch --list | sed 's/^\*\?\s*//')  # Get the list of branches, remove leading '*' from the current branch

  # Use dialog to create a menu
  local branch
  branch=$(dialog --clear --title "Git Branch Selector" --menu "Select a branch to checkout:" 0 0 0 "${branches[@]}" 2>&1 >/dev/tty)

  # Check if the user pressed Enter or Esc
  local exit_code=$?
  if [ $exit_code -eq 0 ]; then
    # Checkout the selected branch
    git checkout "$branch"
    echo "Checked out branch: $branch"
  else
    echo "Operation canceled."
  fi
}

gbs() {
    BRANCH=$(git branch | cat | cut -c 3- | grep -iF "$1")
    if [[ -n "${BRANCH}" ]]
    then
        echo "$BRANCH"

        echo -n "\n^^^ Do you want to checkout this branch? [y/n] "
        read SHOULD_CHECKOUT
        if [ $SHOULD_CHECKOUT = "y" ]
        then
            git checkout "$BRANCH"
        fi

    else
        echo Could not find branch \""$1"\"
    fi
}