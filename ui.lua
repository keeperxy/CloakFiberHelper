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
  -- Ensure panel exists
  if not _G.CFHOptionsPanel then
    -- createOptionsPanel is local in this file
    if type(createOptionsPanel) == "function" then
      createOptionsPanel()
    end
  end

  if Settings and Settings.OpenToCategory then
    Settings.OpenToCategory("CloakFiberHelperOptions")
  elseif InterfaceOptionsFrame_OpenToCategory and _G.CFHOptionsPanel then
    InterfaceOptionsFrame_OpenToCategory(_G.CFHOptionsPanel)
    C_Timer.After(0, function()
      InterfaceOptionsFrame_OpenToCategory(_G.CFHOptionsPanel)
    end)
  else
    -- Fallback: print current config if no options UI is available
    printConfig()
  end
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

-- Options → AddOns panel that lists chat commands
local function createOptionsPanel()
  local panel = CreateFrame("Frame", "CFHOptionsPanel", UIParent)
  local titleText = L["TITLE"] or "Cloak Fiber Helper"
  panel.name = titleText
  _G.CFHOptionsPanel = panel

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText(titleText)

  local intro = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
  intro:SetJustifyH("LEFT")
  intro:SetWidth(700)
  intro:SetText(L["OPTIONS_INTRO"] or "This addon checks your cloak's fiber category. The following chat commands are available:")

  local header = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  header:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -12)
  header:SetText(L["CHAT_COMMANDS"] or "Chat Commands")

  local commands = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  commands:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
  commands:SetJustifyH("LEFT")
  commands:SetWidth(700)
  commands:SetText("/cfh scan\n/cfh cloaks 235499,12345\n/cfh set <crit||haste||versa||mastery> [specID]\n/cfh show")

  -- Cloak Settings section (above fiber/spec settings)
  local cloakSection = CreateFrame("Frame", nil, panel)
  cloakSection:SetPoint("TOPLEFT", commands, "BOTTOMLEFT", 0, -16)
  cloakSection:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
  cloakSection:SetHeight(60) -- will be resized in refresh

  local cloakHeader = cloakSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  cloakHeader:SetPoint("TOPLEFT", cloakSection, "TOPLEFT", 0, 0)
  cloakHeader:SetText(L["ALLOWED_CLOAK_IDS"] or "Allowed cloak ItemIDs (comma-separated)")

  local cloakInput = CreateFrame("EditBox", nil, cloakSection, "InputBoxTemplate")
  cloakInput:SetSize(160, 24)
  cloakInput:SetAutoFocus(false)
  cloakInput:SetPoint("TOPLEFT", cloakHeader, "BOTTOMLEFT", 0, -6)
  cloakInput:SetCursorPosition(0)
  cloakInput:SetTextInsets(4, 4, 2, 2)
  cloakInput:SetMaxLetters(10)

  local addBtn = CreateFrame("Button", nil, cloakSection, "UIPanelButtonTemplate")
  addBtn:SetSize(80, 22)
  addBtn:SetPoint("LEFT", cloakInput, "RIGHT", 8, 0)
  addBtn:SetText(L["ADD"] or "Add")

  local listHeader = cloakSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  listHeader:SetPoint("TOPLEFT", cloakInput, "BOTTOMLEFT", 0, -10)
  listHeader:SetText(L["CURRENT_CLOAKS"] or "Current cloaks")

  cloakSection._rows = {}

  local function setAllowedFromList(idList)
    table.sort(idList)
    local parts = {}
    for _, id in ipairs(idList) do table.insert(parts, tostring(id)) end
    if api and api.setAllowedCloakIDs then
      api.setAllowedCloakIDs(table.concat(parts, ","))
    end
  end

  local function getAllowedListCopy()
    if not api then return {} end
    api.ensureDefaults()
    local ids = api.getAllowedCloakIDs() or {}
    local copy = {}
    for i = 1, #ids do copy[i] = ids[i] end
    return copy
  end

  local function refreshCloakList()
    local ids = getAllowedListCopy()
    table.sort(ids)

    local yAnchor = listHeader
    local totalHeight = 0

    for index, itemID in ipairs(ids) do
      local row = cloakSection._rows[index]
      if not row then
        row = {}
        row.name = cloakSection:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        row.remove = CreateFrame("Button", nil, cloakSection, "UIPanelButtonTemplate")
        row.remove:SetSize(70, 20)
        row.remove:SetText(L["REMOVE"] or "Remove")
        cloakSection._rows[index] = row
      end

      row.name:ClearAllPoints()
      row.name:SetPoint("TOPLEFT", yAnchor, "BOTTOMLEFT", 0, -6)
      row.name:SetWidth(520)
      row.name:SetJustifyH("LEFT")

      local name = GetItemInfo(itemID)
      if not name and Item and Item.CreateFromItemID then
        local obj = Item:CreateFromItemID(itemID)
        obj:ContinueOnItemLoad(function()
          if panel:IsShown() then refreshCloakList() end
        end)
      end
      row.name:SetText((name or (L["ITEM_UNKNOWN"] or "Item") .. " #" .. tostring(itemID)) .. " (" .. tostring(itemID) .. ")")

      row.remove:ClearAllPoints()
      row.remove:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
      row.remove:SetScript("OnClick", function()
        local current = getAllowedListCopy()
        local nextList = {}
        for _, id in ipairs(current) do if id ~= itemID then table.insert(nextList, id) end end
        setAllowedFromList(nextList)
        refreshCloakList()
      end)

      yAnchor = row.name
      totalHeight = totalHeight + 26
    end

    -- Hide extra rows if count shrank
    for i = #ids + 1, #cloakSection._rows do
      local row = cloakSection._rows[i]
      if row then
        if row.name then row.name:SetText("") end
        if row.remove then row.remove:Hide() end
      end
    end

    -- Re-show remove buttons for visible rows
    for i = 1, #ids do
      local row = cloakSection._rows[i]
      if row and row.remove then row.remove:Show() end
    end

    cloakSection:SetHeight(46 + totalHeight)
  end

  addBtn:SetScript("OnClick", function()
    local txt = (cloakInput:GetText() or ""):gsub("%s+", "")
    local id = tonumber(txt)
    if id then
      local list = getAllowedListCopy()
      local exists = false
      for _, v in ipairs(list) do if v == id then exists = true break end end
      if not exists then table.insert(list, id) end
      setAllowedFromList(list)
      cloakInput:SetText("")
      refreshCloakList()
    else
      UIErrorsFrame:AddMessage(L["INVALID_ITEM_ID"] or "Invalid ItemID", 1.0, 0.1, 0.1, 1.0)
    end
  end)

  -- Initial population of the cloak list (will update names asynchronously when item info arrives)
  C_Timer.After(0.1, refreshCloakList)

  -- Header for per-spec desired fiber selection
  local specHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  specHeader:SetPoint("TOPLEFT", cloakSection, "BOTTOMLEFT", 0, -16)
  specHeader:SetText(L["DESIRED_FIBER_PER_SPEC"] or "Desired Fiber per Specialization")

  -- Build dropdowns when the panel is shown the first time
  panel._builtSpecs = false

  local function buildSpecDropdowns()
    if panel._builtSpecs then return end
    panel._builtSpecs = true

    if not api then return end
    api.ensureDefaults()

    local gemTiers = api.getGemTiers() or {}
    local tierChoices = {
      { value = 1, text = (L[gemTiers[1] and gemTiers[1].nameKey or "CRIT"] or "Critical Strike") },
      { value = 2, text = (L[gemTiers[2] and gemTiers[2].nameKey or "HASTE"] or "Haste") },
      { value = 3, text = (L[gemTiers[3] and gemTiers[3].nameKey or "VERS"] or "Versatility") },
      { value = 4, text = (L[gemTiers[4] and gemTiers[4].nameKey or "MASTERY"] or "Mastery") },
    }

    local anchor = specHeader
    local key = api.getPlayerKey()
    local db = _G.CloakFiberHelperDB and _G.CloakFiberHelperDB[key]

    for i = 1, (GetNumSpecializations() or 0) do
      local specID = GetSpecializationInfo(i)
      if specID then
        local _, specName = GetSpecializationInfoByID(specID)

        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -12)
        label:SetWidth(200)
        label:SetJustifyH("LEFT")
        label:SetText(specName or ("Spec %d"):format(i))

        local dropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
        dropdown:SetPoint("LEFT", label, "LEFT", 220, 0)
        UIDropDownMenu_SetWidth(dropdown, 200)

        UIDropDownMenu_Initialize(dropdown, function(self, level)
          for _, choice in ipairs(tierChoices) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = choice.text
            info.value = choice.value
            info.func = function()
              UIDropDownMenu_SetSelectedValue(dropdown, choice.value)
              if api and api.setDesiredTierForSpec then
                api.setDesiredTierForSpec(specID, choice.value)
              end
            end
            UIDropDownMenu_AddButton(info, level)
          end
        end)

        local current = db and db.specPreferences and db.specPreferences[specID] or nil
        if current then
          UIDropDownMenu_SetSelectedValue(dropdown, current)
        end

        anchor = label
      end
    end
  end

  panel:SetScript("OnShow", buildSpecDropdowns)

  if Settings and Settings.RegisterAddOnCategory and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, titleText)
    category.ID = "CloakFiberHelperOptions"
    Settings.RegisterAddOnCategory(category)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end
end

-- Create the panel shortly after load so it appears under Options → AddOns
C_Timer.After(0, createOptionsPanel)
