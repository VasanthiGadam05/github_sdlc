<#
.SYNOPSIS
    Runs the docsync test suite and coverage, and writes a structured test-results.json for Phase 7.

.DESCRIPTION
    Executes pytest (with coverage) and the docsync smoke test, parses the
    pass/fail counts and coverage percentage, and writes
    outputs/<TestCase>/phase-7-verification/test-results.json. This is a
    convenience wrapper around the same commands listed in
    .github/prompts/verification.prompt.md and
    .github/instructions/phase-7-verification.instructions.md — it does not
    replace reading and archiving the full verification.md report.

.PARAMETER TestCase
    Test case identifier, e.g. TC-001.

.EXAMPLE
    scripts\capture-test-results.ps1 -TestCase TC-001
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

$phaseFolder = Join-Path $repoRoot "outputs\$TestCase\phase-7-verification"
New-Item -ItemType Directory -Force -Path $phaseFolder | Out-Null

Push-Location $repoRoot
try {
    $testOutput = & python -m pytest tests/ -v --tb=short 2>&1 | Out-String
    $testExit = $LASTEXITCODE

    $passed = 0
    $failed = 0
    if ($testOutput -match '(\d+)\s+passed') { $passed = [int]$Matches[1] }
    if ($testOutput -match '(\d+)\s+failed') { $failed = [int]$Matches[1] }

    $covOutput = & python -m pytest tests/ --cov=src/docsync --cov-report=term-missing 2>&1 | Out-String
    $coveragePercent = 0
    if ($covOutput -match 'TOTAL\s+\d+\s+\d+\s+(\d+)%') { $coveragePercent = [int]$Matches[1] }

    $smokeOutput = & python -m docsync --src src --docs docs --format json 2>&1 | Out-String
    $smokeExit = $LASTEXITCODE
    $smokeResult = if ($smokeExit -eq 0) { "PASS" } else { "FAIL" }

    $secretHits = Select-String -Path (Join-Path $repoRoot "src\docsync\*.py") -Pattern "password|api[_-]?key|secret|token" -CaseSensitive:$false -ErrorAction SilentlyContinue
    $securityScan = if ($secretHits) { "ISSUES_FOUND" } else { "CLEAN" }
}
finally {
    Pop-Location
}

$results = [ordered]@{
    passed           = $passed
    failed           = $failed
    test_exit_code   = $testExit
    coverage_percent = $coveragePercent
    smoke_test       = $smokeResult
    smoke_exit_code  = $smokeExit
    security_scan    = $securityScan
    captured_at      = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $phaseFolder "test-results.json") -Encoding utf8

Write-Host "Test results captured for $TestCase :"
Write-Host "  Passed: $passed  Failed: $failed  Coverage: $coveragePercent%  Smoke: $smokeResult  Security: $securityScan"
Write-Host "  Written to outputs\$TestCase\phase-7-verification\test-results.json"

if ($failed -gt 0 -or $smokeExit -ne 0 -or $securityScan -ne "CLEAN") {
    Write-Warning "One or more verification checks did not pass. Do not report Phase 7 as PASS."
}
