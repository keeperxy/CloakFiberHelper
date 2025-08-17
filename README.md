## CloakFiberHelper

Checks whether your equipped cloak contains a fiber from the correct category for your current specialization. Comes with an in-game options panel and optional slash commands.

### Features
- Auto-scan on login, on cloak change, and when changing specialization
- **Multi-mode support**: Different fiber preferences for Outdoor, Mythic+, and Raid content
- **Smart detection**: Automatically detects when you enter Mythic+ dungeons or raids
- In-game configuration via Options → AddOns or `/cfh`
- Manual scan via slash command or a small "Scan now" button
- Per-character settings (SavedVariables)
- Per-spec and per-mode desired fiber category (Critical Strike, Haste, Versatility, Mastery)
- Restrict to specific allowed cloak ItemIDs
- **Session control**: Temporarily disable popup warning via chat command
- English and German localization

### Quick start
Open the options panel and configure everything in-game:

```text
/cfh
```

In the options panel you can:
- **Cloaks**: add ItemIDs, see current cloaks (with names), and remove entries.
- **Specializations**: Configure fiber preferences for each spec across three game modes:
  - **Outdoor**: General world content
  - **M+**: Mythic+ dungeons (detected automatically)
  - **Raid**: Raid instances (detected automatically)

Manually trigger a scan at any time:

```text
/cfh scan
```

### Configuring fiber preferences
**Preferred method**: Use the options panel (Options → AddOns → Cloak Fiber Helper or `/cfh`).

The options panel shows a table with:
- **Rows**: Your specializations (e.g., Brewmaster, Mistweaver, Windwalker)
- **Columns**: Game modes (Outdoor, M+, Raid)
- **Dropdowns**: Select the desired fiber for each spec/mode combination

**Legacy slash commands** (for Outdoor mode only):
Valid categories: `crit`, `haste`, `versa` (versatility), `mastery` (or their localized names).

- Assign for your current spec: `/cfh set crit`
- Assign for a specific spec ID: `/cfh set haste 266`

Tip: Use `/cfh show` to list your specs with their spec IDs and current assignments.

### Restricting to allowed cloak ItemIDs
Preferred: use the options panel to add/remove ItemIDs in the Cloaks section.

Alternatively, replace the list with a comma-separated list:

```text
/cfh cloaks 235499,12345,67890
```

The scan will only succeed if the equipped cloak's ItemID is in this list.

### When does the addon scan?
- On login/entering world (after a short delay)
- When you change the cloak in equipment slot 15
- When you change specialization
- **When entering different content types** (Outdoor ↔ Mythic+ ↔ Raid)
- On demand via `/cfh scan`

You may also see a small button labeled "Scan now" that triggers the same check.

### Session control
You can temporarily disable popup warnings if you're intentionally using a different fiber:
- **Chat commands**:
  - `/cfh sessiondisable` - Disable popup warnings for this session (until reload/relog)
  - `/cfh sessionenable` - Re-enable popup warnings for this session
- **Automatic hint**: When wrong fiber is detected, the addon shows these commands in chat

### Messages and popups
Console/chat messages are prefixed with `[CFH]` and show the current game mode context.

- **Success**: `Cloak and fiber are OK for <Category>`
- **Warnings/Errors**:
  - `No allowed cloak equipped.`
  - `No fiber detected in cloak.`
  - `Unassigned (spec <id>)` — No fiber preference set for current spec/mode
  - `Equipped fiber <Actual> is not in desired category <Expected>.`

**Popups** (appear once per session unless condition changes):
- **Wrong fiber**: Shows actual vs expected fiber category
- **No allowed cloak**: Notification when equipped cloak is not in allowed list

**Session control hints**: When wrong fiber is detected, chat shows available commands to disable/enable popup warnings.

### Slash command reference
```text
/cfh
  Opens the options panel.

/cfh scan
  Triggers an immediate scan of your cloak and fibers.

/cfh sessiondisable
  Disables popup warnings for this session (until reload/relog).

/cfh sessionenable
  Re-enables popup warnings for this session.

/cfh set <crit|haste|versa|mastery> [specID]
  Sets the desired fiber category for the given spec (Outdoor mode only).
  If specID is omitted, applies to your current spec.

/cfh cloaks <id1,id2,...>
  Replaces the allowed cloak ItemID list with the provided comma-separated IDs.
```

### Localization
Currently supported: English (`enUS`) and German (`deDE`). To add a new locale, add a new file under `Locales/` (e.g., `frFR.lua`) populating the `CGH_L` table.

### Troubleshooting
- If item data is not yet cached by the client, the addon will delay and auto-rescan once data is available.
- Ensure your cloak has a socket and an inserted fiber. If no fiber is detected, the scan will warn you.
- If you changed your cloak or spec, run `/cfh scan` to re-check immediately.


