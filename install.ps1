#requires -Version 7.0
<#
.SYNOPSIS
    Installs the terminal visual setup (PowerShell profile, oh-my-posh theme,
    Windows Terminal settings, Claude Code statusline) from this repo onto the
    current machine.

.DESCRIPTION
    Copies each tracked file from .\files\ to its real location. Existing files
    are backed up to <file>.bak-<timestamp> before being overwritten.

    Run from the repo root:  pwsh -File .\install.ps1
    Preview only (no writes): pwsh -File .\install.ps1 -WhatIf

.NOTES
    Prerequisites (install separately):
      - PowerShell 7+        winget install Microsoft.PowerShell
      - Windows Terminal     winget install Microsoft.WindowsTerminal
      - oh-my-posh           winget install JanDeDobbeleer.OhMyPosh
      - A RobotoMono Nerd Font (https://www.nerdfonts.com/)
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'
$repo  = $PSScriptRoot
$files = Join-Path $repo 'files'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$claudeSettings = Join-Path $env:USERPROFILE '.claude\settings.json'

# Full-file copies: source (under files\) -> destination
$map = [ordered]@{
    'powershell\Microsoft.PowerShell_profile.ps1' = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'
    'oh-my-posh\omp.json'                         = Join-Path $env:USERPROFILE 'omp.json'
    'claude-code\statusline.ps1'                  = Join-Path $env:USERPROFILE '.claude\statusline.ps1'
}

foreach ($entry in $map.GetEnumerator()) {
    $src = Join-Path $files $entry.Key
    $dst = $entry.Value
    if (-not (Test-Path $src)) { Write-Warning "missing source: $src"; continue }

    $dstDir = Split-Path $dst -Parent
    if (-not (Test-Path $dstDir)) {
        if ($PSCmdlet.ShouldProcess($dstDir, 'create directory')) {
            New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
        }
    }

    if (Test-Path $dst) {
        $bak = "$dst.bak-$stamp"
        if ($PSCmdlet.ShouldProcess($dst, "backup -> $bak")) {
            Copy-Item $dst $bak -Force
        }
    }

    if ($PSCmdlet.ShouldProcess($dst, "install from $($entry.Key)")) {
        Copy-Item $src $dst -Force
        Write-Host "OK    $($entry.Key) -> $dst" -ForegroundColor Green
    }
}

# Claude Code settings.json — merge ADDITIVELY: only set the statusLine key,
# leaving any existing permissions / plugins / other keys on the machine intact.
$fragment = Get-Content (Join-Path $files 'claude-code\settings.json') -Raw | ConvertFrom-Json

if (Test-Path $claudeSettings) {
    $existing = Get-Content $claudeSettings -Raw | ConvertFrom-Json
    $bak = "$claudeSettings.bak-$stamp"
    if ($PSCmdlet.ShouldProcess($claudeSettings, "backup -> $bak")) { Copy-Item $claudeSettings $bak -Force }
} else {
    $dir = Split-Path $claudeSettings -Parent
    if (-not (Test-Path $dir) -and $PSCmdlet.ShouldProcess($dir, 'create directory')) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $existing = [pscustomobject]@{}
}

foreach ($key in $fragment.PSObject.Properties.Name) {
    $existing | Add-Member -NotePropertyName $key -NotePropertyValue $fragment.$key -Force
}

if ($PSCmdlet.ShouldProcess($claudeSettings, 'merge statusLine into settings.json')) {
    $existing | ConvertTo-Json -Depth 20 | Set-Content $claudeSettings -Encoding UTF8
    Write-Host "OK    claude-code\settings.json (statusLine merged) -> $claudeSettings" -ForegroundColor Green
}

Write-Host "`nDone. Restart Windows Terminal and open a new PowerShell tab." -ForegroundColor Cyan
Write-Host "Windows Terminal is configured by hand (see TERMINAL-SPEC.md §1):" -ForegroundColor Cyan
Write-Host "  profiles.defaults -> colorScheme: Retrowave, font.face: RobotoMono Nerd Font Mono, cursorShape: filledBox" -ForegroundColor Cyan
Write-Host "  and paste files\windows-terminal\retrowave.json into the schemes array" -ForegroundColor Cyan
