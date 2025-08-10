local ADDON_NAME = ...
local L = _G.CGH_L or {}

local CloakFiberHelper = CreateFrame("Frame", ADDON_NAME)
_G.CloakGemHelper = CloakFiberHelper -- keep global for compatibility
_G.CloakFiberHelper = CloakFiberHelper

-- SavedVariables per character
CloakFiberHelperDB = CloakFiberHelperDB or {}

-- Constants
local EQUIP_SLOT_CLOAK = 15

-- Fiber categories (IDs only; nameKey used for UI text)
local fiberTiers = {
  [1] = { nameKey = "CRIT", ids = {238044, 238040} },
  [2] = { nameKey = "HASTE", ids = {238045, 238039} },
  [3] = { nameKey = "VERS",  ids = {238042, 238041} },
  [4] = { nameKey = "MASTERY", ids = {238046, 238037} },
}

local defaultAllowedCloaks = {235499}

-- State
local pendingRescanDelaySec = 0.8

local function getPlayerKey()
  local name, realm = UnitName("player")
  realm = realm or GetRealmName()
  return string.format("%s-%s", name or "Unknown", realm or "Unknown")
end

local function scheduleScan(delaySeconds)
  C_Timer.After(delaySeconds or pendingRescanDelaySec, function()
    if CloakFiberHelper and CloakFiberHelper.ScanCloak then
      CloakFiberHelper:ScanCloak()
    end
  end)
end

local function getSpecID()
  local specIndex = GetSpecialization()
  if not specIndex then return 0 end
  return GetSpecializationInfo(specIndex) or 0
end

local function getSpecNameByID(specID)
  if not specID or specID == 0 then return L["SPEC_UNASSIGNED"] or "Unassigned" end
  local _, name = GetSpecializationInfoByID(specID)
  return name or tostring(specID)
end

local function ensureDefaults()
  local key = getPlayerKey()
  CloakFiberHelperDB[key] = CloakFiberHelperDB[key] or {}
  local charDB = CloakFiberHelperDB[key]
  charDB.allowedCloakIDs = charDB.allowedCloakIDs or { unpack(defaultAllowedCloaks) }
  charDB.specPreferences = charDB.specPreferences or {}
end

local function arrayToSet(arr)
  local s = {}
  for _, v in ipairs(arr or {}) do s[v] = true end
  return s
end

local function parseCsvNumbers(csv)
  local result = {}
  for token in string.gmatch(csv or "", "[^,]+") do
    local n = tonumber((token:gsub("%s+", "")))
    if n then table.insert(result, n) end
  end
  return result
end

local function getFullItemLinkFromSlot(unit, slot)
  if C_Item and ItemLocation and ItemLocation.CreateFromEquipmentSlot then
    local loc = ItemLocation:CreateFromEquipmentSlot(slot)
    if C_Item.DoesItemExist(loc) then
      local link = C_Item.GetItemLink(loc)
      if link then return link end
    end
  end
  local link = GetInventoryItemLink(unit, slot)
  if link and link:find("|Hitem:") then
    return link
  end
  local itemID = GetInventoryItemID(unit, slot)
  if itemID then
    local _, itemLink = GetItemInfo(itemID)
    if itemLink then return itemLink end
  end
  return link
end

local function extractFiberIDsFromItemLink(link)
  if not link then return {} end
  local itemString = link:match("|Hitem:([-%d:]+)|h")
  if not itemString then return {} end
  local parts = {}
  for part in string.gmatch(itemString, "[^:]+") do table.insert(parts, part) end
  local fiberIDs = {}
  for i = 3, 6 do
    local id = tonumber(parts[i])
    if id and id > 0 then table.insert(fiberIDs, id) end
  end
  return fiberIDs
end

local function getItemIDFromLink(link)
  if not link then return nil end
  local itemString = link:match("|Hitem:([-%d:]+)|h")
  if not itemString then return nil end
  local itemId = tonumber(itemString:match("^(%-?%d+)"))
  return itemId
end

local function getFiberIDs(link)
  local fibers = {}
  if link then
    for i = 1, 4 do
      local _, fiberLink = GetItemGem(link, i)
      if fiberLink then
        local fid = getItemIDFromLink(fiberLink)
        if fid then table.insert(fibers, fid) end
      end
    end
    if #fibers == 0 then
      fibers = extractFiberIDsFromItemLink(link)
    end
  end
  return fibers
end

local function isCloakAllowed(itemID)
  ensureDefaults()
  local key = getPlayerKey()
  local charDB = CloakFiberHelperDB[key]
  local allowedSet = arrayToSet(charDB.allowedCloakIDs)
  return allowedSet[itemID] == true
end

local function getDesiredTierForCurrentSpec()
  ensureDefaults()
  local key = getPlayerKey()
  local charDB = CloakFiberHelperDB[key]
  local specID = getSpecID()
  return charDB.specPreferences[specID]
end

local function tierContainsFiberID(tierIndex, fiberID)
  local tier = fiberTiers[tierIndex]
  if not tier then return false end
  for _, id in ipairs(tier.ids) do
    if id == fiberID then return true end
  end
  return false
end

local function getTierDisplayName(tierIndex)
  local tier = fiberTiers[tierIndex]
  if tier then return L[tier.nameKey] or tier.nameKey end
  return L["SPEC_UNASSIGNED"]
end

local function findTierIndexForFiberID(fiberID)
  for idx, tier in pairs(fiberTiers) do
    for _, id in ipairs(tier.ids) do
      if id == fiberID then return idx end
    end
  end
  return nil
end

-- Ensure item/cached data is loaded; schedule re-scan when ready
local function ensureCloakItemLoaded()
  if not Item or not ItemLocation or not Item.CreateFromItemLocation then return false end
  local loc = ItemLocation:CreateFromEquipmentSlot(EQUIP_SLOT_CLOAK)
  if C_Item and C_Item.DoesItemExist(loc) then
    local obj = Item:CreateFromItemLocation(loc)
    if obj and not obj:IsItemDataCached() then
      if not CloakFiberHelper._pendingCloakLoad then
        CloakFiberHelper._pendingCloakLoad = true
        obj:ContinueOnItemLoad(function()
          CloakFiberHelper._pendingCloakLoad = false
          CloakFiberHelper:ScanCloak()
        end)
      end
      return true
    end
  end
  return false
end

local function ensureFiberItemDataLoaded(fiberIDs)
  if not Item or not Item.CreateFromItemID then return false end
  local scheduled = false
  for _, id in ipairs(fiberIDs or {}) do
    local obj = Item:CreateFromItemID(id)
    if obj and not obj:IsItemDataCached() then
      scheduled = true
      if not CloakFiberHelper._pendingFiberLoad then
        CloakFiberHelper._pendingFiberLoad = true
        obj:ContinueOnItemLoad(function()
          CloakFiberHelper._pendingFiberLoad = false
          CloakFiberHelper:ScanCloak()
        end)
      end
    end
  end
  return scheduled
end

-- Detect if the Blizzard socketing UI is open to avoid tainting protected actions
local function isSocketingFrameOpen()
  return (ItemSocketingFrame and ItemSocketingFrame:IsShown())
    or (ItemSocketingSocket1 and ItemSocketingSocket1:IsVisible())
end

-- Static popup for wrong fiber, with session gating
StaticPopupDialogs["CLOAKFIBERHELPER_WRONG_FIBER"] = {
  text = L["POPUP_WRONG_FIBER"] or "Wrong cloak fiber: %s\nExpected: %s",
  button1 = OKAY,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
  OnShow = function(self)
    if self and self.text then
      self.text:SetJustifyH("LEFT")
      self.text:SetJustifyV("TOP")
      self.text:SetWidth(360)
    end
  end,
}

-- Static popup for no allowed cloak
StaticPopupDialogs["CLOAKFIBERHELPER_NO_CLOAK"] = {
  text = L["POPUP_NO_CLOAK"] or "No allowed cloak equipped in slot 15.",
  button1 = OKAY,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
  OnShow = function(self)
    if self and self.text then
      self.text:SetJustifyH("LEFT")
      self.text:SetJustifyV("TOP")
      self.text:SetWidth(360)
    end
  end,
}

function CloakFiberHelper:ScanCloak(forcePrint)
  ensureDefaults()
  local specID = getSpecID()
  local desiredTier = getDesiredTierForCurrentSpec()

  -- Defer while loading screen is active
  if CloakFiberHelper._loadingScreen then
    scheduleScan(1.0)
    return false
  end

  -- Delay until cloak item data is cached
  if ensureCloakItemLoaded() then return false end

  local link = getFullItemLinkFromSlot("player", EQUIP_SLOT_CLOAK)
  local itemID = GetInventoryItemID("player", EQUIP_SLOT_CLOAK) or getItemIDFromLink(link)

  -- If the engine hasn't yet populated the equipment slot (e.g., right after a loading screen), try again shortly
  if not itemID then
    scheduleScan(1.0)
    return false
  end

  -- Lightweight result print throttling to avoid duplicate spam during zone transitions
  local function shouldPrintResult(resultKey)
    if forcePrint then return true end
    local now = GetTime and GetTime() or 0
    local last = CloakFiberHelper._lastResult or { key = nil, time = 0 }
    if resultKey ~= last.key then return true end
    if (now - (last.time or 0)) >= 5 then return true end
    return false
  end
  local function markPrinted(resultKey)
    CloakFiberHelper._lastResult = { key = resultKey, time = GetTime and GetTime() or 0 }
  end

  if not isCloakAllowed(itemID) then
    local key = "NO_CLOAK"
    if shouldPrintResult(key) then
      print("[CFH] " .. (L["RESULT_FAIL_NO_CLOAK"] or "No allowed cloak equipped."))
      markPrinted(key)
    end
    if not CloakFiberHelper._warnedNoCloak then
      if not isSocketingFrameOpen() then
        StaticPopup_Show("CLOAKFIBERHELPER_NO_CLOAK")
        CloakFiberHelper._warnedNoCloak = true
      end
    end
    return false
  end

  if (not link or not link:find("|Hitem:")) and itemID then
    local _, itemLink = GetItemInfo(itemID)
    if itemLink then link = itemLink end
  end

  local fiberIDs = getFiberIDs(link)
  if #fiberIDs == 0 then
    local key = "NO_FIBER"
    if shouldPrintResult(key) then
      print("[CFH] " .. (L["RESULT_FAIL_NO_FIBER"] or "No fiber detected in cloak."))
      markPrinted(key)
    end
    return false
  end

  -- Delay until fiber item data is cached (names/categories becoming reliable)
  if ensureFiberItemDataLoaded(fiberIDs) then return false end

  if not desiredTier then
    local key = "UNASSIGNED:" .. tostring(specID)
    if shouldPrintResult(key) then
      print("[CFH] " .. (L["SPEC_UNASSIGNED"] or "Unassigned") .. string.format(" (spec %s)", tostring(specID)))
      markPrinted(key)
    end
    return false
  end

  for _, fiberID in ipairs(fiberIDs) do
    if tierContainsFiberID(desiredTier, fiberID) then
      local key = "OK:" .. tostring(desiredTier) .. ":" .. tostring(itemID)
      if shouldPrintResult(key) then
        print("[CFH] " .. string.format(L["RESULT_OK"] or "OK for %s", getTierDisplayName(desiredTier)))
        markPrinted(key)
      end
      return true
    end
  end

  local actualTierIndex = nil
  local firstFiber = fiberIDs[1]
  for _, fid in ipairs(fiberIDs) do
    local idx = findTierIndexForFiberID(fid)
    if idx then actualTierIndex = idx; firstFiber = fid; break end
  end
  local actualLabel = actualTierIndex and getTierDisplayName(actualTierIndex) or tostring(firstFiber or "?")
  local expected = getTierDisplayName(desiredTier)
  do
    local key = "WRONG:" .. tostring(actualLabel) .. ":" .. tostring(expected)
    if shouldPrintResult(key) then
      print("[CFH] " .. string.format(L["RESULT_FAIL_WRONG_FIBER"] or "Equipped fiber %s is not in desired category %s.", tostring(actualLabel), expected))
      markPrinted(key)
    end
  end

  if not CloakFiberHelper._warnedWrongFiber then
    if not isSocketingFrameOpen() then
      StaticPopup_Show("CLOAKFIBERHELPER_WRONG_FIBER", tostring(actualLabel), expected)
      CloakFiberHelper._warnedWrongFiber = true
    end
  end
  return false
end

CloakFiberHelper:RegisterEvent("PLAYER_ENTERING_WORLD")
CloakFiberHelper:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
CloakFiberHelper:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
-- React to socketing UI to prevent protected actions from being tainted by our popups
CloakFiberHelper:RegisterEvent("SOCKET_INFO_UPDATE")
CloakFiberHelper:RegisterEvent("SOCKET_INFO_CLOSE")
-- React to loading screens to avoid false negatives during zone transitions
CloakFiberHelper:RegisterEvent("LOADING_SCREEN_ENABLED")
CloakFiberHelper:RegisterEvent("LOADING_SCREEN_DISABLED")

CloakFiberHelper:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_ENTERING_WORLD" then
    ensureDefaults()
    CloakFiberHelper._warnedWrongFiber = false
    CloakFiberHelper._warnedNoCloak = false
    CloakFiberHelper._loadingScreen = false
    C_Timer.After(5, function() CloakFiberHelper:ScanCloak() end)
  elseif event == "PLAYER_EQUIPMENT_CHANGED" then
    local slot = ...
    if slot == EQUIP_SLOT_CLOAK then
      CloakFiberHelper._warnedWrongFiber = false
      CloakFiberHelper._warnedNoCloak = false
      CloakFiberHelper:ScanCloak()
    end
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
    local unit = ...
    if unit == "player" then
      CloakFiberHelper._warnedWrongFiber = false
      CloakFiberHelper._warnedNoCloak = false
      CloakFiberHelper:ScanCloak()
    end
  elseif event == "SOCKET_INFO_UPDATE" then
    -- While socketing UI is open, ensure our popups are hidden to avoid taint
    if isSocketingFrameOpen() then
      StaticPopup_Hide("CLOAKFIBERHELPER_WRONG_FIBER")
      StaticPopup_Hide("CLOAKFIBERHELPER_NO_CLOAK")
      -- Allow showing again after the socketing frame is closed
      CloakFiberHelper._warnedWrongFiber = false
      CloakFiberHelper._warnedNoCloak = false
    end
  elseif event == "SOCKET_INFO_CLOSE" then
    -- Re-evaluate once socketing has been closed; popups may be shown now if still relevant
    CloakFiberHelper._warnedWrongFiber = false
    CloakFiberHelper._warnedNoCloak = false
    C_Timer.After(0.1, function() CloakFiberHelper:ScanCloak() end)
  elseif event == "LOADING_SCREEN_ENABLED" then
    CloakFiberHelper._loadingScreen = true
  elseif event == "LOADING_SCREEN_DISABLED" then
    CloakFiberHelper._loadingScreen = false
    CloakFiberHelper._warnedWrongFiber = false
    CloakFiberHelper._warnedNoCloak = false
    scheduleScan(0.8)
  end
end)

SLASH_CFH1 = "/cfh"
SlashCmdList["CFH"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg:find("^scan") then
    CloakFiberHelper:ScanCloak()
  elseif msg:find("^cloaks%s+") then
    local csv = msg:match("^cloaks%s+(.+)$")
    if csv and CloakFiberHelper._api then
      CloakFiberHelper._api.setAllowedCloakIDs(csv)
      print("[CFH] Cloak IDs updated: " .. csv)
    end
  elseif msg:find("^set%s+") then
    local token, spec = msg:match("^set%s+(%S+)%s*(%S*)$")
    local tierIndex = (function()
      if not token then return nil end
      local t = tostring(token):lower()
      if t == "crit" or t == (L["CRIT"] or ""):lower() or t == "1" then return 1 end
      if t == "haste" or t == (L["HASTE"] or ""):lower() or t == "2" then return 2 end
      if t == "versa" or t == "versatility" or t == (L["VERS"] or ""):lower() or t == "3" then return 3 end
      if t == "mastery" or t == (L["MASTERY"] or ""):lower() or t == "4" then return 4 end
      return nil
    end)()

    if not tierIndex then
      print("[CFH] Usage: /cfh set <crit||haste||versa||mastery> [specID]")
      return
    end
    local specIDnum = nil
    if spec and spec ~= "" then
      specIDnum = tonumber(spec)
      if not specIDnum then
        print("[CFH] Invalid specID.")
        return
      end
    else
      specIDnum = getSpecID()
      if specIDnum == 0 then
        print("[CFH] Could not determine current spec.")
        return
      end
    end
    CloakFiberHelper._api.setDesiredTierForSpec(specIDnum, tierIndex)
    local specName = getSpecNameByID(specIDnum)
    print(string.format("[CFH] " .. (L["SET_SPEC_TO_TIER"] or "Set %s to %s"), specName, getTierDisplayName(tierIndex)))
  elseif msg == "show" or msg == "" then
    if CloakGemHelper_OpenOptions then
      CloakGemHelper_OpenOptions()
    end
  else
    print("[CFH] Commands: /cfh scan || /cfh cloaks 235499,12345 || /cfh set <crit||haste||versa||mastery> [specID] || /cfh show")
  end
end

CloakFiberHelper._api = {
  ensureDefaults = ensureDefaults,
  getPlayerKey = getPlayerKey,
  getSpecID = getSpecID,
  getDesiredTierForCurrentSpec = getDesiredTierForCurrentSpec,
  setDesiredTierForSpec = function(specID, tierIndex)
    ensureDefaults()
    local key = getPlayerKey()
    CloakFiberHelperDB[key].specPreferences[specID] = tierIndex
  end,
  getGemTiers = function() return fiberTiers end,
  getAllowedCloakIDs = function()
    ensureDefaults()
    local key = getPlayerKey()
    return CloakFiberHelperDB[key].allowedCloakIDs
  end,
  setAllowedCloakIDs = function(csv)
    ensureDefaults()
    local key = getPlayerKey()
    CloakFiberHelperDB[key].allowedCloakIDs = parseCsvNumbers(csv)
  end,
}
