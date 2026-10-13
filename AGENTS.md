# Bag Sort & Auto Delete Junk

WoW addon that sorts bags by vendor slot value and deletes cheap junk so gatherers (skinners) keep room for loot.

- Target client: WoW Forever beta, `C:\Program Files (x86)\World of Warcraft\_classic_beta_`, Interface 16001 (also flagged for Classic Era 11509).
- Source of truth is `addon/BagSortAutoDeleteJunk`; the game loads a copy from `_classic_beta_\Interface\AddOns\BagSortAutoDeleteJunk`. Copy over after edits.
- Price model: vendor sell price from `GetItemInfo` (11th return) x stack count = slot value. Items with charges report a negative count; `Compat.lua` normalises it to 1.
- Files: `Core.lua` (defaults, DB migration via `version`, events, slash `/bsj`, global binding functions), `Compat.lua` (C_Container / legacy API wrappers), `Scanner.lua` (bag snapshot), `Junk.lua` (candidate rules + deletion), `Sort.lua` (stepwise swap sorter on a ticker), `UI/` (widgets, options window, minimap button + floating bar), `Bindings.xml`, `Locales.lua` (enUS keys, ruRU overrides).
- Sorting matches slots by itemID + count; when the target slot holds the same item with another count it is moved aside first to avoid accidental stack merges.
- Deletion: `PickupContainerItem` + `DeleteCursorItem`, only gray/white (blacklist also limited to quality <= 1). If the client blocks non-hardware deletion the junk button glows and a click/keybind deletes.
- SavedVariables `BSADJ_DB` (account-wide). Bump `version` in `Core.lua` defaults and add a migration block when changing semantics of existing keys.
- Lua errors land in `<WoW>/_classic_beta_/Logs/General.log`; `/console scriptErrors 1` shows them in game.
- Code style: no inline comments.
- Logo: `Media/Logo.tga` (256), `Media/Icon.tga` (64), `curseforge/logo.png` (400).
- Release: bump `## Version` in the .toc, run `packaging/build.ps1`, upload `dist/*.zip` to CurseForge, tag `v<version>` on GitHub.
- CurseForge page text lives in `curseforge/description.md` and `curseforge/summary.txt`.
