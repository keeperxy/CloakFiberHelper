if GetLocale() ~= "deDE" then return end

local L = _G.CGH_L or {}
_G.CGH_L = L

-- German
L["TITLE"] = "Faser Helfer"
L["ALLOWED_CLOAK_IDS"] = "Erlaubte Umhang-ItemIDs (durch Komma getrennt)"
L["DESIRED_FIBER_PER_SPEC"] = "Gewünschte Faser pro Spezialisierung"
L["SCAN_NOW"] = "Jetzt prüfen"
L["UI_OPEN_HINT"] = "Mit /cfh öffnest du die Einstellungen, /cfh scan prüft sofort"
L["RESULT_OK"] = "Umhang und Faser sind OK für %s"
L["RESULT_FAIL_NO_CLOAK"] = "Kein erlaubter Umhang ausgerüstet."
L["RESULT_FAIL_NO_SOCKET"] = "Umhang hat keinen Sockel."
L["RESULT_FAIL_WRONG_FIBER"] = "Eingesetzte Faser %s gehört nicht zur gewünschten Kategorie %s."
L["RESULT_FAIL_NO_FIBER"] = "Keine Faser im Umhang gefunden."
L["FIBER_CATEGORY"] = "Faser-Kategorie"
L["SPEC_UNASSIGNED"] = "Nicht zugewiesen"

-- Tier names
L["CRIT"] = "Kritische Trefferchance"
L["HASTE"] = "Tempo"
L["VERS"] = "Vielseitigkeit"
L["MASTERY"] = "Meisterschaft"

-- Popup
L["POPUP_WRONG_FIBER"] = "Falsche Faser: %s\nErwartet: %s"
L["POPUP_NO_CLOAK"] = "Kein erlaubter Umhang ausgerüstet."

-- Set confirm
L["SET_SPEC_TO_TIER"] = "%s auf %s gesetzt"



