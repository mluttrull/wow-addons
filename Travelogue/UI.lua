-- Travelogue book UI: entry list on the left, details on the right.
local _, ns = ...

local ROW_HEIGHT = 22
local book

local KIND_COLOR = {
    levelup = "ffffd100", zone = "ff3fc7eb", subzone = "ff8ec7d2", dungeon = "ffc69b6d",
    death = "ffc41e3a", note = "ffabd473", start = "ffffffff",
}

local function Colored(kind, text)
    return "|c" .. (KIND_COLOR[kind] or "ffffffff") .. text .. "|r"
end

local function FormatPlayed(secs)
    if not secs then return "?" end
    local d = math.floor(secs / 86400); secs = secs % 86400
    local h = math.floor(secs / 3600); secs = secs % 3600
    local m = math.floor(secs / 60)
    if d > 0 then return format("%dd %dh %dm", d, h, m) end
    return format("%dh %dm", h, m)
end

local function FormatGold(copper)
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return format("%d|cffffd700g|r %d|cffc7c7cfs|r %d|cffeda55fc|r", g, s, c)
end

---------------------------------------------------------------------------
-- Detail pane
---------------------------------------------------------------------------
local function ShowEntry(entry)
    local d = book.detail
    d:Clear()
    if not entry then
        d:AddMessage("Select an entry.")
        return
    end
    d:AddMessage(Colored(entry.kind, entry.title), 1, 1, 1)
    d:AddMessage(date("%A, %B %d %Y at %H:%M", entry.time), 0.7, 0.7, 0.7)
    d:AddMessage(" ")
    d:AddMessage(entry.text or "", 0.9, 0.9, 0.9)
    d:AddMessage(" ")
    local where = entry.zone
    if entry.subzone and entry.subzone ~= "" and entry.subzone ~= entry.zone then
        where = entry.subzone .. ", " .. entry.zone
    end
    if entry.x and entry.y then
        where = format("%s (%.1f, %.1f)", where, entry.x * 100, entry.y * 100)
    end
    d:AddMessage("|cffaaaaaaWhere:|r " .. where)
    d:AddMessage(format("|cffaaaaaaLevel:|r %d    |cffaaaaaaPlayed:|r %s", entry.level, FormatPlayed(entry.played)))
    d:AddMessage("|cffaaaaaaPurse:|r " .. FormatGold(entry.gold or 0))
    if entry.screenshot then
        d:AddMessage("|cffaaaaaaScreenshot:|r WoWScrnShot_" .. entry.screenshot .. ".jpg")
    end
    d:AddMessage(" ")
    d:AddMessage("|cffaaaaaaWearing:|r")
    if #entry.gear == 0 then
        d:AddMessage("  nothing at all")
    end
    for _, g in ipairs(entry.gear) do
        d:AddMessage(format("  |cff888888%s|r  %s", g.slot, g.link))
    end
    -- Oldest message is at the bottom in a ScrollingMessageFrame; jump to top.
    d:ScrollToTop()
end

---------------------------------------------------------------------------
-- List pane
---------------------------------------------------------------------------
local function RefreshList()
    local entries = ns.db.entries
    local n = #entries
    local scroll = book.list
    local offset = scroll.offset or 0
    local rows = book.rows

    for i, row in ipairs(rows) do
        local idx = n - (offset + i - 1) -- newest first
        local entry = entries[idx]
        if entry then
            row.entry = entry
            row.text:SetText(format("%s  %s", Colored(entry.kind, "L" .. entry.level), entry.title))
            row.sub:SetText(date("%b %d", entry.time))
            row:Show()
            if book.selected == entry then row.bg:Show() else row.bg:Hide() end
        else
            row.entry = nil
            row:Hide()
        end
    end

    local maxOffset = math.max(0, n - #rows)
    scroll.bar:SetMinMaxValues(0, maxOffset)
    scroll.bar:SetValue(math.min(offset, maxOffset))
    book.count:SetText(format("%d entries", n))
end

local function Select(entry)
    book.selected = entry
    RefreshList()
    ShowEntry(entry)
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
local function BuildBook()
    local f = CreateFrame("Frame", "TravelogueBook", UIParent, "BackdropTemplate")
    f:SetSize(720, 460)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, f:GetName())

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("Travelogue")

    f.count = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.count:SetPoint("TOPLEFT", 20, -20)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- List
    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", 16, -40)
    list:SetSize(260, 400)
    list.offset = 0
    f.list = list

    local bar = CreateFrame("Slider", nil, list, "UIPanelScrollBarTemplate")
    bar:SetPoint("TOPRIGHT", 0, -16)
    bar:SetPoint("BOTTOMRIGHT", 0, 16)
    bar:SetValueStep(1); bar:SetObeyStepOnDrag(true)
    bar:SetScript("OnValueChanged", function(self, value)
        list.offset = math.floor(value + 0.5)
        RefreshList()
    end)
    list.bar = bar
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        bar:SetValue(bar:GetValue() - delta)
    end)

    f.rows = {}
    local visible = math.floor(400 / ROW_HEIGHT)
    for i = 1, visible do
        local row = CreateFrame("Button", nil, list)
        row:SetSize(236, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints(); row.bg:SetColorTexture(1, 1, 1, 0.12); row.bg:Hide()
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.text:SetPoint("LEFT", 4, 0); row.text:SetPoint("RIGHT", -44, 0)
        row.text:SetJustifyH("LEFT"); row.text:SetWordWrap(false)
        row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.sub:SetPoint("RIGHT", -4, 0)
        row:SetScript("OnClick", function(self) if self.entry then Select(self.entry) end end)
        f.rows[i] = row
    end

    -- Detail
    local detail = CreateFrame("ScrollingMessageFrame", nil, f)
    detail:SetPoint("TOPLEFT", list, "TOPRIGHT", 24, 0)
    detail:SetPoint("BOTTOMRIGHT", -20, 20)
    detail:SetFontObject(GameFontHighlight)
    detail:SetJustifyH("LEFT")
    detail:SetFading(false)
    detail:SetMaxLines(200)
    detail:SetInsertMode("BOTTOM")
    detail:SetHyperlinksEnabled(true)
    detail:EnableMouseWheel(true)
    detail:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    detail:SetScript("OnHyperlinkEnter", function(self, link)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    detail:SetScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
    detail:SetScript("OnHyperlinkClick", function(_, link, text, button)
        SetItemRef(link, text, button)
    end)
    f.detail = detail

    f:Hide()
    return f
end

function ns:ToggleBook()
    if not book then book = BuildBook() end
    if book:IsShown() then
        book:Hide()
    else
        book:Show()
        book.list.offset = 0
        local entries = ns.db.entries
        Select(entries[#entries])
    end
end

function ns.OnEntryAdded(entry)
    if book and book:IsShown() then
        Select(entry)
    end
end
