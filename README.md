# swamp-update-status

Keeps [swamp](https://swamp.club) up to date at the start of each Claude Code session, and shows the result in the Claude Code status line.

## What it does

`bin/swamp-update-status.sh`:

1. Runs `swamp update` and prints the output into the session.
2. Saves the output to `~/.claude/.swamp-version`, which the status line reads.
3. Optionally runs `swamp repo upgrade --json` in the current directory, but only when the update succeeded and you have opted in (see below).

A failed update never breaks session start.

## Setup

Clone the repo somewhere stable, for example `~/dev/swamp-update-status`.

### 1. Session-start hook

Add this to `~/.claude/settings.json`, or to a repo's `.claude/settings.json` to share it with that repo's clones:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "sh ~/dev/swamp-update-status/bin/swamp-update-status.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

### 2. Status line segment

The status line runs as a script configured with `statusLine` in `settings.json`. Add the swamp segment to it. Add this near the top of the script, before the output is built:

```sh
swamp_ver=""
if [ -f ~/.claude/.swamp-version ]; then
  swamp_ver=$(tr -d '\n' < ~/.claude/.swamp-version | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
fi
```

Then pass it into `jq` with `--arg swamp "$swamp_ver"`, and add this as the last element of the array that gets joined with ` | `:

```jq
(if $swamp != "" then "🐊 SC \($swamp)" else empty end)
```

If you don't use a `jq` status line, the segment is just the contents of `~/.claude/.swamp-version`.

### Upgrading repos (opt-in)

By default the script only updates swamp. To also run `swamp repo upgrade` in the session's directory after a successful update, set `SWAMP_UPDATE_UPGRADE_REPO=1` in the hook command:

```json
"command": "SWAMP_UPDATE_UPGRADE_REPO=1 sh ~/dev/swamp-update-status/bin/swamp-update-status.sh"
```

Only turn this on if you're happy for a swamp repo to be upgraded at the start of a session.

### Environment

| Variable | Default | Purpose |
|---|---|---|
| `SWAMP_UPDATE_STATUS_FILE` | `~/.claude/.swamp-version` | Where the output is saved |
| `SWAMP_UPDATE_UPGRADE_REPO` | `0` | Set to `1` to run `swamp repo upgrade` after a successful update |

## Tests

```sh
sh test/update_test.sh
```

The tests use a fake `swamp` on `PATH`, so they don't touch your installation.
