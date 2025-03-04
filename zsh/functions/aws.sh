ecr(){
  assume rs-cicd;
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 674907502808.dkr.ecr.us-east-1.amazonaws.com;
  aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 058238361356.dkr.ecr.us-east-1.amazonaws.com;
  assume --un
}

ssm-list() {
  aws ssm get-parameters-by-path --path $1 --recursive --query 'Parameters[].Name' | jq -r '.[]'
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

rds-creds () {
  ROLE_NAME=$1
  selected_db=$2
  if [ -z "$ROLE_NAME" ]; then
    echo "please pass in role name as first arg. example: rds-creds someteam_dev"
    return 1
  fi

  if [ -z "$selected_db" ]; then
    db_clusters=$(aws rds describe-db-clusters --query 'DBClusters[].DBClusterIdentifier' --output text)
    if [ -z "$db_clusters" ]; then
        echo "No DB clusters found."
        return 1
    fi
    echo "Select a db:"
    index=1
    echo "$db_clusters" | tr '\t' '\n' | while read -r db; do
        echo "$index: $db"
        ((index++))
    done
    echo "Enter a number: "
    read choice
    if ! [[ "$choice" =~ ^[1-9][0-9]*$ ]] || [ "$choice" -gt "$index" ] || [ "$choice" -lt 1 ]; then
        echo "Invalid choice. Please enter a valid number."
        return 1
    fi
    selected_db=$( echo $db_clusters| awk -v var=$choice -F'\t' '{print $var}')
    echo "You selected: $selected_db"
  fi
  RDS_CLUSTER_INFO=$(aws rds describe-db-clusters --db-cluster-identifier "$selected_db" --output json 2>/dev/null)
  if [ -z "$RDS_CLUSTER_INFO" ]; then
      echo "No valid RDS cluster selected."
  else
      RDS_HOSTNAME=$(echo "$RDS_CLUSTER_INFO" | jq -r '.DBClusters[0].Endpoint')
      RDS_PORT=$(echo "$RDS_CLUSTER_INFO" | jq -r '.DBClusters[0].Port')
      echo "\nHere are creds you can use with your preferred DB Client:"
      aws rds generate-db-auth-token --username "$ROLE_NAME" --hostname "$RDS_HOSTNAME" --port "$RDS_PORT" --region us-east-1
  fi
}

st () {
  assume systems-test
}

sq () {
  assume systems-qa
}

sp () {
  assume systems-prod
}
