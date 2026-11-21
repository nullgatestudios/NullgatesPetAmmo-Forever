-- Nullgate's Pet & Ammo: smoke test of the whole addon with stand-in game API.
-- Loads the files in .toc order, logs in as a level 40 hunter with a level 40 boar and drives the
-- Feed Pet button, happiness, combat, the ammo button and warnings, /npet never, settings and check.
-- Run from the repository root:  lua tests/smoke.lua

local source = debug.getinfo(1, "S").source or ""
local script = source:match("^@(.*)$") or "tests/smoke.lua"
local scriptDir = script:match("^(.*)[/\\][^/\\]*$") or "."
local repo = scriptDir:match("^(.*)[/\\][^/\\]*$") or "."
local folder = "NullgatesPetAmmo-Forever"
local root = repo .. "/" .. folder .. "/"

local checks, failures = 0, 0
local function OK(cond, name)
    checks = checks + 1
    if not cond then failures = failures + 1; io.write("FAIL " .. name .. "\n") end
end

-- --- Stand-in game API ----------------------------------------------------------
local frames, printed = {}, {}
local function NewFrame(kind, name, _, template)
    local f = { kind = kind, name = name, template = template, scripts = {}, attributes = {}, events = {}, shown = false }
    setmetatable(f, { __index = function(_, key) if type(key) == "string" and key:match("^%u") then return function() return nil end end end })
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:GetScript(k) return self.scripts[k] end
    function f:RegisterEvent(e) self.events[e] = true end
    function f:SetAttribute(k, v) self.attributes[k] = v end
    function f:GetAttribute(k) return self.attributes[k] end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(v) self.shown = v and true or false end
    function f:IsShown() return self.shown end
    function f:SetText(t) self.text = t end
    function f:GetText() return self.text end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:CreateFontString() return NewFrame("FontString") end
    function f:CreateTexture() return NewFrame("Texture") end
    frames[#frames + 1] = f
    if name then _G[name] = f end
    return f
end
CreateFrame = NewFrame
SlashCmdList = {}
UIParent = NewFrame("Frame", "UIParent")
GameTooltip = NewFrame("GameTooltip", "GameTooltip")
UISpecialFrames = {}
print = function(text) printed[#printed + 1] = tostring(text) end
local function Printed(fragment)
    for _, line in ipairs(printed) do if line:find(fragment, 1, true) then return true end end
    return false
end

local inCombat, pet, happiness, eating = false, true, 3, false
function UnitClass() return "HUNTER", "HUNTER" end
function UnitLevel() return 40 end
function UnitExists(unit) return unit == "player" or (unit == "pet" and pet) end
function InCombatLockdown() return inCombat end
function GetBuildInfo() return "1.60.1", "70532", "Nov 2026", 16001 end
function GetPetFoodTypes() return "Meat", "Fungus" end
function GetPetHappiness() return happiness, 100, 1 end
function PlaySound() end
C_Timer = { After = function(_, fn) fn() end }
C_Spell = { GetSpellName = function() return "Feed Pet" end }
C_UnitAuras = { GetAuraDataByIndex = function(_, i) if eating and i == 1 then return { spellId = 1539 } end end }

local bags = {} -- [bag][slot] = { itemID, count }
local function Put(bag, slot, id, n) bags[bag] = bags[bag] or {}; bags[bag][slot] = { itemID = id, stackCount = n } end
C_Container = {
    GetContainerNumSlots = function() return 16 end,
    GetContainerItemInfo = function(bag, slot) return bags[bag] and bags[bag][slot] end,
}
local equipped = { [18] = 2504 } -- a bow
local ammoCount = 0
function GetInventoryItemID(_, slot) return equipped[slot] end
function GetInventoryItemCount(_, slot) return slot == 0 and ammoCount or 0 end
C_Item = {
    GetItemInfo = function(id) return "Item" .. id end,
    GetItemIconByID = function(id) return "icon" .. id end,
    GetItemInfoInstant = function(id)
        if id == 2504 then return id, nil, nil, nil, nil, 2, 2 end        -- bow
        if id == 11285 or id == 3030 then return id, nil, nil, nil, nil, 6, 2 end -- arrows
        if id == 11284 then return id, nil, nil, nil, nil, 6, 3 end       -- bullets
        return id, nil, nil, nil, nil, 0, 0
    end,
}

-- --- Load the files in .toc order -----------------------------------------------
local ns = {}
local toc = assert(io.open(root .. folder .. ".toc", "r")):read("*a")
for line in toc:gmatch("[^\r\n]+") do
    if not line:match("^##") and line:match("%.lua$") then
        assert(loadfile(root .. line:gsub("\\", "/")))(folder, ns)
    end
end
local core
for _, f in ipairs(frames) do if f.events.PLAYER_LOGIN then core = f end end
local function Fire(event, ...) core.scripts.OnEvent(core, event, ...) end
Fire("ADDON_LOADED", folder)
local db = NullgatesPetAmmoDB
OK(db.ammo.low == 200 and db.ammo.critical == 50 and db.showAmmo, "saved data gets its defaults")
OK(SLASH_NULLGATESPETAMMO1 == "/npet" and SLASH_NULLGATESPETAMMO2 == "/petammo", "slash commands /npet and /petammo")
OK(_G["BINDING_NAME_CLICK NullgatesPetAmmoFeed:LeftButton"] ~= nil, "the Feed Pet key binding has a name")

-- --- Login ------------------------------------------------------------------------
Put(0, 1, 117, 20)   -- Tough Jerky (level 5: too low for a level 40 pet)
Put(0, 2, 3771, 10)  -- Wild Hog Shank (35)
Put(0, 3, 4599, 5)   -- Cured Ham Steak (45)
Put(0, 4, 4537, 20)  -- a banana: a boar doesn't eat fruit
Put(1, 1, 11285, 600) -- Jagged Arrows in the bags
Fire("PLAYER_LOGIN")
local feed, ammo = NullgatesPetAmmoFeed, NullgatesPetAmmoAmmo
OK(feed and ammo and feed.template == "SecureActionButtonTemplate", "Feed Pet and ammo buttons exist and are secure")
OK(feed.attributes.type == "macro" and feed.attributes.macrotext == "/cast Feed Pet\n/use item:3771",
    "it feeds the cheapest food the pet eats (Wild Hog Shank; jerky is too low, bananas aren't meat)")
OK(feed.meals == 15, "15 meals counted")
OK(not feed.glow.shown, "happy pet: no glow")

-- --- No ammo equipped: re-equip a spare stack ---------------------------------------------
OK(ammo.attributes.type == "item" and ammo.attributes.item == "item:11285", "no ammo equipped: the ammo button equips the arrows")
OK(Printed("Out of ammo!"), "and it warns that you're out")

-- --- Happiness ---------------------------------------------------------------------------
printed = {}
happiness = 2
Fire("UNIT_HAPPINESS", "pet")
OK(not Printed("unhappy") and not feed.glow.shown, "content: no warning by default")
happiness = 1
Fire("UNIT_HAPPINESS", "pet")
OK(Printed("Your pet is unhappy: feed it."), "unhappy: a warning")
OK(feed.glow.shown, "and the button glows")
eating = true
Fire("UNIT_AURA", "pet")
OK(not feed.glow.shown, "while it's eating, no glow")
eating, happiness = false, 3
Fire("UNIT_HAPPINESS", "pet")

-- --- Never feed ----------------------------------------------------------------------------
SlashCmdList.NULLGATESPETAMMO("never |cffffffff|Hitem:3771::::::::40:::::|h[Wild Hog Shank]|h|r")
OK(db.never[3771] and feed.attributes.macrotext:find("item:4599", 1, true), "/npet never skips Wild Hog Shank; Cured Ham Steak next")
SlashCmdList.NULLGATESPETAMMO("never 3771")
OK(not db.never[3771], "again allows it")

-- --- Combat: changes wait --------------------------------------------------------------------
inCombat = true
bags[0][2] = nil
Fire("BAG_UPDATE_DELAYED")
OK(feed.attributes.macrotext:find("item:3771", 1, true) and feed.stale, "in combat the food doesn't change and the button is marked")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
OK(feed.attributes.macrotext:find("item:4599", 1, true) and not feed.stale, "after combat it switches")

-- --- Ammo equipped and running low ---------------------------------------------------------
equipped[0], ammoCount = 11285, 600
printed = {}
Fire("UNIT_INVENTORY_CHANGED", "player")
OK(ammo.attributes.type == nil and ammo.count.text == 600, "ammo equipped: shows 600, nothing to equip")
ammoCount = 150
Fire("UNIT_INVENTORY_CHANGED", "player")
OK(Printed("Ammo is running low: 150 left."), "under 200: warns")
ammoCount = 40
Fire("UNIT_INVENTORY_CHANGED", "player")
OK(Printed("Almost out of ammo: 40 left."), "under 50: warns louder")
printed = {}
ammoCount = 30
Fire("UNIT_INVENTORY_CHANGED", "player")
OK(#printed == 0, "no repeat at the same level")

-- --- No pet ---------------------------------------------------------------------------------
pet = false
Fire("UNIT_PET", "player")
OK(feed.attributes.type == nil, "no pet out: nothing to feed")

-- --- Settings and /npet check ----------------------------------------------------------------
SlashCmdList.NULLGATESPETAMMO("")
OK(NullgatesPetAmmoOptions and NullgatesPetAmmoOptions.shown, "/npet opens the settings")
pet = true
SlashCmdList.NULLGATESPETAMMO("check")
local log = table.concat(db.check or {}, "\n")
OK(log:find("GetPetFoodTypes=yes", 1, true), "check reports which calls exist")
OK(log:find("Item117 x20 (Meat, level 5): no: level", 1, true), "check explains why food is refused")
OK(NullgatesPetAmmoCheck and NullgatesPetAmmoCheck.shown, "the check window opens")

io.write(string.format("smoke: %d checks, %d failure(s)\n", checks, failures))
if failures > 0 then os.exit(1) end
