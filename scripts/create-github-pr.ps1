<#
.SYNOPSIS
    Opens the GitHub Pull Request for an approved test case.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^TC-\d+$')]
    [string]$TestCase,

    [Parameter(Mandatory = $false)]
    [string]$Base = 'main'
)

$ErrorActionPreference = 'Stop'

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

$statusPath = Join-Path $repoRoot ('outputs\' + $TestCase + '\phase-status.json')
if (-not (Test-Path $statusPath)) {
    Write-Error ('No pipeline found for ' + $TestCase + '.')
    exit 1
}

$status = Get-Content -Raw -Path $statusPath | ConvertFrom-Json
if ($status.phases.'8'.status -ne 'APPROVED') {
    Write-Error ('Phase 8 is not approved for ' + $TestCase + '.')
    exit 1
}

$descriptionPath = Join-Path $repoRoot ('docs\' + $TestCase + '\pr-description.md')
if (-not (Test-Path $descriptionPath)) {
    Write-Error ('PR description not found: ' + $descriptionPath)
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error 'GitHub CLI (gh) is not installed or not on PATH.'
    exit 1
}

gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error 'gh CLI is not authenticated.'
    exit 1
}

Push-Location $repoRoot
try {
    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($currentBranch -eq $Base) {
        Write-Error ('Currently on the base branch ' + $Base + '.')
        exit 1
    }

    git push -u origin $currentBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'git push failed.'
        exit 1
    }

    $title = '[' + $TestCase + '] ' + $status.user_story
    if ($title.Length -gt 100) {
        $title = $title.Substring(0, 97) + '...'
    }

    $prUrl = gh pr create --title $title --base $Base --body-file $descriptionPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'gh pr create failed.'
        exit 1
    }

    $createdPrUrl = ($prUrl | Select-Object -Last 1).ToString().Trim()
    Write-Host ('Pull Request created: ' + $createdPrUrl)
    $status | Add-Member -MemberType NoteProperty -Name 'pr_url' -Value $createdPrUrl -Force
    $status | ConvertTo-Json -Depth 6 | Set-Content -Path $statusPath -Encoding utf8
}
finally {
    Pop-Location
}
