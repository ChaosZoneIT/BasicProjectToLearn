#!/bin/bash

# Define the home directory of the logged-in user
USER_HOME=$(eval echo ~$USER)

# Default key name
DEFAULT_KEY_NAME="${USER}-rsa-key"

# If a key name is provided as a parameter, use it; otherwise, use the default name
KEY_NAME="${1:-$DEFAULT_KEY_NAME}"

# Define the file path for the SSH key (it will be saved in the user's .ssh directory)
KEY_PATH="$USER_HOME/.ssh/$KEY_NAME"

# Check if the .ssh directory exists; if not, create it
if [ ! -d "$USER_HOME/.ssh" ]; then
  mkdir -p "$USER_HOME/.ssh"
  chmod 700 "$USER_HOME/.ssh"
  echo "Created .ssh directory for $USER"
fi

# Generate an SSH key pair (private and public)
# -t specifies the key type (RSA)
# -b specifies the key size (4096 bits)
# -f specifies the file where the key will be saved
# -N specifies an empty passphrase (no password)
# -q suppresses output (runs quietly)
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -q

# Set correct permissions for the private key
chmod 600 "$KEY_PATH"

# Inform the user where the key was saved
echo "SSH key for user $USER has been generated at: $KEY_PATH"
echo "Public key: $KEY_PATH.pub"
