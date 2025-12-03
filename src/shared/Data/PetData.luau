--!strict
--[[
    PetData
    Contains all pet templates and helper functions
]]

local PetData = {}

-- Pet Templates
PetData.Pets = {
    -- Nature
    fern_fox = {
        id = "fern_fox",
        name = "Fern Fox",
        element = "Nature",
        rarity = "Common",
        baseStats = { hp = 100, atk = 20, def = 10, spd = 5 },
        abilities = { Q = "Leaf Slash", E = "Vine Trap", R = "Forest Fury" },
    },
    
    -- Fire
    ember_pup = {
        id = "ember_pup",
        name = "Ember Pup",
        element = "Fire",
        rarity = "Common",
        baseStats = { hp = 90, atk = 25, def = 8, spd = 6 },
        abilities = { Q = "Flame Bite", E = "Heat Wave", R = "Inferno Burst" },
    },
    
    -- Ice
    frost_bunny = {
        id = "frost_bunny",
        name = "Frost Bunny",
        element = "Ice",
        rarity = "Common",
        baseStats = { hp = 85, atk = 18, def = 12, spd = 8 },
        abilities = { Q = "Ice Shard", E = "Freeze Field", R = "Blizzard" },
    },
    
    -- Tech
    spark_bot = {
        id = "spark_bot",
        name = "Spark Bot",
        element = "Tech",
        rarity = "Common",
        baseStats = { hp = 120, atk = 15, def = 15, spd = 4 },
        abilities = { Q = "Zap", E = "Shield Up", R = "Overcharge" },
    },
    
    -- Chaos
    shadow_cat = {
        id = "shadow_cat",
        name = "Shadow Cat",
        element = "Chaos",
        rarity = "Common",
        baseStats = { hp = 80, atk = 28, def = 6, spd = 10 },
        abilities = { Q = "Dark Claw", E = "Phase Shift", R = "Void Strike" },
    },
    
    -- Rare pets
    blaze_wolf = {
        id = "blaze_wolf",
        name = "Blaze Wolf",
        element = "Fire",
        rarity = "Rare",
        baseStats = { hp = 110, atk = 32, def = 12, spd = 7 },
        abilities = { Q = "Fire Fang", E = "Flame Dash", R = "Wildfire" },
    },
    
    crystal_deer = {
        id = "crystal_deer",
        name = "Crystal Deer",
        element = "Ice",
        rarity = "Rare",
        baseStats = { hp = 100, atk = 22, def = 18, spd = 9 },
        abilities = { Q = "Frost Horn", E = "Ice Shield", R = "Aurora Beam" },
    },
    
    vine_serpent = {
        id = "vine_serpent",
        name = "Vine Serpent",
        element = "Nature",
        rarity = "Rare",
        baseStats = { hp = 95, atk = 30, def = 10, spd = 8 },
        abilities = { Q = "Poison Bite", E = "Constrict", R = "Nature's Wrath" },
    },
    
    cyber_hawk = {
        id = "cyber_hawk",
        name = "Cyber Hawk",
        element = "Tech",
        rarity = "Rare",
        baseStats = { hp = 85, atk = 28, def = 10, spd = 12 },
        abilities = { Q = "Laser Shot", E = "Scan", R = "Missile Barrage" },
    },
    
    void_raven = {
        id = "void_raven",
        name = "Void Raven",
        element = "Chaos",
        rarity = "Rare",
        baseStats = { hp = 90, atk = 35, def = 8, spd = 11 },
        abilities = { Q = "Shadow Strike", E = "Dark Mist", R = "Chaos Rift" },
    },
}

-- Cache for faster lookups
local allPetsCache: {any}? = nil
local petsByElementCache: {[string]: {any}} = {}
local petsByRarityCache: {[string]: {any}} = {}

-- Clear caches (call if you modify Pets table dynamically)
function PetData.ClearCache()
    allPetsCache = nil
    petsByElementCache = {}
    petsByRarityCache = {}
end

-- Get all pets as array
function PetData.GetAllPets(): {any}
    if allPetsCache then
        return allPetsCache
    end
    
    local result = {}
    for _, pet in pairs(PetData.Pets) do
        table.insert(result, pet)
    end
    
    allPetsCache = result
    return result
end

-- Get pet by ID
function PetData.GetPet(petId: string): any?
    return PetData.Pets[petId]
end

-- Get pets by element
function PetData.GetPetsByElement(element: string): {any}
    if petsByElementCache[element] then
        return petsByElementCache[element]
    end
    
    local result = {}
    for _, pet in pairs(PetData.Pets) do
        if pet.element == element then
            table.insert(result, pet)
        end
    end
    
    petsByElementCache[element] = result
    return result
end

-- Get pets by rarity
function PetData.GetPetsByRarity(rarity: string): {any}
    if petsByRarityCache[rarity] then
        return petsByRarityCache[rarity]
    end
    
    local result = {}
    for _, pet in pairs(PetData.Pets) do
        if pet.rarity == rarity then
            table.insert(result, pet)
        end
    end
    
    petsByRarityCache[rarity] = result
    return result
end

-- Get pets by element AND rarity
function PetData.GetPetsByElementAndRarity(element: string, rarity: string): {any}
    local result = {}
    for _, pet in pairs(PetData.Pets) do
        if pet.element == element and pet.rarity == rarity then
            table.insert(result, pet)
        end
    end
    return result
end

-- Get random pet template
function PetData.GetRandomPet(): any
    local allPets = PetData.GetAllPets()
    if #allPets == 0 then
        return nil
    end
    return allPets[math.random(1, #allPets)]
end

-- Get random pet by element
function PetData.GetRandomPetByElement(element: string): any?
    local pets = PetData.GetPetsByElement(element)
    if #pets == 0 then
        return nil
    end
    return pets[math.random(1, #pets)]
end

-- Get random pet by rarity
function PetData.GetRandomPetByRarity(rarity: string): any?
    local pets = PetData.GetPetsByRarity(rarity)
    if #pets == 0 then
        return nil
    end
    return pets[math.random(1, #pets)]
end

return PetData
