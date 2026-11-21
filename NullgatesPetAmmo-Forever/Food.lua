-- Nullgate's Pet & Ammo: choosing what to feed the pet. No game calls here, so the tests can run
-- every case outside the game.
local _, ns = ...

local Food = {}
ns.Food = Food

-- Pets refuse food whose item level is too far below their own. 30 levels is the Classic rule;
-- /npet check confirms it in Forever.
Food.RANGE = 30

-- A diet also covers its raw form ("Meat" pets eat "Raw Meat").
local RAW = { Meat = "Raw Meat", Fish = "Raw Fish" }

-- diets: the pet's diet names (GetPetFoodTypes). Returns a set of every food type it eats.
function Food.DietSet(diets)
    local set = {}
    for _, diet in ipairs(diets or {}) do
        set[diet] = true
        if RAW[diet] then set[RAW[diet]] = true end
    end
    return set
end

-- Whether the pet will eat an item, and why not: true, or false and "diet" / "level" / "never" / "conjured".
function Food.Eats(itemID, dietSet, petLevel, options)
    local entry = ns.PET_FOOD[itemID]
    if not entry or not dietSet[entry[1]] then return false, "diet" end
    if options.never and options.never[itemID] then return false, "never" end
    if options.skipConjured and entry[3] then return false, "conjured" end
    if entry[2] < petLevel - Food.RANGE then return false, "level" end
    return true
end

-- The food to feed from the bags: the lowest-level item the pet will eat (the least valuable),
-- most plentiful first on a tie. carried: { [itemID] = count }. Returns itemID, count or nil.
function Food.Pick(carried, diets, petLevel, options)
    local dietSet = Food.DietSet(diets)
    local best, bestCount
    for itemID, count in pairs(carried) do
        if count > 0 and Food.Eats(itemID, dietSet, petLevel, options) then
            local level = ns.PET_FOOD[itemID][2]
            local bestLevel = best and ns.PET_FOOD[best][2]
            if not best or level < bestLevel or (level == bestLevel and (count > bestCount or (count == bestCount and itemID < best))) then
                best, bestCount = itemID, count
            end
        end
    end
    return best, bestCount
end

-- How many meals the pet would eat from the bags in total.
function Food.Meals(carried, diets, petLevel, options)
    local dietSet, total = Food.DietSet(diets), 0
    for itemID, count in pairs(carried) do
        if Food.Eats(itemID, dietSet, petLevel, options) then total = total + count end
    end
    return total
end

-- The feeding macro: cast Feed Pet, then use the chosen food.
function Food.Macro(feedPetName, itemID)
    return "/cast " .. feedPetName .. "\n/use item:" .. itemID
end

-- --- Ammo ---------------------------------------------------------------------------

-- "empty", "critical", "low" or "ok" for an ammo count.
function Food.AmmoLevel(count, low, critical)
    if count <= 0 then return "empty" end
    if critical > 0 and count < critical then return "critical" end
    if low > 0 and count < low then return "low" end
    return "ok"
end

-- Whether to warn going from one ammo level to another: only when it gets worse.
local RANK = { ok = 0, low = 1, critical = 2, empty = 3 }
function Food.AmmoWorse(before, now)
    return RANK[now] > RANK[before or "ok"]
end
