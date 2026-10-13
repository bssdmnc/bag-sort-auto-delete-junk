local _, ns = ...

local W = {}
ns.W = W

function W.Page(parent)
    local page = CreateFrame("Frame", nil, parent)
    page.refreshers = {}
    page.y = -8
    function page:Add(widget, height, x)
        widget:SetPoint("TOPLEFT", self, "TOPLEFT", x or 8, self.y)
        self.y = self.y - (height or 26)
        if widget.Refresh then
            self.refreshers[#self.refreshers + 1] = widget
        end
        return widget
    end
    function page:Gap(h)
        self.y = self.y - (h or 8)
    end
    function page:Refresh()
        for _, w in ipairs(self.refreshers) do
            w:Refresh()
        end
    end
    page:SetScript("OnShow", page.Refresh)
    return page
end

function W.Header(parent, text)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(460, 20)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT")
    fs:SetText(text)
    local line = f:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.83, 0.66, 0.26, 0.35)
    line:SetHeight(1)
    line:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    line:SetPoint("RIGHT", f, "RIGHT")
    return f
end

local function attachTooltip(frame, tip)
    if not tip then
        return
    end
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(tip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

function W.Check(parent, text, get, set, tip)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local fs = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    fs:SetText(text)
    cb.label = fs
    if cb.Text then
        cb.Text:SetText("")
    end
    cb:SetScript("OnClick", function(self)
        set(self:GetChecked() and true or false)
        ns.Fire("SETTINGS_CHANGED")
    end)
    function cb:Refresh()
        self:SetChecked(get() and true or false)
    end
    attachTooltip(cb, tip)
    return cb
end

function W.Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width or 140, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

function W.Cycle(parent, label, options, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(440, 24)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", 4, 0)
    fs:SetWidth(200)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    local b = W.Button(f, "", 200, function()
        local cur = get()
        local idx = 1
        for i, o in ipairs(options) do
            if o[1] == cur then
                idx = i
            end
        end
        idx = idx % #options + 1
        set(options[idx][1])
        f:Refresh()
        ns.Fire("SETTINGS_CHANGED")
    end)
    b:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    function f:Refresh()
        local cur = get()
        for _, o in ipairs(options) do
            if o[1] == cur then
                b:SetText(o[2])
            end
        end
    end
    return f
end

function W.Stepper(parent, label, minV, maxV, step, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(440, 24)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", 4, 0)
    fs:SetWidth(200)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    local minus = W.Button(f, "-", 26)
    minus:SetPoint("LEFT", fs, "RIGHT", 8, 0)
    local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    box:SetSize(44, 20)
    box:SetPoint("LEFT", minus, "RIGHT", 10, 0)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetJustifyH("CENTER")
    local plus = W.Button(f, "+", 26)
    plus:SetPoint("LEFT", box, "RIGHT", 6, 0)
    local function apply(v)
        v = math.max(minV, math.min(maxV, math.floor(tonumber(v) or minV)))
        set(v)
        f:Refresh()
        ns.Fire("SETTINGS_CHANGED")
    end
    minus:SetScript("OnClick", function() apply(get() - step) end)
    plus:SetScript("OnClick", function() apply(get() + step) end)
    box:SetScript("OnEnterPressed", function(self)
        apply(self:GetText())
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self) apply(self:GetText()) end)
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    function f:Refresh()
        box:SetText(tostring(get()))
        box:SetCursorPosition(0)
    end
    return f
end

function W.Money(parent, label, get, set)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(440, 24)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", 4, 0)
    fs:SetWidth(200)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    local boxes = {}
    local icons = {
        "Interface\\MoneyFrame\\UI-GoldIcon",
        "Interface\\MoneyFrame\\UI-SilverIcon",
        "Interface\\MoneyFrame\\UI-CopperIcon",
    }
    local anchor = fs
    local function apply()
        local g = tonumber(boxes[1]:GetText()) or 0
        local s = tonumber(boxes[2]:GetText()) or 0
        local c = tonumber(boxes[3]:GetText()) or 0
        set(math.max(0, g * 10000 + s * 100 + c))
        f:Refresh()
        ns.Fire("SETTINGS_CHANGED")
    end
    for i = 1, 3 do
        local box = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
        box:SetSize(i == 1 and 44 or 28, 20)
        box:SetPoint("LEFT", anchor, "RIGHT", i == 1 and 12 or 8, 0)
        box:SetAutoFocus(false)
        box:SetNumeric(true)
        box:SetMaxLetters(i == 1 and 5 or 2)
        box:SetJustifyH("RIGHT")
        box:SetScript("OnEnterPressed", function(self)
            apply()
            self:ClearFocus()
        end)
        box:SetScript("OnEditFocusLost", apply)
        box:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
        end)
        box:SetScript("OnTabPressed", function()
            boxes[i % 3 + 1]:SetFocus()
        end)
        local tex = f:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(icons[i])
        tex:SetSize(13, 13)
        tex:SetPoint("LEFT", box, "RIGHT", 2, 0)
        boxes[i] = box
        anchor = tex
    end
    function f:Refresh()
        local v = get()
        boxes[1]:SetText(tostring(math.floor(v / 10000)))
        boxes[2]:SetText(tostring(math.floor((v % 10000) / 100)))
        boxes[3]:SetText(tostring(v % 100))
    end
    return f
end
