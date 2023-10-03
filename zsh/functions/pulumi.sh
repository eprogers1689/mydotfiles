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