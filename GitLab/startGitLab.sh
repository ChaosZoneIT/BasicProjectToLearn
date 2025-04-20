#!/bin/bash

echo "🔁 [$(date)] Re-entered startGitLab.sh (PID: $$)"

set -e  # Exit immediately if a command exits with a non-zero status

# Start GitLab services
/opt/gitlab/embedded/bin/runsvdir-start &

# Restore GitLab configuration if needed
echo "[1/5] Restoring GitLab configuration file..."
if [ -z "$CONFIG_FILE_TMP" ] || [ -z "$CONFIG_FILE" ]; then
  echo "[ERROR] Configuration file variables (CONFIG_FILE_TMP or CONFIG_FILE) are not set. Exiting."
  exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[COPY] No existing configuration found. Restoring from backup..."
    cp "$CONFIG_FILE_TMP" "$CONFIG_FILE"
    # Ensure all changes are fully written to disk before continuing.
    # This is a safeguard to prevent race conditions or partial modifications
    # when the script is used in automated environments or fast systems.
    sync
else
    echo "[SKIP] Configuration already exists. Skipping restore from backup."
fi

# Copy ssl certificate after create volume
# Check if the destination directory exists and is empty
if [ -d "$SSL_CERTIFICATE_DIR" ] && [ "$(ls -A $SSL_CERTIFICATE_DIR)" ]; then
    # If the destination directory is not empty, skip the copying process
    echo "Directory $SSL_CERTIFICATE_DIR is not empty, skipping certificate copy."
else
    # If the destination directory is empty or doesn't exist, create it
    mkdir -p $SSL_CERTIFICATE_DIR

    # Copy certificates from the source directory to the destination directory
    echo "Copying certificates from $SOURCE_DIR to $SSL_CERTIFICATE_DIR..."
    cp -r $SSL_CERTIFICATE_DIR_TMP/* $SSL_CERTIFICATE_DIR/

    # Check if the copy command was successful
    if [ $? -eq 0 ]; then
        # If successful, print a success message
        echo "Certificates copied successfully."
    else
        # If there was an error, print an error message and exit with a non-zero status
        echo "Error occurred while copying certificates."
        exit 1
    fi
fi

# Run additional configuration scripts
echo "[2/5] Running init scripts..."
bash /startScript/configure-before-start.sh

# Reconfigure GitLab
# Warning: If the configuration is modified during the execution of this command,
# the process may be interrupted and the container could restart automatically due
# to the "restart: always" policy in Docker Compose. This is expected behavior
# and ensures the system picks up the latest configuration changes after a restart.
echo "[3/5] Running gitlab-ctl reconfigure..."
gitlab-ctl reconfigure


# Run additional configuration scripts
echo "[4/5] Running init scripts..."
bash /startScript/configure-after-start.sh

# Keep container running
echo "[5/5] Keeping container alive..."
tail -f /dev/null  # or another way to keep the container alive