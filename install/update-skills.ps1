$ErrorActionPreference = "Continue"
$raw = [Console]::In.ReadToEnd()
$event = ""
if ($raw -match '"hook_event_name"\s*:\s*"([^"]+)"') { $event = $Matches[1] }
$raw = $null

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

$env:SKILLS_PATH_PREFIX = ($nodeDirs -join ";")
$env:SKILLS_LOG = $log
$env:SKILLS_LOCK = $lock

$runner = @'
$env:PATH = $env:SKILLS_PATH_PREFIX + ';' + $env:PATH
'---- ' + (Get-Date) + ' ----' | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
npx --yes skills update -g -y *>> $env:SKILLS_LOG
'exit ' + $LASTEXITCODE | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
Remove-Item -Recurse -Force $env:SKILLS_LOCK -ErrorAction SilentlyContinue
'@

Start-Process -WindowStyle Hidden -FilePath "powershell" -ArgumentList @(
  "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $runner
) | Out-Null

Finish
