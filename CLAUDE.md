# wow-addons

Playground repo for World of Warcraft addons. One addon per top-level folder; `HelloAzeroth/` is the template.

## Facts that matter when writing code here

- WoW runs **Lua 5.1** with no `io`, `os`, `require`, or `loadfile`. No bit ops syntax; use `bit.band` etc.
- Every file gets `local ADDON_NAME, ns = ...` at the top. Share state through `ns`, not globals.
- The `.toc` basename must equal the folder name. Current retail Interface number is **120105** (12.1.5, Midnight). Bump it when a patch lands; stale numbers mark the addon "out of date".
- Saved variables: declare `## SavedVariables: Name` in the TOC, read them only after `ADDON_LOADED` fires for this addon.
- Prefer `C_` namespaces (`C_AddOns`, `C_Spell`, `C_Item`, `C_Timer`) over the legacy globals Blizzard keeps removing.
- Midnight (12.0+) restrictions: `COMBAT_LOG_EVENT_UNFILTERED` no longer fires for addons, and combat numbers (health, damage, cooldowns) often arrive as opaque **secret values** you can display but not compare or do math on. Don't design features that need raw combat data.
- Protected actions (casting, targeting, moving frames in combat) can't be done from insecure code. Check `InCombatLockdown()` before touching secure frames.
- No network access from Lua; the only outside channel is addon messages between players.

## Workflow

- Lint: `luacheck .` (config in `.luacheckrc`; add new WoW globals there as you use them).
- Test in game: symlink the addon folder into `_retail_/Interface/AddOns/`, then `/reload`. Enable errors with `/console scriptErrors 1`.
- New addon: copy `HelloAzeroth/`, rename the folder and `.toc`, update `package-as` or add a second entry in `.pkgmeta`.
- Releases: push a `v*` tag; `.github/workflows/release.yml` runs the BigWigs packager and attaches a zip to a GitHub release.

## References

- https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- https://warcraft.wiki.gg/wiki/Events
- https://github.com/Gethe/wow-ui-source (Blizzard's own UI code, the best source of real patterns)
