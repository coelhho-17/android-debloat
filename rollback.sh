#!/bin/bash
# Rollback script for Android debloat (no root).
# Reinstalls every removed package and re-enables every disabled one.
#
# Usage:  ./rollback.sh [path-to-adb]
#   If no path is given, it uses `adb` from PATH.
#
# Fill the two lists below with the packages you removed / disabled.
# Generate them from your own run; this file is a template.

ADB="${1:-$(command -v adb)}"
[ -z "$ADB" ] && { echo "adb not found"; exit 1; }

# Packages that were removed with `pm uninstall --user 0`.
REMOVED=(
  # com.example.bloat1
  # com.example.bloat2
)

# Packages that were disabled with `pm disable-user --user 0`.
DISABLED=(
  # com.example.bloat3
)

for p in "${REMOVED[@]}"; do
  [ -z "$p" ] && continue
  echo "restoring: $p"
  "$ADB" shell pm install-existing "$p" < /dev/null
done

for p in "${DISABLED[@]}"; do
  [ -z "$p" ] && continue
  echo "enabling: $p"
  "$ADB" shell pm enable "$p" < /dev/null
done

echo "Rollback done."
