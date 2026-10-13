# Bag Sort & Auto Delete Junk

A World of Warcraft addon that sorts your bags by vendor value and automatically deletes cheap junk,
so gatherers (especially skinners) fill their bags with leather instead of gray trash.
Made for WoW Forever (`_classic_beta_`, Interface 16001), also flagged for Classic Era.

## Features

- **Sort by value**: slot value = vendor sell price x stack size (5 x 10s = 50s). Expensive or cheap first,
  quest items at the start, optional trade goods first / grays last, merges partial stacks, skips special bags.
- **Auto delete junk**: gray (and optionally white weapons/armor) items cheaper than a threshold,
  and/or the cheapest junk whenever free slots drop below a number you choose.
- **Safe by default**: starts in dry-run mode; never deletes quest items, trade goods, consumables, reagents,
  recipes, ammo, bags or green+ items; protected / always-delete lists.
- **Auto + button**: deletes after looting; if the game blocks it, the junk button glows and one click deletes.
- Options window with logo, minimap button, movable floating buttons, key bindings, English and Russian.

## Usage

| Command | What it does |
| --- | --- |
| `/bsj` | Open the settings window |
| `/bsj sort` | Sort bags |
| `/bsj junk` | Delete junk now |
| `/bsj preview` | List what would be deleted |

## Install

Copy `addon/BagSortAutoDeleteJunk` into `World of Warcraft/_classic_beta_/Interface/AddOns/`,
or install it from CurseForge.

## Build

```powershell
powershell -File packaging/build.ps1
```

Produces `dist/BagSortAutoDeleteJunk-<version>.zip` for CurseForge.

## License

GPL-3.0
