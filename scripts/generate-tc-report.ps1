<#
.SYNOPSIS
    Generates a single consolidated Markdown report for a test case across all 8 phases.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.EXAMPLE
    scripts\generate-tc-report.ps1 -TestCase TC-001
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
    1 = "phase-1-requirements"; 2 = "phase-2-architecture"; 3 = "phase-3-design-review"
    4 = "phase-4-impl-planning"; 5 = "phase-5-implementation"; 6 = "phase-6-code-review"
    7 = "phase-7-verification"; 8 = "phase-8-pr"
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Test Case Report: $TestCase")
$lines.Add("")
$lines.Add("**User Story:** $($status.user_story)")
$lines.Add("**Pipeline Status:** $($status.pipeline_status)")
if ($status.pr_url) { $lines.Add("**Pull Request:** $($status.pr_url)") }
$lines.Add("")
$lines.Add("## Phase Summary")
$lines.Add("")
$lines.Add("| Phase | Name | Status | Completed/Decided At |")
$lines.Add("|-------|------|--------|----------------------|")

foreach ($n in 1..8) {
    $p = $status.phases."$n"
    $when = if ($p.decided_at) { $p.decided_at } elseif ($p.completed_at) { $p.completed_at } else { "-" }
    $lines.Add("| $n | $($p.name) | $($p.status) | $when |")
}

$lines.Add("")
$lines.Add("## Phase Details")

foreach ($n in 1..8) {
    $p = $status.phases."$n"
    $folder = Join-Path $tcOutputsDir $phaseFolders[$n]
    $outputPath = Join-Path $folder "output.md"

    $lines.Add("")
    $lines.Add("### Phase ${n}: $($p.name) — $($p.status)")

    if ($p.status -eq "NOT_STARTED") {
        $lines.Add("_Not yet reached._")
        continue
    }

    if (Test-Path $outputPath) {
        $content = Get-Content $outputPath -Raw
        $preview = if ($content.Length -gt 500) { $content.Substring(0, 500) + "..." } else { $content }
        $lines.Add("")
        $lines.Add('```')
        $lines.Add($preview)
        $lines.Add('```')
        $lines.Add("")
        $lines.Add("Full output: ``outputs/$TestCase/$($phaseFolders[$n])/output.md``")
    } else {
        $lines.Add("_No archived output found at $outputPath._")
    }

    if ($p.status -eq "REJECTED" -and $p.rejection_reason) {
        $lines.Add("")
        $lines.Add("**Rejection reason:** $($p.rejection_reason)")
    }
}

$reportPath = Join-Path $tcOutputsDir "tc-report.md"
$lines -join "`n" | Set-Content -Path $reportPath -Encoding utf8

Write-Host "Report written to outputs\$TestCase\tc-report.md"
