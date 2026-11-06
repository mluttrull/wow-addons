# wow-addons

A playground for World of Warcraft addon development. Each top-level folder is one addon.

## Addons

| Folder | What it does |
|---|---|
| `HelloAzeroth/` | Minimal starter: prints on login, `/hello` slash command, saved variables, a draggable frame. Copy it to start a new addon. |

## Working on an addon

Addons are plain Lua 5.1 plus a `.toc` manifest. The game loads them from
`World of Warcraft/_retail_/Interface/AddOns/<Name>/`, and the `.toc` basename must match the folder name.

The easiest dev loop is a symlink from the game folder to this repo, then `/reload` in game after each edit:

```bash
# Windows (run in an elevated PowerShell)
New-Item -ItemType SymbolicLink -Path "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\HelloAzeroth" -Target "C:\path\to\wow-addons\HelloAzeroth"
```

```bash
# macOS
ln -s "$PWD/HelloAzeroth" "/Applications/World of Warcraft/_retail_/Interface/AddOns/HelloAzeroth"
```

In game, turn on error display once: `/console scriptErrors 1`. BugSack + BugGrabber are nicer.

## Lint

```bash
luarocks install luacheck
luacheck .
```

CI runs luacheck on every push and packages a release zip with the BigWigs packager when you push a tag like `v0.1.0`.

## Reference

- Warcraft Wiki API docs: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- TOC format: https://warcraft.wiki.gg/wiki/TOC_format
- Blizzard UI source mirror: https://github.com/Gethe/wow-ui-source
- In game: `/api` (needs the Blizzard_APIDocumentation addon loaded), `/dump select(4, GetBuildInfo())` for the current Interface number
