local ADDON, ns = ...
local L = ns.L

ns.name = ADDON
ns.title = "Bag Sort & Auto Delete Junk"
ns.short = "BSADJ"
ns.media = "Interface\\AddOns\\" .. ADDON .. "\\Media\\"

BINDING_HEADER_BSADJ = ns.title
BINDING_NAME_BSADJ_SORT = L["Sort bags"]
BINDING_NAME_BSADJ_JUNK = L["Delete junk"]
BINDING_NAME_BSADJ_CONFIG = L["Open settings"]

ns.defaults = {
    version = 2,
    sort = {
        direction = "desc",
        emptyAt = "end",
        reverseBags = false,
        mergeStacks = true,
        questFirst = true,
        tradeGoodsFirst = false,
        junkLast = false,
        autoAfterLoot = false,
        ignoreBags = {},
    },
    junk = {
        enabled = true,
        dryRun = true,
        auto = true,
        grays = true,
        whites = false,
        whitesGearOnly = true,
        priceEnabled = true,
        priceThreshold = 100,
        fullEnabled = true,
        keepFree = 2,
        fullMaxPrice = 10000,
        maxPerRun = 10,
        quiet = false,
        protect = {
            tradegoods = true,
            consumable = true,
            reagent = true,
            quest = true,
            recipe = true,
            projectile = true,
            container = true,
            quiver = true,
            craftreagent = true,
        },
    },
    whitelist = {},
    blacklist = {},
    ui = {
        minimap = { show = true, angle = 200 },
        bar = { show = true, locked = false, point = { "CENTER", "UIParent", "CENTER", 300, -200 } },
        frame = {},
    },
}

local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            merge(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function ns.Print(msg, force)
    if not force and ns.db and ns.db.junk.quiet then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffd4a842BSADJ|r: " .. tostring(msg))
end

function ns.Money(copper)
    copper = math.floor(copper or 0)
    local fmt = (C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString) or GetCoinTextureString
    if fmt then
        return fmt(copper)
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("%dg %ds %dc", g, s, c)
    elseif s > 0 then
        return string.format("%ds %dc", s, c)
    end
    return string.format("%dc", c)
end

local callbacks = {}

function ns.On(event, fn)
    callbacks[event] = callbacks[event] or {}
    table.insert(callbacks[event], fn)
end

function ns.Fire(event, ...)
    local list = callbacks[event]
    if not list then
        return
    end
    for _, fn in ipairs(list) do
        fn(...)
    end
end

local pending = {}

function ns.Debounce(key, delay, fn)
    if pending[key] then
        return
    end
    pending[key] = true
    C_Timer.After(delay, function()
        pending[key] = nil
        fn()
    end)
end

local frame = CreateFrame("Frame")
ns.eventFrame = frame

local function onBagsChanged()
    ns.Debounce("junk", 0.3, function()
        ns.Junk:Evaluate()
    end)
end

local handlers = {}

function handlers.ADDON_LOADED(name)
    if name ~= ADDON then
        return
    end
    BSADJ_DB = merge(BSADJ_DB or {}, ns.defaults)
    ns.db = BSADJ_DB
    if (ns.db.version or 1) < 2 then
        ns.db.sort.mode = nil
        ns.db.junk.perStack = nil
        ns.db.sort.tradeGoodsFirst = false
        ns.db.sort.junkLast = false
        ns.db.version = 2
    end
    frame:UnregisterEvent("ADDON_LOADED")
end

function handlers.PLAYER_LOGIN()
    ns.Fire("LOGIN")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:RegisterEvent("LOOT_CLOSED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    frame:RegisterEvent("ADDON_ACTION_BLOCKED")
    frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
    onBagsChanged()
end

function handlers.BAG_UPDATE_DELAYED()
    if ns.Sort:IsRunning() then
        return
    end
    onBagsChanged()
end

function handlers.LOOT_CLOSED()
    onBagsChanged()
    if ns.db.sort.autoAfterLoot then
        ns.Debounce("autosort", 1.0, function()
            if not InCombatLockdown() and not ns.Sort:IsRunning() then
                ns.Sort:Start(true)
            end
        end)
    end
end

function handlers.PLAYER_REGEN_ENABLED()
    onBagsChanged()
end

function handlers.GET_ITEM_INFO_RECEIVED()
    ns.Debounce("iteminfo", 0.5, onBagsChanged)
end

function handlers.ADDON_ACTION_BLOCKED(addon)
    if addon == ADDON then
        ns.Junk:SetBlocked()
    end
end
handlers.ADDON_ACTION_FORBIDDEN = handlers.ADDON_ACTION_BLOCKED

frame:SetScript("OnEvent", function(_, event, ...)
    local fn = handlers[event]
    if fn then
        fn(...)
    end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

function BSADJ_SortBags()
    ns.Sort:Start()
end

function BSADJ_DeleteJunk()
    ns.Junk:DeleteNow(true)
end

function BSADJ_OpenConfig()
    ns.Options:Toggle()
end

function BSADJ_OnAddonCompartmentClick(_, button)
    if button == "RightButton" then
        ns.Sort:Start()
    else
        ns.Options:Toggle()
    end
end

SLASH_BSADJ1 = "/bsj"
SLASH_BSADJ2 = "/bsadj"
SlashCmdList.BSADJ = function(msg)
    local cmd = strtrim(msg or ""):lower()
    if cmd == "sort" then
        ns.Sort:Start()
    elseif cmd == "junk" or cmd == "delete" then
        ns.Junk:DeleteNow(true)
    elseif cmd == "preview" then
        ns.Junk:Preview()
    elseif cmd == "config" or cmd == "" then
        ns.Options:Toggle()
    else
        ns.Print(L["Commands"] .. ": /bsj [config | sort | junk | preview]", true)
    end
end
