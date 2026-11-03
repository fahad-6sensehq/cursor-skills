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
├── install/
│   ├── hooks.json
│   ├── hooks.windows.json
│   ├── track-skill-usage.sh
│   └── track-skill-usage.ps1
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

`.cursor-plugin/marketplace.json` indexes this repo as one plugin. `.cursor-plugin/plugin.json` is that plugin. Skills are discovered from `skills/`. The `install/` files are the usage hook. Cursor does not load them from this repo.

## Install

Install the skills globally so every project on that machine can use them. Requires Node.js 22.20 or newer.

```bash
npx skills add fahad-6sensehq/cursor-skills -g -a cursor -y
```

Skills land in `~/.agents/skills/`. This command does not install the usage hook below.

## Usage tracking

`track-skill-usage` is the only hook, and it is the only script that calls the API. It reports a skill when someone uses it. It does not report that the skills are merely installed.

| Hook | When it runs |
| --- | --- |
| `beforeSubmitPrompt` | The user sends a prompt that contains `/skill-name`, such as `/jira-task`. |
| `beforeReadFile` | The agent reads a file under that skill. |

The prompt is not blocked, and the file read is allowed. The same skill is sent at most once every 60 seconds, so the prompt and the following file read count as one use.

Cursor passes the signed-in user's email as `user_email`. The hook sends:

```bash
curl --request POST \
  --url https://ops4-api.6sensehq.com/users/last-skill-usage \
  --header 'content-type: application/json' \
  --data '{"email":"user@example.com","time":"2026-11-02T07:00:00Z","skill":"jira-task"}'
```

| Field | Value |
| --- | --- |
| `email` | `user_email` from the hook input |
| `time` | Current time in UTC, ISO 8601 |
| `skill` | Skill directory name from `~/.agents/.skill-lock.json` whose source is `fahad-6sensehq/cursor-skills` |

Notes:

- If the user is not signed in to Cursor, `user_email` is empty and no request is sent.
- A command or file read is ignored unless that skill is installed from `fahad-6sensehq/cursor-skills`. After `npx skills update -g` installs a new skill, the next `/skill-name` is reported. The hook script does not need an edit. Skills from other repos are ignored.
- The hook does not send the prompt or the file contents.
- The request runs in the background with a 10-second timeout. A failure never blocks Cursor. The result is written to `~/.cursor/hooks/track-skill-usage.log`.
- The endpoint has to store `skill`. A handler that only saves the last timestamp will return success and still not show which skill was used.
- Anyone who installs this hook is sending their email, and the skill name when they use one, to that endpoint. Tell your users.

After the files are in place, reload the window (**Developer: Reload Window**).

### macOS and Linux

This creates `~/.cursor/hooks`, then downloads `hooks.json` and `track-skill-usage.sh` into place. `curl` must be installed. The script reads the hook payload with `python3`, or with `node` when `python3` is missing.

```bash
mkdir -p ~/.cursor/hooks
base=https://raw.githubusercontent.com/fahad-6sensehq/cursor-skills/main/install
curl -fsSL "$base/hooks.json" -o ~/.cursor/hooks.json
curl -fsSL "$base/track-skill-usage.sh" -o ~/.cursor/hooks/track-skill-usage.sh
chmod +x ~/.cursor/hooks/track-skill-usage.sh
```

From a checkout of this repo, copy the same files instead of downloading them:

```bash
mkdir -p ~/.cursor/hooks
cp install/hooks.json ~/.cursor/hooks.json
cp install/track-skill-usage.sh ~/.cursor/hooks/track-skill-usage.sh
chmod +x ~/.cursor/hooks/track-skill-usage.sh
```

`~/.cursor/hooks.json` only runs the usage script:

```json
{
  "version": 1,
  "hooks": {
    "beforeSubmitPrompt": [
      { "command": "./hooks/track-skill-usage.sh", "timeout": 10 }
    ],
    "beforeReadFile": [
      { "command": "./hooks/track-skill-usage.sh", "timeout": 10, "matcher": "Read" }
    ]
  }
}
```

### Windows

This creates `%USERPROFILE%\.cursor\hooks`, then downloads the Windows hook files.

```powershell
$dest = Join-Path $env:USERPROFILE ".cursor"
$hooks = Join-Path $dest "hooks"
New-Item -ItemType Directory -Force -Path $hooks | Out-Null
$base = "https://raw.githubusercontent.com/fahad-6sensehq/cursor-skills/main/install"
Invoke-WebRequest "$base/hooks.windows.json" -OutFile (Join-Path $dest "hooks.json")
Invoke-WebRequest "$base/track-skill-usage.ps1" -OutFile (Join-Path $hooks "track-skill-usage.ps1")
```

From a checkout of this repo:

```powershell
$dest = Join-Path $env:USERPROFILE ".cursor"
$hooks = Join-Path $dest "hooks"
New-Item -ItemType Directory -Force -Path $hooks | Out-Null
Copy-Item install\hooks.windows.json (Join-Path $dest "hooks.json") -Force
Copy-Item install\track-skill-usage.ps1 (Join-Path $hooks "track-skill-usage.ps1") -Force
```

`hooks.windows.json` is the same hook list as macOS. The command is `powershell -File ./hooks/track-skill-usage.ps1`.
