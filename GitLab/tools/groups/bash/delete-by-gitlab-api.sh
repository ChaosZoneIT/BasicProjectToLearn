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


# GitLab API URL for groups
GITLAB_API_URL="$GITLAB_API_URL/groups"

# Use --insecure (-k) for curl if CURL_INSECURE is set to true
CURL_OPTIONS=""
if [ "$CURL_INSECURE" = "true" ]; then
  CURL_OPTIONS="-k"
fi

# Function to delete group by name
delete_group_by_name() {
  GROUP_NAME=$1
  echo "Attempting to delete group: $GROUP_NAME"

  # Get the group ID by name
  GROUP_ID=$(curl $CURL_OPTIONS -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$GITLAB_API_URL" | jq -r ".[] | select(.name==\"$GROUP_NAME\") | .id")

  if [ -n "$GROUP_ID" ]; then
    # If group ID is found, send DELETE request to GitLab API
    response=$(curl $CURL_OPTIONS -s -w "%{http_code}" -o /dev/null --request DELETE "$GITLAB_API_URL/$GROUP_ID" \
      --header "PRIVATE-TOKEN: $GITLAB_TOKEN")

    # Check if the group was deleted successfully (HTTP status code 204 means successful deletion)
    if [ "$response" -eq 202 ]; then
      echo "Group '$GROUP_NAME' with ID $GROUP_ID successfully deleted."
    else
      echo "Failed to delete group '$GROUP_NAME' with ID $GROUP_ID. HTTP status code: $response"
    fi
  else
    # If group ID is not found, notify user
    echo "Group '$GROUP_NAME' not found. Skipping deletion."
  fi
}

# Loop through group names and attempt to delete each
IFS=',' read -ra GROUPS_LIST <<< "$GROUP_NAMES"
for GROUP_NAME in "${GROUPS_LIST[@]}"; do
  delete_group_by_name "$GROUP_NAME"
done