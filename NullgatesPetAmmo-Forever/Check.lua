-- Nullgate's Pet & Ammo: /npet check, the in-game self test (phase 0 of PLAN.md).
-- Every result goes to chat and to NullgatesPetAmmoDB.check, so the log can be copied from
-- WTF\Account\<account>\<realm>\<character>\SavedVariables\NullgatesPetAmmo-Forever.lua.
--
--   1. Which calls exist; the pet's diets, level and happiness; every food carried and whether the
--      addon thinks the pet eats it; the equipped ammo and what GetInventoryItemCount returns.
--   2. While the window is open: feeding is reported (the cast, any game error such as "too low
--      level", and whether the pet's happiness went up), to confirm the 30-level rule.
local _, ns = ...

local Check = {}
ns.Check = Check

local LOG_LIMIT = 400
local panel, fedItem

local function Log(text)
    local db = ns.db
    if db then
        db.check = db.check or {}
        if #db.check >= LOG_LIMIT then table.remove(db.check, 1) end
        db.check[#db.check + 1] = text
    end
    print("|cff00c0ffNullgate's Pet & Ammo check:|r " .. text)
    if NullgateReport then NullgateReport.Update("pet-ammo") end
end
Check.Log = Log

-- Opens the report window every Nullgate addon shares (NullgateReport.lua) with this check's log,
-- ready to copy and paste into the report form on our website.
function Check.ShowReport()
    local L = ns.L
    return NullgateReport.Show({
        slug = "pet-ammo", name = "Nullgate's Pet & Ammo", addon = "NullgatesPetAmmo-Forever", command = "/npet check",
        lines = function() return ns.db and ns.db.check end,
        title = L["Bug report"], selectAll = L["Select all"], selectLink = L["Select link"],
        help = L["Press Ctrl+C to copy this report, then paste it into a new report at the link below, with a few words on what happened."],
    })
end

local function Exists(path)
    local value = _G
    for part in path:gmatch("[^.]+") do
        if type(value) ~= "table" then return false end
        value = value[part]
    end
    return type(value) == "function"
end

local function StaticChecks()
    local _, class = UnitClass("player")
    Log(string.format("client %s, build %s, interface %s; class %s, level %s; data build %s",
        tostring(GetBuildInfo and select(1, GetBuildInfo())), tostring(GetBuildInfo and select(2, GetBuildInfo())),
        tostring(GetBuildInfo and select(4, GetBuildInfo())), tostring(class), tostring(UnitLevel("player")),
        tostring(ns.PET_FOOD_DATA_BUILD)))
    local calls = {}
    for _, name in ipairs({ "GetPetFoodTypes", "GetPetHappiness", "GetInventoryItemCount", "C_UnitAuras.GetAuraDataByIndex",
        "UnitBuff", "C_Item.GetItemInfoInstant", "C_Spell.GetSpellName" }) do
        calls[#calls + 1] = name .. "=" .. (Exists(name) and "yes" or "no")
    end
    Log("calls: " .. table.concat(calls, " "))
    Log("Feed Pet spell name: " .. tostring(ns.Items.FeedPetName()))
    local diets = ns.Items.PetDiets()
    if diets then
        local h, damage, loyalty = GetPetHappiness()
        Log(string.format("pet: level %s, diets %s, happiness %s (damage %s%%, loyalty rate %s), eating %s",
            tostring(UnitLevel("pet")), table.concat(diets, ", "), tostring(h), tostring(damage), tostring(loyalty),
            tostring(ns.Items.PetEating())))
        local set, opts = ns.Food.DietSet(diets), { never = ns.db.never, skipConjured = ns.db.skipConjured }
        for id, count in pairs(ns.Items.Foods()) do
            local eats, why = ns.Food.Eats(id, set, UnitLevel("pet"), opts)
            Log(string.format("food %s x%d (%s, level %d): %s", ns.Items.Name(id) or id, count, ns.PET_FOOD[id][1],
                ns.PET_FOOD[id][2], eats and "eats" or ("no: " .. why)))
        end
    else
        Log("no pet out: call your pet and run /npet check again for the pet tests")
    end
    local ammo = GetInventoryItemID("player", ns.Items.AMMO_SLOT)
    Log(string.format("ammo: slot item %s, GetInventoryItemCount %s, ranged weapon %s (%s), spare %s",
        tostring(ammo), tostring(GetInventoryItemCount("player", ns.Items.AMMO_SLOT)),
        tostring(GetInventoryItemID("player", ns.Items.RANGED_SLOT)), tostring(ns.Items.RangedKind()),
        tostring((ns.Items.SpareAmmo()))))
end

local function BuildPanel()
    panel = CreateFrame("Frame", "NullgatesPetAmmoCheck", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(300, 110)
    panel:SetPoint("TOPLEFT", NullgateReport.Frame(), "TOPRIGHT", 4, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    local title = "Pet & Ammo check"
    if type(panel.SetTitle) == "function" then panel:SetTitle(title)
    elseif type(panel.TitleText) == "table" then panel.TitleText:SetText(title) end
    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOP", panel, "TOP", 0, -36)
    note:SetWidth(270)
    note:SetText("Feed your pet with the Feed Pet button (try a low-level food too) while this window is open; the results go to chat and are saved.")
end

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
watcher:RegisterEvent("UNIT_HAPPINESS")
watcher:RegisterEvent("UI_ERROR_MESSAGE")
watcher:RegisterEvent("ADDON_ACTION_BLOCKED")
watcher:RegisterEvent("ADDON_ACTION_FORBIDDEN")
watcher:SetScript("OnEvent", function(_, event, a, b, c)
    if not (panel and panel:IsShown()) then return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if a == "player" and c == ns.Items.FEED_PET then
            fedItem = ns.Buttons.buttons.feed and ns.Buttons.buttons.feed.food
            Log(string.format("feed: Feed Pet cast with %s (level %s) on a level %s pet", tostring(fedItem),
                tostring(fedItem and ns.PET_FOOD[fedItem] and ns.PET_FOOD[fedItem][2]), tostring(UnitLevel("pet"))))
        end
    elseif event == "UNIT_HAPPINESS" then
        if a == "pet" then Log("happiness now " .. tostring(GetPetHappiness())) end
    elseif event == "UI_ERROR_MESSAGE" then
        Log("game error: " .. tostring(b or a))
    else
        Log(event .. ": " .. tostring(a) .. " tried " .. tostring(b))
    end
end)

function Check.Run()
    if ns.db then ns.db.check = {} end
    StaticChecks()
    if not panel then BuildPanel() end
    panel:Show()
    Check.ShowReport()
end
