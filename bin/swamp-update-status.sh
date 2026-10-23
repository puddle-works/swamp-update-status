#!/bin/sh
# Run from a Claude Code SessionStart hook. Updates swamp, prints the result,
# and records it in the state file that the status line reads.
#
# Environment:
#   SWAMP_UPDATE_STATUS_FILE  state file (default ~/.claude/.swamp-version)
#   SWAMP_UPDATE_UPGRADE_REPO set to 1 to run `swamp repo upgrade` in the current
#                             directory after a successful update (default off)
set -u

state="${SWAMP_UPDATE_STATUS_FILE:-$HOME/.claude/.swamp-version}"

out=$(swamp update 2>&1 || true)
printf '%s\n' "$out"

mkdir -p "$(dirname "$state")"
printf '%s\n' "$out" > "$state"

if [ "${SWAMP_UPDATE_UPGRADE_REPO:-0}" = 1 ] && printf '%s\n' "$out" | grep -q 'updated successfully'; then
  swamp repo upgrade --json 2>&1 || true
fi

exit 0
