# Bag Sort & Auto Delete Junk

A World of Warcraft addon that finds and deletes the cheapest eligible items in your bags,
so gatherers (especially skinners) keep room for leather and other loot. Bag sorting remains available separately.
Made for WoW Forever (`_classic_beta_`, Interface 16001), also flagged for Classic Era.

## Features

- **Sort by value**: slot value = vendor sell price x stack size (5 x 10s = 50s). Expensive or cheap first,
  quest items at the start, optional trade goods first / grays last, merges partial stacks, skips special bags.
- **Find cheap junk**: show the cheapest eligible stacks when free slots reach the configured limit (0 by default).
- **Choose item quality**: gray, white, and green items can be selected; blue and higher-quality items are always excluded.
- **Safe by default**: candidates are shown without deleting; manual deletion is available, and automatic deletion is opt-in.
  Quest items are always protected; category protections and the protected list are configurable.
- **Quiet chat**: no automatic item-by-item messages; manual deletion reports one short summary.
- Options window with logo, minimap button, movable floating buttons, key bindings, English and Russian.

## Usage

| Command | What it does |
| --- | --- |
| `/bsj` | Open the settings window |
| `/bsj sort` | Sort bags |
| `/bsj junk` | Delete junk now |
| `/bsj preview` | Open the candidate list |

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
