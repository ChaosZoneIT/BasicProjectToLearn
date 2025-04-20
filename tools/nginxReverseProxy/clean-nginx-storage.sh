#!/bin/bash

# Auto elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Path to the directory
TARGET_DIR="./storage/nginxReverseProxy"

# Check if the directory exists
if [ -d "$TARGET_DIR" ]; then
    echo "Removing directory: $TARGET_DIR and its contents..."
    # Remove the directory and its contents recursively
    rm -rf "$TARGET_DIR"
    echo "Directory has been removed."
else
    # If the directory doesn't exist, inform the user
    echo "Directory $TARGET_DIR does not exist."
fi
