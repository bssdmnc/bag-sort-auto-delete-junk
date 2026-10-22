local _, ns = ...
local L = ns.L
local C = ns.C

local Junk = { candidates = {}, blocked = false }
ns.Junk = Junk

function Junk:IsProtected(item)
    local j = ns.db.junk
    if ns.db.whitelist[item.itemID] then
        return true
    end
    if item.classKey and j.protect[item.classKey] then
        return true
    end
    if item.isQuest then
        return true
    end
    if item.craftReagent and j.protect.craftreagent then
        return true
    end
    return false
end

function Junk:IsEligible(item)
    local j = ns.db.junk
    local quality = item.quality
    if not item.cached or item.price <= 0 or quality == nil or quality < 0 or quality > 2 then
        return false
    end
    if quality == 1 and j.whiteGearOnly and item.classID ~= 2 and item.classID ~= 4 then
        return false
    end
    return not self:IsProtected(item) and j.qualities[quality] == true
end

function Junk:Candidates(scan)
    local j = ns.db.junk
    if not j.enabled then
        return {}
    end
    local threshold = math.max(0, math.floor(tonumber(j.freeSlots) or 0))
    if scan.free > threshold then
        return {}
    end
    local list = {}
    for _, s in ipairs(scan.slots) do
        local item = s.item
        if s.general and item and not item.locked then
            local quality = item.quality
            local blacklisted = ns.db.blacklist[item.itemID]
                and item.cached
                and item.price > 0
                and quality ~= nil
                and quality >= 0
                and quality <= 2
                and not self:IsProtected(item)
            if self:IsEligible(item) or blacklisted then
                list[#list + 1] = { slot = s, item = item, reason = blacklisted and "list" or "price" }
            end
        end
    end
    table.sort(list, function(a, b)
        if a.item.value ~= b.item.value then
            return a.item.value < b.item.value
        end
        if a.item.itemID ~= b.item.itemID then
            return a.item.itemID < b.item.itemID
        end
        if a.slot.bag ~= b.slot.bag then
            return a.slot.bag < b.slot.bag
        end
        return a.slot.slot < b.slot.slot
    end)
    local required = math.min(#list, threshold - scan.free + 1)
    local candidates = {}
    for i = 1, required do
        candidates[i] = list[i]
    end
    return candidates
end

function Junk:Summary()
    local total = 0
    for _, c in ipairs(self.candidates) do
        total = total + c.item.value
    end
    return #self.candidates, total
end

function Junk:Refresh(scan)
    self.candidates = self:Candidates(scan or ns.Scanner:Scan())
    ns.Fire("JUNK_UPDATED")
    return self.candidates
end

function Junk:Preview()
    local list = self:Refresh()
    ns.Options:OpenJunk()
    return list
end

function Junk:Evaluate()
    if not ns.db then
        return
    end
    local list = self:Refresh()
    if #list == 0 then
        return
    end
    if InCombatLockdown() or not ns.db.junk.enabled then
        return
    end
    if ns.db.junk.auto and not self.blocked and not ns.Sort:IsRunning() then
        self:DeleteNow(false)
    end
end

function Junk:SetBlocked()
    if self.blocked then
        return
    end
    self.blocked = true
    ns.Print(L["The game blocked automatic deletion. Click the junk button or use the key binding."])
    ns.Fire("JUNK_UPDATED")
end

function Junk:DeleteNow(manual)
    if not ns.db then
        return
    end
    if not manual and InCombatLockdown() then
        return
    end
    if GetCursorInfo() then
        return
    end
    local list = self:Refresh()
    if #list == 0 then
        return
    end
    local deleted, failed = {}, false
    local limit = math.min(#list, math.max(1, ns.db.junk.maxPerRun))
    local total = 0
    for i = 1, limit do
        local c = list[i]
        local s = c.slot
        local id, _, _, locked = C.SlotInfo(s.bag, s.slot)
        if id == c.item.itemID and not locked then
            C.Pickup(s.bag, s.slot)
            if C.CursorItemID() == id then
                DeleteCursorItem()
                if GetCursorInfo() then
                    ClearCursor()
                    failed = true
                    break
                end
                deleted[#deleted + 1] = c
                total = total + c.item.value
            else
                if GetCursorInfo() then
                    ClearCursor()
                end
                failed = true
                break
            end
        end
    end
    if failed and not manual then
        self:SetBlocked()
    elseif not manual and #deleted > 0 then
        C_Timer.After(1.5, function()
            for _, c in ipairs(deleted) do
                local id, _, _, locked = C.SlotInfo(c.slot.bag, c.slot.slot)
                if id == c.item.itemID and not locked then
                    self:SetBlocked()
                    return
                end
            end
        end)
    end
    if manual then
        if #deleted > 0 then
            ns.Print(string.format(L["Deleted junk stacks: %d (%s)"], #deleted, ns.Money(total)))
        end
    end
    C_Timer.After(0.5, function()
        self:Refresh()
    end)
end
