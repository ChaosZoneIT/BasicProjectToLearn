#!/bin/bash


# Auto elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Path to the gitlab directory
GITLAB_DIR="storage/gitlab"
KEEP_DIR="$GITLAB_DIR/init.scripts"

# Safety check
if [ ! -d "$KEEP_DIR" ]; then
  echo "❌ Directory $KEEP_DIR does not exist. Aborting."
  exit 1
fi

echo "🔍 Cleaning $GITLAB_DIR, keeping only init.scripts..."

# Loop through contents of storage/gitlab
for item in "$GITLAB_DIR"/*; do
  if [[ "$item" != "$KEEP_DIR" ]]; then
    echo "🗑️ Removing: $item"
    sudo rm -rf "$item"
  fi
done

echo "✅ Cleanup complete. Only init.scripts is kept."