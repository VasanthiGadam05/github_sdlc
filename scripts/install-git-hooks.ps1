<#
.SYNOPSIS
    Installs the docsync SDLC pre-commit hook into .git/hooks/.

.DESCRIPTION
    Copies .github/hooks/pre-commit into .git/hooks/pre-commit so it is
    active for local commits. Git does not track file mode on Windows, so
    this script also ensures the hook is executable where the platform
    supports it (Git Bash / WSL / macOS / Linux).

.EXAMPLE
    scripts\install-git-hooks.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "Not inside a git repository."
    exit 1
}

$source = Join-Path $repoRoot ".github/hooks/pre-commit"
$gitHooksDir = Join-Path $repoRoot ".git/hooks"
$destination = Join-Path $gitHooksDir "pre-commit"

if (-not (Test-Path $source)) {
    Write-Error "Source hook not found: $source"
    exit 1
}

if (-not (Test-Path $gitHooksDir)) {
    New-Item -ItemType Directory -Force -Path $gitHooksDir | Out-Null
}

Copy-Item -Path $source -Destination $destination -Force

try {
    & git update-index --chmod=+x $destination 2>$null | Out-Null
} catch {
    # Non-fatal on platforms without POSIX chmod semantics.
}

if (Get-Command chmod -ErrorAction SilentlyContinue) {
    chmod +x $destination
}

Write-Host "Installed pre-commit hook: $destination"
Write-Host "It will run automatically on the next 'git commit'."
