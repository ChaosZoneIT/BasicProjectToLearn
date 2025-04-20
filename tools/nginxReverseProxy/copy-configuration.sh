#!/bin/bash

# Auto elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Source and destination paths
SOURCE="./nginxReverseProxy/config/nginx.conf"
DESTINATION="./storage/nginxReverseProxy/config/nginx.conf"

# Check if the destination directory exists, if not, create it
DEST_DIR=$(dirname "$DESTINATION")
if [ ! -d "$DEST_DIR" ]; then
  echo "Creating directories: $DEST_DIR"
  mkdir -p "$DEST_DIR"
  chmod -R a+rw "$DEST_DIR"
fi

# Copy the configuration file from source to destination
echo "Copying configuration file from $SOURCE to $DESTINATION"
cp "$SOURCE" "$DESTINATION"

# Check if the copy operation was successful
if [ $? -eq 0 ]; then
  echo "File copied successfully!"
  chmod a+rw "$DESTINATION"
else
  echo "An error occurred while copying the file."
fi
