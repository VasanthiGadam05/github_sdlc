<#
.SYNOPSIS
    Prints the phase-by-phase status table for a docsync pipeline test case.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001. If omitted, uses the first entry in
    outputs/phase-status.json's active_test_cases.

.EXAMPLE
    scripts\show-phase-status.ps1 -TestCase TC-001
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestCase
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

if (-not $TestCase) {
    $masterStatusPath = Join-Path $repoRoot "outputs\phase-status.json"
    if (-not (Test-Path $masterStatusPath)) {
        Write-Error "No pipeline has been initialized yet. Run scripts\init-pipeline.ps1 first."
        exit 1
    }
    $master = Get-Content $masterStatusPath -Raw | ConvertFrom-Json
    if (-not $master.active_test_cases -or $master.active_test_cases.Count -eq 0) {
        Write-Error "No active test cases found in $masterStatusPath."
        exit 1
    }
    $TestCase = $master.active_test_cases[0]
}

$tcStatusPath = Join-Path $repoRoot "outputs\$TestCase\phase-status.json"
if (-not (Test-Path $tcStatusPath)) {
    Write-Error "No pipeline found for $TestCase."
    exit 1
}

$status = Get-Content $tcStatusPath -Raw | ConvertFrom-Json

Write-Host ""
Write-Host "Test Case  : $TestCase"
Write-Host "User Story : $($status.user_story)"
Write-Host "Pipeline   : $($status.pipeline_status)"
Write-Host ""
Write-Host ("{0,-6} {1,-24} {2,-18} {3}" -f "Phase", "Name", "Status", "Decided/Completed At")
Write-Host ("-" * 80)

foreach ($n in 1..8) {
    $p = $status.phases."$n"
    $when = if ($p.decided_at) { $p.decided_at } elseif ($p.completed_at) { $p.completed_at } else { "-" }
    Write-Host ("{0,-6} {1,-24} {2,-18} {3}" -f $n, $p.name, $p.status, $when)
    if ($p.status -eq "REJECTED" -and $p.rejection_reason) {
        Write-Host ("       Reason: {0}" -f $p.rejection_reason)
    }
}
Write-Host ""

$pending = @(1..8 | Where-Object { $status.phases."$_".status -eq "PENDING_APPROVAL" })
if ($pending.Count -gt 0) {
    foreach ($n in $pending) {
        Write-Host "Awaiting approval for Phase $n. Run:"
        Write-Host "  scripts\approve-phase.ps1 -Phase $n -Decision APPROVED -TestCase $TestCase"
    }
}
