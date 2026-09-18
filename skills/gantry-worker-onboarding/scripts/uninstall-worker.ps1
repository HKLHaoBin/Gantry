[CmdletBinding()]
param(
  [switch] $RemoveWorkspaceMemory
)

$ErrorActionPreference = "Stop"
$taskName = "Cursor Agent Worker"
$configRoot = Join-Path $env:USERPROFILE ".cursor\agent-worker"
$memoryPath = Join-Path $env:USERPROFILE ".cursor\memory-graphs\WORKSPACE-ROOTS.md"

$task = $null
if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
  $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
  if ($task) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Removed scheduled task: $taskName"
  } else {
    Write-Host "Scheduled task not found: $taskName"
  }
} elseif (Get-Command schtasks.exe -ErrorAction SilentlyContinue) {
  & (Get-Command schtasks.exe).Source /Delete /TN $taskName /F | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "Removed scheduled task: $taskName"
  } else {
    Write-Host "Scheduled task not found: $taskName"
  }
} else {
  Write-Host "No ScheduledTasks module or schtasks.exe was available."
}

if (Test-Path -LiteralPath $configRoot) {
  Remove-Item -LiteralPath $configRoot -Recurse -Force
  Write-Host "Removed worker configuration and logs: $configRoot"
} else {
  Write-Host "Worker configuration not found: $configRoot"
}

if ($RemoveWorkspaceMemory -and (Test-Path -LiteralPath $memoryPath)) {
  $begin = "<!-- BEGIN GANTRY WORKSPACE ROOTS -->"
  $end = "<!-- END GANTRY WORKSPACE ROOTS -->"
  $content = Get-Content -LiteralPath $memoryPath -Raw
  $pattern = "(?s)" + [Regex]::Escape($begin) + ".*?" + [Regex]::Escape($end)
  $updated = [Regex]::Replace($content, $pattern, "").Trim()
  if ($updated.Length -eq 0) {
    Remove-Item -LiteralPath $memoryPath -Force
    Write-Host "Removed generated workspace memory file: $memoryPath"
  } else {
    Set-Content -LiteralPath $memoryPath -Value ($updated + [Environment]::NewLine) -Encoding UTF8
    Write-Host "Removed Gantry workspace block and preserved other memory: $memoryPath"
  }
} elseif (Test-Path -LiteralPath $memoryPath) {
  Write-Host "Preserved workspace memory. Pass -RemoveWorkspaceMemory only after reviewing it."
}

Write-Host "Cursor CLI login state and project directories were not changed."
