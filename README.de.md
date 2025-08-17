## Faser Helfer (CloakFiberHelper)

Prüft, ob dein ausgerüsteter Umhang eine Faser aus der gewünschten Kategorie für deine aktuelle Spezialisierung enthält. Enthält ein Ingame-Optionsmenü sowie optionale Slash-Befehle.

### Funktionen
- Auto-Scan beim Login, beim Umhangwechsel und beim Spezialisationswechsel
- **Multi-Modus-Unterstützung**: Verschiedene Faser-Präferenzen für Outdoor, Mythic+ und Raid-Inhalte
- **Intelligente Erkennung**: Erkennt automatisch Mythic+-Dungeons und Raids
- Ingame-Konfiguration über Optionen → AddOns oder `/cfh`
- Manueller Scan per Slash-Befehl oder über einen kleinen „Jetzt prüfen"-Button
- Einstellungen pro Charakter (SavedVariables)
- Gewünschte Faser-Kategorie pro Skillung und Spielmodus (Kritische Trefferchance, Tempo, Vielseitigkeit, Meisterschaft)
- Einschränkung auf erlaubte Umhang-ItemIDs
- **Session-Kontrolle**: Popup-Warnungen temporär per Chat-Befehl deaktivieren
- Lokalisierung auf Deutsch und Englisch

### Schnellstart
Optionsmenü öffnen und alles ingame konfigurieren:

```text
/cfh
```

Im Optionsmenü kannst du:
- **Umhänge**: ItemIDs hinzufügen, aktuelle Umhänge (mit Namen) sehen und Einträge entfernen.
- **Spezialisierungen**: Faser-Präferenzen für jede Skillung in drei Spielmodi konfigurieren:
  - **Outdoor**: Allgemeine Weltinhalte
  - **M+**: Mythic+-Dungeons (automatisch erkannt)
  - **Raid**: Raid-Instanzen (automatisch erkannt)

Manuellen Scan jederzeit auslösen:

```text
/cfh scan
```

### Faser-Präferenzen konfigurieren
**Bevorzugte Methode**: Über das Optionsmenü (Optionen → AddOns → Cloak Fiber Helper oder `/cfh`).

Das Optionsmenü zeigt eine Tabelle mit:
- **Zeilen**: Deine Spezialisierungen (z.B. Braumeister, Nebelwirker, Windläufer)
- **Spalten**: Spielmodi (Outdoor, M+, Raid)
- **Dropdowns**: Gewünschte Faser für jede Skillung/Modus-Kombination auswählen

**Legacy-Slash-Befehle** (nur für Outdoor-Modus):
Gültige Kategorien: `crit`, `haste`, `versa` (Vielseitigkeit), `mastery` (oder die lokalisierten Namen).

- Für die aktuelle Skillung setzen: `/cfh set crit`
- Für eine spezifische Spezialisations-ID setzen: `/cfh set haste 266`

Tipp: Mit `/cfh show` siehst du deine Skillungen mit deren IDs und aktuellen Zuordnungen.

### Erlaubte Umhänge begrenzen
Bevorzugt: über das Optionsmenü im Bereich „Umhänge" ItemIDs hinzufügen/entfernen.

Alternativ die Liste direkt ersetzen (kommasepariert):

```text
/cfh cloaks 235499,12345,67890
```

Der Scan ist nur erfolgreich, wenn der ausgerüstete Umhang in dieser Liste enthalten ist.

### Wann wird gescannt?
- Beim Login/Welt betreten (mit kurzer Verzögerung)
- Beim Wechsel des Umhangs im Ausrüstungsslot 15
- Beim Wechsel der Spezialisierung
- **Beim Wechsel zwischen verschiedenen Inhaltstypen** (Outdoor ↔ Mythic+ ↔ Raid)
- Manuell via `/cfh scan`

Zusätzlich kann ein kleiner Button „Jetzt prüfen" erscheinen, der denselben Check auslöst.

### Session-Kontrolle
Du kannst Popup-Warnungen temporär deaktivieren, wenn du bewusst eine andere Faser verwendest:
- **Chat-Befehle**:
  - `/cfh sessiondisable` - Popup-Warnungen für diese Session deaktivieren (bis Reload/Relog)
  - `/cfh sessionenable` - Popup-Warnungen für diese Session wieder aktivieren
- **Automatischer Hinweis**: Wenn falsche Faser erkannt wird, zeigt das Addon diese Befehle im Chat an

### Mögliche Meldungen und Popups
Konsolen-/Chat-Meldungen sind mit `[CFH]` prefixiert und zeigen den aktuellen Spielmodus-Kontext.

- **Erfolg**: `Umhang und Faser sind OK für <Kategorie>`
- **Warnungen/Fehler**:
  - `Kein erlaubter Umhang ausgerüstet.`
  - `Keine Faser im Umhang gefunden.`
  - `Nicht zugewiesen (spec <id>)` — Keine Faser-Präferenz für aktuelle Skillung/Modus gesetzt
  - `Eingesetzte Faser <Aktuell> gehört nicht zur gewünschten Kategorie <Erwartet>.`

**Popups** (erscheinen einmal pro Sitzung, außer die Situation ändert sich):
- **Falsche Faser**: Zeigt aktuelle vs. erwartete Faser-Kategorie
- **Kein erlaubter Umhang**: Benachrichtigung wenn ausgerüsteter Umhang nicht in erlaubter Liste steht

**Session-Kontrolle Hinweise**: Wenn falsche Faser erkannt wird, zeigt der Chat verfügbare Befehle zum Deaktivieren/Aktivieren der Popup-Warnungen.

### Slash-Befehle
```text
/cfh
  Öffnet das Optionsmenü.

/cfh scan
  Startet sofort eine Prüfung des Umhangs und der Fasern.

/cfh sessiondisable
  Deaktiviert Popup-Warnungen für diese Session (bis Reload/Relog).

/cfh sessionenable
  Aktiviert Popup-Warnungen für diese Session wieder.

/cfh set <crit|haste|versa|mastery> [specID]
  Setzt die gewünschte Faser-Kategorie für die angegebene Skillung (nur Outdoor-Modus).
  Ohne specID gilt die aktuelle Skillung.

/cfh cloaks <id1,id2,...>
  Ersetzt die Liste erlaubter Umhang-ItemIDs durch die angegebenen IDs (kommasepariert).
```

### Lokalisierung
Aktuell unterstützt: Englisch (`enUS`) und Deutsch (`deDE`). Weitere Sprachen können durch eine Datei in `Locales/` (z. B. `frFR.lua`) ergänzt werden, die die Tabelle `CGH_L` befüllt.

### Fehlerbehebung
- Falls Itemdaten noch nicht gecached sind, wartet das Addon und führt den Scan automatisch erneut aus, sobald die Daten vorliegen.
- Achte darauf, dass dein Umhang einen Sockel hat und eine Faser eingesetzt ist. Wenn keine Faser erkannt wird, gibt es eine entsprechende Meldung.
- Nach Umhang- oder Skillungswechsel kannst du mit `/cfh scan` sofort neu prüfen.