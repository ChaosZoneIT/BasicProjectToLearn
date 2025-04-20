#!/bin/bash

# Check if the script is being run from the project root
if [ ! -d "GitLab" ] || [ ! -d "storage" ]; then
  echo "❌ Please run this script from the project root directory."
  exit 1
fi

# Paths to the directories
SOURCE_DIR="GitLab/config/before-start"
DEST_DIR="storage/gitlab/config-before-start"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Source directory $SOURCE_DIR does not exist. Aborting."
  exit 1
fi

# Create destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
  echo "⚙️ Destination directory $DEST_DIR does not exist. Creating it..."
  mkdir -p "$DEST_DIR"
fi

# Copy entire contents from source to destination, preserving structure
echo "🔄 Copying contents from $SOURCE_DIR to $DEST_DIR..."

# This enables the dotglob shell option, which makes the glob pattern * include hidden files and directories — that is, files and folders starting with a dot (.), like .conf, .env, or .gitignore.
shopt -s dotglob
cp -r "$SOURCE_DIR/"* "$DEST_DIR/"
# This disables the dotglob option, restoring the default behavior where glob patterns exclude hidden files.
shopt -u dotglob

# Make all .sh files in the destination (including subdirectories) executable
echo "🔐 Ensuring all .sh files in $DEST_DIR are executable..."
find "$DEST_DIR" -type f -name "*.sh" -exec chmod +x {} \;

echo "✅ Copy and permissions setup completed successfully."