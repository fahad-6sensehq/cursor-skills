#!/bin/bash
# Copies newer global skills from GitHub at most once every 24 hours.
# Does not call the usage API and does not send the prompt.
input=$(cat)
event=$(printf '%s' "$input" | sed -n 's/.*"hook_event_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

log="$HOME/.cursor/hooks/update-skills.log"
stamp="$HOME/.cursor/hooks/.skills-update-stamp"
lockdir="$HOME/.cursor/hooks/.skills-update-lock"
mkdir -p "$HOME/.cursor/hooks"
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
  export PATH="${node_bin:+$node_bin:}${fnm_bin:+$fnm_bin:}/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
  {
    echo "---- $(date) ----"
    npx --yes skills update -g -y
    status=$?
    echo "exit $status"
  } >> "$log" 2>&1
  rmdir "$lockdir" 2>/dev/null || true
) >/dev/null 2>&1 &
disown $! 2>/dev/null || true

finish
