# wow-addons

Playground repo for **World of Warcraft: Forever** addons. One addon per top-level folder; `HelloAzeroth/` is the template.

## The target client

- Forever (codename Camelot) reports version 1.60.1. TOC line is `## Interface: 16001`. Not 120xxx, not 11xxx.
- It runs the **modern Midnight 12.x UI codebase** with "all Modern changes up to 12.1.5". Write against the modern API, never Classic Era habits. `WOW_PROJECT_ID` is 1 (mainline); there is no Forever constant.
- Flavor-specific TOC suffix is `_Camelot` (also matched by `_Mainline`). Game type names `camelot` / `forever` may still be renamed, so a plain `Name.toc` with Interface 16001 is the safe choice for this repo.
- Live install folder is `_forever_` (beta was `_classic_beta_`). Addons sit at `<folder>/Interface/AddOns/<Name>/`.
- Characters have surnames and there are no realms. `GetRealmName` and `UnitFullName` behave differently from retail; don't key saved data on realm.

## Facts that matter when writing code here

- WoW runs **Lua 5.1** with no `io`, `os`, `require`, or `loadfile`. No bit ops syntax; use `bit.band` etc.
- Every file gets `local ADDON_NAME, ns = ...` at the top. Share state through `ns`, not globals.
- Saved variables: declare `## SavedVariables: Name` in the TOC, read them only after `ADDON_LOADED` fires for this addon. The beta had a bug where SavedVariables failed to restore on restart; if settings vanish, suspect the client before the code.
- Prefer `C_` namespaces (`C_AddOns`, `C_Spell`, `C_Item`, `C_Timer`) over removed legacy globals (`GetSpellInfo`, `GetAddOnMetadata`, ...). Over a thousand globals retail addons used are gone.
- **Secret values** are everywhere on Forever, more than on retail: unit and creature names can be secret strings, `UnitExists` / `UnitCanAttack` secret booleans, friendly `UnitHealth` a secret number. Comparing, doing math on, or `format`ting a secret value throws and blanks your frame. Check with `issecretvalue(v)` and fall back. Hand secret numbers straight to StatusBars and FontStrings, which accept them.
- No combat log for addons: `COMBAT_LOG_EVENT_UNFILTERED` does not fire and `CombatLogGetCurrentEventInfo` is unavailable. Damage meters and boss timers are not buildable; UI, bag, map, quest, vendor and tooltip addons are.
- Protected actions (casting, targeting, moving secure frames in combat) fail **silently** from insecure code, with no Lua error even inside `pcall`. Check `InCombatLockdown()`.
- `PlaySoundFile` with `Sound\Interface\*.ogg` paths fails silently; use `PlaySound(SOUNDKIT.xxx)`.
- `NAME_PLATE_UNIT_ADDED` fires before the unit is populated and plates carry no `namePlateUnitToken`; re-check a frame later.
- No network access from Lua; the only outside channel is addon messages between players. Automation of any kind is bannable.

## Workflow

- Lint: `luacheck .` (config in `.luacheckrc`; add new WoW globals there as you use them).
- Test in game: symlink the addon folder into `_forever_/Interface/AddOns/`, restart once, then `/reload` after edits. Enable errors with `/console scriptErrors 1`.
- New addon: copy `HelloAzeroth/`, rename the folder and `.toc`, update `package-as` in `.pkgmeta`.
- Releases: push a `v*` tag; `.github/workflows/release.yml` runs the BigWigs packager with `-g 1.60.1` and attaches a zip to a GitHub release.

## References

- https://warcraft.wiki.gg/wiki/TOC_format (current Interface numbers, Forever row)
- https://warcraft.wiki.gg/wiki/Secret_values
- https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- https://warcraft.wiki.gg/wiki/World_of_Warcraft_API and https://warcraft.wiki.gg/wiki/Events
- https://github.com/Gethe/wow-ui-source (Blizzard's own UI code)
