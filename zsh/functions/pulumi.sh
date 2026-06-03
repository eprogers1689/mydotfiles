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

v () {
    if [ -n "$1" ]; then
        STACK_NAME=$1
    else
        STACK_NAME=$(pwd | cut -d '/' -f 5)
    fi
    TASK_DEF=$(pulumi stack export --stack "$STACK_NAME" | jq '
        .deployment.resources[]
        | select(.type == "aws:ecs/taskDefinition:TaskDefinition")
    ')
    CONTAINER_DEF=$(echo "$TASK_DEF" | jq '
        .inputs.containerDefinitions
        | fromjson
        | map(select(.name != "log_router"))[0]
    ')

    VERSION=$(echo "$CONTAINER_DEF" | jq -r '.image' | cut -d ':' -f 2)
    TIMESTAMP=$(echo "$CONTAINER_DEF" | jq -r '.environment[] | select(.name == "TIMESTAMP").value')
    CI_PROJECT_URL=$(echo "$TASK_DEF" | jq -r '.inputs.tags.repo')

    echo "VERSION=$VERSION"
    echo "TIMESTAMP=$TIMESTAMP"
    echo "CI_PROJECT_URL=$CI_PROJECT_URL"

    export VERSION=$VERSION
    export TIMESTAMP=$TIMESTAMP
    export CI_PROJECT_URL=$CI_PROJECT_URL
}

vl () {
    STACK_NAME=$(pwd | cut -d '/' -f 5)
    LAMBDA_STATE=$(pulumi stack export --stack "$STACK_NAME" | jq '
        .deployment.resources[]
        | select(.type == "aws:lambda/function:Function")'
    )

    TIMESTAMP=$(echo "$LAMBDA_STATE" | jq -r '.inputs.environment.variables.TIMESTAMP')
    S3_KEY=$(echo "$LAMBDA_STATE" | jq -r '.inputs.s3Key')
    CI_PROJECT_URL=$(echo "$LAMBDA_STATE" | jq -r '.inputs.tags.repo')

    IFS='/' read -r CI_PROJECT_NAME STACK_NAME2 VERSION LAMBDA_FUNCTION_NAME_ZIP <<< "$S3_KEY"
    LAMBDA_FUNCTION_NAME="${LAMBDA_FUNCTION_NAME_ZIP%.zip}"

    echo "CI_PROJECT_NAME: $CI_PROJECT_NAME"
    echo "CI_PROJECT_URL=$CI_PROJECT_URL"
    echo "LAMBDA_FUNCTION_NAME: $LAMBDA_FUNCTION_NAME"
    echo "TIMESTAMP=$TIMESTAMP"
    echo "VERSION: $VERSION"

    export CI_PROJECT_NAME=$CI_PROJECT_NAME
    export CI_PROJECT_URL=$CI_PROJECT_URL
    export LAMBDA_FUNCTION_NAME=$LAMBDA_FUNCTION_NAME
    export TIMESTAMP=$TIMESTAMP
    export VERSION=$VERSION
}

nuke () {
  echo "💣 Nuking stack: $1"
  pl && p stack select $1 && p destroy --yes && p stack rm --yes
}

# plock - Acquire a Pulumi lock on the currently selected stack
plock() {
  local STACK_NAME=$(pulumi stack --show-name 2>/dev/null)
  if [ -z "$STACK_NAME" ]; then
    echo "Error: No stack selected. Run 'pulumi stack select <name>' first."
    return 1
  fi

  local AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  local STATE_BUCKET="s3://rs-pulumi-state-$AWS_ACCOUNT_ID"
  local S3_LOCK_DIR="${STATE_BUCKET}/.pulumi/locks/${STACK_NAME}"
  local LOCK_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  local S3_LOCK_PATH="${S3_LOCK_DIR}/${LOCK_UUID}.json"

  local EXISTING_LOCKS=$(aws s3 ls "${S3_LOCK_DIR}/" 2>/dev/null)
  if [ -n "$EXISTING_LOCKS" ]; then
    echo "Error: Stack '$STACK_NAME' is currently locked!"
    echo "Existing locks:"
    for lock_file in $(echo "$EXISTING_LOCKS" | awk '{print $4}'); do
      aws s3 cp "${S3_LOCK_DIR}/${lock_file}" - 2>/dev/null | jq -r '"  \(.username)@\(.hostname) (pid \(.pid)) at \(.timestamp)"'
    done
    echo "Use 'pulumi cancel' to remove stale locks."
    return 1
  fi

  local LOCK_CONTENT=$(jq -n \
    --argjson pid $$ \
    --arg username "$USER" \
    --arg hostname "$(hostname)" \
    --arg ts "$(date +%Y-%m-%dT%H:%M:%S.%N%z | sed 's/\([0-9]\{2\}\)\([0-9]\{2\}\)$/\1:\2/')" \
    '{pid: $pid, username: $username, hostname: $hostname, timestamp: $ts}')
  echo "$LOCK_CONTENT" | aws s3 cp - "$S3_LOCK_PATH" --quiet
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create lock"
    return 1
  fi

  echo "Lock acquired on '$STACK_NAME': $S3_LOCK_PATH"
}

# plocal - Lock S3 state, backup, download locally, switch to local backend
plocal() {
  local STACK_NAME="${1:-$(basename $(git rev-parse --show-toplevel 2>/dev/null))}"
  if [ -z "$STACK_NAME" ]; then
    echo "Error: No stack name provided and not in a git repo"
    return 1
  fi

  local AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  local STATE_BUCKET="s3://rs-pulumi-state-$AWS_ACCOUNT_ID"
  local S3_STATE_PATH="${STATE_BUCKET}/.pulumi/stacks/${STACK_NAME}.json"
  local LOCK_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  local S3_LOCK_DIR="${STATE_BUCKET}/.pulumi/locks/${STACK_NAME}"
  local S3_LOCK_PATH="${S3_LOCK_DIR}/${LOCK_UUID}.json"
  local LOCAL_DIR="$HOME/.pulumi-local/.pulumi/stacks"
  local BACKUP_DIR="$HOME/.pulumi-backups"
  local TIMESTAMP=$(date +%Y%m%d-%H%M%S)

  echo "Stack: $STACK_NAME"
  echo "S3 State: $S3_STATE_PATH"

  # Check if any locks exist
  local EXISTING_LOCKS=$(aws s3 ls "${S3_LOCK_DIR}/" 2>/dev/null)
  if [ -n "$EXISTING_LOCKS" ]; then
    echo "Error: Stack is currently locked!"
    echo "Existing locks:"
    for lock_file in $(echo "$EXISTING_LOCKS" | awk '{print $4}'); do
      aws s3 cp "${S3_LOCK_DIR}/${lock_file}" - 2>/dev/null | jq -r '"  \(.username)@\(.hostname) (pid \(.pid)) at \(.timestamp)"'
    done
    echo "Use 'pulumi cancel' to remove stale locks."
    return 1
  fi

  # Create lock in Pulumi's native format
  local LOCK_CONTENT=$(jq -n \
    --argjson pid $$ \
    --arg username "$USER" \
    --arg hostname "$(hostname)" \
    --arg ts "$(date +%Y-%m-%dT%H:%M:%S.%N%z | sed 's/\([0-9]\{2\}\)\([0-9]\{2\}\)$/\1:\2/')" \
    '{pid: $pid, username: $username, hostname: $hostname, timestamp: $ts}')
  echo "$LOCK_CONTENT" | aws s3 cp - "$S3_LOCK_PATH" --quiet
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create lock"
    return 1
  fi
  echo "Lock acquired: $S3_LOCK_PATH"

  # Store lock info for premote
  export PLOCAL_LOCK_PATH="$S3_LOCK_PATH"
  export PLOCAL_STACK_NAME="$STACK_NAME"

  # Create directories
  mkdir -p "$LOCAL_DIR" "$BACKUP_DIR"

  # Download and backup
  echo "Downloading state..."
  aws s3 cp "$S3_STATE_PATH" "$BACKUP_DIR/${STACK_NAME}-${TIMESTAMP}.json" --quiet
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download state. Releasing lock..."
    aws s3 rm "$S3_LOCK_PATH" --quiet
    return 1
  fi
  echo "Backup saved: $BACKUP_DIR/${STACK_NAME}-${TIMESTAMP}.json"

  # Copy to local backend location
  cp "$BACKUP_DIR/${STACK_NAME}-${TIMESTAMP}.json" "$LOCAL_DIR/${STACK_NAME}.json"

  # Switch to local backend
  export PULUMI_BACKEND_URL="file://$HOME/.pulumi-local"
  echo "Switched to local backend: $PULUMI_BACKEND_URL"
  echo "Ready to run pulumi commands locally"
}

# premote - Upload local state to S3, unlock, switch back to S3 backend
premote() {
  local STACK_NAME="${1:-${PLOCAL_STACK_NAME:-$(basename $(git rev-parse --show-toplevel 2>/dev/null))}}"
  if [ -z "$STACK_NAME" ]; then
    echo "Error: No stack name provided and not in a git repo"
    return 1
  fi

  local AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
  local STATE_BUCKET="s3://rs-pulumi-state-$AWS_ACCOUNT_ID"
  local S3_STATE_PATH="${STATE_BUCKET}/.pulumi/stacks/${STACK_NAME}.json"
  local S3_LOCK_DIR="${STATE_BUCKET}/.pulumi/locks/${STACK_NAME}"
  local LOCAL_STATE="$HOME/.pulumi-local/.pulumi/stacks/${STACK_NAME}.json"

  echo "Stack: $STACK_NAME"

  # Check local state exists
  if [ ! -f "$LOCAL_STATE" ]; then
    echo "Error: Local state not found at $LOCAL_STATE"
    return 1
  fi

  # Upload state
  echo "Uploading state to S3..."
  aws s3 cp "$LOCAL_STATE" "$S3_STATE_PATH" --quiet
  if [ $? -ne 0 ]; then
    echo "Error: Failed to upload state"
    return 1
  fi
  echo "State uploaded"

  # Remove our lock (use stored path if available, otherwise find and remove our lock)
  if [ -n "$PLOCAL_LOCK_PATH" ]; then
    aws s3 rm "$PLOCAL_LOCK_PATH" --quiet
    echo "Lock released: $PLOCAL_LOCK_PATH"
    unset PLOCAL_LOCK_PATH
    unset PLOCAL_STACK_NAME
  else
    # Find and remove lock owned by this user/host
    local MY_HOSTNAME=$(hostname)
    for lock_file in $(aws s3 ls "${S3_LOCK_DIR}/" 2>/dev/null | awk '{print $4}'); do
      local LOCK_INFO=$(aws s3 cp "${S3_LOCK_DIR}/${lock_file}" - 2>/dev/null)
      local LOCK_USER=$(echo "$LOCK_INFO" | jq -r '.username')
      local LOCK_HOST=$(echo "$LOCK_INFO" | jq -r '.hostname')
      if [ "$LOCK_USER" = "$USER" ] && [ "$LOCK_HOST" = "$MY_HOSTNAME" ]; then
        aws s3 rm "${S3_LOCK_DIR}/${lock_file}" --quiet
        echo "Lock released: ${S3_LOCK_DIR}/${lock_file}"
        break
      fi
    done
  fi

  # Switch back to S3 backend
  pl
}
