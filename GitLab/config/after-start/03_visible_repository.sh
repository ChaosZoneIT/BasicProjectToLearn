#!/bin/bash

# Changes introduced in Redis-based settings: 
# Since GitLab version 14, some configuration options are stored in the database 
# and are no longer respected from gitlab.rb at startup.

# default_project_visibility: 
# 0 – private, 
# 10 – internal (visible to all signed-in users), 
# 20 – public (visible to everyone)

# Public repositories cannot be created. Internal projects are still allowed 
# (visible to logged-in users only). 
# restricted_visibility_levels: [20] blocks public visibility.

# Configure GitLab default application settings:
# - Set default project visibility to private
# - Block public project creation

# Use single quotes (' ') instead of double quotes (" ") 
# to prevent Bash from interpreting ! as a history expansion trigger.
echo "[CONFIGURE] Configuring visibility repository..."

gitlab-rails runner 'ApplicationSetting.current.update!(
  default_project_visibility: 0,
  restricted_visibility_levels: [20]
)'

# Alternative: temporarily disable history expansion in Bash,
# which allows the use of double quotes and exclamation marks (!) inside the string.
# set +H
# gitlab-rails runner "ApplicationSetting.current.update!(...)"

# Yet another approach: use a here-document for better readability and multiline code.
# gitlab-rails runner <<'EOF'
# ApplicationSetting.current.update!(
#   default_project_visibility: 0,
#   restricted_visibility_levels: [20]
# )
# EOF

