#!/bin/bash

# [3.1] Wait for GitLab to be fully up
echo "[3.1] Waiting for GitLab to be fully up..."
# Wait for Sidekiq and Web interface to indicate system is ready
until gitlab-ctl status | grep -q "run: sidekiq:"; do
  echo "[3.1.1] [WAITING] Waiting for Sidekiq..."
  sleep 5
done

# Wait for avalible port 443 
until nc -z localhost 443; do
  echo "[3.1.2] [WAITING] Waiting for GitLab port 443 to be open..."
  sleep 3
done

# Wait for HTTP 200 from login page
until [ "$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost/users/sign_in)" == "200" ]; do
  echo "[3.1.3] [WAITING] Waiting for GitLab web interface to be ready..."
  sleep 5
done

# It is risk, because http server can diferent response about status (nginx can HTTP/2 200 or lasted HTTP/1.1 200 OK)
# until curl -k -s --head https://localhost/users/sign_in | grep "200 OK" > /dev/null; do
#   echo "Waiting for GitLab web interface (HTTPS)..."
#   sleep 5
# done

echo "[3.1] [OK] GitLab is ready."


# [3.2] Running configuration scripts
echo "[3.2] Running init scripts..."

for script in "$CONFIGURE_SCRIPTS_TO_EXECUTE"/*.sh; do
  script_name="$(basename "$script")"
  
  if [ -f "$CONFIGURE_SCRIPTS_TO_DONE/$script_name" ]; then
    echo "[3.2.1] [SKIP] Already executed: $script_name"
    continue
  fi

  echo "[3.2.1] Executing: $script_name"
  if bash "$script"; then
    cp "$script" "$CONFIGURE_SCRIPTS_TO_DONE/"
    echo "[3.2.2] [SUCCESS] $script_name executed successfully"
  else
    echo "[3.2.2] [FAIL] $script_name failed"
    exit 1
  fi
done

# [3.3] Final confirmation
echo "[3.3] All init scripts executed successfully."