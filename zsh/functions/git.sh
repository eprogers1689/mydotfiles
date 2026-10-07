function gbs(){
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

function cleanup(){
  git checkout master;
  git pull;
  git branch | egrep -v "(^\*|master|test|qa)" | xargs git branch -D;
}


push() {
    git add .
    git commit -m "$1" || return

    local PUSH_OUTPUT
    PUSH_OUTPUT=$(git push -u origin HEAD -o merge_request.create 2>&1) || {
        print -r -- "$PUSH_OUTPUT"
        return 1
    }

    local CLEAN_PR_URL
    CLEAN_PR_URL=$(print -r -- "$PUSH_OUTPUT" | grep -o 'https://[^ ]*/-/merge_requests/[0-9]*')
    [[ -n "$CLEAN_PR_URL" ]] || return

    print -r -- "$CLEAN_PR_URL" | pbcopy
    open "$CLEAN_PR_URL"
}
