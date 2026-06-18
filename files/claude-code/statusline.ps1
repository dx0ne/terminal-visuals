param()
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ANSI color helpers
function ansi([int]$code, [string]$text) { "$([char]27)[${code}m${text}$([char]27)[0m" }

# Color palette (standard ANSI SGR codes, compatible with Windows Terminal)
$clrDir      = 36   # Cyan          — directory
$clrBranch   = 94   # Bright blue   — git branch glyph + name
$clrStaged   = 32   # Green         — staged changes (+)
$clrUnstaged = 33   # Yellow        — unstaged changes (~)
$clrUntrack  = 35   # Magenta       — untracked files (?)
$clrTokensLow  = 90   # Dark gray     — token counter < 70%
$clrTokensMid  = 33   # Yellow        — token counter 70–90%
$clrTokensHigh = 31   # Red           — token counter > 90%

$raw = [Console]::In.ReadToEnd()
if (-not $raw) { return }
$ctx = $raw | ConvertFrom-Json

$cwd = $ctx.workspace.current_dir
if (-not $cwd) { $cwd = $ctx.cwd }
$dir = if ($cwd) { Split-Path $cwd -Leaf } else { '?' }

# Directory segment
$dirPart = ansi $clrDir "$([char]0xf07c) $dir"

# Git section
$gitPart = ''
if ($cwd -and (Test-Path $cwd)) {
    $null = & git -C $cwd rev-parse --git-dir 2>$null
    if ($LASTEXITCODE -eq 0) {
        $branch = & git -C $cwd symbolic-ref --short HEAD 2>$null
        if (-not $branch) { $branch = & git -C $cwd rev-parse --short HEAD 2>$null }

        $staged    = @(& git -C $cwd diff --cached --name-only 2>$null).Count
        $unstaged  = @(& git -C $cwd diff --name-only 2>$null).Count
        $untracked = @(& git -C $cwd ls-files --others --exclude-standard 2>$null).Count

        $gitPart = " " + (ansi $clrBranch "$([char]0xe0a0) $branch")
        if ($staged    -gt 0) { $gitPart += " " + (ansi $clrStaged   "$([char]0xf067)+$staged") }
        if ($unstaged  -gt 0) { $gitPart += " " + (ansi $clrUnstaged "$([char]0xf111)~$unstaged") }
        if ($untracked -gt 0) { $gitPart += " " + (ansi $clrUntrack  "$([char]0xf128)?$untracked") }
    }
}

# Context tokens from transcript
$ctxPart = ''
$transcript = $ctx.transcript_path
$modelId = $ctx.model.id
$totalK = if ($modelId -match '\[1m\]|1m') { 1000 } else { 200 }

if ($transcript -and (Test-Path $transcript)) {
    $lines = Get-Content $transcript -Tail 80
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try {
            $entry = $lines[$i] | ConvertFrom-Json
            $u = $entry.message.usage
            if ($u) {
                $inp   = if ($u.input_tokens)                { [int]$u.input_tokens }                else { 0 }
                $cread = if ($u.cache_read_input_tokens)     { [int]$u.cache_read_input_tokens }     else { 0 }
                $ccrt  = if ($u.cache_creation_input_tokens) { [int]$u.cache_creation_input_tokens } else { 0 }
                $tokens = $inp + $cread + $ccrt
                if ($tokens -gt 0) {
                    $usedK = [math]::Round($tokens / 1000)
                    $maxTokens = $totalK * 1000

                    # Prefer the pre-calculated used_percentage from JSON input if present
                    $pct = $null
                    if ($ctx.context_window -and $ctx.context_window.used_percentage -ne $null) {
                        $pct = [double]$ctx.context_window.used_percentage
                    } elseif ($ctx.context_window -and $ctx.context_window.context_window_size -gt 0) {
                        $cwSize = [double]$ctx.context_window.context_window_size
                        $pct = ($tokens / $cwSize) * 100
                    } else {
                        $pct = ($tokens / $maxTokens) * 100
                    }

                    $clrTokens = if ($pct -ge 90) { $clrTokensHigh }
                                 elseif ($pct -ge 70) { $clrTokensMid }
                                 else { $clrTokensLow }

                    $ctxPart = " " + (ansi $clrTokens "$([char]0xf080) ${usedK}k/${totalK}k")
                    break
                }
            }
        } catch { continue }
    }
}

"$dirPart$gitPart$ctxPart"
