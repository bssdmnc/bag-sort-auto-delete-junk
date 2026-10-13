# Bag Sort & Auto Delete Junk

Sort your bags by **vendor value** and **automatically delete cheap junk**, so your bags fill up with leather, cloth and loot instead of gray trash. Made for **WoW Forever**, perfect for leveling **Skinning** or any gathering profession.

## Sorting

- Sorts by **slot value**: vendor sell price x stack size (5 x 10s = 50s).
- Expensive first or cheap first, empty slots at the end or at the start.
- **Quest items** go to the start of your bags.
- Optional: trade goods (leather, hides) first, gray items last.
- Merges partial stacks; never touches quivers, ammo or other special bags.
- Choose which bags to leave alone.

## Junk deletion

- Deletes **gray** items cheaper than a price you set (gold / silver / copper).
- Optional: **white weapons and armor** too.
- **Keep X free slots**: when your bags are almost full, the cheapest junk is removed first.
- Use both rules together or just one.

## Safe by default

- Starts in **dry-run mode**: it only tells you in chat what it *would* delete. Turn it off when you are happy.
- Never deletes quest items, trade goods, consumables, reagents, crafting reagents, recipes, ammo, bags or anything green or better.
- **Protected list** and **Always delete list**: shift-click, drag or type an item ID.
- If the game blocks automatic deletion, the junk button glows and **one click** (or a key binding) deletes the junk.

## How to use

1. Type **/bsj** to open the settings.
2. Click the **bag button** (minimap or floating bar) to sort.
3. Check the chat preview, then switch off **Dry run** on the Junk tab.

## Commands

- **/bsj**: settings window
- **/bsj sort**: sort bags
- **/bsj junk**: delete junk now
- **/bsj preview**: list what would be deleted

Key bindings: *Key Bindings > AddOns > Bag Sort & Auto Delete Junk*.

## Details

- No libraries, lightweight, settings saved account-wide.
- English and Russian.
- Works with Bagnon (sorts the real bags; use the floating buttons or minimap button).

Source code: https://github.com/bssdmnc/bag-sort-auto-delete-junk
