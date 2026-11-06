-- Travelogue: records moments in your character's life.
local ADDON_NAME, ns = ...

ns.defaults = {
    entries = {},            -- array of entry tables, oldest first
    seenZones = {},          -- [zoneName] = true
    seenSubzones = {},       -- [zone .. "|" .. subzone] = true
    screenshot = {           -- per event type
        levelup = true,
        zone = true,
        subzone = false,
        dungeon = true,
        death = false,
        note = false,
    },
    screenshotDelay = 1.5,   -- seconds, lets the level-up flash show
    hideUIForScreenshot = false,
}

-- Equipment slot ids 1..19 (ammo slot 0 excluded, 20+ are bags).
ns.SLOTS = {
    { 1, "Head" }, { 2, "Neck" }, { 3, "Shoulder" }, { 15, "Back" }, { 5, "Chest" },
    { 4, "Shirt" }, { 19, "Tabard" }, { 9, "Wrist" }, { 10, "Hands" }, { 6, "Waist" },
    { 7, "Legs" }, { 8, "Feet" }, { 11, "Ring 1" }, { 12, "Ring 2" },
    { 13, "Trinket 1" }, { 14, "Trinket 2" }, { 16, "Main Hand" }, { 17, "Off Hand" }, { 18, "Ranged" },
}

ns.KIND_LABEL = {
    levelup = "Level Up",
    zone    = "New Zone",
    subzone = "Discovered",
    dungeon = "Dungeon",
    death   = "Death",
    note    = "Note",
    start   = "First Login",
}

local function Print(msg, ...)
    print("|cffd4a017Travelogue|r: " .. format(msg, ...))
end
ns.Print = Print

-- Secret values: on Forever, several unit APIs can hand back opaque values.
-- Anything we store in SavedVariables or format into a string must be plain.
local function Plain(v, fallback)
    if v == nil then return fallback end
    if issecretvalue and issecretvalue(v) then return fallback end
    return v
end
ns.Plain = Plain

---------------------------------------------------------------------------
-- Snapshot helpers
---------------------------------------------------------------------------
local function ZoneInfo()
    local zone = Plain(GetZoneText(), "Unknown")
    local sub = Plain(GetSubZoneText(), "")
    local mapID = C_Map.GetBestMapForUnit("player")
    local x, y
    if mapID then
        local pos = C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then
            x, y = pos:GetXY()
            x, y = Plain(x), Plain(y)
        end
    end
    return zone, sub, mapID, x, y
end

local function GearSnapshot()
    local gear = {}
    for _, slot in ipairs(ns.SLOTS) do
        local link = Plain(GetInventoryItemLink("player", slot[1]))
        if link then
            gear[#gear + 1] = { slot = slot[2], link = link }
        end
    end
    return gear
end

local timePlayed = 0          -- total seconds, refreshed by TIME_PLAYED_MSG
local timePlayedAt = 0        -- GetTime() when refreshed

local function TimePlayedNow()
    if timePlayed == 0 then return nil end
    return math.floor(timePlayed + (GetTime() - timePlayedAt))
end

---------------------------------------------------------------------------
-- Screenshot
---------------------------------------------------------------------------
local pendingShot = nil

local function TakeScreenshot(entry)
    if not ns.db.screenshot[entry.kind] then return end
    C_Timer.After(ns.db.screenshotDelay, function()
        pendingShot = entry
        if ns.db.hideUIForScreenshot then
            UIParent:Hide()
            C_Timer.After(0.1, function()
                Screenshot()
                C_Timer.After(0.5, function() UIParent:Show() end)
            end)
        else
            Screenshot()
        end
    end)
end

---------------------------------------------------------------------------
-- Recording
---------------------------------------------------------------------------
function ns:AddEntry(kind, title, text)
    local zone, sub, mapID, x, y = ZoneInfo()
    local entry = {
        kind = kind,
        title = title,
        text = text,
        time = time(),
        level = Plain(UnitLevel("player"), 0),
        zone = zone,
        subzone = sub,
        mapID = mapID,
        x = x, y = y,
        gold = Plain(GetMoney(), 0),
        played = TimePlayedNow(),
        gear = GearSnapshot(),
    }
    tinsert(ns.db.entries, entry)
    TakeScreenshot(entry)
    if ns.OnEntryAdded then ns.OnEntryAdded(entry) end
    return entry
end

local function OnZoneChanged()
    local zone, sub = ZoneInfo()
    if zone == "Unknown" or zone == "" then return end
    if not ns.db.seenZones[zone] then
        ns.db.seenZones[zone] = true
        ns:AddEntry("zone", zone, format("First steps into %s.", zone))
    elseif sub ~= "" then
        local key = zone .. "|" .. sub
        if not ns.db.seenSubzones[key] then
            ns.db.seenSubzones[key] = true
            ns:AddEntry("subzone", sub, format("Discovered %s, in %s.", sub, zone))
        end
    end
end

local lastInstance = nil
local function OnEnteringWorld()
    local inInstance, instanceType = IsInInstance()
    if inInstance and (instanceType == "party" or instanceType == "raid") then
        local name = Plain(select(1, GetInstanceInfo()), "an instance")
        if lastInstance ~= name then
            lastInstance = name
            ns:AddEntry("dungeon", name, format("Entered %s.", name))
        end
    else
        lastInstance = nil
    end
    RequestTimePlayed()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= ADDON_NAME then return end
        TravelogueDB = TravelogueDB or {}
        for k, v in pairs(ns.defaults) do
            if TravelogueDB[k] == nil then
                if type(v) == "table" then
                    TravelogueDB[k] = {}
                    for k2, v2 in pairs(v) do TravelogueDB[k][k2] = v2 end
                else
                    TravelogueDB[k] = v
                end
            end
        end
        ns.db = TravelogueDB
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self:RegisterEvent("ZONE_CHANGED")
        self:RegisterEvent("ZONE_CHANGED_INDOORS")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_DEAD")
        self:RegisterEvent("TIME_PLAYED_MSG")
        self:RegisterEvent("SCREENSHOT_SUCCEEDED")
        self:RegisterEvent("SCREENSHOT_FAILED")
        RequestTimePlayed()
        if #ns.db.entries == 0 then
            C_Timer.After(3, function()
                ns:AddEntry("start", "The journey begins", "A new adventurer sets out into Azeroth.")
                OnZoneChanged()
            end)
        end
        Print("recording. /tlog to open the journal.")

    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = Plain(..., UnitLevel("player"))
        local entry = ns:AddEntry("levelup", format("Level %d", newLevel), format("Reached level %d.", newLevel))
        entry.level = newLevel

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
        -- Zone text can lag the event by a frame.
        C_Timer.After(0.2, OnZoneChanged)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, OnEnteringWorld)

    elseif event == "PLAYER_DEAD" then
        ns:AddEntry("death", "Fell in battle", "Died here.")

    elseif event == "TIME_PLAYED_MSG" then
        timePlayed = Plain(..., 0)
        timePlayedAt = GetTime()

    elseif event == "SCREENSHOT_SUCCEEDED" then
        if pendingShot then
            pendingShot.screenshot = date("%m%d%y_%H%M%S") -- matches WoW's WoWScrnShot_ naming
            pendingShot = nil
        end

    elseif event == "SCREENSHOT_FAILED" then
        pendingShot = nil
    end
end)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
SLASH_TRAVELOGUE1 = "/tlog"
SLASH_TRAVELOGUE2 = "/travelogue"
SlashCmdList.TRAVELOGUE = function(input)
    local cmd, rest = strsplit(" ", strtrim(input or ""), 2)
    cmd = cmd:lower()
    if cmd == "" then
        ns:ToggleBook()
    elseif cmd == "note" and rest and rest ~= "" then
        ns:AddEntry("note", rest, rest)
        Print("noted.")
    elseif cmd == "shot" then
        local kind = rest and rest:lower()
        if kind and ns.db.screenshot[kind] ~= nil then
            ns.db.screenshot[kind] = not ns.db.screenshot[kind]
            Print("screenshots on %s: %s", kind, ns.db.screenshot[kind] and "on" or "off")
        else
            Print("usage: /tlog shot <levelup|zone|subzone|dungeon|death|note>")
        end
    elseif cmd == "hideui" then
        ns.db.hideUIForScreenshot = not ns.db.hideUIForScreenshot
        Print("hide UI for screenshots: %s", ns.db.hideUIForScreenshot and "on" or "off")
    elseif cmd == "wipe" and rest == "confirm" then
        wipe(ns.db.entries); wipe(ns.db.seenZones); wipe(ns.db.seenSubzones)
        Print("journal wiped.")
    else
        Print("commands: /tlog | note <text> | shot <kind> | hideui | wipe confirm")
    end
end
