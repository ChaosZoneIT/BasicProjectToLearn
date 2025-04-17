#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Start GitLab services
/opt/gitlab/embedded/bin/runsvdir-start &

# Restore GitLab configuration if needed
echo "[1/4] Restoring GitLab configuration file..."
cp /tmp/gitlab.rb /etc/gitlab/gitlab.rb

# Reconfigure GitLab
echo "[2/4] Running gitlab-ctl reconfigure..."
gitlab-ctl reconfigure


# Run additional configuration scripts
echo "[3/4] Running init scripts..."
bash /startScript/init.scripts.sh

# Keep container running
echo "[4/4] Keeping container alive..."
tail -f /dev/null  # or another way to keep the container alive