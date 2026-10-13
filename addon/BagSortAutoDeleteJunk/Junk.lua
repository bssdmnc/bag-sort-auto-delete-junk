local _, ns = ...
local L = ns.L
local C = ns.C

local Junk = { candidates = {}, blocked = false, lastSignature = nil }
ns.Junk = Junk

local REASON_TEXT = {
    price = "reason: price",
    full = "reason: full bags",
    list = "reason: list",
}

function Junk:CompareValue(item)
    return item.value
end

function Junk:IsEligible(item)
    local j = ns.db.junk
    if ns.db.whitelist[item.itemID] then
        return false
    end
    if not item.cached or item.price <= 0 then
        return false
    end
    if item.quality == 0 then
        if not j.grays then
            return false
        end
    elseif item.quality == 1 then
        if not j.whites then
            return false
        end
        if j.whitesGearOnly and item.classID ~= 2 and item.classID ~= 4 then
            return false
        end
    else
        return false
    end
    if item.classKey and j.protect[item.classKey] then
        return false
    end
    if item.isQuest and j.protect.quest then
        return false
    end
    if item.craftReagent and j.protect.craftreagent then
        return false
    end
    return true
end

function Junk:Candidates(scan)
    local j = ns.db.junk
    local list, spare = {}, {}
    local freedGeneral = 0
    if not j.enabled then
        return list
    end
    for _, s in ipairs(scan.slots) do
        local item = s.item
        if item and not item.locked then
            if ns.db.blacklist[item.itemID] and not ns.db.whitelist[item.itemID] and (item.quality or 0) <= 1 then
                list[#list + 1] = { slot = s, item = item, reason = "list" }
                if s.general then
                    freedGeneral = freedGeneral + 1
                end
            elseif self:IsEligible(item) then
                local v = self:CompareValue(item)
                if j.priceEnabled and v < j.priceThreshold then
                    list[#list + 1] = { slot = s, item = item, reason = "price" }
                    if s.general then
                        freedGeneral = freedGeneral + 1
                    end
                elseif s.general then
                    spare[#spare + 1] = { slot = s, item = item, reason = "full" }
                end
            end
        end
    end
    if j.fullEnabled and j.keepFree > 0 then
        local need = j.keepFree - (scan.free + freedGeneral)
        if need > 0 then
            table.sort(spare, function(a, b)
                if a.item.value ~= b.item.value then
                    return a.item.value < b.item.value
                end
                return a.item.itemID < b.item.itemID
            end)
            for _, c in ipairs(spare) do
                if need <= 0 then
                    break
                end
                if self:CompareValue(c.item) <= j.fullMaxPrice then
                    list[#list + 1] = c
                    need = need - 1
                end
            end
        end
    end
    table.sort(list, function(a, b)
        if a.item.value ~= b.item.value then
            return a.item.value < b.item.value
        end
        return a.item.itemID < b.item.itemID
    end)
    return list
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

local function signature(list)
    local parts = {}
    for _, c in ipairs(list) do
        parts[#parts + 1] = c.item.itemID .. ":" .. c.item.count
    end
    return table.concat(parts, ",")
end

local function describe(fmt, c)
    local link = c.item.link or (L["Unknown item"] .. " #" .. c.item.itemID)
    return string.format(L[fmt], link, c.item.count, ns.Money(c.item.value)) .. " |cff888888" .. L[REASON_TEXT[c.reason]] .. "|r"
end

function Junk:Preview(list, force)
    list = list or self:Refresh()
    if #list == 0 then
        ns.Print(L["No junk to delete."], true)
        return
    end
    for _, c in ipairs(list) do
        ns.Print(describe("Would delete %s x%d (%s)", c), force ~= false)
    end
end

function Junk:Evaluate()
    if not ns.db then
        return
    end
    local list = self:Refresh()
    if #list == 0 then
        self.lastSignature = nil
        return
    end
    if InCombatLockdown() or not ns.db.junk.enabled then
        return
    end
    if ns.db.junk.dryRun then
        local sig = signature(list)
        if sig ~= self.lastSignature then
            self.lastSignature = sig
            self:Preview(list, false)
        end
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
    ns.Print(L["The game blocked automatic deletion. Click the junk button or use the key binding."], true)
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
        if manual then
            ns.Print(L["No junk to delete."], true)
        end
        return
    end
    if ns.db.junk.dryRun then
        if manual then
            self:Preview(list)
            ns.Print(L["Dry run is ON: nothing was deleted. Disable it in /bsj config."], true)
        end
        return
    end
    local deleted, failed = {}, false
    local limit = math.min(#list, math.max(1, ns.db.junk.maxPerRun))
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
                ns.Print(describe("Deleted %s x%d (%s)", c))
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
    C_Timer.After(0.5, function()
        self:Refresh()
    end)
end
