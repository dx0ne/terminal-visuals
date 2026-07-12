# Terminal Visuals — Configuration Specification

A complete dump of the terminal appearance/statusline setup on this machine, so it
can be reproduced or version-controlled.

- **OS:** Windows 11 Pro 10.0.26200
- **Captured:** 2026-06-18 (updated 2026-07-12: color scheme Dimidium → Retrowave)
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
| `copyOnSelect` | `false` |
| `copyFormatting` | `none` |

### Default profile appearance (`profiles.defaults`)

| Setting | Value |
|---|---|
| `colorScheme` | **Retrowave** |
| `cursorShape` | `filledBox` |
| `font.face` | **RobotoMono Nerd Font Mono** |

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
    "foreground": "#46BDFF",
    "black":        "#181A1F",
    "red":          "#FF16B0",
    "green":        "#929292",
    "yellow":       "#fcee54",
    "blue":         "#46BDFF",
    "purple":       "#FF92DF",
    "cyan":         "#df81fc",
    "white":        "#FFFFFF",
    "brightBlack":  "#FF16B0",
    "brightRed":    "#f85353",
    "brightGreen":  "#fcee54",
    "brightYellow": "#ffffff",
    "brightBlue":   "#46BDFF",
    "brightPurple": "#FF92DF",
    "brightCyan":   "#ff901f",
    "brightWhite":  "#ffffff"
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

Schema v4. A "diamond + powerline" prompt.

**Palette**

| Name | Hex |
|---|---|
| black | `#262B44` |
| blue | `#4B95E9` |
| green | `#59C9A5` |
| orange | `#F07623` |
| white | `#E0DEF4` |
| yellow | `#F3AE35` |
| red | `#D81E5B` |

**Left prompt blocks (in order)**

1. **path** (diamond, `style: folder`) — white on **orange**, leading icon ``.
2. **git** (powerline) — black on **green** by default, with background overrides:
   - changed (working/staging) → **yellow** (text black)
   - ahead **and** behind → **red** (text white)
   - ahead only → `#49416D` (text white)
   - behind only → `#7A306C`
   - Shows upstream icon, branch (truncated 25), branch status, working/staging counts.
3. **root** (powerline) — white on **yellow**, shown only when elevated.
4. **status** (diamond) — exit-status glyph; white on **blue**, turns **red** on non-zero exit.

**Right prompt (rprompt)**

- **python** segment (yellow, `display_mode: files`) — venv indicator.
- **time** segment — `at HH:MM:SS` (time in blue/bold, "at" in white).

**Other**

- `transient_prompt` and `secondary_prompt`: minimal yellow `` chevron form.
- `console_title_template`: `"{{ .Shell }} in {{ .Folder }}"`.
- `final_space: true`.
- oh-my-posh auto-upgrade: disabled (`upgrade.auto: false`, no notice).
- `_tui.disabled` holds segments toggled off in the configure UI (session/username,
  node, go, shell name, AWS & Azure tooltips) — present but inactive.

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
 <dir>   <branch> +<staged> ~<unstaged> ?<untracked>   <usedK>k/<totalK>k
```

**Segments & colors (ANSI SGR codes)**

| Segment | Glyph | Color | Code |
|---|---|---|---|
| Directory (cwd leaf) |  | Cyan | 36 |
| Git branch |  | Bright blue | 94 |
| Staged (`+n`) |  | Green | 32 |
| Unstaged (`~n`) |  | Yellow | 33 |
| Untracked (`?n`) |  | Magenta | 35 |
| Token counter (<70%) |  | Dark gray | 90 |
| Token counter (70–90%) |  | Yellow | 33 |
| Token counter (>90%) |  | Red | 31 |

**Behavior**

- Directory = leaf of `workspace.current_dir` (falls back to `cwd`).
- Git section only when cwd is inside a repo; counts via `git diff --cached`,
  `git diff`, and `git ls-files --others --exclude-standard`.
- Token budget: `totalK` = **1000** when the model id contains `[1m]`/`1m`,
  otherwise **200**.
- Used % preference order: `context_window.used_percentage` →
  `tokens / context_window_size` → `tokens / (totalK*1000)`.
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
   `font.face: RobotoMono Nerd Font Mono`, `cursorShape: filledBox`. Paste the
   Retrowave scheme (§1, tracked as `files/windows-terminal/retrowave.json`) into
   the `schemes` array.
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
