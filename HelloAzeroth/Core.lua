-- HelloAzeroth: a minimal starter addon.
-- Every file in the TOC receives the addon name and a private table as varargs.
local ADDON_NAME, ns = ...

-- Defaults for the saved-variables table. Anything the user changes lives in HelloAzerothDB.
local defaults = {
    greetings = 0,
    framePos = { point = "CENTER", x = 0, y = 0 },
}

local function Print(msg, ...)
    print("|cff33ff99" .. ADDON_NAME .. "|r: " .. format(msg, ...))
end

---------------------------------------------------------------------------
-- A small draggable frame
---------------------------------------------------------------------------
local function CreateMainFrame()
    local f = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent, "BackdropTemplate")
    f:SetSize(220, 60)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        ns.db.framePos = { point = point, x = x, y = y }
    end)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("CENTER")

    -- Escape closes it, like a Blizzard panel.
    tinsert(UISpecialFrames, f:GetName())
    f:Hide()
    return f
end

-- On Forever, unit names (even your own) can arrive as secret values. Formatting a
-- secret string into another string throws, so fall back to a plain word.
local function SafeName(unit)
    local name = UnitName(unit)
    if name == nil or (issecretvalue and issecretvalue(name)) then
        return "adventurer"
    end
    return name
end

local function UpdateFrameText()
    if not ns.frame then return end
    ns.frame.text:SetText(format("Hello, %s! Greeted %d times.", SafeName("player"), ns.db.greetings))
end

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
SLASH_HELLOAZEROTH1 = "/hello"
SLASH_HELLOAZEROTH2 = "/hz"
SlashCmdList.HELLOAZEROTH = function(input)
    local cmd = strtrim(input or ""):lower()
    if cmd == "reset" then
        wipe(ns.db)
        for k, v in pairs(defaults) do ns.db[k] = v end
        Print("settings reset")
        UpdateFrameText()
    elseif cmd == "show" or cmd == "" then
        ns.db.greetings = ns.db.greetings + 1
        UpdateFrameText()
        if ns.frame:IsShown() then ns.frame:Hide() else ns.frame:Show() end
    else
        Print("usage: /hello [show|reset]")
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")

events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Saved variables are only populated once our own ADDON_LOADED fires.
        HelloAzerothDB = HelloAzerothDB or {}
        for k, v in pairs(defaults) do
            if HelloAzerothDB[k] == nil then HelloAzerothDB[k] = v end
        end
        ns.db = HelloAzerothDB
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        ns.frame = CreateMainFrame()
        local pos = ns.db.framePos
        ns.frame:ClearAllPoints()
        ns.frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
        UpdateFrameText()

        local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
        Print("v%s loaded. Type /hello.", version)
    end
end)
