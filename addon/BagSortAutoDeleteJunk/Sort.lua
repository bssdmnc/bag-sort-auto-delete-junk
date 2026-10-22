local _, ns = ...
local C = ns.C

local Sort = { running = false }
ns.Sort = Sort

local STEP_DELAY = 0.05
local MAX_STEPS = 600
local MAX_WAIT = 5

function Sort:IsRunning()
    return self.running
end

local function groupRank(item)
    local s = ns.db.sort
    if s.questFirst and item.isQuest then
        return 0
    end
    if s.junkLast and item.quality == 0 then
        return 3
    end
    if s.tradeGoodsFirst and (item.classID == 7 or ns.db.whitelist[item.itemID]) then
        return 1
    end
    return 2
end

local function same(a, b)
    return a and b and a.itemID == b.itemID and a.count == b.count
end

local function compare(a, b)
    local s = ns.db.sort
    local ga, gb = groupRank(a), groupRank(b)
    if ga ~= gb then
        return ga < gb
    end
    local va, vb = a.value, b.value
    if va ~= vb then
        if s.direction == "asc" then
            return va < vb
        end
        return va > vb
    end
    if (a.quality or 0) ~= (b.quality or 0) then
        return (a.quality or 0) > (b.quality or 0)
    end
    if (a.classID or 99) ~= (b.classID or 99) then
        return (a.classID or 99) < (b.classID or 99)
    end
    if a.itemID ~= b.itemID then
        return a.itemID < b.itemID
    end
    return a.count > b.count
end

function Sort:Slots(scan)
    local slots = {}
    local ignore = ns.db.sort.ignoreBags
    for _, s in ipairs(scan.slots) do
        if s.general and not ignore[s.bag] then
            slots[#slots + 1] = s
        end
    end
    return slots
end

function Sort:NextMerge(slots)
    if not ns.db.sort.mergeStacks then
        return nil
    end
    local first = {}
    for _, s in ipairs(slots) do
        local it = s.item
        if it and it.maxStack > 1 and it.count < it.maxStack then
            local prev = first[it.itemID]
            if prev then
                local key = s.bag .. ":" .. s.slot .. ">" .. prev.bag .. ":" .. prev.slot .. "=" .. it.count .. "/" .. prev.item.count
                if not self.tried[key] then
                    self.tried[key] = true
                    return s, prev
                end
            else
                first[it.itemID] = s
            end
        end
    end
    return nil
end

function Sort:NextMove(slots)
    local items = {}
    for _, s in ipairs(slots) do
        if s.item then
            items[#items + 1] = s.item
        end
    end
    table.sort(items, compare)
    local offset = 0
    if ns.db.sort.emptyAt == "start" then
        offset = #slots - #items
    end
    for i, s in ipairs(slots) do
        local want = items[i - offset]
        local cur = s.item
        if want then
            if not same(cur, want) then
                local src
                for j = i + 1, #slots do
                    if same(slots[j].item, want) then
                        src = slots[j]
                        break
                    end
                end
                if src then
                    if cur and cur.itemID == want.itemID then
                        for k = i + 1, #slots do
                            local o = slots[k]
                            if o ~= src and (not o.item or o.item.itemID ~= cur.itemID) then
                                return s, o
                            end
                        end
                    else
                        return src, s
                    end
                end
            end
        elseif cur then
            for j = #slots, i + 1, -1 do
                if not slots[j].item then
                    return s, slots[j]
                end
            end
        end
    end
    return nil
end

function Sort:Stop()
    self.running = false
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    ns.Fire("SORT_STATE")
    ns.Junk:Evaluate()
end

function Sort:Step()
    if InCombatLockdown() then
        return self:Stop()
    end
    if GetCursorInfo() then
        return self:Stop()
    end
    self.steps = self.steps + 1
    if self.steps > MAX_STEPS then
        return self:Stop()
    end
    local scan = ns.Scanner:Scan()
    if scan.locked then
        self.waited = self.waited + STEP_DELAY
        if self.waited > MAX_WAIT then
            return self:Stop()
        end
        return
    end
    self.waited = 0
    local slots = self:Slots(scan)
    local from, to = self:NextMerge(slots)
    if not from then
        from, to = self:NextMove(slots)
    end
    if not from then
        return self:Stop()
    end
    C.Pickup(from.bag, from.slot)
    C.Pickup(to.bag, to.slot)
    if GetCursorInfo() then
        ClearCursor()
    end
end

function Sort:Start()
    if not ns.db then
        return
    end
    if self.running then
        return
    end
    if InCombatLockdown() then
        return
    end
    if GetCursorInfo() then
        return
    end
    self.running = true
    self.steps = 0
    self.waited = 0
    self.tried = {}
    ns.Fire("SORT_STATE")
    self.ticker = C_Timer.NewTicker(STEP_DELAY, function()
        self:Step()
    end)
end
