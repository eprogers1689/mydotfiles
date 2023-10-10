alias p='pulumi'
alias pl='pulumi login s3://rs-pulumi-state-$(aws sts get-caller-identity --query 'Account' --output text)'
alias pup='pulumi up'
alias puppy='pulumi up --yes'