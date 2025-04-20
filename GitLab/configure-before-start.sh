#!/bin/bash

# [2.1] Running configuration scripts
echo "[2.1] Running init scripts..."

for script in "$CONFIGURE_BEFORE_START"/*.sh; do
  script_name="$(basename "$script")"
  
  if [ -f "$CONFIGURE_BEFORE_START_DONE/$script_name" ]; then
    echo "[2.1.1] [SKIP] Already executed: $script_name"
    continue
  fi

  echo "[2.1.1] Executing: $script_name"
  if bash "$script"; then
    cp "$script" "$CONFIGURE_BEFORE_START_DONE/"
    echo "[2.1.2] [SUCCESS] $script_name executed successfully"
  else
    echo "[2.1.2] [FAIL] $script_name failed"
    exit 1
  fi
done

# [2.2] Final confirmation
echo "[2.2] All init scripts executed successfully."