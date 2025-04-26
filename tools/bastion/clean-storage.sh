#!/bin/bash

# Path to the target directory
TARGET_DIR="storage/a_bastion"

# Auto-elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Remove everything inside the target directory 
# except for ansible/.gitkeep and scripts/.gitkeep
find "$TARGET_DIR" -mindepth 1 \
  ! -path "$TARGET_DIR/ansible/.gitkeep" \
  ! -path "$TARGET_DIR/scripts/.gitkeep" \
  ! -path "$TARGET_DIR/ansible" \
  ! -path "$TARGET_DIR/scripts" \
  -exec rm -rf {} +

echo "✅ Cleanup completed. Preserved .gitkeep files in ansible and scripts directories."
