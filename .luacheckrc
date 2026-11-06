std = "lua51"
max_line_length = false
self = false
exclude_files = { ".release/", "**/Libs/" }

ignore = {
    "212/self", -- unused argument self
    "212/event",
    "212/...",
    "631", -- line too long
}

-- WoW API globals the addons touch. Add to this list as you use more.
read_globals = {
    -- frames & UI
    "CreateFrame", "UIParent", "GameTooltip", "UISpecialFrames",
    "GameFontNormal", "GameFontHighlight", "BackdropTemplateMixin",
    "DEFAULT_CHAT_FRAME", "SlashCmdList",
    -- namespaces
    "C_AddOns", "C_Timer", "C_Spell", "C_Item", "C_UnitAuras", "C_Map",
    "C_CombatLog", "C_CVar", "Enum",
    -- misc globals
    "GetBuildInfo", "UnitName", "UnitClass", "GetRealmName", "InCombatLockdown",
    "GetTime", "IsInInstance", "issecretvalue", "UnitFullName", "PlaySound", "SOUNDKIT", "date", "strsplit", "strtrim", "tinsert", "tremove",
    "wipe", "format", "LibStub",
}

-- Globals the addon itself defines (saved variables, slash command names).
globals = {
    "SLASH_HELLOAZEROTH1", "SLASH_HELLOAZEROTH2",
    "HelloAzerothDB",
}
