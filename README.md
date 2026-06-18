# terminal-visuals

My terminal look on Windows — PowerShell + oh-my-posh prompt, Windows Terminal
(Dimidium / RobotoMono Nerd Font), and a custom Claude Code statusline — tracked so I
can push it to GitHub and reinstall on any machine.

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
    │   └── settings.json
    └── claude-code/
        ├── settings.json
        └── statusline.ps1
```

| File | Installs to |
|---|---|
| `files/powershell/Microsoft.PowerShell_profile.ps1` | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| `files/oh-my-posh/omp.json` | `~\omp.json` |
| `files/windows-terminal/settings.json` | `…\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| `files/claude-code/settings.json` | `~\.claude\settings.json` |
| `files/claude-code/statusline.ps1` | `~\.claude\statusline.ps1` |

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

The PowerShell profile, oh-my-posh theme, Windows Terminal settings, and
`statusline.ps1` are **full-file copies**. The Claude Code `settings.json` is the one
exception: it's merged **additively** — only the `statusLine` key is written into your
existing `~/.claude/settings.json`, leaving any permissions, plugins, and other keys on
that machine untouched.

## ⚠️ Notes before pushing public

- **`files/claude-code/settings.json` contains only the `statusLine` key** (path uses
  `~`, not an absolute `C:/Users/greg/...`). It is *not* a full settings file — the
  installer merges this key into whatever `~/.claude/settings.json` already exists, so
  no permissions or plugins are shipped or clobbered.
- **`files/windows-terminal/settings.json`** references the `Dimidium` color scheme by
  name without defining it (it resolves as a Terminal built-in). See TERMINAL-SPEC.md
  §1 for an explicit scheme block you can paste in if a machine lacks it.
