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

local scanTip
local function getScanTip()
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "BSADJScanTooltip", nil, "GameTooltipTemplate")
        if scanTip.SetOwner then
            scanTip:SetOwner(WorldFrame or UIParent, "ANCHOR_NONE")
        end
    end
    return scanTip
end

ns.PROFESSION_TOOL_NAMES = {
    ["skinning knife"] = 7005,
    ["нож для снятия шкур"] = 7005,
    ["finkle's skinner"] = 12709,
    ["нож финкла"] = 12709,
    ["zulian slicer"] = 19901,
    ["зулийский тесак"] = 19901,
    ["mining pick"] = 2901,
    ["шахтерская кирка"] = 2901,
    ["шахтёрская кирка"] = 2901,
    ["blacksmith hammer"] = 5956,
    ["кузнечный молот"] = 5956,
    ["arclight spanner"] = 5507,
    ["искристый ключ"] = 5507,
    ["gyromatic micro-adjustor"] = 4371,
    ["гироматический микро-регулировщик"] = 4371,
    ["thieves' tools"] = 5060,
    ["воровские инструменты"] = 5060,
    ["copper rod"] = 6218,
    ["медный жезл"] = 6218,
    ["runed copper rod"] = 6219,
    ["рунический медный жезл"] = 6219,
    ["silver rod"] = 6338,
    ["серебряный жезл"] = 6338,
    ["runed silver rod"] = 6339,
    ["рунический серебряный жезл"] = 6339,
    ["golden rod"] = 11128,
    ["золотой жезл"] = 11128,
    ["runed golden rod"] = 11130,
    ["рунический золотой жезл"] = 11130,
    ["truesilver rod"] = 11144,
    ["жезл истинного серебра"] = 11144,
    ["runed truesilver rod"] = 11145,
    ["рунический жезл истинного серебра"] = 11145,
    ["arcanite rod"] = 16206,
    ["арканитовый жезл"] = 16206,
    ["runed arcanite rod"] = 16207,
    ["рунический арканитовый жезл"] = 16207,
    ["fishing pole"] = 6256,
    ["удочка"] = 6256,
    ["strong fishing pole"] = 6365,
    ["крепкая удочка"] = 6365,
    ["big iron fishing pole"] = 6366,
    ["большая железная удочка"] = 6366,
    ["blended fishing pole"] = 6367,
    ["стильная удочка"] = 6367,
    ["nat pagle's extreme angler fc-5000"] = 19970,
    ["удочка с леской ната пэгла fc-5000"] = 19970,
    ["philosopher's stone"] = 9149,
    ["философский камень"] = 9149,
    ["alchemist's stone"] = 13503,
    ["камень алхимика"] = 13503,
    ["flint and tinder"] = 4471,
    ["трут и огниво"] = 4471,
    ["simple wood"] = 4470,
    ["простая древесина"] = 4470,
}

function C.IsProfessionTool(itemID, bag, slot)
    if not itemID then
        return false
    end
    if ns.DEFAULT_WHITELIST and ns.DEFAULT_WHITELIST[itemID] then
        return true
    end
    local tip = getScanTip()
    tip:ClearLines()
    if bag and slot and tip.SetBagItem then
        tip:SetBagItem(bag, slot)
    elseif tip.SetHyperlink then
        tip:SetHyperlink("item:" .. itemID)
    end
    for i = 1, tip:NumLines() do
        local line = _G["BSADJScanTooltipTextLeft" .. i]
        local txt = line and line:GetText()
        if txt then
            local low = txt:lower()
            if low:find("requires") or low:find("требуется") or low:find("profession") or low:find("инструмент") then
                if low:find("skinning") or low:find("снятие шкур")
                    or low:find("mining") or low:find("горное дело")
                    or low:find("blacksmithing") or low:find("кузнечное дело")
                    or low:find("engineering") or low:find("инженерное дело")
                    or low:find("leatherworking") or low:find("кожевничество")
                    or low:find("tailoring") or low:find("портняжное дело")
                    or low:find("alchemy") or low:find("алхимия")
                    or low:find("enchanting") or low:find("наложение чар")
                    or low:find("fishing") or low:find("рыбная ловля")
                    or low:find("herbalism") or low:find("травничество")
                    or low:find("lockpicking") or low:find("взлом замков") then
                    return true
                end
            end
        end
    end
    return false
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
    local num = tonumber(strtrim(text))
    if num then
        return num
    end
    local raw = strtrim(text)
    if raw == "" then
        return nil
    end
    local _, link = C.ItemInfo(raw)
    if link then
        local lid = link:match("item:(%d+)")
        if lid then
            return tonumber(lid)
        end
    end
    local lower = raw:lower()
    if ns.PROFESSION_TOOL_NAMES and ns.PROFESSION_TOOL_NAMES[lower] then
        return ns.PROFESSION_TOOL_NAMES[lower]
    end
    for bag = C.FIRST_BAG, C.LAST_BAG do
        local numSlots = C.NumSlots(bag)
        for slot = 1, numSlots do
            local slotID = C.SlotInfo(bag, slot)
            if slotID then
                local name = C.ItemInfo(slotID)
                if name and name:lower() == lower then
                    return slotID
                end
            end
        end
    end
    if GetInventoryItemID then
        for slot = 1, 19 do
            local slotID = GetInventoryItemID("player", slot)
            if slotID then
                local name = C.ItemInfo(slotID)
                if name and name:lower() == lower then
                    return slotID
                end
            end
        end
    end
    return nil
end
