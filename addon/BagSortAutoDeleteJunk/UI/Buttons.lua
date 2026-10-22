local _, ns = ...
local L = ns.L

local Buttons = {}
ns.Buttons = Buttons

local function junkTooltip(tip)
    local count, total = ns.Junk:Summary()
    if count == 0 then
        tip:AddLine(L["No junk to delete."], 0.6, 0.6, 0.6)
        return
    end
    tip:AddLine(string.format(L["Junk to delete: %d (%s)"], count, ns.Money(total)), 1, 0.82, 0)
    for i, c in ipairs(ns.Junk.candidates) do
        if i > 12 then
            tip:AddLine("...", 0.6, 0.6, 0.6)
            break
        end
        tip:AddDoubleLine((c.item.link or c.item.itemID) .. " x" .. c.item.count, ns.Money(c.item.value), 1, 1, 1, 1, 1, 1)
    end
end

local function showTooltip(owner, hints)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:AddLine(ns.title)
    local scan = ns.Scanner:Scan()
    GameTooltip:AddLine(string.format(L["Free slots: %d"], scan.free), 0.8, 0.8, 0.8)
    GameTooltip:AddLine(" ")
    junkTooltip(GameTooltip)
    if hints then
        GameTooltip:AddLine(" ")
        for _, h in ipairs(hints) do
            GameTooltip:AddLine(h, 0.5, 0.8, 1)
        end
    end
    GameTooltip:Show()
end

local function createMinimapButton()
    local b = CreateFrame("Button", "BSADJMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ns.media .. "Icon.tga")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    local function place()
        local angle = math.rad(ns.db.ui.minimap.angle or 200)
        local r = (Minimap:GetWidth() / 2) + 5
        b:ClearAllPoints()
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
    end
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            ns.db.ui.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
            place()
        end)
    end)
    b:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    b:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ns.Options:Toggle()
        elseif IsShiftKeyDown() then
            ns.Sort:Start()
        else
            ns.Junk:DeleteNow(true)
        end
    end)
    b:SetScript("OnEnter", function(self)
        showTooltip(self, { L["Left-click: delete junk"], L["Shift-click: sort bags"], L["Right-click: settings"], L["Drag to move"] })
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
    b.place = place
    return b
end

local function createIconButton(parent, texture, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:RegisterForDrag("LeftButton")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(texture)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.icon = icon
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetColorTexture(0.83, 0.66, 0.26, 0.6)
    border:SetDrawLayer("BACKGROUND")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    return b
end

local function createBar()
    local bar = CreateFrame("Frame", "BSADJBar", UIParent, "BackdropTemplate")
    bar:SetSize(88, 44)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    if bar.SetBackdrop then
        bar:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        bar:SetBackdropColor(0.07, 0.05, 0.03, 0.85)
        bar:SetBackdropBorderColor(0.83, 0.66, 0.26, 0.9)
    end

    local function startMove()
        if not ns.db.ui.bar.locked then
            bar:StartMoving()
        end
    end
    local function stopMove()
        bar:StopMovingOrSizing()
        local point, _, rel, x, y = bar:GetPoint()
        ns.db.ui.bar.point = { point, "UIParent", rel, x, y }
    end
    bar:SetScript("OnDragStart", startMove)
    bar:SetScript("OnDragStop", stopMove)

    local sort = createIconButton(bar, ns.media .. "Icon.tga", 32)
    sort.icon:SetTexCoord(0, 1, 0, 1)
    sort:SetPoint("RIGHT", -6, 0)
    sort:SetScript("OnDragStart", startMove)
    sort:SetScript("OnDragStop", stopMove)
    sort:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ns.Options:Toggle()
        else
            ns.Sort:Start()
        end
    end)
    sort:SetScript("OnEnter", function(self)
        showTooltip(self, { L["Left-click: sort bags"], L["Right-click: settings"], L["Drag to move"] })
    end)
    sort:SetScript("OnLeave", GameTooltip_Hide)

    local junk = createIconButton(bar, "Interface\\Icons\\INV_Misc_Bone_01", 32)
    junk:SetPoint("RIGHT", sort, "LEFT", -6, 0)
    junk:SetScript("OnDragStart", startMove)
    junk:SetScript("OnDragStop", stopMove)
    junk:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ns.Junk:Preview()
        else
            ns.Junk:DeleteNow(true)
        end
    end)
    junk:SetScript("OnEnter", function(self)
        showTooltip(self, { L["Left-click: delete junk"], L["Right-click: preview candidates"], L["Drag to move"] })
    end)
    junk:SetScript("OnLeave", GameTooltip_Hide)

    local count = junk:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -1, 2)
    junk.count = count

    local glow = junk:CreateTexture(nil, "OVERLAY")
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    glow:SetVertexColor(1, 0.3, 0.2)
    glow:SetPoint("CENTER")
    glow:SetSize(64, 64)
    glow:Hide()
    local anim = glow:CreateAnimationGroup()
    anim:SetLooping("BOUNCE")
    local alpha = anim:CreateAnimation("Alpha")
    alpha:SetFromAlpha(1)
    alpha:SetToAlpha(0.2)
    alpha:SetDuration(0.6)
    junk.glow = glow
    junk.anim = anim

    bar.sort = sort
    bar.junk = junk
    return bar
end

function Buttons:UpdateJunk()
    local bar = self.bar
    if not bar then
        return
    end
    local count = ns.Junk:Summary()
    local junk = bar.junk
    junk.count:SetText(count > 0 and count or "")
    local needsClick = count > 0 and (ns.Junk.blocked or not ns.db.junk.auto)
    if needsClick then
        junk.glow:Show()
        if not junk.anim:IsPlaying() then
            junk.anim:Play()
        end
    else
        junk.anim:Stop()
        junk.glow:Hide()
    end
    junk.icon:SetDesaturated(count == 0)
end

function Buttons:Layout()
    local ui = ns.db.ui
    if self.minimap then
        self.minimap:SetShown(ui.minimap.show)
        self.minimap.place()
    end
    if self.bar then
        local p = ui.bar.point
        self.bar:ClearAllPoints()
        self.bar:SetPoint(p[1] or "CENTER", UIParent, p[3] or "CENTER", p[4] or 0, p[5] or 0)
        self.bar:SetShown(ui.bar.show)
        self.bar:EnableMouse(not ui.bar.locked)
    end
    self:UpdateJunk()
end

ns.On("LOGIN", function()
    Buttons.minimap = createMinimapButton()
    Buttons.bar = createBar()
    Buttons:Layout()
end)
ns.On("UI_LAYOUT", function()
    Buttons:Layout()
end)
ns.On("JUNK_UPDATED", function()
    Buttons:UpdateJunk()
end)
ns.On("SORT_STATE", function()
    if Buttons.bar then
        Buttons.bar.sort.icon:SetAlpha(ns.Sort:IsRunning() and 0.4 or 1)
    end
end)
