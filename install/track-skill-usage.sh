#!/bin/bash
# Reports a skill from fahad-6sensehq/cursor-skills when the agent loads it.
# A slash command such as /jira-task does not read SKILL.md, so this also
# checks the prompt and attachments. Names come from ~/.agents/.skill-lock.json.
# Sends email, skill name, and time only. Never sends file contents or the prompt.
input=$(cat)

node_bin=""
if [ -d "$HOME/.nvm/versions/node" ]; then
  node_bin=$(ls -d "$HOME/.nvm/versions/node/"*/bin 2>/dev/null | tail -1)
fi
fnm_bin="$HOME/.local/share/fnm/aliases/default/bin"
export PATH="${node_bin:+$node_bin:}${fnm_bin:+$fnm_bin:}/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

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
elif command -v node >/dev/null 2>&1; then
  node_js=$(cat << 'EOF'
const fs = require('fs');
const os = require('os');
const path = require('path');
let data;
try {
  data = JSON.parse(fs.readFileSync(0, 'utf8'));
} catch (e) {
  process.exit(0);
}
const event = data.hook_event_name || '';
process.stdout.write(event === 'beforeSubmitPrompt' ? '{"continue":true}\n' : '{"permission":"allow"}\n');
const email = data.user_email || '';
const source = 'fahad-6sensehq/cursor-skills';
const lockPath = path.join(os.homedir(), '.agents', '.skill-lock.json');
const allowed = new Set();
let lockRead = false;
try {
  const lock = JSON.parse(fs.readFileSync(lockPath, 'utf8'));
  lockRead = true;
  for (const [skillName, meta] of Object.entries(lock.skills || {})) {
    if (!meta || typeof meta !== 'object' || Array.isArray(meta)) continue;
    if (!/^[A-Za-z0-9._-]+$/.test(skillName)) continue;
    const src = meta.source || '';
    const url = meta.sourceUrl || '';
    if (src === source || url.includes(source)) allowed.add(skillName);
  }
} catch (e) {
  lockRead = false;
}
if (!lockRead) {
  for (const name of ['jira-task', 'create-pr', 'code-review', 'system-design']) allowed.add(name);
}
const found = new Set();
function addPath(p) {
  p = String(p || '').replace(/\\/g, '/').replace(/\/+/g, '/');
  const marker = '/skills/';
  const idx = p.lastIndexOf(marker);
  if (idx === -1) return;
  const name = p.slice(idx + marker.length).split('/')[0];
  if (/^[A-Za-z0-9._-]+$/.test(name || '')) found.add(name);
}
addPath(data.file_path);
for (const att of data.attachments || []) {
  if (att && typeof att === 'object') addPath(att.file_path);
}
const prompt = data.prompt || '';
for (const match of prompt.matchAll(/(?:^|[^A-Za-z0-9._-])\/([A-Za-z0-9._-]+)/g)) found.add(match[1]);
for (const match of prompt.replace(/\\/g, '/').matchAll(/\/skills\/([A-Za-z0-9._-]+)/g)) found.add(match[1]);
const now = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
for (const name of [...found].sort()) {
  if (!allowed.has(name)) continue;
  if (!email) {
    process.stdout.write(name + '\nNO_EMAIL\n');
    continue;
  }
  process.stdout.write(name + '\n' + JSON.stringify({ email, time: now, skill: name }) + '\n');
}
EOF
)
  parsed=$(printf '%s' "$input" | node -e "$node_js")
fi

log="$HOME/.cursor/hooks/track-skill-usage.log"
hookdir="$HOME/.cursor/hooks"
mkdir -p "$hookdir"

if [ -z "$parsed" ]; then
  if printf '%s' "$input" | grep -q 'beforeSubmitPrompt'; then
    printf '%s\n' '{"continue":true}'
  else
    printf '%s\n' '{"permission":"allow"}'
  fi
  unset input
  if [ -z "$py" ] && ! command -v node >/dev/null 2>&1; then
    echo "---- $(date) skill ping skipped: no python3 or node ----" >> "$log"
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
  if [ -f "$stamp" ] && [ $((now - $(cat "$stamp"))) -lt 60 ]; then
    continue
  fi
  echo "$now" > "$stamp"
  echo "---- $(date) skill=$skill ----" >> "$log"
  echo "request $body" >> "$log"
  (
    {
      curl --silent --show-error --max-time 10 --request POST \
        --url "$api_url" \
        --header 'content-type: application/json' \
        --data "$body"
      status=$?
      echo
      echo "skill ping exit $status"
    } >> "$log" 2>&1
  ) >/dev/null 2>&1 &
  disown $! 2>/dev/null || true
done <<EOF
$rest
EOF

exit 0
