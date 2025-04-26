#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set the path to the .env file
ENV_FILE="$SCRIPT_DIR/.env"

# Check if the .env file exists, and if not, exit with an error
if [ ! -f "$ENV_FILE" ]; then
  echo ".env file not found in $SCRIPT_DIR"
  exit 1
fi

# Load the environment variables from the .env file
set -a
source "$ENV_FILE"
set +a

# Split the GROUP_NAMES into an array
IFS=',' read -r -a GROUPS_LIST <<< "$GROUP_NAMES"

# Use --insecure (-k) for curl if CURL_INSECURE is set to true
CURL_OPTIONS=""
if [ "$CURL_INSECURE" = "true" ]; then
  CURL_OPTIONS="-k"
fi

# Iterate through each group name in the GROUPS_LIST array and create a group in GitLab
for GROUP_NAME in "${GROUPS_LIST[@]}"; do
  echo "Creating group: $GROUP_NAME"
  
  # Prepare the data to send to the API
  if [ "$PARENT_GROUP_ID" == "null" ]; then
    # If PARENT_GROUP_ID is null, exclude it from the request data
    data="{\"name\": \"$GROUP_NAME\", \"path\": \"${GROUP_NAME,,}\", \"visibility\": \"private\"}"
  else
    # If PARENT_GROUP_ID is not null, include it in the request data
    data="{\"name\": \"$GROUP_NAME\", \"path\": \"${GROUP_NAME,,}\", \"visibility\": \"private\", \"parent_id\": $PARENT_GROUP_ID}"
  fi

  #Send a POST request to GitLab API to create the group
  response=$(curl $CURL_OPTIONS -s -w "%{http_code}" -o /dev/null --request POST "$GITLAB_API_URL/groups" \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    --header "Content-Type: application/json" \
    --data "$data")
  
  # Check response code
  if [[ "$response" == "201" ]]; then
    echo "✅ Group '$GROUP_NAME' created successfully (HTTP $response)"
  elif [[ "$response" == "409" ]]; then
    echo "⚠️ Group '$GROUP_NAME' already exists (HTTP $response)"
  else
    echo "❌ Failed to create group '$GROUP_NAME' (HTTP $response)"
  fi

  echo ""
done