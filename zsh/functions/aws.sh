ssm-list() {
  aws ssm get-parameters-by-path --path $1 --recursive --query 'Parameters[].Name' --no-cli-pager | jq -r '.[]'
}

ssm-get() {
  aws ssm get-parameter --with-decryption  --query 'Parameter.Value' --output text --name $1 --no-cli-pager | tr -d '\n' | pbcopy
}

ssm-put() {
  aws ssm put-parameter --name $1 --type SecureString --value $2 --no-cli-pager
}

ssm-copy(){
  VALUE=$(aws ssm get-parameter --with-decryption  --query 'Parameter.Value' --output text --name $1 --no-cli-pager | tr -d '\n' )
  ssm-put $2 $VALUE
}

role() {
  OUTPUT=$(aws sts assume-role \
  --role-arn arn:aws:iam::${1}:role/${2} \
  --role-session-name "$USER" \
  --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]")
  export AWS_ACCESS_KEY_ID=$(echo $OUTPUT | jq -r '.[0]')
  export AWS_SECRET_ACCESS_KEY=$(echo $OUTPUT | jq -r '.[1]')
  export AWS_SESSION_TOKEN=$(echo $OUTPUT | jq -r '.[2]')
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
