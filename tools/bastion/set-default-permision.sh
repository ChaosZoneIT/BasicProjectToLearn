#!/bin/bash

# Paths to target directories
ANSIBLE_DIR="storage/a_bastion/ansible"
SSCRIPTS_DIR="storage/a_bastion/scripts"

# Auto-elevate privileges if not running as root
if [[ "$EUID" -ne 0 ]]; then
  echo "🔒 This script needs to be run as root. Restarting with sudo..."
  exec sudo "$0" "$@"
fi

# Check if directories exist before applying permissions
if [ -d "$ANSIBLE_DIR" ]; then
  chmod a+rw "$ANSIBLE_DIR"
  echo "✅ Permissions set: a+rw on $ANSIBLE_DIR"
else
  echo "⚠️ Directory not found: $ANSIBLE_DIR"
fi

if [ -d "$SSCRIPTS_DIR" ]; then
  chmod a+rw "$SSCRIPTS_DIR"
  echo "✅ Permissions set: a+rw on $SSCRIPTS_DIR"
else
  echo "⚠️ Directory not found: $SSCRIPTS_DIR"
fi
