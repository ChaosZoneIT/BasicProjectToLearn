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