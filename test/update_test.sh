#!/bin/sh
# Tests for bin/swamp-update-status.sh. A fake `swamp` on PATH stands in for the real CLI.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
script="$root/bin/swamp-update-status.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fakebin="$tmp/bin"
mkdir -p "$fakebin"
calls="$tmp/calls"

cat > "$fakebin/swamp" <<FAKE
#!/bin/sh
echo "\$*" >> "$calls"
case "\$1" in
  update) echo "\${FAKE_UPDATE_OUT:-swamp is up to date (20261023.144040.0-sha.61d1aa5f)}" ;;
  repo) echo '{"ok":true}' ;;
esac
FAKE
chmod +x "$fakebin/swamp"

fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Prints the update output and records it in the state file.
state="$tmp/state/swamp-version"
out=$(PATH="$fakebin:$PATH" SWAMP_UPDATE_STATUS_FILE="$state" sh "$script")
case "$out" in *"up to date"*) ;; *) fail "output not printed: $out" ;; esac
[ -f "$state" ] || fail "state file not written"
grep -q "up to date" "$state" || fail "state file missing update output"

# 2. Does not run `repo upgrade` by default.
rm -f "$calls"
PATH="$fakebin:$PATH" SWAMP_UPDATE_STATUS_FILE="$state" sh "$script" >/dev/null
if [ -f "$calls" ] && grep -q "^repo" "$calls"; then fail "repo upgrade ran without opt-in"; fi

# 3. Runs `repo upgrade` after a successful update when opted in.
rm -f "$calls"
PATH="$fakebin:$PATH" SWAMP_UPDATE_STATUS_FILE="$state" SWAMP_UPDATE_UPGRADE_REPO=1 \
  FAKE_UPDATE_OUT="swamp updated successfully to 20261024" sh "$script" >/dev/null
grep -q "^repo upgrade --json" "$calls" || fail "repo upgrade not run after successful update"

# 4. Does not run `repo upgrade` when opted in but the update did not succeed.
rm -f "$calls"
PATH="$fakebin:$PATH" SWAMP_UPDATE_STATUS_FILE="$state" SWAMP_UPDATE_UPGRADE_REPO=1 sh "$script" >/dev/null
if grep -q "^repo" "$calls"; then fail "repo upgrade ran without a successful update"; fi

# 5. A failing `swamp update` does not fail the script (session start must not break).
cat > "$fakebin/swamp" <<'FAKE'
#!/bin/sh
echo "network down" >&2
exit 1
FAKE
PATH="$fakebin:$PATH" SWAMP_UPDATE_STATUS_FILE="$state" sh "$script" >/dev/null 2>&1 || fail "script exited non-zero on swamp failure"

echo "all update tests passed"
