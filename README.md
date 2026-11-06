# wow-addons

A playground for World of Warcraft: Forever addon development. Each top-level folder is one addon.

See `SETUP.md` for the full package: which CurseForge addons to run alongside these.

## Addons

| Folder | What it does |
|---|---|
| `HelloAzeroth/` | Minimal starter: prints on login, `/hello` slash command, saved variables, a draggable frame. Copy it to start a new addon. |
| `Travelogue/` | Automatic journal of your character: level-ups, first visits to zones and subzones, dungeons, deaths, and `/tlog note` entries. Each entry snapshots level, location, gold, time played and full gear, and can take a screenshot. `/tlog` opens the book. |
| `TotemTwister/` | Shaman HUD: four totem slots with timers, main and off hand imbue timers, Lightning/Water/Earth Shield charges, Ankh count and Reincarnation cooldown. Flashes and plays a sound when something is about to drop. `/tt` for options. |

## The Forever client in one paragraph

Forever (codename Camelot) is the level-60 "Classic Plus" client. It reports game version **1.60.1**, so the TOC
`## Interface:` number is **16001**, but it runs the modern Midnight 12.x UI codebase, not the Classic Era one.
Classic Era addons do not work on it, and neither do retail addons that declare only 120xxx. An addon written
for Forever is a normal modern-API addon with a 16001 Interface line. Confirm the number on your own client with
`/dump select(4, GetBuildInfo())`.

## Working on an addon

Addons are plain Lua 5.1 plus a `.toc` manifest. The `.toc` basename must match the folder name.
The game folder was `_classic_beta_` during the beta and is `_forever_` on live. Find it from Battle.net:
pick WoW Forever above Play, then the gear icon, then Show in Explorer / Finder.

The easiest dev loop is a symlink from the game folder to this repo, then `/reload` in game after each edit.
New addon folders are only discovered at client start, so restart once after creating one.

```powershell
# Windows (elevated PowerShell)
New-Item -ItemType SymbolicLink -Path "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\HelloAzeroth" -Target "C:\path\to\wow-addons\HelloAzeroth"
```

```bash
# macOS
ln -s "$PWD/HelloAzeroth" "/Applications/World of Warcraft/_forever_/Interface/AddOns/HelloAzeroth"
```

In game, turn on error display once: `/console scriptErrors 1`. BugSack + BugGrabber are nicer.

## Lint

```bash
luarocks install luacheck
luacheck .
```

CI runs luacheck on every push. Pushing a tag like `v0.1.0` zips every addon folder, substitutes `@project-version@` in the TOC, and attaches the zips to a GitHub release.

## Reference

- Warcraft Wiki API docs: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- TOC format and current Interface numbers: https://warcraft.wiki.gg/wiki/TOC_format
- Secret values: https://warcraft.wiki.gg/wiki/Secret_values
- 12.0 API removals and replacements: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- Blizzard UI source mirror: https://github.com/Gethe/wow-ui-source
- In game: `/api` (needs Blizzard_APIDocumentation loaded)
