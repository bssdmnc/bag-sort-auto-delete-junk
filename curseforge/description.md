# Bag Sort & Auto Delete Junk

Find and delete the **cheapest eligible items in your bags** to keep room for leather, cloth and loot. Made for **WoW Forever**, perfect for leveling **Skinning** or any gathering profession. Bag sorting remains available as a separate feature.

## Sorting

- Sorts by **slot value**: vendor sell price x stack size (5 x 10s = 50s).
- Expensive first or cheap first, empty slots at the end or at the start.
- **Quest items** go to the start of your bags.
- Optional: trade goods (leather, hides) first, gray items last.
- Merges partial stacks; never touches quivers, ammo or other special bags.
- Choose which bags to leave alone.

## Junk deletion

- Shows the cheapest eligible stacks when free slots reach your configured limit (**0 by default**).
- Choose whether to include **gray, white, or green** items; **blue and higher-quality items are always excluded**.
- Candidates are ranked by full stack vendor price, so even a green item can rank below a stack of gray or white items.
- Quest items are always protected; category protections and your protected list are configurable.

## Safe by default

- Starts in **preview mode**: candidates are shown in the settings and junk-button tooltip; nothing is deleted automatically.
- **Automatic deletion is optional**. Manual deletion removes the lowest-priced candidates and reports one concise chat summary.
- **Protected list** and **Always delete list**: shift-click, drag or type an item ID.
- If the game blocks automatic deletion, the junk button glows and a hardware click or key binding can delete the junk.

## How to use

1. Type **/bsj** to open the settings.
2. Set the qualities to consider and the free-slot threshold on the **Junk** tab.
3. Review candidates in the junk-button tooltip or settings, then click **Delete junk** when ready.
4. Enable **Delete automatically** only if you want automatic deletion. Use the separate **Sort** tab/button to sort bags.

## Commands

- **/bsj**: settings window
- **/bsj sort**: sort bags
- **/bsj junk**: delete junk now
- **/bsj preview**: open the candidate list

Key bindings: *Key Bindings > AddOns > Bag Sort & Auto Delete Junk*.

## Details

- No libraries, lightweight, settings saved account-wide.
- English and Russian.
- Works with Bagnon (sorts the real bags; use the floating buttons or minimap button).

Source code: https://github.com/bssdmnc/bag-sort-auto-delete-junk
