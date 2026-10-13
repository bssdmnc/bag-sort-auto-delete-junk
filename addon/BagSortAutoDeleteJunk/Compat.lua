local _, ns = ...

local C = {}
ns.C = C

local CC = C_Container
local CI = C_Item

C.FIRST_BAG = 0
C.LAST_BAG = NUM_BAG_SLOTS or 4

function C.NumSlots(bag)
    if CC and CC.GetContainerNumSlots then
        return CC.GetContainerNumSlots(bag) or 0
    end
    return GetContainerNumSlots(bag) or 0
end

function C.NumFree(bag)
    if CC and CC.GetContainerNumFreeSlots then
        return CC.GetContainerNumFreeSlots(bag)
    end
    return GetContainerNumFreeSlots(bag)
end

local function stackSize(count)
    count = tonumber(count) or 1
    if count < 1 then
        return 1
    end
    return count
end

function C.SlotInfo(bag, slot)
    if CC and CC.GetContainerItemInfo then
        local i = CC.GetContainerItemInfo(bag, slot)
        if not i or not i.itemID then
            return nil
        end
        return i.itemID, stackSize(i.stackCount), i.quality, i.isLocked, i.hyperlink, i.iconFileID
    end
    local icon, count, locked, quality, _, _, link, _, _, itemID = GetContainerItemInfo(bag, slot)
    if not itemID and link then
        itemID = tonumber(link:match("item:(%d+)"))
    end
    if not itemID then
        return nil
    end
    return itemID, stackSize(count), quality, locked, link, icon
end

function C.IsQuestSlot(bag, slot)
    if CC and CC.GetContainerItemQuestInfo then
        local q = CC.GetContainerItemQuestInfo(bag, slot)
        return q and (q.isQuestItem or q.questID) and true or false
    end
    if GetContainerItemQuestInfo then
        local isQuest, questID = GetContainerItemQuestInfo(bag, slot)
        return (isQuest or questID) and true or false
    end
    return false
end

function C.Pickup(bag, slot)
    if CC and CC.PickupContainerItem then
        CC.PickupContainerItem(bag, slot)
    else
        PickupContainerItem(bag, slot)
    end
end

function C.ItemInfo(item)
    if CI and CI.GetItemInfo then
        return CI.GetItemInfo(item)
    end
    return GetItemInfo(item)
end

function C.ItemIcon(itemID)
    if CI and CI.GetItemIconByID then
        return CI.GetItemIconByID(itemID)
    end
    if GetItemIcon then
        return GetItemIcon(itemID)
    end
    return select(10, C.ItemInfo(itemID))
end

function C.RequestItem(itemID)
    if CI and CI.RequestLoadItemDataByID then
        CI.RequestLoadItemDataByID(itemID)
    else
        C.ItemInfo(itemID)
    end
end

function C.CursorItemID()
    local kind, id = GetCursorInfo()
    if kind == "item" then
        return id
    end
    return nil
end

function C.ParseItemID(text)
    if type(text) == "number" then
        return text
    end
    if not text then
        return nil
    end
    local id = text:match("item:(%d+)")
    if id then
        return tonumber(id)
    end
    return tonumber(strtrim(text))
end
