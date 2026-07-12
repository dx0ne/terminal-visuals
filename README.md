# terminal-visuals

My terminal look on Windows — PowerShell + oh-my-posh prompt, Windows Terminal
(Retrowave / RobotoMono Nerd Font), and a custom Claude Code statusline — tracked so I
can push it to GitHub and reinstall on any machine. The oh-my-posh prompt deliberately
mirrors the Claude Code statusline (same glyphs and ANSI colors:
` dir   branch +staged ~unstaged ?untracked ❯`), so the shell prompt and Claude's
statusline look like one system.

See **[TERMINAL-SPEC.md](TERMINAL-SPEC.md)** for a full description of every setting.

## Layout

```
terminal-visuals/
├── README.md
├── TERMINAL-SPEC.md          # human-readable spec of the whole setup
├── install.ps1               # copies files/ into place (with backups)
└── files/                    # the actual source files, ready to deploy
    ├── powershell/
    │   └── Microsoft.PowerShell_profile.ps1
    ├── oh-my-posh/
    │   └── omp.json
    ├── windows-terminal/
    │   └── retrowave.json    # color scheme — pasted into Terminal's schemes array by hand
    └── claude-code/
        ├── settings.json
        └── statusline.ps1
```

| File | Installs to |
|---|---|
| `files/powershell/Microsoft.PowerShell_profile.ps1` | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `files/oh-my-posh/omp.json` | `~\omp.json` |
| `files/claude-code/settings.json` | merged into `~\.claude\settings.json` (statusLine only) |
| `files/claude-code/statusline.ps1` | `~\.claude\statusline.ps1` |

**Windows Terminal is configured by hand** — the few keys that define the look
(`colorScheme: Retrowave`, `font.face: RobotoMono Nerd Font Mono`, `font.size: 10`,
`cursorShape: filledBox`, `intenseTextStyle: bright`)
are documented in [TERMINAL-SPEC.md §1](TERMINAL-SPEC.md#1-windows-terminal), and the
`Retrowave` scheme itself ships as `files/windows-terminal/retrowave.json` — paste it into
the `schemes` array. The full machine-specific settings file is intentionally **not**
shipped, so installing never clobbers a machine's own Terminal profiles/keybindings.

## Install on a new machine

Prerequisites:

```powershell
winget install Microsoft.PowerShell
winget install Microsoft.WindowsTerminal
winget install JanDeDobbeleer.OhMyPosh
# + install a RobotoMono Nerd Font from https://www.nerdfonts.com/
```

Then from the repo root:

```powershell
pwsh -File .\install.ps1            # back up existing files, then install
pwsh -File .\install.ps1 -WhatIf    # dry run — show what would change
```

Existing files are backed up to `<file>.bak-<timestamp>` before being changed.
Restart Windows Terminal afterward.

The PowerShell profile, oh-my-posh theme, and `statusline.ps1` are **full-file copies**.
The Claude Code `settings.json` is the one exception: it's merged **additively** — only
the `statusLine` key is written into your existing `~/.claude/settings.json`, leaving any
permissions, plugins, and other keys on that machine untouched.

## Notes

- **`files/claude-code/settings.json` contains only the `statusLine` key** (path uses
  `~`, not an absolute `C:/Users/greg/...`). It is *not* a full settings file — the
  installer merges this key into whatever `~/.claude/settings.json` already exists, so
  no permissions or plugins are shipped or clobbered.
- **Windows Terminal settings are not shipped.** The `Retrowave` scheme is **not** a
  Terminal built-in — paste `files/windows-terminal/retrowave.json` into the `schemes`
  array (same block as TERMINAL-SPEC.md §1). Set the five appearance keys by hand.
  The scheme now carries the yellow foreground (`#FFD866`) and cursor color (`#4B95E9`)
  itself, so no per-profile color overrides are needed on a new machine.
