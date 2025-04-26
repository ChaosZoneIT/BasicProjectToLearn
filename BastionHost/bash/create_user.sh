#!/bin/bash

# Check if username is passed as a parameter
if [ -z "$1" ]; then
    echo "ERROR: User name is required as the first parameter."
    exit 1
fi

# Set user name and password (password defaults to username if not provided)
USER_NAME=$1
USER_PASSWORD=${2:-$USER_NAME}

# Define the sshd_config file path as a variable
SSHD_CONFIG_PATH="/etc/ssh/sshd_config"

# Create the user with the specified name and password
echo "Creating user $USER_NAME with password $USER_PASSWORD"
useradd -m -s /bin/bash "$USER_NAME"
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Add user to sudoers file with NOPASSWD:ALL permission
echo "Granting $USER_NAME sudo privileges without password"
echo "$USER_NAME ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"

# Set proper permissions for the sudoers file
chmod 0440 "/etc/sudoers.d/$USER_NAME"

# Update SSH configuration to allow the user to log in
echo "Configuring SSH to allow $USER_NAME to login"
if grep -q '^AllowUsers' "$SSHD_CONFIG_PATH"; then
    # If AllowUsers already exists, add the new user to the list
    grep -q "\<$USER_NAME\>" "$SSHD_CONFIG_PATH" || \
    sed -i "/^AllowUsers/ s/$/ $USER_NAME/" "$SSHD_CONFIG_PATH"
else
    # If AllowUsers does not exist, create it with the new user
    echo "AllowUsers $USER_NAME" >> "$SSHD_CONFIG_PATH"
fi

# Restart SSH service to apply changes (if necessary)
# echo "Restarting SSH service to apply the new configuration"
# systemctl restart sshd
kill $(pgrep -f '/usr/sbin/sshd')
/usr/sbin/sshd

echo "User $USER_NAME created successfully with sudo privileges and SSH access."