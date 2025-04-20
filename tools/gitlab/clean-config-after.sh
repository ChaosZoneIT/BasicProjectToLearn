#!/bin/bash

# Auto elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Ensure the target directory exists
CONFIG_DIR="storage/gitlab/config-after-start"

if [ ! -d "$CONFIG_DIR" ]; then
  echo "❌ Directory $CONFIG_DIR does not exist. Aborting."
  exit 1
fi

echo "🧹 Cleaning $CONFIG_DIR but keeping .gitkeep..."

# Include hidden files in glob patterns
shopt -s dotglob

# Loop through all items and remove everything except .gitkeep
for item in "$CONFIG_DIR"/*; do
  if [[ "$(basename "$item")" != ".gitkeep" ]]; then
    echo "🗑️ Removing: $item"
    rm -rf "$item"
  fi
done

# Restore default globbing behavior
shopt -u dotglob

echo "✅ Cleanup complete. .gitkeep preserved."
