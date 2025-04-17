#!/bin/bash

# Changes introduced in Redis-based settings: 
# Since GitLab version 14, some configuration options are stored in the database 
# and are no longer respected from gitlab.rb at startup.

# Disabling user registration – only admin can create employee accounts
# signup_enabled: false

# Configure GitLab default application settings:
# - Disable user signup

# Use single quotes (' ') instead of double quotes (" ") 
# to prevent Bash from interpreting ! as a history expansion trigger.
echo "[CONFIGURE] Disabling signup"

gitlab-rails runner 'ApplicationSetting.current.update!(
  signup_enabled: false
)'

# Alternative: temporarily disable history expansion in Bash,
# which allows the use of double quotes and exclamation marks (!) inside the string.
# set +H
# gitlab-rails runner "ApplicationSetting.current.update!(...)"

# Yet another approach: use a here-document for better readability and multiline code.
# gitlab-rails runner <<'EOF'
# ApplicationSetting.current.update!(
#   signup_enabled: false
# )
# EOF

