-- Nullgate's Pet & Ammo: the bar. The Feed Pet button is a secure macro button (cast Feed Pet, use
-- the chosen food); the ammo button shows your ammo and re-equips a spare stack when the slot runs
-- empty. What either button does can only change out of combat.
local _, ns = ...

local L = ns.L
local Buttons = {}
ns.Buttons = Buttons

local SIZE, GAP = 40, 4
local FEED_ICON = "Interface\\Icons\\Ability_Hunter_BeastTraining"
local AMMO_ICON = "Interface\\Icons\\INV_Ammo_Arrow_02"
local HAPPY_COLOR = { [1] = { 1, 0.2, 0.2 }, [2] = { 1, 0.85, 0.2 }, [3] = { 0.3, 1, 0.3 } }
local bar
local buttons = {}
Buttons.buttons = buttons

local function Options()
    local never = {}
    for id in pairs(ns.db.never) do never[id] = true end
    return { never = never, skipConjured = ns.db.skipConjured }
end

local function HappinessName(h)
    return (h == 3 and L["Happy"]) or (h == 2 and L["Content"]) or (h == 1 and L["Unhappy"]) or "?"
end

local function ShowTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.kind == "feed" then
        GameTooltip:AddLine(L["Feed Pet"], 1, 0.82, 0)
        if not UnitExists("pet") then
            GameTooltip:AddLine(L["No pet out."], 1, 0.3, 0.3, true)
        else
            local h = GetPetHappiness and GetPetHappiness()
            if h then
                local c = HAPPY_COLOR[h] or { 1, 1, 1 }
                GameTooltip:AddLine(string.format(L["Your pet is %s."], HappinessName(h)), c[1], c[2], c[3])
            end
            if button.food then
                GameTooltip:AddLine(string.format(L["Click to feed: %s (%d meals in your bags)."],
                    ns.Items.Name(button.food) or ("item " .. button.food), button.meals or 0), 1, 1, 1, true)
            else
                GameTooltip:AddLine(L["You carry nothing your pet will eat."], 1, 0.3, 0.3, true)
            end
        end
    else
        GameTooltip:AddLine(L["Ammo"], 1, 0.82, 0)
        local id, count = ns.Items.EquippedAmmo()
        if id then
            GameTooltip:AddLine(string.format("%s: %d", ns.Items.Name(id) or ("item " .. id), count), 1, 1, 1)
        else
            GameTooltip:AddLine(L["No ammo equipped."], 1, 0.3, 0.3, true)
        end
        if button.spare then
            GameTooltip:AddLine(string.format(L["Click to equip %s."], ns.Items.Name(button.spare) or ("item " .. button.spare)), 0.6, 1, 0.6, true)
        end
    end
    if button.stale then GameTooltip:AddLine(L["In combat: updates when combat ends."], 1, 0.3, 0.3, true) end
    GameTooltip:Show()
end

local function NewButton(name, kind, icon)
    local button = CreateFrame("Button", name, bar, "SecureActionButtonTemplate")
    button.kind = kind
    button:SetSize(SIZE, SIZE)
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.icon:SetTexture(icon)
    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetPoint("TOPLEFT", -4, 4)
    button.glow:SetPoint("BOTTOMRIGHT", 4, -4)
    button.glow:SetColorTexture(1, 0.6, 0.1, 0.35)
    button.glow:Hide()
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -2, 2)
    button.staleMark = button:CreateFontString(nil, "OVERLAY", "GameFontRedSmall")
    button.staleMark:SetPoint("TOPLEFT", 2, -2)
    button.staleMark:SetText("*")
    button.staleMark:Hide()
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(button)
    highlight:SetColorTexture(1, 1, 1, 0.15)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function() bar:GetScript("OnDragStart")(bar) end)
    button:SetScript("OnDragStop", function() bar:GetScript("OnDragStop")(bar) end)
    buttons[kind] = button
    return button
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ns.db.point = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function RestorePosition()
    bar:ClearAllPoints()
    local p = ns.db.point
    if p and p.point then
        bar:SetPoint(p.point, UIParent, p.relativePoint or p.point, p.x or 0, p.y or 0)
    else
        bar:SetPoint("CENTER", UIParent, "CENTER", 0, -220)
    end
end

function Buttons.Create()
    if bar then return end
    bar = CreateFrame("Frame", "NullgatesPetAmmoBar", UIParent)
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function(self)
        if not ns.db.locked and not InCombatLockdown() then self:StartMoving() end
    end)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    bar.background = bar:CreateTexture(nil, "BACKGROUND")
    bar.background:SetAllPoints(bar)
    bar.background:SetColorTexture(0.08, 0.1, 0.13, 0.75)
    local feed = NewButton("NullgatesPetAmmoFeed", "feed", FEED_ICON)
    feed.happy = feed:CreateTexture(nil, "OVERLAY")
    feed.happy:SetSize(10, 10)
    feed.happy:SetPoint("TOPRIGHT", -3, -3)
    NewButton("NullgatesPetAmmoAmmo", "ammo", AMMO_ICON)
    RestorePosition()
    Buttons.Layout()
    Buttons.Update()
end

function Buttons.Layout()
    if not bar then return end
    ns.WhenSafe("layout", function()
        local order = { buttons.feed, buttons.ammo }
        for i, button in ipairs(order) do
            button:ClearAllPoints()
            local offset = GAP + (i - 1) * (SIZE + GAP)
            if ns.db.vertical then button:SetPoint("TOP", bar, "TOP", 0, -offset)
            else button:SetPoint("LEFT", bar, "LEFT", offset, 0) end
        end
        local long, short = GAP + #order * (SIZE + GAP), SIZE + 2 * GAP
        if ns.db.vertical then bar:SetSize(short, long) else bar:SetSize(long, short) end
        bar:SetScale(ns.db.scale or 1)
        bar.background:SetShown(not ns.db.locked)
        buttons.ammo:SetShown(ns.db.showAmmo)
        bar:Show()
    end)
    Buttons.UpdateStatus()
end

-- Picks the food and the spare ammo, out of combat.
function Buttons.Update()
    if not bar then return end
    local applied = ns.WhenSafe("buttons", function()
        local feed, ammo = buttons.feed, buttons.ammo
        local diets = ns.Items.PetDiets()
        local food, meals
        if diets then
            local carried, petLevel, opts = ns.Items.Foods(), UnitLevel("pet"), Options()
            food = ns.Food.Pick(carried, diets, petLevel, opts)
            meals = ns.Food.Meals(carried, diets, petLevel, opts)
        end
        feed.food, feed.meals = food, meals
        feed:SetAttribute("type", food and "macro" or nil)
        feed:SetAttribute("macrotext", food and ns.Food.Macro(ns.Items.FeedPetName(), food) or nil)
        feed.icon:SetTexture((food and ns.Items.Icon(food)) or FEED_ICON)
        feed.icon:SetDesaturated(food == nil)

        local equipped = ns.Items.EquippedAmmo()
        local spare = (not equipped) and ns.Items.SpareAmmo() or nil
        ammo.spare = spare
        ammo:SetAttribute("type", spare and "item" or nil)
        ammo:SetAttribute("item", spare and ("item:" .. spare) or nil)
        for _, b in ipairs({ feed, ammo }) do
            b.stale = false
            b.staleMark:Hide()
        end
    end)
    if not applied then
        for _, b in pairs(buttons) do
            b.stale = true
            b.staleMark:Show()
        end
    end
    Buttons.UpdateStatus()
end

-- Happiness, counts, icons and warnings; none of this is protected.
function Buttons.UpdateStatus()
    if not bar then return end
    local feed, ammo = buttons.feed, buttons.ammo
    local petOut = UnitExists("pet") and GetPetHappiness ~= nil
    local happiness = petOut and GetPetHappiness() or nil
    local c = happiness and HAPPY_COLOR[happiness]
    if c then feed.happy:SetColorTexture(c[1], c[2], c[3], 1) end
    feed.happy:SetShown(c ~= nil)
    feed.count:SetText(feed.meals and feed.meals > 0 and feed.meals or "")
    local hungry = happiness and happiness < (ns.db.warnBelowHappy and 3 or 2) or false
    feed.glow:SetShown(hungry and feed.food ~= nil and not ns.Items.PetEating())
    ns.Warn.Happiness(happiness)

    local id, count = ns.Items.EquippedAmmo()
    ammo.icon:SetTexture((id and ns.Items.Icon(id)) or (ammo.spare and ns.Items.Icon(ammo.spare)) or AMMO_ICON)
    ammo.icon:SetDesaturated(id == nil)
    ammo.count:SetText(count > 0 and count or "")
    local hasRanged = ns.Items.RangedKind() ~= nil
    local level = hasRanged and ns.Food.AmmoLevel(count, ns.db.ammo.low, ns.db.ammo.critical) or "ok"
    ammo.glow:SetShown(level ~= "ok")
    ns.Warn.Ammo(level, count)
end

function Buttons.ResetPosition()
    if not bar then return end
    ns.db.point = nil
    ns.WhenSafe("position", RestorePosition)
end
