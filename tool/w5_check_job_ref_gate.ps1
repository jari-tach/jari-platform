#Requires -Version 5.1
<#
.SYNOPSIS
  Local static check of W5 F1 job-level ref eligibility expressions.
  Does not call GitHub; evaluates the same ref rules used in workflow if:.
#>
param(
  [Parameter(Mandatory = $true)][string]$WorkflowPath
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $WorkflowPath)) { throw "missing $WorkflowPath" }
$text = Get-Content -Raw $WorkflowPath

# Reject legacy bypass pattern
if ($text -match "github\.event_name == 'workflow_dispatch' \|\|\s*startsWith\(github\.ref") {
  throw "F1 FAIL: legacy workflow_dispatch||ref bypass still present in $WorkflowPath"
}

# Signing jobs with environment must also require release/ or v* in the same if block vicinity
$envJobs = [regex]::Matches($text, '(?ms)^  ([a-z0-9_]+):\r?\n(?:.*?\r?\n)*?    environment: w5-signing-(?:production|test)')
if ($envJobs.Count -lt 1) { throw "F1 FAIL: no environment signing jobs found" }

foreach ($m in $envJobs) {
  $block = $m.Value
  $name = $m.Groups[1].Value
  if ($block -notmatch "startsWith\(github\.ref, 'refs/heads/release/'\)") {
    throw "F1 FAIL: job '$name' with Environment lacks release/* ref gate in if"
  }
  if ($block -notmatch "startsWith\(github\.ref, 'refs/tags/v'\)") {
    throw "F1 FAIL: job '$name' with Environment lacks v* tag gate in if"
  }
  if ($block -notmatch 'signing_ref_gate') {
    throw "F1 FAIL: job '$name' does not need signing_ref_gate"
  }
}

if ($text -notmatch '(?m)^  signing_ref_gate:') {
  throw "F1 FAIL: signing_ref_gate job missing"
}
# Gate job must not declare environment
$gate = [regex]::Match($text, '(?ms)^  signing_ref_gate:.*?(?=^  [a-z]|$)')
if ($gate.Success -and $gate.Value -match 'environment:') {
  throw 'F1 FAIL: signing_ref_gate must not use environment'
}

function Test-Eligible([string]$ref) {
  return ($ref -like 'refs/heads/release/*') -or ($ref -like 'refs/tags/v*')
}

$cases = @(
  @{ Ref = 'refs/heads/fix/customer-production-signing-w5'; Expect = $false },
  @{ Ref = 'refs/heads/feature/x'; Expect = $false },
  @{ Ref = 'refs/heads/release/customer-sot-consolidation'; Expect = $true },
  @{ Ref = 'refs/tags/v1.2.3'; Expect = $true }
)
foreach ($c in $cases) {
  $got = Test-Eligible $c.Ref
  if ($got -ne $c.Expect) {
    throw "F1 FAIL: eligibility mismatch for $($c.Ref) got=$got expect=$($c.Expect)"
  }
  $label = if ($c.Expect) { 'ELIGIBLE' } else { 'NOT ELIGIBLE' }
  Write-Host ("{0} -> {1}" -f $c.Ref, $label)
}

Write-Host "F1 job-level ref gate STATIC PASS - $WorkflowPath"
