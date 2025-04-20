#!/bin/bash

# [4.1] Wait for GitLab to be fully up
echo "[4.1] Waiting for GitLab to be fully up..."
# Wait for Sidekiq and Web interface to indicate system is ready
until gitlab-ctl status | grep -q "run: sidekiq:"; do
  echo "[4.1.1] [WAITING] Waiting for Sidekiq..."
  sleep 5
done

# Wait for avalible port 443 
until nc -z localhost 443; do
  echo "[4.1.2] [WAITING] Waiting for GitLab port 443 to be open..."
  sleep 3
done

# Wait for HTTP 200 from login page
until [ "$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/users/sign_in)" == "200" ]; do
  echo "[4.1.3] [WAITING] Waiting for GitLab web interface to be ready..."
  sleep 5
done

# It is risk, because http server can diferent response about status (nginx can HTTP/2 200 or lasted HTTP/1.1 200 OK)
# until curl -k -s --head https://localhost/users/sign_in | grep "200 OK" > /dev/null; do
#   echo "Waiting for GitLab web interface (HTTPS)..."
#   sleep 5
# done

echo "[4.1] [OK] GitLab is ready."


# [4.2] Running configuration scripts
echo "[4.2] Running init scripts..."

for script in "$CONFIGURE_AFTER_START"/*.sh; do
  script_name="$(basename "$script")"
  
  if [ -f "$CONFIGURE_AFTER_START_DONE/$script_name" ]; then
    echo "[4.2.1] [SKIP] Already executed: $script_name"
    continue
  fi

  echo "[4.2.1] Executing: $script_name"
  if bash "$script"; then
    cp "$script" "$CONFIGURE_AFTER_START_DONE/"
    echo "[4.2.1.1] [SUCCESS] $script_name executed successfully"
  else
    echo "[4.2.2.1] [FAIL] $script_name failed"
    exit 1
  fi
done

# [4.3] Final confirmation
echo "[4.3] All init scripts executed successfully."