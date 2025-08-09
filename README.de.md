## Faser Helfer (CloakFiberHelper)

Prüft, ob dein ausgerüsteter Umhang eine Faser aus der gewünschten Kategorie für deine aktuelle Spezialisierung enthält. Enthält ein Ingame-Optionsmenü sowie optionale Slash-Befehle.

### Funktionen
- Auto-Scan beim Login, beim Umhangwechsel und beim Spezialisationswechsel
- Ingame-Konfiguration über Optionen → AddOns oder `/cfh`
- Manueller Scan per Slash-Befehl oder über einen kleinen „Jetzt prüfen“-Button
- Einstellungen pro Charakter (SavedVariables)
- Gewünschte Faser-Kategorie pro Skillung (Kritische Trefferchance, Tempo, Vielseitigkeit, Meisterschaft)
- Einschränkung auf erlaubte Umhang-ItemIDs
- Lokalisierung auf Deutsch und Englisch

### Schnellstart
Optionsmenü öffnen und alles ingame konfigurieren:

```text
/cfh
```

Im Optionsmenü kannst du:
- Umhänge: ItemIDs hinzufügen, aktuelle Umhänge (mit Namen) sehen und Einträge entfernen.
- Spezialisierungen: pro Skillung die gewünschte Faser per Dropdown auswählen.

Manuellen Scan jederzeit auslösen:

```text
/cfh scan
```

### Faser einer Skillung (Spezialisierung) zuordnen
Bevorzugt: über die Dropdowns im Optionsmenü (Optionen → AddOns → Cloak Fiber Helper oder `/cfh`).

Alternativ per Slash-Befehl (Name oder Zahl). Gültige Kategorien: `crit`, `haste`, `versa` (Vielseitigkeit), `mastery` (oder die lokalisierten Namen).

- Für die aktuelle Skillung setzen:

```text
/cfh set crit
```

- Für eine spezifische Spezialisations-ID setzen (z. B. Dämonologie-Hexer 266):

```text
/cfh set haste 266
```

Tipp: Mit `/cfh show` siehst du deine Skillungen mit deren IDs und aktueller Zuordnung.

### Erlaubte Umhänge begrenzen
Bevorzugt: über das Optionsmenü im Bereich „Umhänge“ ItemIDs hinzufügen/entfernen.

Alternativ die Liste direkt ersetzen (kommasepariert):

```text
/cfh cloaks 235499,12345,67890
```

Der Scan ist nur erfolgreich, wenn der ausgerüstete Umhang in dieser Liste enthalten ist.

### Wann wird gescannt?
- Beim Login/Welt betreten (mit kurzer Verzögerung)
- Beim Wechsel des Umhangs im Ausrüstungsslot 15
- Beim Wechsel der Spezialisierung
- Manuell via `/cfh scan`

Zusätzlich kann ein kleiner Button „Jetzt prüfen“ erscheinen, der denselben Check auslöst.

### Mögliche Meldungen und Popups
Konsolen-/Chat-Meldungen sind mit `[CFH]` prefixiert.

- Erfolg:
  - `Umhang und Faser sind OK für <Kategorie>`
- Warnungen/Fehler:
  - `Kein erlaubter Umhang ausgerüstet.`
  - `Keine Faser im Umhang gefunden.`
  - `Nicht zugewiesen (spec <id>)` — Für diese Skillung ist noch keine gewünschte Kategorie gesetzt
  - `Eingesetzte Faser <Aktuell> gehört nicht zur gewünschten Kategorie <Erwartet>.`

Popups (erscheinen einmal pro Sitzung, bis sich die Situation ändert):
- Falsche Faser: zeigt aktuelle vs. erwartete Faser-Kategorie
- Kein erlaubter Umhang ausgerüstet

### Slash-Befehle (optional)
```text
/cfh
  Öffnet das Optionsmenü.

/cfh scan
  Startet sofort eine Prüfung des Umhangs und der Fasern.

/cfh set <crit|haste|versa|mastery> [specID]
  Setzt die gewünschte Faser-Kategorie für die angegebene Skillung. Ohne specID gilt die aktuelle Skillung.

/cfh cloaks <id1,id2,...>
  Ersetzt die Liste erlaubter Umhang-ItemIDs durch die angegebenen IDs (kommasepariert).
```

### Lokalisierung
Aktuell unterstützt: Englisch (`enUS`) und Deutsch (`deDE`). Weitere Sprachen können durch eine Datei in `Locales/` (z. B. `frFR.lua`) ergänzt werden, die die Tabelle `CGH_L` befüllt.

### Fehlerbehebung
- Falls Itemdaten noch nicht gecached sind, wartet das Addon und führt den Scan automatisch erneut aus, sobald die Daten vorliegen.
- Achte darauf, dass dein Umhang einen Sockel hat und eine Faser eingesetzt ist. Wenn keine Faser erkannt wird, gibt es eine entsprechende Meldung.
- Nach Umhang- oder Skillungswechsel kannst du mit `/cfh scan` sofort neu prüfen.


