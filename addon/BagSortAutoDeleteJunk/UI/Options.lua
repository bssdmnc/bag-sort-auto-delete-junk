local _, ns = ...
local L = ns.L
local C = ns.C
local W = ns.W

local Options = {}
ns.Options = Options

local function db()
    return ns.db
end

local function buildSortPage(page)
    local s = function() return db().sort end
    page:Add(W.Header(page, L["Sort"]), 24)
    local info = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    page:Add(info, 18, 12)
    info:SetText(L["Price = vendor sell price x stack size (e.g. 5 x 10s = 50s)"])
    page:Add(W.Cycle(page, L["Direction"], { { "desc", L["Expensive first"] }, { "asc", L["Cheap first"] } },
        function() return s().direction end, function(v) s().direction = v end))
    page:Add(W.Cycle(page, L["Empty slots"], { { "end", L["At the end"] }, { "start", L["At the start"] } },
        function() return s().emptyAt end, function(v) s().emptyAt = v end))
    page:Add(W.Cycle(page, L["Bag order"], { { false, L["Backpack first"] }, { true, L["Last bag first"] } },
        function() return s().reverseBags end, function(v) s().reverseBags = v end))
    page:Gap(4)
    page:Add(W.Check(page, L["Quest items at the start of bags"], function() return s().questFirst end, function(v) s().questFirst = v end))
    page:Add(W.Check(page, L["Trade goods (leather, hides) first"], function() return s().tradeGoodsFirst end, function(v) s().tradeGoodsFirst = v end))
    page:Add(W.Check(page, L["Gray items last"], function() return s().junkLast end, function(v) s().junkLast = v end))
    page:Add(W.Check(page, L["Merge partial stacks"], function() return s().mergeStacks end, function(v) s().mergeStacks = v end))
    page:Add(W.Check(page, L["Auto sort after looting"], function() return s().autoAfterLoot end, function(v) s().autoAfterLoot = v end))
    page:Gap(6)
    local label = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    page:Add(label, 22, 12)
    label:SetText(L["Ignore bags while sorting:"])
    local y = page.y
    for bag = C.FIRST_BAG, C.LAST_BAG do
        local name = bag == 0 and L["Backpack"] or string.format(L["Bag %d"], bag)
        local cb = W.Check(page, name, function() return s().ignoreBags[bag] end, function(v) s().ignoreBags[bag] = v or nil end)
        cb:SetPoint("TOPLEFT", page, "TOPLEFT", 8 + bag * 92, y)
        page.refreshers[#page.refreshers + 1] = cb
    end
    page.y = y - 34
    page:Add(W.Header(page, L["Settings"]), 24)
    local ui = function() return db().ui end
    page:Add(W.Check(page, L["Show minimap button"], function() return ui().minimap.show end, function(v)
        ui().minimap.show = v
        ns.Fire("UI_LAYOUT")
    end))
    page:Add(W.Check(page, L["Show floating buttons"], function() return ui().bar.show end, function(v)
        ui().bar.show = v
        ns.Fire("UI_LAYOUT")
    end))
    page:Add(W.Check(page, L["Lock floating buttons"], function() return ui().bar.locked end, function(v)
        ui().bar.locked = v
        ns.Fire("UI_LAYOUT")
    end))
end

local function buildJunkPage(page)
    local j = function() return db().junk end
    page:Add(W.Header(page, L["Junk"]), 24)
    page:Add(W.Check(page, L["Enable junk deletion"], function() return j().enabled end, function(v) j().enabled = v end))
    page:Add(W.Check(page, L["Delete automatically"], function() return j().auto end, function(v)
        j().auto = v
        ns.Junk.blocked = false
    end))
    page:Gap(2)
    page:Add(W.Header(page, L["Qualities to delete"]), 24)
    local qualities = {
        { 0, "|cff9d9d9d" .. L["Gray (poor) items"] .. "|r" },
        { 1, L["White (common) items"] },
        { 2, "|cff1eff00" .. L["Green (uncommon) items"] .. "|r" },
    }
    local y = page.y
    for i, quality in ipairs(qualities) do
        local qualityID = quality[1]
        local cb = W.Check(page, quality[2], function() return j().qualities[qualityID] end, function(v)
            j().qualities[qualityID] = v
        end)
        cb:SetPoint("TOPLEFT", page, "TOPLEFT", 8 + (i - 1) * 150, y)
        page.refreshers[#page.refreshers + 1] = cb
    end
    page.y = y - 28
    page:Add(W.Check(page, "    " .. L["White items: only weapons and armor"],
        function() return j().whiteGearOnly end, function(v) j().whiteGearOnly = v end))
    page:Add(W.Stepper(page, L["Show candidates when free slots are at or below"], 0, 40, 1,
        function() return j().freeSlots end, function(v) j().freeSlots = v end))
    local info = page:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    page:Add(info, 18, 12)
    info:SetText(L["Candidates are sorted by vendor price per stack. Quest items and your protected list are never deleted. Categories below can be protected too."])
    info:SetWidth(448)
    info:SetJustifyH("LEFT")
    local status = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    status:SetWidth(448)
    status:SetHeight(140)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetWordWrap(true)
    function status:Refresh()
        local candidates = ns.Junk.candidates
        if #candidates == 0 then
            self:SetText(L["No junk candidates."])
            return
        end
        local lines = { string.format(L["Junk to delete: %d (%s)"], ns.Junk:Summary()) }
        for i, candidate in ipairs(candidates) do
            if i > 6 then
                lines[#lines + 1] = "..."
                break
            end
            local item = candidate.item
            lines[#lines + 1] = string.format("%s x%d (%s)",
                item.link or (L["Unknown item"] .. " #" .. item.itemID),
                item.count,
                ns.Money(item.value))
        end
        self:SetText(table.concat(lines, "\n"))
    end
    page:Add(status, 146)
    page:Gap(4)
    page:Add(W.Header(page, L["Never delete these categories:"]), 24)
    local protected = {
        { "tradegoods", "Trade goods" },
        { "consumable", "Consumables" },
        { "reagent", "Reagents" },
        { "recipe", "Recipes" },
        { "projectile", "Projectiles" },
        { "container", "Containers" },
        { "quiver", "Quivers" },
        { "craftreagent", "Crafting reagents" },
    }
    y = page.y
    for i, category in ipairs(protected) do
        local key = category[1]
        local cb = W.Check(page, L[category[2]], function() return j().protect[key] end, function(v)
            j().protect[key] = v
        end)
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        cb:SetPoint("TOPLEFT", page, "TOPLEFT", 8 + col * 232, y - row * 24)
        page.refreshers[#page.refreshers + 1] = cb
    end
    page.y = y - math.ceil(#protected / 2) * 24
    ns.On("JUNK_UPDATED", function()
        status:Refresh()
    end)
end

local function addToList(key, itemID)
    if not itemID then
        return
    end
    local other = key == "whitelist" and "blacklist" or "whitelist"
    db()[other][itemID] = nil
    db()[key][itemID] = true
    C.RequestItem(itemID)
    ns.Fire("LISTS_CHANGED")
    ns.Fire("SETTINGS_CHANGED")
end

local activeListBox

local function itemList(page, key, title, color)
    local f = CreateFrame("Frame", nil, page)
    f:SetSize(232, 440)
    local head = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", 4, 0)
    head:SetText(color .. title .. "|r")

    local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    box:SetSize(160, 20)
    box:SetPoint("TOPLEFT", 10, -22)
    box:SetAutoFocus(false)
    local function commit()
        local id = C.ParseItemID(box:GetText())
        addToList(key, id)
        box:SetText("")
        box:ClearFocus()
    end
    box:SetScript("OnEnterPressed", commit)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusGained", function(self) activeListBox = self end)
    box:SetScript("OnEditFocusLost", function(self)
        if activeListBox == self then
            activeListBox = nil
        end
    end)
    local function takeCursor()
        local id = C.CursorItemID()
        if id then
            ClearCursor()
            addToList(key, id)
            return true
        end
    end
    box:SetScript("OnReceiveDrag", takeCursor)
    box:HookScript("OnMouseDown", takeCursor)

    local add = W.Button(f, L["Add"], 56, function()
        if not takeCursor() then
            commit()
        end
    end)
    add:SetPoint("LEFT", box, "RIGHT", 6, 0)
    add:SetScript("OnReceiveDrag", takeCursor)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 6, -46)
    hint:SetWidth(222)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["Shift-click an item, type an ID, or drop an item here"])

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -74)
    scroll:SetSize(200, 360)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(200, 1)
    scroll:SetScrollChild(child)
    scroll:SetScript("OnReceiveDrag", takeCursor)
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", takeCursor)

    local rows = {}
    local function getRow(i)
        local r = rows[i]
        if r then
            return r
        end
        r = CreateFrame("Button", nil, child)
        r:SetSize(200, 22)
        r:SetPoint("TOPLEFT", 0, -(i - 1) * 22)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(18, 18)
        r.icon:SetPoint("LEFT", 2, 0)
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.text:SetPoint("LEFT", r.icon, "RIGHT", 4, 0)
        r.text:SetWidth(150)
        r.text:SetJustifyH("LEFT")
        r.text:SetWordWrap(false)
        r.remove = CreateFrame("Button", nil, r, "UIPanelCloseButton")
        r.remove:SetSize(22, 22)
        r.remove:SetPoint("RIGHT", 0, 0)
        r.remove:SetScript("OnClick", function()
            db()[key][r.itemID] = nil
            ns.Fire("LISTS_CHANGED")
            ns.Fire("SETTINGS_CHANGED")
        end)
        local hl = r:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.08)
        r:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. self.itemID)
            GameTooltip:Show()
        end)
        r:SetScript("OnLeave", GameTooltip_Hide)
        r:SetScript("OnReceiveDrag", takeCursor)
        rows[i] = r
        return r
    end

    local retry = false
    function f:Refresh()
        local ids = {}
        for id in pairs(db()[key]) do
            ids[#ids + 1] = id
        end
        table.sort(ids)
        local missing = false
        for i, id in ipairs(ids) do
            local r = getRow(i)
            r.itemID = id
            local name, link = C.ItemInfo(id)
            if not name then
                missing = true
                C.RequestItem(id)
            end
            r.icon:SetTexture(C.ItemIcon(id) or 134400)
            r.text:SetText(link or ("item #" .. id))
            r:Show()
        end
        for i = #ids + 1, #rows do
            rows[i]:Hide()
        end
        child:SetHeight(math.max(1, #ids * 22))
        if missing and not retry then
            retry = true
            C_Timer.After(1, function()
                retry = false
                if f:IsVisible() then
                    f:Refresh()
                end
            end)
        end
    end
    ns.On("LISTS_CHANGED", function()
        if f:IsVisible() then
            f:Refresh()
        end
    end)
    return f
end

local function buildListsPage(page)
    page:Add(W.Header(page, L["Lists"]), 28)
    local y = page.y
    local white = itemList(page, "whitelist", L["Protected (never delete)"], "|cff40ff40")
    white:SetPoint("TOPLEFT", page, "TOPLEFT", 4, y)
    local black = itemList(page, "blacklist", L["Always delete"], "|cffff4040")
    black:SetPoint("TOPLEFT", page, "TOPLEFT", 244, y)
    page.refreshers[#page.refreshers + 1] = white
    page.refreshers[#page.refreshers + 1] = black
    if ChatEdit_InsertLink then
        hooksecurefunc("ChatEdit_InsertLink", function(link)
            if activeListBox and activeListBox:HasFocus() and link then
                activeListBox:SetText(link)
            end
        end)
    end
end

function Options:Build()
    if self.frame then
        return self.frame
    end
    local f = CreateFrame("Frame", "BSADJOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
    f:SetSize(500, 740)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()
    table.insert(UISpecialFrames, "BSADJOptionsFrame")
    if f.TitleText then
        f.TitleText:SetText(ns.title)
    end

    local logo = f:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(ns.media .. "Logo.tga")
    logo:SetSize(64, 64)
    logo:SetPoint("TOPLEFT", 14, -30)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -6)
    title:SetText(ns.title)
    local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    sub:SetWidth(390)
    sub:SetJustifyH("LEFT")
    sub:SetText(L["Finds and deletes the cheapest eligible bag items so your bags keep room for leather and other loot; bag sorting is available separately."])

    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", 12, -136)
    content:SetPoint("BOTTOMRIGHT", -12, 44)

    local pages = {}
    local tabs = {}
    local builders = { buildJunkPage, buildSortPage, buildListsPage }
    local names = { L["Junk"], L["Sort"], L["Lists"] }
    local function selectTab(index)
        for i, p in ipairs(pages) do
            p:SetShown(i == index)
            if i == index then
                tabs[i]:LockHighlight()
            else
                tabs[i]:UnlockHighlight()
            end
        end
        f.tab = index
    end
    for i, build in ipairs(builders) do
        local page = W.Page(content)
        page:SetAllPoints()
        page:Hide()
        build(page)
        pages[i] = page
        local tab = W.Button(f, names[i], 150, function() selectTab(i) end)
        tab:SetPoint("TOPLEFT", 14 + (i - 1) * 158, -104)
        tabs[i] = tab
    end

    local junkBtn = W.Button(f, L["Delete junk"], 150, function() ns.Junk:DeleteNow(true) end)
    junkBtn:SetPoint("BOTTOMLEFT", 14, 12)
    local sortBtn = W.Button(f, L["Sort bags"], 150, function() ns.Sort:Start() end)
    sortBtn:SetPoint("LEFT", junkBtn, "RIGHT", 8, 0)

    f:SetScript("OnShow", function()
        selectTab(f.tab or 1)
    end)
    ns.On("SETTINGS_CHANGED", function()
        ns.Junk:Refresh()
    end)
    self.frame = f
    f.selectTab = selectTab
    return f
end

function Options:Toggle()
    local f = self:Build()
    if SettingsPanel and SettingsPanel:IsShown() then
        HideUIPanel(SettingsPanel)
    end
    if InterfaceOptionsFrame and InterfaceOptionsFrame:IsShown() then
        HideUIPanel(InterfaceOptionsFrame)
    end
    f:SetShown(not f:IsShown())
end

function Options:OpenJunk()
    local f = self:Build()
    f.tab = 1
    f:Show()
    f.selectTab(1)
end

function Options:RegisterPanel()
    local panel = CreateFrame("Frame")
    panel.name = ns.title
    local logo = panel:CreateTexture(nil, "ARTWORK")
    logo:SetTexture(ns.media .. "Logo.tga")
    logo:SetSize(128, 128)
    logo:SetPoint("TOPLEFT", 16, -16)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 16, -20)
    title:SetText(ns.title)
    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetWidth(380)
    sub:SetJustifyH("LEFT")
    sub:SetText(L["Finds and deletes the cheapest eligible bag items so your bags keep room for leather and other loot; bag sorting is available separately."])
    local open = W.Button(panel, L["Open settings"], 180, function() Options:Toggle() end)
    open:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -16)
    local cmds = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cmds:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -12)
    cmds:SetText("/bsj config  |  /bsj sort  |  /bsj junk  |  /bsj preview")
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, ns.title)
        if ok and cat then
            pcall(Settings.RegisterAddOnCategory, cat)
        end
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

ns.On("LOGIN", function()
    Options:RegisterPanel()
end)
