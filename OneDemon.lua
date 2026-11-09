local ADDON = ...
local SPELLS = { 688, 697, 712, 691, 713 } -- Imp, Voidwalker, Succubus, Felhunter, Incubus
local SIZE, GAP = 44, 4

BINDING_HEADER_ONEDEMON = "OneDemon"
_G["BINDING_NAME_CLICK OneDemonMain:LeftButton"] = "Summon Demon"

local DEFAULTS = { scale = 1, dir = "UP", locked = false, tooltips = true, cooldown = true }
local DIRS = {
  UP    = { "BOTTOM", "TOP",    0,  1, "Up" },
  DOWN  = { "TOP",    "BOTTOM", 0, -1, "Down" },
  RIGHT = { "LEFT",   "RIGHT",  1,  0, "Right" },
  LEFT  = { "RIGHT",  "LEFT",  -1,  0, "Left" },
}
local DIR_ORDER = { "UP", "RIGHT", "DOWN", "LEFT" }

local GetName = (C_Spell and C_Spell.GetSpellName) or GetSpellInfo
local function GetIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
  return select(3, GetSpellInfo(id))
end
local function Known(id)
  if not GetName(id) then return false end
  if C_SpellBook and C_SpellBook.IsSpellKnown then return C_SpellBook.IsSpellKnown(id) end
  if IsPlayerSpell then return IsPlayerSpell(id) end
  return IsSpellKnown(id)
end

local main, flyout, category
local buttons, pending = {}, false

local function UpdateCooldown(b)
  if not b.spellID then return end
  pcall(function()
    if C_Spell and C_Spell.GetSpellCooldown then
      local cd = C_Spell.GetSpellCooldown(b.spellID)
      if cd then b.cd:SetCooldown(cd.startTime, cd.duration) end
    else
      local s, d = GetSpellCooldown(b.spellID)
      b.cd:SetCooldown(s, d)
    end
  end)
end

local function SetupButton(b, id)
  b.spellID = id
  b:SetAttribute("type", "spell")
  b:SetAttribute("spell", GetName(id))
  b.icon:SetTexture(GetIcon(id))
  UpdateCooldown(b)
end

local function NewButton(name, parent)
  local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
  b:SetSize(SIZE, SIZE)
  b:RegisterForClicks("LeftButtonUp")
  b:SetAttribute("useOnKeyDown", false)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
  b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  b.cd:SetAllPoints()
  b:SetScript("OnEnter", function(self)
    if not OneDemonDB.tooltips then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.spellID and GameTooltip.SetSpellByID then GameTooltip:SetSpellByID(self.spellID) end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

local function Layout()
  if not main or InCombatLockdown() then return end
  local d = DIRS[OneDemonDB.dir] or DIRS.UP
  main:SetScale(OneDemonDB.scale)
  flyout:SetScale(OneDemonDB.scale)
  main.cd:SetShown(OneDemonDB.cooldown)
  for i, b in ipairs(buttons) do
    local off = GAP + (i - 1) * (SIZE + GAP)
    b:ClearAllPoints()
    b:SetPoint(d[1], main, d[2], d[3] * off, d[4] * off)
    b.cd:SetShown(OneDemonDB.cooldown)
  end
end

local function MakeFlyoutButton(i)
  local b = NewButton("OneDemonChoice" .. i, flyout)
  local ok = pcall(SecureHandlerWrapScript, b, "OnClick", flyout, "", [[ owner:Hide() ]])
  b:HookScript("PostClick", function(self)
    OneDemonDB.last = self.spellID
    if InCombatLockdown() then
      pending = true
    else
      SetupButton(main, self.spellID)
      if not ok then flyout:Hide() end
    end
  end)
  return b
end

local function Rebuild()
  if InCombatLockdown() then pending = true return end
  pending = false

  local known = {}
  for _, id in ipairs(SPELLS) do if Known(id) then known[#known + 1] = id end end
  if #known == 0 then main:Hide() return end
  main:Show()

  local cur, ok = OneDemonDB.last, false
  for _, id in ipairs(known) do if id == cur then ok = true end end
  if not ok then cur = known[1]; OneDemonDB.last = cur end
  SetupButton(main, cur)

  for i, id in ipairs(known) do
    local b = buttons[i]
    if not b then
      b = MakeFlyoutButton(i)
      buttons[i] = b
    end
    SetupButton(b, id)
    b:Show()
  end
  for i = #known + 1, #buttons do buttons[i]:Hide() end
  Layout()
end

local function SafeRebuild()
  local ok, err = xpcall(Rebuild, geterrorhandler())
  if not ok then print("|cffff5555OneDemon error:|r", err) end
end

local function ResetPosition()
  if not main or InCombatLockdown() then print("OneDemon: can't do that in combat.") return end
  OneDemonDB.pos = nil
  main:ClearAllPoints()
  main:SetPoint("CENTER", 0, -150)
end

-- Options panel
local function BuildOptions()
  local panel = CreateFrame("Frame")
  panel.name = "OneDemon"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("OneDemon")

  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Left-click summons. Right-click opens the demon list. Shift-drag moves the button. Changes can't be made in combat.")

  local function Guard()
    if InCombatLockdown() then print("OneDemon: can't change options in combat.") return false end
    return true
  end

  local function Checkbox(label, key, y)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, y)
    local fs = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(label)
    cb:SetScript("OnClick", function(self)
      if not Guard() then self:SetChecked(OneDemonDB[key]) return end
      OneDemonDB[key] = self:GetChecked() and true or false
      Layout()
    end)
    cb.key = key
    return cb
  end

  local cbLock = Checkbox("Lock position (disable Shift-drag)", "locked", -70)
  local cbTip  = Checkbox("Show spell tooltips", "tooltips", -100)
  local cbCd   = Checkbox("Show cooldown swipe", "cooldown", -130)

  local scaleLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  scaleLabel:SetPoint("TOPLEFT", 20, -178)

  local minus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  minus:SetSize(28, 24); minus:SetText("-")
  minus:SetPoint("LEFT", scaleLabel, "RIGHT", 16, 0)
  local plus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  plus:SetSize(28, 24); plus:SetText("+")
  plus:SetPoint("LEFT", minus, "RIGHT", 4, 0)

  local dirLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  dirLabel:SetPoint("TOPLEFT", 20, -218)
  local dirBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  dirBtn:SetSize(90, 24)
  dirBtn:SetPoint("LEFT", dirLabel, "RIGHT", 16, 0)

  local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reset:SetSize(140, 24); reset:SetText("Reset position")
  reset:SetPoint("TOPLEFT", 16, -258)
  reset:SetScript("OnClick", ResetPosition)

  local function Refresh()
    cbLock:SetChecked(OneDemonDB.locked)
    cbTip:SetChecked(OneDemonDB.tooltips)
    cbCd:SetChecked(OneDemonDB.cooldown)
    scaleLabel:SetText(string.format("Button scale: %.1f", OneDemonDB.scale))
    dirLabel:SetText("Flyout direction:")
    dirBtn:SetText((DIRS[OneDemonDB.dir] or DIRS.UP)[5])
  end

  local function ChangeScale(delta)
    if not Guard() then return end
    local s = math.floor((OneDemonDB.scale + delta) * 10 + 0.5) / 10
    OneDemonDB.scale = math.max(0.5, math.min(2.0, s))
    Layout(); Refresh()
  end
  minus:SetScript("OnClick", function() ChangeScale(-0.1) end)
  plus:SetScript("OnClick", function() ChangeScale(0.1) end)

  dirBtn:SetScript("OnClick", function()
    if not Guard() then return end
    local idx = 1
    for i, k in ipairs(DIR_ORDER) do if k == OneDemonDB.dir then idx = i end end
    OneDemonDB.dir = DIR_ORDER[idx % #DIR_ORDER + 1]
    Layout(); Refresh()
  end)

  panel:SetScript("OnShow", Refresh)
  Refresh()

  local ok = pcall(function()
    if Settings and Settings.RegisterCanvasLayoutCategory then
      category = Settings.RegisterCanvasLayoutCategory(panel, "OneDemon")
      Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
      InterfaceOptions_AddCategory(panel)
    end
  end)
  if not ok then print("|cffff5555OneDemon:|r couldn't register options panel.") end
  panel.refresh = Refresh
  return panel
end

local optionsPanel
local function OpenOptions()
  if Settings and Settings.OpenToCategory and category then
    local id = category.GetID and category:GetID() or category
    Settings.OpenToCategory(id)
  elseif InterfaceOptionsFrame_OpenToCategory and optionsPanel then
    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    InterfaceOptionsFrame_OpenToCategory(optionsPanel)
  end
end

local function Init()
  OneDemonDB = OneDemonDB or {}
  for k, v in pairs(DEFAULTS) do
    if OneDemonDB[k] == nil then OneDemonDB[k] = v end
  end

  main = NewButton("OneDemonMain", UIParent)
  main:SetMovable(true)
  main:SetClampedToScreen(true)
  main:RegisterForDrag("LeftButton")
  main:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  local p = OneDemonDB.pos
  if p then main:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else main:SetPoint("CENTER", 0, -150) end

  flyout = CreateFrame("Frame", "OneDemonFlyout", UIParent, "SecureHandlerBaseTemplate")
  flyout:SetSize(SIZE, SIZE)
  flyout:SetPoint("CENTER", main, "CENTER", 0, 0)
  flyout:SetFrameStrata("DIALOG")
  flyout:SetClampedToScreen(true)
  flyout:Hide()

  local ok = pcall(SecureHandlerWrapScript, main, "OnClick", flyout, [[
    if button == "RightButton" then
      if owner:IsShown() then owner:Hide() else owner:Show() end
      return false
    end
  ]])
  if not ok then
    print("|cffff5555OneDemon:|r secure wrap failed, using fallback (flyout won't open in combat)")
    main:HookScript("OnClick", function(_, btn)
      if btn == "RightButton" and not InCombatLockdown() then flyout:SetShown(not flyout:IsShown()) end
    end)
  end

  main:SetScript("OnDragStart", function(self)
    if OneDemonDB.locked then return end
    if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end
  end)
  main:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt, _, rp, x, y = self:GetPoint()
    OneDemonDB.pos = { pt, rp, x, y }
  end)

  optionsPanel = BuildOptions()
  SafeRebuild()
end

local f = CreateFrame("Frame")
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED",
  "PLAYER_REGEN_ENABLED", "SPELL_UPDATE_COOLDOWN", "PLAYER_TALENT_UPDATE" }) do
  pcall(f.RegisterEvent, f, e)
end

f:SetScript("OnEvent", function(_, ev, arg)
  if ev == "ADDON_LOADED" then
    if arg ~= ADDON then return end
    if select(2, UnitClass("player")) ~= "WARLOCK" then return end
    Init()
  elseif not main then
    return
  elseif ev == "SPELL_UPDATE_COOLDOWN" then
    UpdateCooldown(main)
    for _, b in ipairs(buttons) do if b:IsShown() then UpdateCooldown(b) end end
  elseif ev == "PLAYER_REGEN_ENABLED" then
    if pending then SafeRebuild() end
  else
    SafeRebuild()
  end
end)

SLASH_ONEDEMON1 = "/onedemon"
SlashCmdList.ONEDEMON = function(msg)
  if msg and msg:lower():match("^reset") then ResetPosition() else OpenOptions() end
end

SLASH_ONEDEMONDBG1 = "/oddebug"
SlashCmdList.ONEDEMONDBG = function()
  for _, id in ipairs(SPELLS) do
    print(id, GetName(id), Known(id) and "KNOWN" or "not known")
  end
  print("main:", main and tostring(main:IsShown()) or "nil",
        "flyout:", flyout and tostring(flyout:IsShown()) or "nil",
        "buttons:", #buttons)
end
