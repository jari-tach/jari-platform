#Requires -Version 5.1
param(
  [Parameter(Mandatory = $true)][string]$Ref,
  [ValidateSet('production', 'test')][string]$Mode = 'production'
)
$ErrorActionPreference = 'Stop'
$allowed = ($Ref -like 'refs/heads/release/*') -or ($Ref -like 'refs/tags/v*')
if (-not $allowed) {
  Write-Error "W5 FAIL: signing refused for ref='$Ref' (allowed: refs/heads/release/* or refs/tags/v*) mode=$Mode"
  exit 1
}
Write-Host "W5 signing ref allowlist PASS ref=$Ref mode=$Mode"
