#!/bin/bash

# Changes introduced in Redis-based settings: 
# Since GitLab version 14, some configuration options are stored in the database 
# and are no longer respected from gitlab.rb at startup.

# When the administrator creates an account, the user must confirm it via email 
# before accessing GitLab. 
# email_confirmation_setting: 2 
# (0 – no email sent, account is active; 
#  1 – email sent, account is active anyway; 
#  2 – email sent, account must be confirmed)

# Configure GitLab default application settings:
# - Require email confirmation

# Use single quotes (' ') instead of double quotes (" ") 
# to prevent Bash from interpreting ! as a history expansion trigger.
echo "[CONFIGURE] Required confirm email after creating account..."

gitlab-rails runner 'ApplicationSetting.current.update!(
  email_confirmation_setting: 2
)'

# Alternative: temporarily disable history expansion in Bash,
# which allows the use of double quotes and exclamation marks (!) inside the string.
# set +H
# gitlab-rails runner "ApplicationSetting.current.update!(...)"

# Yet another approach: use a here-document for better readability and multiline code.
# gitlab-rails runner <<'EOF'
# ApplicationSetting.current.update!(
#   email_confirmation_setting: 2
# )
# EOF

