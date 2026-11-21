-- Nullgate's Pet & Ammo: bags, ammo and pet helpers (the only file that reads them).
local _, ns = ...

local Items = {}
ns.Items = Items

Items.AMMO_SLOT = 0
Items.RANGED_SLOT = 18
Items.FEED_PET = 6991
Items.FEED_PET_EFFECT = 1539

local function SlotItem(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then
        local info = C_Container.GetContainerItemInfo(bag, slot)
        if info then return info.itemID, info.stackCount or 1 end
        return nil
    end
    if GetContainerItemInfo then
        local _, count, _, _, _, _, _, _, _, itemID = GetContainerItemInfo(bag, slot)
        return itemID, count or 1
    end
end

-- { [itemID] = count } for every item in the bags that matches(itemID).
function Items.Scan(matches)
    local numSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
    local found = {}
    if not numSlots then return found end
    for bag = 0, 4 do
        for slot = 1, (numSlots(bag) or 0) do
            local id, count = SlotItem(bag, slot)
            if id and matches(id) then found[id] = (found[id] or 0) + count end
        end
    end
    return found
end

function Items.Foods()
    return Items.Scan(function(id) return ns.PET_FOOD[id] ~= nil end)
end

function Items.Name(itemID)
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    return info and (info(itemID)) or nil
end

function Items.Icon(itemID)
    local icon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
    return icon and icon(itemID) or nil
end

local function Instant(itemID)
    local instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not instant then return nil end
    local _, _, _, _, _, classID, subclassID = instant(itemID)
    return classID, subclassID
end

-- "arrow", "bullet" or nil for the ranged weapon equipped.
function Items.RangedKind()
    local id = GetInventoryItemID("player", Items.RANGED_SLOT)
    if not id then return nil end
    local classID, subclassID = Instant(id)
    if classID ~= 2 then return nil end
    if subclassID == 2 or subclassID == 18 then return "arrow" end -- bows, crossbows
    if subclassID == 3 then return "bullet" end                    -- guns
end

-- The kind of an ammo item: "arrow", "bullet" or nil.
function Items.AmmoKind(itemID)
    local classID, subclassID = Instant(itemID)
    if classID ~= 6 then return nil end
    if subclassID == 2 then return "arrow" end
    if subclassID == 3 then return "bullet" end
end

-- The equipped ammo and how many of it you carry (bags included), or nil, 0.
function Items.EquippedAmmo()
    local id = GetInventoryItemID("player", Items.AMMO_SLOT)
    local count = GetInventoryItemCount("player", Items.AMMO_SLOT) or 0
    if not id or count <= 0 then return nil, 0 end
    return id, count
end

-- The best spare ammo in the bags for the ranged weapon (most of it), when none is equipped.
function Items.SpareAmmo()
    local kind = Items.RangedKind()
    if not kind then return nil end
    local best, bestCount
    for id, count in pairs(Items.Scan(function(id) return Items.AmmoKind(id) == kind end)) do
        if not best or count > bestCount then best, bestCount = id, count end
    end
    return best, bestCount
end

function Items.FeedPetName()
    if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(Items.FEED_PET) end
    return GetSpellInfo and (GetSpellInfo(Items.FEED_PET)) or "Feed Pet"
end

-- Whether the pet is eating right now (the Feed Pet Effect buff).
function Items.PetEating()
    for i = 1, 40 do
        local spellID
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local aura = C_UnitAuras.GetAuraDataByIndex("pet", i, "HELPFUL")
            if not aura then return false end
            spellID = aura.spellId
        else
            local name, _, _, _, _, _, _, _, _, id = UnitBuff("pet", i)
            if not name then return false end
            spellID = id
        end
        if spellID == Items.FEED_PET_EFFECT then return true end
    end
    return false
end

function Items.PetDiets()
    if not (UnitExists("pet") and GetPetFoodTypes) then return nil end
    return { GetPetFoodTypes() }
end
