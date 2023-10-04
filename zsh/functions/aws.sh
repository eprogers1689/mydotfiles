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

a() {
  if [ -z "$1" ]; then
    jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] |  @tsv" ~/.aws/sso_accounts.json;
  else
    if [[ "$1" =~ ^[0-9]+$ ]]; then
      matched_account=$(jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] | @tsv" ~/.aws/sso_accounts.json | grep $1 )
      if [ -n "$matched_account" ]; then
        echo -n "$matched_account" | awk '{print $2}' | tr -d '\n' | pbcopy
        account_name=$(echo -n "$matched_account" | awk '{print $2}' | tr -d '\n')
        account_id=$(echo -n "$matched_account" | awk '{print $1}' | tr -d '\n')
        echo -e "Copied: $account_name \e[90m($account_id)\e[0m"
      else
        echo "No account found with the provided account ID: $1"
      fi
    else
      # Create an awk pattern for fuzzy finding based on multiple args
      construct_awk_pattern() {
        local result=""
        for arg in "$@"; do
          result="${result}/$arg/ && "
        done
        # Remove the trailing " && " from the result
        result="${result% && }"
        echo "$result"
      }
      awk_pattern=$(construct_awk_pattern "$@")
      matched_accounts=$(jq -r ".accountList | sort_by(.accountName)[] | [.accountId,.accountName] | @tsv" ~/.aws/sso_accounts.json | awk "$awk_pattern")
      if [ -n "$matched_accounts" ]; then
        num_accounts_found=$(echo "$matched_accounts" | wc -l)
        if [ "$num_accounts_found" -gt 1 ]; then
          echo "Found multiple accounts that match your query:"
          echo $matched_accounts
        else
          account_name=$(echo -n "$matched_accounts" | awk '{print $2}')
          account_id=$(echo -n "$matched_accounts" | awk '{print $1}')
          echo -n "$matched_accounts" | awk '{print $1}' | tr -d '\n' | pbcopy
          echo -e "Copied: $account_id \e[90m($account_name)\e[0m"
        fi
      else
        echo "No accounts found matching: $@"
      fi
    fi
  fi
}
