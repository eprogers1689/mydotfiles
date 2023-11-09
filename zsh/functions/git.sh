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

clone() {
 cd ~/projects && \
 git clone git@github.com:lampo/$1.git 2> /dev/null || git clone $(/Users/ethan.rogers/.pyenv/shims/gitlab -o json project list --owned true --search $1 | jq -r --arg REPO "$1" '.[] | select(.path==$REPO) | .ssh_url_to_repo');
 cd $1
 code .
}

push() {
    git add .
    git commit -m $1
    PR_URL=$(git push -u origin HEAD -o merge_request.create 2>&1 | grep -o 'https.*')
    CLEAN_PR_URL=$(echo "$PR_URL" | tr -d '[:space:]')
    echo $CLEAN_PR_URL | pbcopy
    open $CLEAN_PR_URL
}