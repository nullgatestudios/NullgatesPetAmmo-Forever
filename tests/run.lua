-- Nullgate's Pet & Ammo: tests for the food data, choosing food and the ammo levels.
-- Run from the repository root:  lua tests/run.lua   (Lua 5.1 or newer)

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/run.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local root = (scriptDir:match("^(.*)[/\\][^/\\]*$") or ".") .. "/NullgatesPetAmmo-Forever/"

local ns = {}
local function Load(file) assert(loadfile(root .. file), "cannot load " .. file)("NullgatesPetAmmo-Forever", ns) end
Load("Data/PetFood.lua")
Load("Food.lua")
local F = ns.Food

local checks, failures = 0, 0
local function EQ(got, want, name)
    checks = checks + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL %s: expected %s, got %s", name, tostring(want), tostring(got)))
    end
end

-- --- The data ---------------------------------------------------------------------
EQ(type(ns.PET_FOOD_DATA_BUILD), "string", "the data names its client build")
local count = 0
for _, entry in pairs(ns.PET_FOOD) do
    count = count + 1
    EQ(type(entry[1]) == "string" and entry[2] >= 1, true, "every food has a diet and a level")
end
EQ(count > 300, true, "over 300 pet foods")
EQ(ns.PET_FOOD[117][1], "Meat", "Tough Jerky is meat")
EQ(ns.PET_FOOD[1113][3], true, "Conjured Bread is conjured")

-- --- Choosing food ------------------------------------------------------------------
local JERKY, HAUNCH, HAM, QUAIL, BREAD, CONJURED, APPLE = 117, 2287, 4599, 8952, 4540, 1113, 4536
local opts = { never = {}, skipConjured = false }
local carried = { [JERKY] = 20, [HAM] = 10, [QUAIL] = 5, [APPLE] = 20 }
EQ(F.Pick(carried, { "Meat" }, 30, opts), JERKY, "level 30 meat pet: the cheapest meat it eats (Tough Jerky, level 5)")
EQ(F.Pick(carried, { "Meat" }, 40, opts), HAM, "level 40: Tough Jerky is too low, so Cured Ham Steak")
EQ(F.Pick(carried, { "Fruit" }, 30, opts), APPLE, "a fruit pet gets the apple")
EQ(F.Pick(carried, { "Fish" }, 30, opts), nil, "a fish pet eats none of it")
EQ(F.Meals(carried, { "Meat" }, 40, opts), 15, "15 meals for a level 40 meat pet")
EQ(F.Meals(carried, { "Meat", "Fruit" }, 30, opts), 55, "every meal it eats, across diets")

opts.never[HAM] = true
EQ(F.Pick(carried, { "Meat" }, 40, opts), QUAIL, "a never-feed item is skipped")
opts.never = {}

carried = { [CONJURED] = 20, [BREAD] = 5 }
EQ(F.Pick(carried, { "Bread" }, 20, opts), BREAD, "the lower-level bread first")
EQ(F.Pick({ [CONJURED] = 20 }, { "Bread" }, 20, opts), CONJURED, "conjured food is fed when allowed")
opts.skipConjured = true
EQ(F.Pick({ [CONJURED] = 20 }, { "Bread" }, 20, opts), nil, "and skipped when not")
opts.skipConjured = false

-- Raw meat counts as meat.
local rawMeat
for id, e in pairs(ns.PET_FOOD) do if e[1] == "Raw Meat" then rawMeat = id end end
EQ(rawMeat ~= nil, true, "the data has raw meat")
EQ((F.Eats(rawMeat, F.DietSet({ "Meat" }), ns.PET_FOOD[rawMeat][2], opts)), true, "a meat pet eats raw meat")
local _, why = F.Eats(JERKY, F.DietSet({ "Meat" }), 60, opts)
EQ(why, "level", "the reason food is refused is reported")

-- Ties: the bigger stack first.
EQ(ns.PET_FOOD[HAUNCH][2] == ns.PET_FOOD[733][2], true, "Haunch of Meat and Westfall Stew are the same level")
EQ(F.Pick({ [HAUNCH] = 3, [733] = 8 }, { "Meat" }, 20, opts), 733, "same level: the bigger stack")
EQ(F.Pick({ [HAUNCH] = 8, [733] = 3 }, { "Meat" }, 20, opts), HAUNCH, "either way round")
EQ(F.Macro("Feed Pet", JERKY), "/cast Feed Pet\n/use item:117", "the feeding macro")

-- --- Ammo ---------------------------------------------------------------------------
EQ(F.AmmoLevel(0, 200, 50), "empty", "no ammo")
EQ(F.AmmoLevel(30, 200, 50), "critical", "under 50: critical")
EQ(F.AmmoLevel(150, 200, 50), "low", "under 200: low")
EQ(F.AmmoLevel(800, 200, 50), "ok", "plenty")
EQ(F.AmmoLevel(30, 0, 0), "ok", "both warnings off")
EQ(F.AmmoWorse("ok", "low"), true, "warn when it gets worse")
EQ(F.AmmoWorse("low", "low"), false, "not again at the same level")
EQ(F.AmmoWorse("critical", "low"), false, "not when it improves")
EQ(F.AmmoWorse(nil, "empty"), true, "first check: warn if already out")

print(string.format("%d checks, %d failure(s)", checks, failures))
if failures > 0 then os.exit(1) end
