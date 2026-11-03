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

## Auto-update hook

The update hook checks GitHub and copies newer skills into the global install. It also reports the signed-in Cursor user's email to the skills usage endpoint. A second hook reports which skill the agent actually loaded (see [Usage tracking](#usage-tracking)). The update runs at most once every 24 hours, in the background, on three events:

| Hook | When it runs |
| --- | --- |
| `workspaceOpen` | Cursor opens a workspace. Covers people who quit the app. |
| `sessionStart` | A new agent chat starts. Covers people who leave Cursor open and start a new chat. |
| `beforeSubmitPrompt` | The user sends a prompt. Covers people who leave Cursor open and keep using an existing chat. |

The prompt is not blocked. The chat that triggers the update still has the skill text it loaded at the start. A **new chat** uses the updated files.

Log file: `~/.cursor/hooks/update-skills.log`

After saving `hooks.json`, reload the window (**Developer: Reload Window**).

### Usage tracking

Cursor passes the signed-in user's email to every hook as `user_email` in the JSON on stdin. The two hooks report different facts. Neither one sends the prompt or the file contents.

| Report | Hook | What it tells you |
| --- | --- | --- |
| Installed | `update-skills.sh`, at most once every 24 hours | This person has the hook installed. It does not say which skill they used. All four skills install together. |
| Used | `track-skill-usage.sh`, when the user sends `/skill-name` or the agent reads that skill's files | Which installed skill from `fahad-6sensehq/cursor-skills` was loaded. The same skill is sent at most once every 24 hours. |

```bash
curl --request POST \
  --url https://example.com/skill \
  --header 'content-type: application/json' \
  --data '{"email":"user@example.com","time":"2026-11-02T07:00:00Z","skill":"jira-task"}'
```

| Field | Value |
| --- | --- |
| `email` | `user_email` from the hook input |
| `time` | Current time in UTC, ISO 8601 |
| `skill` | On the used report only. The skill directory name from `~/.agents/.skill-lock.json` whose source is `fahad-6sensehq/cursor-skills`. |

Notes:

- If the user is not signed in to Cursor, `user_email` is empty and no request is sent.
- `/jira-task` does not read `SKILL.md`. Cursor pastes the skill into the prompt, so `beforeSubmitPrompt` reads the command name. A file read is still reported from `beforeReadFile`.
- A command or read is ignored unless that skill is installed from `fahad-6sensehq/cursor-skills`. After `update-skills.sh` installs a new skill, the next `/skill-name` is reported. No hook edit is required. Skills from other repos are ignored. The hook script itself is not updated by `npx skills update`.
- The request runs in the background with a 10-second timeout. A failure never blocks Cursor and is written to the log file.
- Use the same endpoint in both scripts. Replace `https://example.com/skill` with that endpoint.
- The endpoint has to store `skill`. A handler that only saves the last timestamp will return success and still not show which skill was used.
- Anyone who installs these hooks is sending their email, and the skill name when they use one, to that endpoint. Tell your users.

### macOS and Linux

User hooks live in the home directory and run from `~/.cursor/`.

Create the directory and empty files, then paste the contents below into each file:

```bash
mkdir -p ~/.cursor/hooks
touch ~/.cursor/hooks.json \
  ~/.cursor/hooks/update-skills.sh \
  ~/.cursor/hooks/track-skill-usage.sh
```

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
      { "command": "./hooks/update-skills.sh", "timeout": 15 },
      { "command": "./hooks/track-skill-usage.sh", "timeout": 10 }
    ],
    "beforeReadFile": [
      { "command": "./hooks/track-skill-usage.sh", "timeout": 10, "matcher": "Read" }
    ]
  }
}
```

`~/.cursor/hooks/update-skills.sh`:

```bash
#!/bin/bash
input=$(cat)
event=$(printf '%s' "$input" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
email=$(printf '%s' "$input" | sed -n 's/.*"user_email"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

api_url="https://ops4-api.6sensehq.com/users/last-skill-usage"
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

if [ -f "$stamp" ] && [ $((now - $(cat "$stamp"))) -lt 43200 ]; then
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

    if [ -n "$email" ]; then
      curl --silent --show-error --max-time 10 --request POST \
        --url "$api_url" \
        --header 'content-type: application/json' \
        --data "{\"email\":\"$email\",\"time\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
      echo "ping exit $?"
    else
      echo "ping skipped: no user_email"
    fi

    npx --yes skills update -g -y
    echo "exit $?"
  } >> "$log" 2>&1
  rmdir "$lockdir" 2>/dev/null || true
) >/dev/null 2>&1 &

finish
```

Make it executable:

`~/.cursor/hooks/track-skill-usage.sh`:

```bash
#!/bin/bash
# Reports a skill from fahad-6sensehq/cursor-skills when the agent loads it.
# A slash command such as /jira-task does not read SKILL.md, so this also
# checks the prompt and attachments. Names come from ~/.agents/.skill-lock.json.
# Sends email, skill name, and time only. Never sends file contents or the prompt.
input=$(cat)

py=""
if [ -x /usr/bin/python3 ]; then
  py=/usr/bin/python3
elif command -v python3 >/dev/null 2>&1; then
  py=$(command -v python3)
fi

parsed=""
if [ -n "$py" ]; then
  parsed=$(printf '%s' "$input" | "$py" -c '
import json, os, re, sys
from datetime import datetime, timezone
try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)
event = data.get("hook_event_name") or ""
if event == "beforeSubmitPrompt":
    sys.stdout.write("{\"continue\":true}\n")
else:
    sys.stdout.write("{\"permission\":\"allow\"}\n")
email = data.get("user_email") or ""
source = "fahad-6sensehq/cursor-skills"
lock_path = os.path.join(os.path.expanduser("~"), ".agents", ".skill-lock.json")
allowed = set()
lock_read = False
try:
    with open(lock_path) as f:
        lock = json.load(f)
    lock_read = True
    for skill_name, meta in (lock.get("skills") or {}).items():
        if not isinstance(meta, dict):
            continue
        if not re.fullmatch(r"[A-Za-z0-9._-]+", skill_name):
            continue
        src = meta.get("source") or ""
        url = meta.get("sourceUrl") or ""
        if src == source or source in url:
            allowed.add(skill_name)
except Exception:
    lock_read = False
if not lock_read:
    allowed = {"jira-task", "create-pr", "code-review", "system-design"}

def add_path(path, found):
    path = re.sub(r"/+", "/", (path or "").replace("\\", "/"))
    marker = "/skills/"
    idx = path.rfind(marker)
    if idx == -1:
        return
    name = path[idx + len(marker):].split("/", 1)[0]
    if re.fullmatch(r"[A-Za-z0-9._-]+", name or ""):
        found.add(name)

found = set()
add_path(data.get("file_path"), found)
for att in data.get("attachments") or []:
    if isinstance(att, dict):
        add_path(att.get("file_path"), found)
prompt = data.get("prompt") or ""
for match in re.finditer(r"(?:^|[^A-Za-z0-9._-])/([A-Za-z0-9._-]+)", prompt):
    found.add(match.group(1))
for match in re.finditer(r"/skills/([A-Za-z0-9._-]+)", prompt.replace("\\", "/")):
    found.add(match.group(1))

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
for name in sorted(found):
    if name not in allowed:
        continue
    if not email:
        sys.stdout.write(name + "\nNO_EMAIL\n")
        continue
    body = json.dumps({"email": email, "time": now, "skill": name})
    sys.stdout.write(name + "\n" + body + "\n")
')
fi
log="$HOME/.cursor/hooks/update-skills.log"
hookdir="$HOME/.cursor/hooks"
mkdir -p "$hookdir"

if [ -z "$parsed" ]; then
  if printf '%s' "$input" | grep -q 'beforeSubmitPrompt'; then
    printf '%s\n' '{"continue":true}'
  else
    printf '%s\n' '{"permission":"allow"}'
  fi
  unset input
  if [ -z "$py" ]; then
    echo "---- $(date) skill ping skipped: no python3 ----" >> "$log"
  fi
  exit 0
fi
unset input

response=$(printf '%s\n' "$parsed" | sed -n '1p')
printf '%s\n' "$response"
rest=$(printf '%s\n' "$parsed" | tail -n +2)

api_url="https://ops4-api.6sensehq.com/users/last-skill-usage"
now=$(date +%s)
while IFS= read -r skill; do
  [ -z "$skill" ] && continue
  IFS= read -r body || break
  case "$skill" in
    ""|*[!A-Za-z0-9._-]*) continue ;;
  esac
  if [ "$body" = "NO_EMAIL" ]; then
    echo "---- $(date) skill=$skill ping skipped: no user_email ----" >> "$log"
    continue
  fi
  stamp="$hookdir/.skill-use-$skill"
  if [ -f "$stamp" ] && [ $((now - $(cat "$stamp"))) -lt 86400 ]; then
    continue
  fi
  echo "$now" > "$stamp"
  (
    node_bin=""
    if [ -d "$HOME/.nvm/versions/node" ]; then
      node_bin=$(ls -d "$HOME/.nvm/versions/node/"*/bin 2>/dev/null | tail -1)
    fi
    fnm_bin="$HOME/.local/share/fnm/aliases/default/bin"
    export PATH="${node_bin:+$node_bin:}${fnm_bin:+$fnm_bin:}/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
    {
      echo "---- $(date) skill=$skill ----"
      curl --silent --show-error --max-time 10 --request POST \
        --url "$api_url" \
        --header 'content-type: application/json' \
        --data "$body"
      echo
      echo "skill ping exit $?"
    } >> "$log" 2>&1
  ) >/dev/null 2>&1 &
done <<EOF
$rest
EOF

exit 0
```

Make both scripts executable:

```bash
chmod +x ~/.cursor/hooks/update-skills.sh ~/.cursor/hooks/track-skill-usage.sh
```

On macOS, Node installed with nvm or Homebrew is on that `PATH`. On Linux, the script also checks nvm and fnm. A system Node in `/usr/local/bin` or `/usr/bin` works with no extra path. `curl` and `python3` must be installed (`python3` is used to read the hook JSON). `curl` is installed by default on macOS and most Linux distributions.

### Windows

Cursor runs user hooks with PowerShell. Paths use `%USERPROFILE%\.cursor\`.

Create the directory and empty files, then paste the contents below into each file:

```powershell
mkdir "$env:USERPROFILE\.cursor\hooks" -Force
New-Item -ItemType File -Force -Path @(
  "$env:USERPROFILE\.cursor\hooks.json",
  "$env:USERPROFILE\.cursor\hooks\update-skills.ps1",
  "$env:USERPROFILE\.cursor\hooks\track-skill-usage.ps1"
)
```

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
      },
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/track-skill-usage.ps1",
        "timeout": 10
      }
    ],
    "beforeReadFile": [
      {
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File ./hooks/track-skill-usage.ps1",
        "timeout": 10,
        "matcher": "Read"
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
$email = ""
if ($raw -match '"user_email"\s*:\s*"([^"]+)"') {
  $email = $Matches[1]
}

$apiUrl = "https://ops4-api.6sensehq.com/users/last-skill-usage"
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

# Pass values to the background process through environment variables.
$env:SKILLS_PATH_PREFIX = ($nodeDirs -join ";")
$env:SKILLS_LOG = $log
$env:SKILLS_LOCK = $lock
$env:SKILLS_API_URL = $apiUrl
$env:SKILLS_USER_EMAIL = $email

$runner = @'
$env:PATH = $env:SKILLS_PATH_PREFIX + ';' + $env:PATH
'---- ' + (Get-Date) + ' ----' | Out-File -Append -Encoding utf8 $env:SKILLS_LOG

if ($env:SKILLS_USER_EMAIL) {
  try {
    $body = @{
      email = $env:SKILLS_USER_EMAIL
      time  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    } | ConvertTo-Json -Compress
    Invoke-RestMethod -Method Post -Uri $env:SKILLS_API_URL `
      -ContentType 'application/json' -Body $body -TimeoutSec 10 | Out-Null
    'ping ok' | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
  } catch {
    ('ping failed: ' + $_.Exception.Message) | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
  }
} else {
  'ping skipped: no user_email' | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
}

npx --yes skills update -g -y *>> $env:SKILLS_LOG
'exit ' + $LASTEXITCODE | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
Remove-Item -Recurse -Force $env:SKILLS_LOCK -ErrorAction SilentlyContinue
'@

Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $runner
) | Out-Null

Finish
```

`%USERPROFILE%\.cursor\hooks\track-skill-usage.ps1`:

```powershell
$ErrorActionPreference = "Continue"
$raw = [Console]::In.ReadToEnd()
$event = ""
if ($raw -match '"hook_event_name"\s*:\s*"([^"]+)"') { $event = $Matches[1] }
if ($event -eq "beforeSubmitPrompt") {
  Write-Output '{"continue":true}'
} else {
  Write-Output '{"permission":"allow"}'
}

$apiUrl = "https://ops4-api.6sensehq.com/users/last-skill-usage"
$hookDir = Join-Path $env:USERPROFILE ".cursor\hooks"
$log = Join-Path $hookDir "update-skills.log"
New-Item -ItemType Directory -Force -Path $hookDir | Out-Null

$data = $null
try { $data = $raw | ConvertFrom-Json } catch { exit 0 }
$raw = $null

$email = [string]$data.user_email
$source = 'fahad-6sensehq/cursor-skills'
$lockPath = Join-Path $env:USERPROFILE '.agents\.skill-lock.json'
$allowed = @{}
$lockRead = $false
if (Test-Path $lockPath) {
  try {
    $lock = Get-Content $lockPath -Raw | ConvertFrom-Json
    $lockRead = $true
    foreach ($prop in $lock.skills.PSObject.Properties) {
      $src = [string]$prop.Value.source
      $url = [string]$prop.Value.sourceUrl
      if (($src -eq $source -or $url.Contains($source)) -and $prop.Name -match '^[A-Za-z0-9._-]+$') {
        $allowed[$prop.Name] = $true
      }
    }
  } catch {}
}
if (-not $lockRead) {
  foreach ($n in @('jira-task','create-pr','code-review','system-design')) {
    $allowed[$n] = $true
  }
}
$names = New-Object System.Collections.Generic.HashSet[string]
function Add-SkillPath([string]$p) {
  if (-not $p) { return }
  $norm = ($p -replace '\\','/') -replace '/+','/'
  $marker = '/skills/'
  $i = $norm.LastIndexOf($marker)
  if ($i -lt 0) { return }
  $n = $norm.Substring($i + $marker.Length).Split('/')[0]
  if ($n -match '^[A-Za-z0-9._-]+$') { [void]$names.Add($n) }
}
Add-SkillPath ([string]$data.file_path)
if ($data.attachments) {
  foreach ($att in @($data.attachments)) { Add-SkillPath ([string]$att.file_path) }
}
$prompt = [string]$data.prompt
foreach ($m in [regex]::Matches($prompt, '(?:^|[^A-Za-z0-9._-])/([A-Za-z0-9._-]+)')) {
  if ($m.Groups[1].Value -match '^[A-Za-z0-9._-]+$') { [void]$names.Add($m.Groups[1].Value) }
}
foreach ($m in [regex]::Matches(($prompt -replace '\\','/'), '/skills/([A-Za-z0-9._-]+)')) {
  if ($m.Groups[1].Value -match '^[A-Za-z0-9._-]+$') { [void]$names.Add($m.Groups[1].Value) }
}

$env:SKILLS_API_URL = $apiUrl
$env:SKILLS_USER_EMAIL = $email
$env:SKILLS_LOG = $log
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

foreach ($skill in $names) {
  if (-not $allowed.ContainsKey($skill)) { continue }
  if (-not $email) {
    "---- $(Get-Date) skill=$skill ping skipped: no user_email ----" |
      Out-File -Append -Encoding utf8 $log
    continue
  }
  $stamp = Join-Path $hookDir ".skill-use-$skill"
  if (Test-Path $stamp) {
    $age = $now - [int64](Get-Content $stamp -Raw).Trim()
    if ($age -lt 86400) { continue }
  }
  Set-Content -Path $stamp -Value $now -NoNewline
  $env:SKILLS_SKILL = $skill
  $runner = @'
'---- ' + (Get-Date) + ' skill=' + $env:SKILLS_SKILL + ' ----' |
  Out-File -Append -Encoding utf8 $env:SKILLS_LOG
try {
  $body = @{
    email = $env:SKILLS_USER_EMAIL
    time  = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    skill = $env:SKILLS_SKILL
  } | ConvertTo-Json -Compress
  Invoke-RestMethod -Method Post -Uri $env:SKILLS_API_URL `
    -ContentType 'application/json' -Body $body -TimeoutSec 10 |
    Out-File -Append -Encoding utf8 $env:SKILLS_LOG
  'skill ping ok' | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
} catch {
  ('skill ping failed: ' + $_.Exception.Message) |
    Out-File -Append -Encoding utf8 $env:SKILLS_LOG
}
'@
  Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $runner
  ) | Out-Null
}

exit 0
```

Node from the official Windows installer is picked up from `Program Files\nodejs`. fnm and nvm-windows are included when those folders exist. `npx` must be on that `PATH`. `track-skill-usage.ps1` does not need Node.
