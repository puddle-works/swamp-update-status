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

### 2. Status line

`statusline/statusline.sh` is the full Claude Code status line. It shows the model, context and rate-limit usage, and the swamp version from `~/.claude/.swamp-version` as its last segment. It needs `jq`.

If you don't already have a status line, install it:

```sh
cp ~/dev/swamp-update-status/statusline/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

Then add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

If you already have a status line, back up your script first and merge in only the swamp segment. It's the `swamp_ver` block at the top, and the `🐊 SC` entry at the end of the `jq` array.

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
