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
$log = Join-Path $hookDir "track-skill-usage.log"
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
    if ($age -lt 60) { continue }
  }
  Set-Content -Path $stamp -Value $now -NoNewline
  "---- $(Get-Date) skill=$skill ----" | Out-File -Append -Encoding utf8 $log
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
  ('request ' + $body) | Out-File -Append -Encoding utf8 $env:SKILLS_LOG
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
