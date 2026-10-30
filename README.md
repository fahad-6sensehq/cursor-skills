# Cursor Skills

Cursor plugin of engineering workflow skills: Jira task breakdown, pull requests, code review, and system design.

## Skills

| Skill | Use when |
| --- | --- |
| `jira-task` | Breaking a Jira story into subtasks with a fixed 1, 2, or 3 point scale |
| `create-pr` | Opening or updating a pull request (Conventional Commits, Jira key, 200-line budget, stack work report) |
| `code-review` | Reviewing a diff or pull request and returning severity-ranked findings |
| `system-design` | Writing a design doc with one recommended approach, interfaces, and tradeoffs |

## Layout

```
cursor-skills/
├── .cursor-plugin/
│   ├── marketplace.json
│   └── plugin.json
├── skills/
│   ├── jira-task/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── create-pr/
│   │   ├── SKILL.md
│   │   └── examples.md
│   ├── code-review/SKILL.md
│   └── system-design/SKILL.md
└── README.md
```

`.cursor-plugin/marketplace.json` indexes this repo as one plugin. `.cursor-plugin/plugin.json` is that plugin. Skills are discovered from `skills/`.

## Install

Install the skills globally so every project on that machine can use them. Requires Node.js 22.20 or newer.

```bash
npx skills add fahad-6sensehq/cursor-skills -g -a cursor -y
```

Skills land in `~/.agents/skills/`. This command does not install the auto-update hook below. Each person adds that hook once.

To list this repo in the Cursor Marketplace, submit the public repository at [cursor.com/marketplace/publish](https://cursor.com/marketplace/publish).

## Auto-update hook

The hook checks GitHub and copies newer skills into the global install. It runs at most once every 24 hours, in the background, on three events:

| Hook | When it runs |
| --- | --- |
| `workspaceOpen` | Cursor opens a workspace. Covers people who quit the app. |
| `sessionStart` | A new agent chat starts. Covers people who leave Cursor open and start a new chat. |
| `beforeSubmitPrompt` | The user sends a prompt. Covers people who leave Cursor open and keep using an existing chat. |

The prompt is not blocked. The chat that triggers the update still has the skill text it loaded at the start. A **new chat** uses the updated files.

Log file: `~/.cursor/hooks/update-skills.log`

After saving `hooks.json`, reload the window (**Developer: Reload Window**).

### macOS and Linux

User hooks live in the home directory and run from `~/.cursor/`.

`~/.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "workspaceOpen": [
      { "command": "./hooks/update-skills.sh", "timeout": 15 }
    ],
    "sessionStart": [
      { "command": "./hooks/update-skills.sh", "timeout": 15 }
    ],
    "beforeSubmitPrompt": [
      { "command": "./hooks/update-skills.sh", "timeout": 15 }
    ]
  }
}
```

`~/.cursor/hooks/update-skills.sh`:

```bash
#!/bin/bash
input=$(cat)
event=$(printf '%s' "$input" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

log="$HOME/.cursor/hooks/update-skills.log"
stamp="$HOME/.cursor/hooks/.skills-update-stamp"
lockdir="$HOME/.cursor/hooks/.skills-update-lock"
now=$(date +%s)

finish() {
  if [ "$event" = "beforeSubmitPrompt" ]; then
    printf '%s\n' '{"continue":true}'
  else
    printf '%s\n' '{}'
  fi
  exit 0
}

if [ -f "$stamp" ] && [ $((now - $(cat "$stamp"))) -lt 86400 ]; then
  finish
fi

if ! mkdir "$lockdir" 2>/dev/null; then
  finish
fi

echo "$now" > "$stamp"

node_bin=""
if [ -d "$HOME/.nvm/versions/node" ]; then
  node_bin=$(ls -d "$HOME/.nvm/versions/node/"*/bin 2>/dev/null | tail -1)
fi
fnm_bin="$HOME/.local/share/fnm/aliases/default/bin"

(
  export PATH="${node_bin:+$node_bin:}${fnm_bin:+$fnm_bin:}/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
  {
    echo "---- $(date) ----"
    npx --yes skills update -g -y
    echo "exit $?"
  } >> "$log" 2>&1
  rmdir "$lockdir" 2>/dev/null || true
) >/dev/null 2>&1 &

finish
```

Make it executable:

```bash
chmod +x ~/.cursor/hooks/update-skills.sh
```

On macOS, Node installed with nvm or Homebrew is on that `PATH`. On Linux, the script also checks nvm and fnm. A system Node in `/usr/local/bin` or `/usr/bin` works with no extra path.

### Windows

Cursor runs user hooks with PowerShell. Paths use `%USERPROFILE%\.cursor\`.

`%USERPROFILE%\.cursor\hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "workspaceOpen": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/update-skills.ps1",
        "timeout": 15
      }
    ],
    "sessionStart": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/update-skills.ps1",
        "timeout": 15
      }
    ],
    "beforeSubmitPrompt": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/update-skills.ps1",
        "timeout": 15
      }
    ]
  }
}
```

`%USERPROFILE%\.cursor\hooks\update-skills.ps1`:

```powershell
$ErrorActionPreference = "Continue"
$raw = [Console]::In.ReadToEnd()
$event = ""
if ($raw -match '"hook_event_name"\s*:\s*"([^"]+)"') {
  $event = $Matches[1]
}

$hookDir = Join-Path $env:USERPROFILE ".cursor\hooks"
$log = Join-Path $hookDir "update-skills.log"
$stamp = Join-Path $hookDir ".skills-update-stamp"
$lock = Join-Path $hookDir ".skills-update-lock"
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null

function Finish {
  if ($event -eq "beforeSubmitPrompt") {
    Write-Output '{"continue":true}'
  } else {
    Write-Output "{}"
  }
  exit 0
}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
if (Test-Path $stamp) {
  $age = $now - [int64](Get-Content $stamp -Raw).Trim()
  if ($age -lt 86400) { Finish }
}

if (Test-Path $lock) { Finish }
New-Item -ItemType Directory -Path $lock | Out-Null
Set-Content -Path $stamp -Value $now -NoNewline

$nodeDirs = @(
  "$env:ProgramFiles\nodejs",
  "$env:LOCALAPPDATA\fnm",
  "$env:APPDATA\nvm"
) | Where-Object { $_ -and (Test-Path $_) }
$pathPrefix = ($nodeDirs -join ";")

$runner = @"
`$env:PATH = '$pathPrefix;' + `$env:PATH
'---- ' + (Get-Date) + ' ----' | Out-File -Append -Encoding utf8 '$log'
npx --yes skills update -g -y *>> '$log'
'exit ' + `$LASTEXITCODE | Out-File -Append -Encoding utf8 '$log'
Remove-Item -Recurse -Force '$lock' -ErrorAction SilentlyContinue
"@

Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $runner
) | Out-Null

Finish
```

Node from the official Windows installer is picked up from `Program Files\nodejs`. fnm and nvm-windows are included when those folders exist. `npx` must be on that `PATH`.
