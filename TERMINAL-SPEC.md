# Terminal Visuals — Configuration Specification

A complete dump of the terminal appearance/statusline setup on this machine, so it
can be reproduced or version-controlled.

- **OS:** Windows 11 Pro 10.0.26200
- **Captured:** 2026-06-18 (updated 2026-07-12: color scheme Dimidium → Retrowave;
  yellow foreground + cursor color baked into scheme, font size 10, `intenseTextStyle: bright`;
  oh-my-posh theme rewritten to mirror the Claude Code statusline)
- **Shell:** PowerShell 7.6.2 (PowerShell Core / `pwsh`)
- **Terminal:** Windows Terminal 1.21.10351.0

---

## 1. Windows Terminal

**Settings file:**
`C:\Users\greg\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json`

### Global

| Setting | Value |
|---|---|
| `defaultProfile` | `{574e775e-4f2a-5b96-ac1e-a2962a402336}` (PowerShell Core) |
| `disableAnimations` | `true` |
| `compatibility.enableUnfocusedAcrylic` | `false` |
| `copyOnSelect` | `true` |
| `copyFormatting` | `none` |

### Default profile appearance (`profiles.defaults`)

| Setting | Value |
|---|---|
| `colorScheme` | **Retrowave** |
| `cursorShape` | `filledBox` |
| `font.face` | **RobotoMono Nerd Font Mono** |
| `font.size` | `10` |
| `intenseTextStyle` | `bright` |

> On this machine the yellow text (`foreground: #FFD866`) and cursor color
> (`cursorColor: #4B95E9`) are set as `profiles.defaults` overrides, but they are
> baked into the shipped `retrowave.json` scheme — a new machine only needs the
> five keys above plus the scheme.

> The Nerd Font face is required — both the oh-my-posh prompt and the Claude Code
> statusline use Nerd Font / Powerline glyphs (, , , , …).

### Keybindings

| Keys | Action |
|---|---|
| `ctrl+c` | copy (`singleLine: false`) |
| `ctrl+v` | paste |
| `ctrl+shift+f` | find |
| `alt+shift+d` | split pane (`auto`, duplicate) |

### Visible profiles

- **PowerShell** (Core) — default
- Command Prompt
- Ubuntu (WSL)
- Several Visual Studio Developer prompts (2022 / 18)
- Hidden: Windows PowerShell (v1.0), Azure Cloud Shell

### Color scheme: "Retrowave"

A custom neon-on-dark-navy scheme, **not** a Terminal built-in. It lives explicitly in
the `schemes` array of `settings.json` on this machine, and is tracked in this repo as
`files/windows-terminal/retrowave.json` — paste that file's contents into the `schemes`
array on a new machine.

```json
{
    "name": "Retrowave",
    "background": "#070825",
    "foreground": "#FFD866",
    "cursorColor": "#4B95E9",
    "selectionBackground": "#FFFFFF",
    "black":        "#181A1F",
    "red":          "#FF16B0",
    "green":        "#929292",
    "yellow":       "#FCEE54",
    "blue":         "#46BDFF",
    "purple":       "#FF92DF",
    "cyan":         "#DF81FC",
    "white":        "#FFFFFF",
    "brightBlack":  "#FF16B0",
    "brightRed":    "#F85353",
    "brightGreen":  "#FCEE54",
    "brightYellow": "#FFFFFF",
    "brightBlue":   "#46BDFF",
    "brightPurple": "#FF92DF",
    "brightCyan":   "#FF901F",
    "brightWhite":  "#FFFFFF"
}
```

---

## 2. PowerShell

### Profile

**File:** `C:\Users\greg\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

```powershell
oh-my-posh init pwsh --config ~/omp.json | Invoke-Expression
function cc { claude $args }
```

- Prompt engine: **oh-my-posh 29.13.1** (`...\WindowsApps\oh-my-posh.exe`)
- Theme config: `C:\Users\greg\omp.json` (see below)
- `cc` is a shorthand alias for `claude`
- `$env:POSH_THEME` is not set (theme is passed explicitly via `--config`)

### oh-my-posh theme — `~/omp.json`

Schema v4. A flat, transparent-background prompt that **mirrors the Claude Code
statusline** (§3) — same glyphs, same standard ANSI colors, so both render
identically under the Retrowave scheme:

```
 <dir>   <branch> +<staged> ~<unstaged> ?<untracked> ❯
```

No palette — all colors are named ANSI colors (`cyan`, `lightBlue`, …), which emit
the same SGR codes the statusline uses and inherit the Windows Terminal scheme.

**Left prompt segments (all `style: plain`, background transparent)**

| Segment | Glyph | Color | SGR |
|---|---|---|---|
| **path** (`style: folder` — cwd leaf) |  | cyan | 36 |
| **git** branch (`.HEAD`, branch truncated 25) |  | lightBlue | 94 |
| — staged count (`+n` = Staging Added+Deleted+Modified+Unmerged) |  | green | 32 |
| — unstaged count (`~n` = Working Modified+Deleted+Unmerged) |  | yellow | 33 |
| — untracked count (`?n` = Working.Untracked) |  | magenta | 35 |
| **root** — only when elevated |  | yellow | 33 |
| **status** — prompt char, always shown | ❯ | green; **red** on non-zero exit | 32 / 31 |

**Other**

- No right prompt (the statusline's token counter has no terminal analog).
- `transient_prompt`: cyan ` <folder>` + blue `❯`; `secondary_prompt`: blue `❯❯`.
- `console_title_template`: `"{{ .Shell }} in {{ .Folder }}"`.
- `final_space: true`.
- oh-my-posh auto-upgrade: disabled (`upgrade.auto: false`, no notice).

---

## 3. Claude Code statusline

**Registered in:** `C:\Users\greg\.claude\settings.json`

```json
"statusLine": {
    "type": "command",
    "command": "pwsh -NoProfile -File C:/Users/greg/.claude/statusline.ps1"
}
```

**Script:** `C:\Users\greg\.claude\statusline.ps1`

Reads the Claude Code status JSON from stdin and emits one ANSI-colored line:

```
 <dir>   <branch> +<staged> ~<unstaged> ?<untracked> <MODEL>  <usedK>k/<totalK>k
```

**Segments & colors (ANSI SGR codes)**

| Segment | Glyph | Color | Code |
|---|---|---|---|
| Directory (cwd leaf) |  | Cyan | 36 |
| Git branch |  | Bright blue | 94 |
| Staged (`+n`) |  | Green | 32 |
| Unstaged (`~n`) |  | Yellow | 33 |
| Untracked (`?n`) |  | Magenta | 35 |
| Model shorthand (`Sonnet 5` → `S5`, `Opus 4.8` → `O4.8`) | — | Fixed gray (palette-independent) | 38;5;245 |
| Token counter (< 100k) |  | Fixed gray (palette-independent) | 38;5;245 |
| Token counter (100–150k) |  | Yellow | 33 |
| Token counter (> 150k) |  | Red | 31 |

**Behavior**

- Directory = leaf of `workspace.current_dir` (falls back to `cwd`).
- Git section only when cwd is inside a repo; counts via `git diff --cached`,
  `git diff`, and `git ls-files --others --exclude-standard`.
- Model shorthand from `model.display_name`: first letter of each alphabetic word
  (uppercased) + numeric tokens kept verbatim, joined without spaces.
- Token budget: `totalK` = **1000** when the model id contains `[1m]`/`1m`,
  otherwise **200** (display only — does not affect the counter color).
- Counter color uses **absolute** used-token thresholds (not % of window):
  gray < 100k, yellow 100–150k, red > 150k.
  Tokens summed from the last usage entry in the tail (80 lines) of the transcript:
  `input + cache_read + cache_creation`.
- Output forced to UTF-8 for correct glyph rendering.

---

## 4. Reproduction checklist

To recreate this look on a fresh machine:

1. Install **PowerShell 7+**, **Windows Terminal**, and a **RobotoMono Nerd Font**.
2. Install **oh-my-posh** (`winget install JanDeDobbeleer.OhMyPosh`).
3. Copy `omp.json` → `~/omp.json`.
4. Create the PowerShell profile with the two lines in §2.
5. Set Windows Terminal `profiles.defaults`: `colorScheme: Retrowave`,
   `font.face: RobotoMono Nerd Font Mono`, `font.size: 10`, `cursorShape: filledBox`,
   `intenseTextStyle: bright`. Paste the Retrowave scheme (§1, tracked as
   `files/windows-terminal/retrowave.json`) into the `schemes` array.
6. Copy `statusline.ps1` → `~/.claude/statusline.ps1` and add the `statusLine` block
   to `~/.claude/settings.json`.

---

## 5. Source file inventory

| Purpose | Path |
|---|---|
| PowerShell profile | `C:\Users\greg\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| oh-my-posh theme | `C:\Users\greg\omp.json` |
| Windows Terminal settings | `…\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` |
| Claude Code settings | `C:\Users\greg\.claude\settings.json` |
| Claude Code statusline | `C:\Users\greg\.claude\statusline.ps1` |
