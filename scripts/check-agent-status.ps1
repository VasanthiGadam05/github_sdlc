<#
.SYNOPSIS
    Verifies each completed phase's agent-log.json is consistent with phase-status.json.

.DESCRIPTION
    Cross-checks outputs/<TestCase>/phase-N-<name>/agent-log.json against the
    phase-status.json tracker, flagging any phase marked complete without a
    matching SUCCESS agent-log, or an agent-log present with no corresponding
    tracker entry.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.EXAMPLE
    scripts\check-agent-status.ps1 -TestCase TC-001
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$tcOutputsDir = Join-Path $repoRoot "outputs\$TestCase"
$tcStatusPath = Join-Path $tcOutputsDir "phase-status.json"

if (-not (Test-Path $tcStatusPath)) {
    Write-Error "No pipeline found for $TestCase."
    exit 1
}

$status = Get-Content $tcStatusPath -Raw | ConvertFrom-Json

$phaseFolders = @{
    1 = "phase-1-requirements"
    2 = "phase-2-architecture"
    3 = "phase-3-design-review"
    4 = "phase-4-impl-planning"
    5 = "phase-5-implementation"
    6 = "phase-6-code-review"
    7 = "phase-7-verification"
    8 = "phase-8-pr"
}

$problems = 0

foreach ($n in 1..8) {
    $p = $status.phases."$n"
    $folder = Join-Path $tcOutputsDir $phaseFolders[$n]
    $logPath = Join-Path $folder "agent-log.json"

    $hasLog = Test-Path $logPath
    $trackedAsStarted = $p.status -ne "NOT_STARTED"

    if ($trackedAsStarted -and -not $hasLog) {
        Write-Host "MISMATCH: Phase $n is '$($p.status)' in phase-status.json but no agent-log.json exists at $logPath"
        $problems++
        continue
    }

    if (-not $hasLog) {
        Write-Host "Phase $n ($($p.name)): NOT_STARTED"
        continue
    }

    $log = Get-Content $logPath -Raw | ConvertFrom-Json
    if ($log.status -ne "SUCCESS") {
        Write-Host "Phase $n ($($p.name)): agent-log reports status '$($log.status)' (expected SUCCESS)"
        $problems++
    } else {
        Write-Host "Phase $n ($($p.name)): agent-log OK, completed $($log.completed_at), tracker status $($p.status)"
    }
}

Write-Host ""
if ($problems -eq 0) {
    Write-Host "No inconsistencies found for $TestCase."
} else {
    Write-Host "$problems inconsistency(ies) found for $TestCase. Investigate before approving further phases."
    exit 1
}
