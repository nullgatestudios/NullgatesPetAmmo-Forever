-- Nullgate's Pet & Ammo: happiness and ammo warnings. Each warns once when things get worse, and
-- again only after they've improved.
local _, ns = ...

local L = ns.L
local Warn = {}
ns.Warn = Warn

local lastHappiness, lastAmmo

local function Sound()
    if ns.db.sound and PlaySound then PlaySound((SOUNDKIT and SOUNDKIT.RAID_WARNING) or 8959, "Master") end
end

function Warn.Happiness(happiness)
    local before = lastHappiness
    lastHappiness = happiness
    if not happiness or not before or happiness >= before then return end
    local limit = ns.db.warnBelowHappy and 3 or 2
    if happiness < limit and ns.db.chat then
        ns.Print(happiness == 1 and L["Your pet is unhappy: feed it."] or L["Your pet is no longer happy."])
        Sound()
    end
end

function Warn.Ammo(level, count)
    local before = lastAmmo
    lastAmmo = level
    if not ns.Food.AmmoWorse(before, level) or not ns.db.chat then return end
    if level == "empty" then
        ns.Print(L["Out of ammo!"])
    elseif level == "critical" then
        ns.Print(string.format(L["Almost out of ammo: %d left."], count))
    else
        ns.Print(string.format(L["Ammo is running low: %d left."], count))
    end
    Sound()
end
