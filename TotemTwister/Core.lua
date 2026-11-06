-- Totem Twister: a small shaman HUD. Totems, weapon imbues, shield, Ankh.
local ADDON_NAME, ns = ...

local defaults = {
    point = "CENTER", x = 0, y = -180,
    scale = 1.0,
    locked = false,
    sound = true,
    warnTotem = 5,     -- seconds left on a totem before it flashes
    warnImbue = 60,    -- seconds left on an imbue before it flashes
}

local ANKH_ITEM = 17030
local REINCARNATION = 20608
local SHIELDS = { "Lightning Shield", "Water Shield", "Earth Shield" }

-- Slot order from GetTotemInfo: 1 Fire, 2 Earth, 3 Water, 4 Air.
local ELEMENTS = {
    { name = "Fire",  icon = "Interface\\Icons\\Spell_Fire_SealOfFire" },
    { name = "Earth", icon = "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02" },
    { name = "Water", icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental" },
    { name = "Air",   icon = "Interface\\Icons\\Spell_Nature_InvisibilityTotem" },
}

local ICON = 36
local GAP = 4

local function Print(msg, ...)
    print("|cff3fc7ebTotem Twister|r: " .. format(msg, ...))
end

local function Plain(v, fallback)
    if v == nil then return fallback end
    if issecretvalue and issecretvalue(v) then return fallback end
    return v
end

local function Clock(secs)
    if secs >= 60 then return format("%dm", math.ceil(secs / 60)) end
    return format("%d", math.ceil(secs))
end

---------------------------------------------------------------------------
-- Data readers. Each returns plain values or nil.
---------------------------------------------------------------------------
local function ReadTotem(slot)
    local _, name, start, duration, icon = GetTotemInfo(slot)
    name = Plain(name, "")
    if name == "" then return nil end
    start, duration = Plain(start, 0), Plain(duration, 0)
    if duration <= 0 then return nil end
    return { name = name, start = start, duration = duration, icon = Plain(icon) }
end

-- Returns remaining seconds for main hand and off hand imbues, or nil.
local function ReadImbues()
    local mh, oh
    if C_Item and C_Item.GetWeaponEnchantInfo then
        local function first(list)
            local e = list and list[1]
            if not e then return nil end
            -- Field names vary between builds; take whatever expiration we can find.
            local ms = Plain(e.expirationTime or e.expiration or e.timeRemaining)
            if ms then return ms / 1000 end
            return nil
        end
        local ok, mhList = pcall(C_Item.GetWeaponEnchantInfo, Enum.WeaponSlot and Enum.WeaponSlot.MainHand or 0)
        local ok2, ohList = pcall(C_Item.GetWeaponEnchantInfo, Enum.WeaponSlot and Enum.WeaponSlot.OffHand or 1)
        if ok then mh = first(mhList) end
        if ok2 then oh = first(ohList) end
        if mh or oh then return mh, oh end
    end
    if GetWeaponEnchantInfo then
        local hasMH, mhExp, _, _, hasOH, ohExp = GetWeaponEnchantInfo()
        if Plain(hasMH) then mh = Plain(mhExp, 0) / 1000 end
        if Plain(hasOH) then oh = Plain(ohExp, 0) / 1000 end
    end
    return mh, oh
end

local function ReadShield()
    for _, spellName in ipairs(SHIELDS) do
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", spellName, "HELPFUL")
        if aura then
            return {
                name = spellName,
                icon = Plain(aura.icon),
                charges = Plain(aura.applications, 0),
                expires = Plain(aura.expirationTime, 0),
            }
        end
    end
    return nil
end

local function ReadAnkh()
    local count = Plain(C_Item.GetItemCount(ANKH_ITEM), 0)
    local cd = C_Spell.GetSpellCooldown(REINCARNATION)
    local remaining = 0
    if cd then
        local start, duration = Plain(cd.startTime, 0), Plain(cd.duration, 0)
        if duration > 2 then -- ignore the GCD
            remaining = math.max(0, start + duration - GetTime())
        end
    end
    return count, remaining
end

---------------------------------------------------------------------------
-- UI
---------------------------------------------------------------------------
local hud

local function MakeIcon(parent, texture)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(ICON, ICON)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if texture then b.icon:SetTexture(texture) end
    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetAllPoints()
    b.cd:SetHideCountdownNumbers(true)
    b.cd:SetDrawEdge(false)
    b.time = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
    b.time:SetPoint("BOTTOM", 0, 2)
    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalOutline")
    b.count:SetPoint("TOPRIGHT", -2, -1)
    b.flash = b:CreateTexture(nil, "OVERLAY")
    b.flash:SetAllPoints()
    b.flash:SetColorTexture(1, 0.2, 0.2, 0.35)
    b.flash:Hide()
    return b
end

local function SetDim(b, dim)
    if dim then b.icon:SetVertexColor(0.35, 0.35, 0.35) else b.icon:SetVertexColor(1, 1, 1) end
end

local function Flash(b, on)
    if on then
        local t = GetTime() % 1
        b.flash:SetShown(t < 0.5)
    else
        b.flash:Hide()
    end
end

local function BuildHUD()
    local f = CreateFrame("Frame", "TotemTwisterHUD", UIParent)
    f:SetSize(4 * ICON + 3 * GAP, ICON * 2 + GAP)
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) if not ns.db.locked then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        ns.db.point, ns.db.x, ns.db.y = point, x, y
    end)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetColorTexture(0, 0, 0, 0.25)
    f.bg:Hide()

    -- Row 1: totems
    f.totems = {}
    for i, el in ipairs(ELEMENTS) do
        local b = MakeIcon(f, el.icon)
        b:SetPoint("TOPLEFT", (i - 1) * (ICON + GAP), 0)
        b.slot = i
        b:RegisterForClicks("RightButtonUp")
        b:SetScript("OnClick", function(self) if DestroyTotem then DestroyTotem(self.slot) end end)
        b:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine(self.totemName or (el.name .. " totem"))
            GameTooltip:AddLine("Right-click to destroy", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        f.totems[i] = b
    end

    -- Row 2: main hand, off hand, shield, ankh
    f.mh = MakeIcon(f); f.mh:SetPoint("TOPLEFT", 0, -(ICON + GAP))
    f.oh = MakeIcon(f); f.oh:SetPoint("TOPLEFT", ICON + GAP, -(ICON + GAP))
    f.shield = MakeIcon(f); f.shield:SetPoint("TOPLEFT", 2 * (ICON + GAP), -(ICON + GAP))
    f.ankh = MakeIcon(f, "Interface\\Icons\\Spell_Nature_Reincarnation"); f.ankh:SetPoint("TOPLEFT", 3 * (ICON + GAP), -(ICON + GAP))

    f:SetScript("OnUpdate", function(self, elapsed)
        self.acc = (self.acc or 0) + elapsed
        if self.acc < 0.1 then return end
        self.acc = 0
        ns:Refresh()
    end)
    return f
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
local warned = {} -- [key] = true once we've played a sound for this expiry

local function Warn(key, on)
    if not on then warned[key] = nil; return end
    if warned[key] then return end
    warned[key] = true
    if ns.db.sound then PlaySound(SOUNDKIT.RAID_WARNING) end
end

function ns:Refresh()
    local now = GetTime()

    for i, b in ipairs(hud.totems) do
        local t = ReadTotem(i)
        if t then
            local left = t.start + t.duration - now
            b.totemName = t.name
            if t.icon then b.icon:SetTexture(t.icon) end
            SetDim(b, false)
            b.cd:SetCooldown(t.start, t.duration)
            b.time:SetText(left > 0 and Clock(left) or "")
            local warn = left > 0 and left <= ns.db.warnTotem
            Flash(b, warn); Warn("totem" .. i, warn)
        else
            b.totemName = nil
            b.icon:SetTexture(ELEMENTS[i].icon)
            SetDim(b, true)
            b.cd:Clear()
            b.time:SetText("")
            Flash(b, false); Warn("totem" .. i, false)
        end
    end

    local mh, oh = ReadImbues()
    for _, pair in ipairs({ { hud.mh, mh, 16 }, { hud.oh, oh, 17 } }) do
        local b, left, invSlot = pair[1], pair[2], pair[3]
        local tex = Plain(GetInventoryItemTexture("player", invSlot))
        b.icon:SetTexture(tex or "Interface\\Icons\\INV_Misc_QuestionMark")
        if not tex then
            b:Hide()
        else
            b:Show()
            if left and left > 0 then
                SetDim(b, false)
                b.time:SetText(Clock(left))
                local warn = left <= ns.db.warnImbue
                Flash(b, warn); Warn("imbue" .. invSlot, warn)
            else
                SetDim(b, true)
                b.time:SetText("")
                Flash(b, true); Warn("imbue" .. invSlot, true) -- no imbue at all is worth a nudge
            end
        end
    end

    local s = ReadShield()
    if s then
        if s.icon then hud.shield.icon:SetTexture(s.icon) end
        SetDim(hud.shield, false)
        hud.shield.count:SetText(s.charges > 0 and s.charges or "")
        local left = s.expires > 0 and (s.expires - now) or 0
        hud.shield.time:SetText(left > 0 and Clock(left) or "")
        Flash(hud.shield, false); Warn("shield", false)
    else
        hud.shield.icon:SetTexture("Interface\\Icons\\Spell_Nature_LightningShield")
        SetDim(hud.shield, true)
        hud.shield.count:SetText("")
        hud.shield.time:SetText("")
        Flash(hud.shield, true); Warn("shield", true)
    end

    local ankhs, cd = ReadAnkh()
    hud.ankh.count:SetText(ankhs)
    if ankhs == 0 then
        hud.ankh.count:SetTextColor(1, 0.2, 0.2)
    else
        hud.ankh.count:SetTextColor(1, 0.82, 0)
    end
    if cd > 0 then
        SetDim(hud.ankh, true)
        hud.ankh.time:SetText(Clock(cd))
    else
        SetDim(hud.ankh, ankhs == 0)
        hud.ankh.time:SetText("")
    end
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------
local function ApplyPosition()
    hud:ClearAllPoints()
    hud:SetPoint(ns.db.point, UIParent, ns.db.point, ns.db.x, ns.db.y)
    hud:SetScale(ns.db.scale)
    hud.bg:SetShown(not ns.db.locked)
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        TotemTwisterDB = TotemTwisterDB or {}
        for k, v in pairs(defaults) do
            if TotemTwisterDB[k] == nil then TotemTwisterDB[k] = v end
        end
        ns.db = TotemTwisterDB
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        local _, class = UnitClass("player")
        if Plain(class) ~= "SHAMAN" then return end
        hud = BuildHUD()
        ApplyPosition()
        Print("loaded. /tt for options.")
    end
end)

SLASH_TOTEMTWISTER1 = "/tt"
SLASH_TOTEMTWISTER2 = "/totemtwister"
SlashCmdList.TOTEMTWISTER = function(input)
    if not hud then Print("only for shamans."); return end
    local cmd, rest = strsplit(" ", strtrim(input or ""), 2)
    cmd = cmd:lower()
    if cmd == "lock" then
        ns.db.locked = not ns.db.locked
        ApplyPosition()
        Print(ns.db.locked and "locked" or "unlocked, drag to move")
    elseif cmd == "scale" and tonumber(rest) then
        ns.db.scale = math.max(0.5, math.min(3, tonumber(rest)))
        ApplyPosition()
    elseif cmd == "sound" then
        ns.db.sound = not ns.db.sound
        Print("sound %s", ns.db.sound and "on" or "off")
    elseif cmd == "reset" then
        for k, v in pairs(defaults) do ns.db[k] = v end
        ApplyPosition()
        Print("reset")
    else
        Print("commands: /tt lock | scale <0.5-3> | sound | reset")
    end
end
