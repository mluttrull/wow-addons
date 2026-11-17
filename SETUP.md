# My Forever setup

A shaman, playing for fun. This is the full addon package: what to grab from CurseForge, and what comes from this repo.
CurseForge entries were checked on 2026-11-05 against client 1.60.1. Install through the CurseForge app or
WowUp (beta releases support Forever) so updates keep coming.

## From CurseForge

### Must have
| Addon | Why |
|---|---|
| **Questie** | Quest givers and objectives on the map. The single biggest quality-of-life jump on a vanilla-style world. |
| **Baganator** (or Bagnon) | One bag window, categories, MIT licensed. Five separate bags gets old by level 10. |
| **Leatrix Maps** | Zoomable world map with an unexplored overlay instead of fog. |
| **BugSack + BugGrabber** | Catches Lua errors into a sack instead of popups. Essential while running our own addons. |

### Fun, not optimising
| Addon | Why |
|---|---|
| **Lore Forever** | Zone stories and lore read aloud by a narrator as you travel. Pick a voice pack you like. |
| **Cinematic** | Slows the camera and hides the UI for walking around and taking it in. |
| **Forever Quest Tint** | Colours quests that are new to Forever so you notice the fresh content. |
| **TomTom** | Waypoint arrow. Mostly for Wanderlust later. |

### Shaman
| Addon | Why |
|---|---|
| **ShamanPower** or **ShamanForever** | Mature shaman HUDs. Run one alongside Totem Twister for a while and steal whatever you miss. |

### Small and tasteful
| Addon | Why |
|---|---|
| **Tweaks Forever** | ~25 togglable tweaks that look like they shipped with the game: XP/hour, dungeon entrance icons, Train All, gear groups, fishing double-click. GPL-3, so a good source to lift from. |
| **SkillUp Forever** | Skill-up chances and shopping lists in the Professions window. |
| **Forever Windows** | Drag any Blizzard window and have it stay there. |

### Polestar, in wander mode
Polestar is a full 1-60 leveling guide with quest automation, which is the opposite of wandering. But its Lookup,
Dungeons and Rares pages are reference tools, not a leash, and they're worth having. GPL-3, by Fitz (0xfitz).

Install: CurseForge app, search "Polestar Guides". Or unzip `Polestar-<version>.zip` from the GitHub release
Assets (not "Source code") so the `Polestar`, `Polestar_Guides`, `Polestar_Codex` and `Polestar_Nav` folders sit
directly in `_forever_/Interface/AddOns/`. Skip the Polestar Client app and the `Polestar_Recorder` addon unless you
want to upload your play data; without the Client the recorder stays off.

After first login, open `/ps options` and turn these off so it stops driving:

| Page | Setting | Set to |
|---|---|---|
| Questing | Accept guide quests, Turn in guide quests | Off |
| Questing | Skip single-option gossip, Pick what the step asks for | Off (read the NPCs) |
| Questing | Take the best reward, Wear reward upgrades | Off (already default) |
| Quality of Life | Faster auto-loot, auto-sell, training | your call |
| Guide window | Close the guide tab, or `/ps hide` | hidden |
| Alerts | Dungeons heads-up card | Off unless you like being told a dungeon opened up |

Then use it as a reference:

- `/ps lookup <thing>` answers "how do I get that" for items, mounts, pets, NPCs, quests, zones.
- `/ps dungeons` has a page per dungeon with every quest, chain and reward. "Pick up the quests" builds a one-off guide to collect them before a run.
- `/ps rares` lists rares and treasures by zone, and alerts when one is near.
- `/ps mount` names the mount of whoever you're pointing at and where it comes from.
- `/ps xp`, `/ps bags`, `/ps restock` are handy one-liners.
- Shift held while talking to an NPC skips any automation you left on, once.

### Skipped on purpose
ElvUI / EllesmereUI / ForeverPlus / ForeverForge (full suites, replace too much), RestedXP and other route guides
(the point is to wander; Polestar's guide engine counts, see above for using only its reference side), damage meters (Forever has one built in and the API hides the numbers anyway).

## From this repo
| Addon | Status |
|---|---|
| **Travelogue** | Auto-journal with gear snapshots and screenshots. `/tlog` |
| **Totem Twister** | Totem timers, weapon imbues, shield charges, Ankh count, Reincarnation cooldown. `/tt` |
| HelloAzeroth | Template only, don't install. |

## Install
Symlink each repo addon folder into `_forever_/Interface/AddOns/` (see README), restart the client once, then `/reload` after edits.
