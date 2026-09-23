<#
.SYNOPSIS
    Archives a completed phase's output and updates the pipeline tracker to PENDING_APPROVAL.

.DESCRIPTION
    Utility used by agents/prompts (or invoked manually) after writing a
    docs/<TestCase>/<doc>.md artifact, to perform the standard "Save & Archive"
    steps: copy the doc into outputs/<TestCase>/phase-N-<name>/output.md,
    write agent-log.json, and update phase-status.json to PENDING_APPROVAL.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.PARAMETER Phase
    Phase number, 1-8.

.PARAMETER SourceFile
    Path (relative to repo root or absolute) to the doc that was just written,
    e.g. docs/TC-001/requirements.md.

.PARAMETER AgentName
    Name of the prompt/agent that produced this output, e.g. requirements.prompt.md.

.EXAMPLE
    scripts\save-phase-output.ps1 -TestCase TC-001 -Phase 1 -SourceFile docs\TC-001\requirements.md -AgentName requirements.prompt.md
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 8)]
    [int]$Phase,

    [Parameter(Mandatory = $true)]
    [string]$SourceFile,

    [Parameter(Mandatory = $true)]
    [string]$AgentName
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$phaseNames = @{
    1 = "Requirements"; 2 = "Architecture"; 3 = "Design Review"
    4 = "Implementation Planning"; 5 = "Implementation"; 6 = "Code Review"
    7 = "Verification"; 8 = "PR Creation"
}
$phaseFolders = @{
    1 = "phase-1-requirements"; 2 = "phase-2-architecture"; 3 = "phase-3-design-review"
    4 = "phase-4-impl-planning"; 5 = "phase-5-implementation"; 6 = "phase-6-code-review"
    7 = "phase-7-verification"; 8 = "phase-8-pr"
}

$sourceFullPath = Join-Path $repoRoot $SourceFile
if (-not (Test-Path $sourceFullPath)) {
    Write-Error "Source file not found: $sourceFullPath"
    exit 1
}

$tcOutputsDir = Join-Path $repoRoot "outputs\$TestCase"
$tcStatusPath = Join-Path $tcOutputsDir "phase-status.json"
if (-not (Test-Path $tcStatusPath)) {
    Write-Error "No pipeline found for $TestCase. Run scripts\init-pipeline.ps1 first."
    exit 1
}

$folderName = $phaseFolders[$Phase]
$phaseFolder = Join-Path $tcOutputsDir $folderName
New-Item -ItemType Directory -Force -Path $phaseFolder | Out-Null

$archivePath = Join-Path $phaseFolder "output.md"
Copy-Item -Path $sourceFullPath -Destination $archivePath -Force

$nowIso = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
$relSource = $SourceFile -replace '\\', '/'
$relArchive = "outputs/$TestCase/$folderName/output.md"

$agentLog = [ordered]@{
    phase              = $Phase
    phase_name         = $phaseNames[$Phase]
    agent              = $AgentName
    completed_at       = $nowIso
    output_file        = $relSource
    output_archived_to = $relArchive
    status             = "SUCCESS"
}
$agentLog | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $phaseFolder "agent-log.json") -Encoding utf8

$status = Get-Content $tcStatusPath -Raw | ConvertFrom-Json
$phaseKey = "$Phase"
$status.phases.$phaseKey.status = "PENDING_APPROVAL"
$status.phases.$phaseKey | Add-Member -MemberType NoteProperty -Name "output_archive" -Value $relArchive -Force
$status.phases.$phaseKey | Add-Member -MemberType NoteProperty -Name "phase_folder" -Value $folderName -Force
$status.phases.$phaseKey | Add-Member -MemberType NoteProperty -Name "completed_at" -Value $nowIso -Force
$status | ConvertTo-Json -Depth 6 | Set-Content -Path $tcStatusPath -Encoding utf8

Write-Host "Archived Phase $Phase ($($phaseNames[$Phase])) output for $TestCase."
Write-Host "  $relSource -> $relArchive"
Write-Host "Status set to PENDING_APPROVAL. Awaiting human review."
Write-Host "  scripts\approve-phase.ps1 -Phase $Phase -Decision APPROVED -TestCase $TestCase"
