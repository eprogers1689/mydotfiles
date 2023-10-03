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

cleanup () {
  git checkout master;
  git pull;
  git branch | egrep -v "(^\*|master|test|qa)" | xargs git branch -D;
}