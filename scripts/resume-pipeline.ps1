<#
.SYNOPSIS
    Resumes an interrupted docsync pipeline from a specific phase.

.DESCRIPTION
    Resets phase FromPhase through 8 to NOT_STARTED so they can be re-run,
    while leaving phases 1..FromPhase-1 untouched. Refuses to run unless
    those earlier phases are already APPROVED, unless -Force is supplied.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.PARAMETER FromPhase
    Phase number to resume from, 1-8.

.PARAMETER Force
    Skip the check that phases before FromPhase are APPROVED.

.EXAMPLE
    scripts\resume-pipeline.ps1 -TestCase TC-001 -FromPhase 4 -Force
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$FromPhase,

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$tcStatusPath = Join-Path $repoRoot "outputs\$TestCase\phase-status.json"
if (-not (Test-Path $tcStatusPath)) {
    Write-Error "No pipeline found for $TestCase."
    exit 1
}

$status = Get-Content $tcStatusPath -Raw | ConvertFrom-Json

for ($p = 1; $p -lt $FromPhase; $p++) {
    $priorStatus = $status.phases."$p".status
    if ($priorStatus -ne "APPROVED" -and -not $Force) {
        Write-Error "Phase $p is '$priorStatus', not APPROVED. Use -Force to resume anyway, or approve phase $p first."
        exit 1
    }
}

for ($p = $FromPhase; $p -le 8; $p++) {
    $status.phases."$p".status = "NOT_STARTED"
    foreach ($field in @("decided_at", "rejection_reason", "completed_at", "output_archive", "phase_folder")) {
        if ($status.phases."$p".PSObject.Properties.Match($field).Count -gt 0) {
            $status.phases."$p".PSObject.Properties.Remove($field)
        }
    }
}

$status | Add-Member -MemberType NoteProperty -Name "pipeline_status" -Value "IN_PROGRESS" -Force

$status | ConvertTo-Json -Depth 6 | Set-Content -Path $tcStatusPath -Encoding utf8

Write-Host "Resumed $TestCase from Phase $FromPhase."
Write-Host "Phases 1-$($FromPhase - 1) left untouched. Phases $FromPhase-8 reset to NOT_STARTED."
Write-Host "Invoke the Phase $FromPhase prompt to continue."
