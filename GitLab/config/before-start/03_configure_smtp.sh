#!/bin/bash
set -e

GITLAB_CONFIG="/etc/gitlab/gitlab.rb"
SMTP_CONFIG_FILE="$(dirname "$0")/03_configure_smtp/smtp-mailhog.conf"

# Load configuration from .conf file
if [[ -f "$SMTP_CONFIG_FILE" ]]; then
  source "$SMTP_CONFIG_FILE"
else
  echo "[ERROR] Configuration file not found: $SMTP_CONFIG_FILE"
  exit 1
fi

# Reference marker to locate the SMTP section
MARKER="# SMTP settings"
INSERT_BELOW_LINE=$(grep -n "$MARKER" "$GITLAB_CONFIG" | cut -d: -f1)

# If marker is not found, append it at the end of the file
if [[ -z "$INSERT_BELOW_LINE" ]]; then
  INSERT_BELOW_LINE=$(wc -l < "$GITLAB_CONFIG")
  echo -e "\n# SMTP settings" >> "$GITLAB_CONFIG"
  ((INSERT_BELOW_LINE++))
fi

# Function to update, uncomment or insert a config line
update_or_insert() {
  local key="$1"
  local value="$2"
  local type="${3:-string}"  # string or bool

  local formatted_value
  if [[ "$type" == "bool" ]]; then
    formatted_value="$value"
  else
    formatted_value="\"$value\""
  fi

  local escaped_key=$(echo "$key" | sed 's/[]\/$*.^[]/\\&/g')

  # If the line exists (commented or uncommented), replace it
  if grep -qE "^[# ]*$escaped_key" "$GITLAB_CONFIG"; then
    sed -i "s|^[# ]*$escaped_key.*|$key $formatted_value|" "$GITLAB_CONFIG"
  else
    # Otherwise insert the line near the marker
    sed -i "${INSERT_BELOW_LINE}a$key $formatted_value" "$GITLAB_CONFIG"
  fi
  # Prevent the script from continuing until all file changes are fully flushed to disk.
  sync
}

# Apply all SMTP settings
update_or_insert "gitlab_rails['smtp_enable'] =" "true" "bool"
update_or_insert "gitlab_rails['smtp_address'] =" "$SMTP_ADDRESS"
update_or_insert "gitlab_rails['smtp_port'] =" "$SMTP_PORT"
update_or_insert "gitlab_rails['smtp_user_name'] =" "$SMTP_USER"
update_or_insert "gitlab_rails['smtp_password'] =" "$SMTP_PASSWORD"
update_or_insert "gitlab_rails['smtp_domain'] =" "$SMTP_DOMAIN"
update_or_insert "gitlab_rails['smtp_authentication'] =" "$SMTP_AUTH"
update_or_insert "gitlab_rails['smtp_enable_starttls_auto'] =" "$SMTP_TLS" "bool"
update_or_insert "gitlab_rails['gitlab_email_from'] =" "$SMTP_FROM"
update_or_insert "gitlab_rails['gitlab_email_display_name'] =" "$SMTP_DISPLAY_NAME"
update_or_insert "gitlab_rails['gitlab_email_reply_to'] =" "$SMTP_EMAIL_REPLY_TO"

echo "[OK] SMTP configuration updated successfully."
