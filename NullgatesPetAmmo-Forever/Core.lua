-- Nullgate's Pet & Ammo: saved data, events, the out-of-combat queue and slash commands.
local addonName, ns = ...

local L = ns.L

ns.DEFAULTS = {
    locked = false,
    vertical = false,
    scale = 1,
    never = {},              -- [itemID] = true: food the pet is never fed
    skipConjured = false,
    warnBelowHappy = false,  -- warn when the pet drops below Happy (otherwise only at Unhappy)
    showAmmo = true,
    ammo = { low = 200, critical = 50 },
    chat = true,
    sound = false,
    language = "auto",
}

local function Merge(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            if next(value) then Merge(target[key], value) end
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function ns.Print(text)
    print("|cff00c0ffPet & Ammo:|r " .. tostring(text))
end

function ns.IsHunter()
    local _, class = UnitClass("player")
    return class == "HUNTER"
end

local pending = {}
function ns.WhenSafe(key, fn)
    if InCombatLockdown() then
        pending[key] = fn
        return false
    end
    pending[key] = nil
    fn()
    return true
end

BINDING_HEADER_NULLGATESPETAMMO = "Nullgate's Pet & Ammo"
local function NameBindings()
    _G["BINDING_NAME_CLICK NullgatesPetAmmoFeed:LeftButton"] = L["Feed your pet"]
end

local events = CreateFrame("Frame")
local active = false

local function OnEvent(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            if type(NullgatesPetAmmoDB) ~= "table" then NullgatesPetAmmoDB = {} end
            Merge(NullgatesPetAmmoDB, ns.DEFAULTS)
            ns.db = NullgatesPetAmmoDB
            ns.SetLanguage(ns.db.language)
            NameBindings()
        end
        if arg1 == addonName or arg1 == "NullgatesAddonConfig-Forever" then ns.Options.RegisterHub() end
    elseif event == "PLAYER_LOGIN" then
        active = ns.IsHunter()
        if active then ns.Buttons.Create() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        for key, fn in pairs(pending) do
            pending[key] = nil
            fn()
        end
    elseif not active then
        return
    elseif event == "UNIT_HAPPINESS" or event == "UNIT_AURA" then
        if arg1 == "pet" then ns.Buttons.UpdateStatus() end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        if arg1 == "player" then ns.Buttons.Update() end
    elseif event == "UNIT_PET" then
        if arg1 == "player" then ns.Buttons.Update() end
    elseif event == "UNIT_LEVEL" then
        if arg1 == "pet" then ns.Buttons.Update() end
    else -- bags or equipment changed
        ns.Buttons.Update()
    end
end

events:SetScript("OnEvent", OnEvent)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_REGEN_ENABLED", "BAG_UPDATE_DELAYED",
    "PLAYER_EQUIPMENT_CHANGED", "UNIT_INVENTORY_CHANGED", "UNIT_PET", "UNIT_HAPPINESS", "UNIT_AURA", "UNIT_LEVEL" }) do
    events:RegisterEvent(event)
end

local function Help()
    ns.Print(L["commands:"])
    print("  /npet - " .. L["open the settings"])
    print("  /npet never <" .. L["item link"] .. "> - " .. L["never feed this item (again to allow it)"])
    print("  /npet lock | unlock - " .. L["lock or unlock the bar"])
    print("  /npet reset - " .. L["reset the bar's position"])
    print("  /npet check - " .. L["test what the addon needs in this client (results are saved)"])
end

SLASH_NULLGATESPETAMMO1 = "/npet"
SLASH_NULLGATESPETAMMO2 = "/petammo"
SlashCmdList["NULLGATESPETAMMO"] = function(msg)
    msg = msg or ""
    local command, rest = msg:match("^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "check" then
        ns.Check.Run()
    elseif command == "help" then
        Help()
    elseif not active then
        ns.Print(L["This addon is for hunters; only /npet check works on other classes."])
    elseif command == "" or command == "options" or command == "config" then
        ns.Options.Open()
    elseif command == "never" then
        local id = tonumber(rest:match("item:(%d+)") or rest:match("^(%d+)$") or "")
        if not id then
            ns.Print(L["Shift-click a food item into the chat box after /npet never."])
            return
        end
        ns.db.never[id] = not ns.db.never[id] or nil
        ns.Print(string.format(ns.db.never[id] and L["Never feeding %s."] or L["%s can be fed again."], ns.Items.Name(id) or ("item " .. id)))
        ns.Buttons.Update()
    elseif command == "lock" or command == "unlock" then
        ns.db.locked = command == "lock"
        ns.Buttons.Layout()
    elseif command == "reset" then
        ns.Buttons.ResetPosition()
    else
        Help()
    end
end
