<#
.SYNOPSIS
    Initializes the docsync Agentic SDLC pipeline for a new test case.

.DESCRIPTION
    Creates outputs/<TestCase>/phase-status.json with all 8 phases set to
    NOT_STARTED, creates docs/<TestCase>/ for SDLC artifacts, and registers
    the test case in the master outputs/phase-status.json tracker.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.PARAMETER UserStory
    Free-text user story / feature description for this test case.

.EXAMPLE
    scripts\init-pipeline.ps1 -TestCase TC-001 -UserStory "US-001: As a developer I want docsync to detect renamed functions"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase,

    [Parameter(Mandatory = $true)]
    [string]$UserStory
)

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$outputsDir = Join-Path $repoRoot "outputs"
$tcOutputsDir = Join-Path $outputsDir $TestCase
$tcDocsDir = Join-Path $repoRoot "docs\$TestCase"
$masterStatusPath = Join-Path $outputsDir "phase-status.json"
$tcStatusPath = Join-Path $tcOutputsDir "phase-status.json"

if (Test-Path $tcStatusPath) {
    Write-Error "Pipeline already initialized for $TestCase ($tcStatusPath exists). Use resume-pipeline.ps1 to continue it, or pick a new test case ID."
    exit 1
}

New-Item -ItemType Directory -Force -Path $tcOutputsDir | Out-Null
New-Item -ItemType Directory -Force -Path $tcDocsDir | Out-Null

$nowIso = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

$phaseNames = [ordered]@{
    "1" = "Requirements"
    "2" = "Architecture"
    "3" = "Design Review"
    "4" = "Implementation Planning"
    "5" = "Implementation"
    "6" = "Code Review"
    "7" = "Verification"
    "8" = "PR Creation"
}

$phases = [ordered]@{}
foreach ($key in $phaseNames.Keys) {
    $phases[$key] = [ordered]@{
        status = "NOT_STARTED"
        name   = $phaseNames[$key]
    }
}

$tcStatus = [ordered]@{
    test_case       = $TestCase
    user_story      = $UserStory
    created_at      = $nowIso
    pipeline_status = "IN_PROGRESS"
    phases          = $phases
}

$tcStatus | ConvertTo-Json -Depth 6 | Set-Content -Path $tcStatusPath -Encoding utf8

if (Test-Path $masterStatusPath) {
    $master = Get-Content $masterStatusPath -Raw | ConvertFrom-Json
} else {
    New-Item -ItemType Directory -Force -Path $outputsDir | Out-Null
    $master = [PSCustomObject]@{
        active_test_cases = @()
        test_cases        = [PSCustomObject]@{}
    }
}

$masterHash = @{
    active_test_cases = @($master.active_test_cases) + $TestCase | Select-Object -Unique
    test_cases        = @{}
}
foreach ($prop in $master.test_cases.PSObject.Properties) {
    $masterHash.test_cases[$prop.Name] = $prop.Value
}
$masterHash.test_cases[$TestCase] = @{
    user_story  = $UserStory
    created_at  = $nowIso
    status_file = "outputs/$TestCase/phase-status.json"
}

$masterHash | ConvertTo-Json -Depth 6 | Set-Content -Path $masterStatusPath -Encoding utf8

Write-Host "Initialized pipeline for $TestCase"
Write-Host "  Status file : $tcStatusPath"
Write-Host "  Docs folder : $tcDocsDir"
Write-Host ""
Write-Host "Next: invoke the Phase 1 (Requirements) prompt in Copilot Chat or Claude Code:"
Write-Host "  @requirements.prompt.md"
