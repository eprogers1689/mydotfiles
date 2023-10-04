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

# TODO: setup gitlab in pyenv and configure creds so this works
#clonegh() {
#  cd ~/projects && \
#  git clone git@github.com:lampo/$1.git 2> /dev/null || git clone $(/Users/ethan.rogers/.pyenv/shims/gitlab -o json project list --owned true --search $1 | jq -r --arg REPO "$1" '.[] | select(.path==$REPO) | .ssh_url_to_repo');
#  cd $1
#}
#
#
#clonegl() {
#  cd ~/projects && \
#  REPO=$(gitlab -o json project list --owned true --search $1 | jq -r --arg REPO "$1" '.[] | select(.path==$REPO) | .ssh_url_to_repo')
#  git clone $REPO;
#  cd $1
#}