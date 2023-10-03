ssm-list() {
  aws ssm get-parameters-by-path --path "/" --recursive --query 'Parameters[].Name' | jq -r '.[]' | grep $1
}

ssm-get() {
  aws ssm get-parameter --with-decryption  --query 'Parameter.Value' --output text --name $1 | tr -d '\n' | pbcopy
}

ssm-put() {
  aws ssm put-parameter --name $1 --type SecureString --value $2
}

role() {
  OUTPUT=$(aws sts assume-role \
--role-arn arn:aws:iam::${1}:role/${2} \
--role-session-name ashwin \
--query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]")
  export AWS_ACCESS_KEY_ID=$(echo $OUTPUT | jq -r '.[0]')
  export AWS_SECRET_ACCESS_KEY=$(echo $OUTPUT | jq -r '.[1]')
  export AWS_SESSION_TOKEN=$(echo $OUTPUT | jq -r '.[2]')
}

a () {
  if [ -z $1 ]; then
    jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] |  @tsv" ~/.aws/sso_accounts.json;
  else
    if [[ $1 =~ '^[0-9]+$' ]]; then
      jq -r ".accountList[] | select( .accountId == \"$1\" ) | .accountName" ~/.aws/sso_accounts.json;
    else
      jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] |  @tsv" ~/.aws/sso_accounts.json | grep $1
    fi;
  fi;
}