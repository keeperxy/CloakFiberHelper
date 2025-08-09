## CloakFiberHelper

Checks whether your equipped cloak contains a fiber from the correct category for your current specialization. Provides simple slash commands and a small helper UI.

### Features
- Auto-scan on login, on cloak change, and when changing specialization
- Manual scan via slash command or a small "Scan now" button
- Per-character settings (SavedVariables)
- Per-spec desired fiber category (Critical Strike, Haste, Versatility, Mastery)
- Restrict to specific allowed cloak ItemIDs
- English and German localization

### Quick start
Open the helper and see usage hints:

```text
/cfh show
```

Manually trigger a scan:

```text
/cfh scan
```

### Assigning a desired fiber per specialization
You can assign by name or number. Valid categories: `crit`, `haste`, `versa` (versatility), `mastery` (or their localized names).

- Assign for your current spec:

```text
/cfh set crit
```

- Assign for a specific spec ID (e.g., Demonology Warlock 266):

```text
/cfh set haste 266
```

Tip: Use `/cfh show` to list your specs with their spec IDs and current assignment.

### Restricting to allowed cloak ItemIDs
By default the addon allows cloak ItemID `235499`. You can override the allowed list with a comma-separated list:

```text
/cfh cloaks 235499,12345,67890
```

The scan will only succeed if the equipped cloak's ItemID is in this list.

### When does the addon scan?
- On login/entering world (after a short delay)
- When you change the cloak in equipment slot 15
- When you change specialization
- On demand via `/cfh scan`

You may also see a small button labeled "Scan now" that triggers the same check.

### Possible messages and popups
Console/chat messages are prefixed with `[CFH]`.

- Success:
  - `Cloak and fiber are OK for <Category>`
- Warnings/Errors:
  - `No allowed cloak equipped.`
  - `No fiber detected in cloak.`
  - `Unassigned (spec <id>)` — You have not set a desired category for this spec yet
  - `Equipped fiber <Actual> is not in desired category <Expected>.`

Popups (can appear once per session until the condition changes):
- Wrong fiber: shows actual vs expected fiber category
- No allowed cloak equipped

### Slash command reference
```text
/cfh show
  Prints current configuration, spec IDs with their assigned fiber categories, and usage hints.

/cfh scan
  Triggers an immediate scan of your cloak and fibers.

/cfh set <crit|haste|versa|mastery> [specID]
  Sets the desired fiber category for the given spec. If specID is omitted, applies to your current spec.

/cfh cloaks <id1,id2,...>
  Replaces the allowed cloak ItemID list with the provided comma-separated IDs.
```

### Localization
Currently supported: English (`enUS`) and German (`deDE`). To add a new locale, add a new file under `Locales/` (e.g., `frFR.lua`) populating the `CGH_L` table.

### Troubleshooting
- If item data is not yet cached by the client, the addon will delay and auto-rescan once data is available.
- Ensure your cloak has a socket and an inserted fiber. If no fiber is detected, the scan will warn you.
- If you changed your cloak or spec, run `/cfh scan` to re-check immediately.


