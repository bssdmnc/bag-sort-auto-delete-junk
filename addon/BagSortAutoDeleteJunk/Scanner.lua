local _, ns = ...
local C = ns.C

local Scanner = {}
ns.Scanner = Scanner

local CLASS_KEYS = {
    [0] = "consumable",
    [1] = "container",
    [5] = "reagent",
    [6] = "projectile",
    [7] = "tradegoods",
    [9] = "recipe",
    [11] = "quiver",
    [12] = "quest",
}
Scanner.CLASS_KEYS = CLASS_KEYS

function Scanner:BagOrder()
    local order = {}
    if ns.db and ns.db.sort.reverseBags then
        for bag = C.LAST_BAG, C.FIRST_BAG, -1 do
            order[#order + 1] = bag
        end
    else
        for bag = C.FIRST_BAG, C.LAST_BAG do
            order[#order + 1] = bag
        end
    end
    return order
end

function Scanner:ReadItem(bag, slot)
    local itemID, count, quality, locked, link, icon = C.SlotInfo(bag, slot)
    if not itemID then
        return nil
    end
    local _, ilink, iquality, _, _, _, _, maxStack, _, iicon, sellPrice, classID, subclassID, _, _, _, isCraftingReagent = C.ItemInfo(itemID)
    local cached = sellPrice ~= nil
    if not cached then
        C.RequestItem(itemID)
    end
    local item = {
        itemID = itemID,
        count = count or 1,
        quality = quality or iquality,
        locked = locked and true or false,
        link = link or ilink,
        icon = icon or iicon,
        price = sellPrice or 0,
        maxStack = maxStack or 1,
        classID = classID,
        subclassID = subclassID,
        cached = cached,
        craftReagent = isCraftingReagent and true or false,
        isQuest = classID == 12 or C.IsQuestSlot(bag, slot),
    }
    item.value = item.price * item.count
    item.classKey = classID and CLASS_KEYS[classID]
    return item
end

function Scanner:Scan()
    local result = { slots = {}, free = 0, total = 0, locked = false }
    for _, bag in ipairs(self:BagOrder()) do
        local num = C.NumSlots(bag)
        if num and num > 0 then
            local free, family = C.NumFree(bag)
            local general = bag == 0 or not family or family == 0
            if general then
                result.free = result.free + (free or 0)
                result.total = result.total + num
            end
            for slot = 1, num do
                local item = self:ReadItem(bag, slot)
                if item and item.locked then
                    result.locked = true
                end
                result.slots[#result.slots + 1] = { bag = bag, slot = slot, general = general, item = item }
            end
        end
    end
    return result
end
