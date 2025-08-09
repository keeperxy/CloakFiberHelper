local L = _G.CGH_L or {}
local api = _G.CloakFiberHelper and _G.CloakFiberHelper._api or (_G.CloakGemHelper and _G.CloakGemHelper._api)

-- Minimal UI shim: print help and current config
local function printConfig()
  if not api then return end
  api.ensureDefaults()
  local key = api.getPlayerKey()
  local cloaks = api.getAllowedCloakIDs() or {}
  local csv = table.concat(cloaks, ", ")
  print("[CFH] Allowed cloaks: " .. (csv ~= "" and csv or "(none)"))

  -- List specs and their desired fiber tier
  for i = 1, GetNumSpecializations() do
    local specID = GetSpecializationInfo(i)
    if specID then
      local _, specName = GetSpecializationInfoByID(specID)
      local tier = (_G.CloakFiberHelperDB[key].specPreferences[specID])
      local tierText = tier and (api.getGemTiers()[tier] and (L[api.getGemTiers()[tier].nameKey] or api.getGemTiers()[tier].nameKey)) or (L["SPEC_UNASSIGNED"] or "Unassigned")
      print(string.format("[CFH] Spec %s (%d): %s", specName or "?", specID, tierText))
    end
  end
  print("[CFH] Commands: /cfh scan || /cfh cloaks 235499,12345 || /cfh set <crit||haste||versa||mastery> [specID]")
end

function CloakGemHelper_OpenOptions()
  printConfig()
  print("[CFH] " .. (L["UI_OPEN_HINT"] or "Use /cfh to open settings, /cfh scan to scan"))
end

-- Add a small action button to trigger scan instantly
local f
local function ensureScanButton()
  if f then return end
  f = CreateFrame("Button", "CGHScanButton", UIParent, "UIPanelButtonTemplate")
  f:SetSize(120, 24)
  f:SetText(L["SCAN_NOW"] or "Scan now")
  f:SetPoint("CENTER")
  f:Hide()
  f:SetScript("OnClick", function()
    if CloakGemHelper and CloakGemHelper.ScanCloak then
      CloakGemHelper:ScanCloak()
    end
  end)
end

-- Show hint after login
C_Timer.After(5, function()
  ensureScanButton()
  print("[CFH] " .. (L["UI_OPEN_HINT"] or "Use /cfh to open settings, /cfh scan to scan"))
end)
