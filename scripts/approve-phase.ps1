<#
.SYNOPSIS
    Records the human approval or rejection decision for a docsync pipeline phase.

.DESCRIPTION
    This is the ONLY script that may set a phase's status to APPROVED. No
    agent or prompt may call this on the human's behalf — it exists precisely
    so the human-in-the-loop checkpoint is a real gate, not a formality.

.PARAMETER Phase
    Phase number, 1-8.

.PARAMETER Decision
    APPROVED or REJECTED.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.PARAMETER Reason
    Required when Decision is REJECTED — explains what must change.

.EXAMPLE
    scripts\approve-phase.ps1 -Phase 1 -Decision APPROVED -TestCase TC-001

.EXAMPLE
    scripts\approve-phase.ps1 -Phase 2 -Decision REJECTED -TestCase TC-001 -Reason "Architecture missed NFR-1 performance budget"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$Phase,

    [Parameter(Mandatory = $true)]
    [ValidateSet("APPROVED", "REJECTED")]
    [string]$Decision,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase,

    [Parameter(Mandatory = $false)]
    [string]$Reason
)

$ErrorActionPreference = "Stop"

if ($Decision -eq "REJECTED" -and [string]::IsNullOrWhiteSpace($Reason)) {
    Write-Error "-Reason is required when -Decision is REJECTED."
    exit 1
}

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$tcStatusPath = Join-Path $repoRoot "outputs\$TestCase\phase-status.json"
if (-not (Test-Path $tcStatusPath)) {
    Write-Error "No pipeline found for $TestCase. Run scripts\init-pipeline.ps1 -TestCase $TestCase -UserStory `"...`" first."
    exit 1
}

$status = Get-Content $tcStatusPath -Raw | ConvertFrom-Json
$phaseKey = "$Phase"

if (-not $status.phases.$phaseKey) {
    Write-Error "Phase $Phase not found in $tcStatusPath."
    exit 1
}

$currentStatus = $status.phases.$phaseKey.status
if ($currentStatus -notin @("PENDING_APPROVAL", "REJECTED")) {
    Write-Error "Phase $Phase is currently '$currentStatus', not PENDING_APPROVAL. The agent must produce the phase output before it can be approved or rejected."
    exit 1
}

$nowIso = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

$status.phases.$phaseKey.status = $Decision
$status.phases.$phaseKey | Add-Member -MemberType NoteProperty -Name "decided_at" -Value $nowIso -Force
if ($Decision -eq "REJECTED") {
    $status.phases.$phaseKey | Add-Member -MemberType NoteProperty -Name "rejection_reason" -Value $Reason -Force
} else {
    if ($status.phases.$phaseKey.PSObject.Properties.Match("rejection_reason").Count -gt 0) {
        $status.phases.$phaseKey.PSObject.Properties.Remove("rejection_reason")
    }
}

if ($Decision -eq "APPROVED" -and $Phase -eq 8) {
    $status | Add-Member -MemberType NoteProperty -Name "pipeline_status" -Value "PIPELINE_COMPLETE" -Force
}

$status | ConvertTo-Json -Depth 6 | Set-Content -Path $tcStatusPath -Encoding utf8

Write-Host "Phase $Phase ($($status.phases.$phaseKey.name)) for $TestCase recorded as $Decision."

if ($Decision -eq "APPROVED") {
    if ($Phase -lt 8) {
        Write-Host "You may now invoke the Phase $($Phase + 1) prompt to continue the pipeline."
    } else {
        Write-Host "All 8 phases are approved. Run scripts\create-github-pr.ps1 -TestCase $TestCase to open the Pull Request."
    }
} else {
    Write-Host "Re-invoke the Phase $Phase prompt with the rejection reason as feedback before approving again."
}
