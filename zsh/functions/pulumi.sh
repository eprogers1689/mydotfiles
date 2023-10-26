showstate(){
    if [ -n "$1" ]; then
        STACK_NAME=$1
    else
        STACK_NAME=$(basename `git rev-parse --show-toplevel`)
    fi
    STATE_BUCKET=s3://rs-pulumi-state-$(aws sts get-caller-identity --query Account --output text)
    echo $STACK_NAME
    echo $STATE_BUCKET
    aws s3 cp "${STATE_BUCKET}/.pulumi/stacks/${STACK_NAME}.json" - | code -
}

# Pulumi Login - by setting PULUMI_BACKEND_URL
pl(){
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
    PULUMI_BACKEND_URL="s3://rs-pulumi-state-$AWS_ACCOUNT_ID"
    matched_account=$(jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] | @tsv" ~/.aws/sso_accounts.json | grep $AWS_ACCOUNT_ID | awk '{print $2}' )
    echo "setting PULUMI_BACKEND_URL to $PULUMI_BACKEND_URL \e[90m($matched_account)\e[0m"
    export PULUMI_BACKEND_URL=$PULUMI_BACKEND_URL
}

# Pulumi logout - by unsetting PULUMI_BACKEND_URL
plo(){
  if [[ ! -z "$PULUMI_BACKEND_URL" ]]; then
    echo "Logging out of: $PULUMI_BACKEND_URL"
    unset PULUMI_BACKEND_URL
  else
    echo "Already logged out of pulumi..."
  fi
}
