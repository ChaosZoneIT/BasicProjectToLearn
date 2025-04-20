#!/bin/bash

# Auto elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Path to the gitlab directory
GITLAB_DIR="storage/gitlab"
KEEP_DIR_1="$GITLAB_DIR/config-before-start"
KEEP_DIR_2="$GITLAB_DIR/config-after-start"

# Safety check - ensure both directories exist
if [ ! -d "$KEEP_DIR_1" ] || [ ! -d "$KEEP_DIR_2" ]; then
  echo "❌ One or both directories $KEEP_DIR_1 or $KEEP_DIR_2 do not exist. Aborting."
  exit 1
fi

echo "🔍 Cleaning $GITLAB_DIR, keeping only $KEEP_DIR_1 and $KEEP_DIR_2..."

# Loop through contents of storage/gitlab
for item in "$GITLAB_DIR"/*; do
  if [[ "$item" != "$KEEP_DIR_1" && "$item" != "$KEEP_DIR_2" ]]; then
    echo "🗑️ Removing: $item"
    sudo rm -rf "$item"
  fi
done

echo "✅ Cleanup complete. Only $KEEP_DIR_1 and $KEEP_DIR_2 are kept."