--!strict
--[[
    Seed Data
    All seed templates and helper functions
]]

local SeedData = {}

SeedData.Seeds = {
    ----- COMMON SEEDS -----
    sprout_seed = {
        id = "sprout_seed",
        name = "Sprout Seed",
        rarity = "Common",
        element = "Nature",
        growthTime = 60,
        mutationChance = 0.01,
        rewards = {xpBonus = 0.05},
        description = "A basic seed that grants bonus XP.",
    },
    
    fire_bud = {
        id = "fire_bud",
        name = "Fire Bud",
        rarity = "Common",
        element = "Fire",
        growthTime = 60,
        mutationChance = 0.01,
        rewards = {statBonus = {atk = 0.03}},
        description = "A warm seed that boosts attack power.",
    },
    
    ice_bloom = {
        id = "ice_bloom",
        name = "Ice Bloom",
        rarity = "Common",
        element = "Ice",
        growthTime = 60,
        mutationChance = 0.01,
        rewards = {statBonus = {spd = 0.02}},
        description = "A cold seed that increases speed.",
    },
    
    spark_seed = {
        id = "spark_seed",
        name = "Spark Seed",
        rarity = "Common",
        element = "Tech",
        growthTime = 60,
        mutationChance = 0.01,
        rewards = {statBonus = {def = 0.03}},
        description = "An electric seed that boosts defense.",
    },
    
    shadow_spore = {
        id = "shadow_spore",
        name = "Shadow Spore",
        rarity = "Common",
        element = "Chaos",
        growthTime = 60,
        mutationChance = 0.02,
        rewards = {statBonus = {atk = 0.02, spd = 0.01}},
        description = "A dark spore with unpredictable effects.",
    },
    
    ----- RARE SEEDS -----
    lava_lily = {
        id = "lava_lily",
        name = "Lava Lily",
        rarity = "Rare",
        element = "Fire",
        growthTime = 120,
        mutationChance = 0.03,
        rewards = {statBonus = {atk = 0.07}},
        description = "A rare flower that thrives in volcanic heat.",
    },
    
    frost_fern = {
        id = "frost_fern",
        name = "Frost Fern",
        rarity = "Rare",
        element = "Ice",
        growthTime = 120,
        mutationChance = 0.03,
        rewards = {statBonus = {spd = 0.05, def = 0.02}},
        description = "A fern that grows in frozen climates.",
    },
    
    circuit_root = {
        id = "circuit_root",
        name = "Circuit Root",
        rarity = "Rare",
        element = "Tech",
        growthTime = 120,
        mutationChance = 0.03,
        rewards = {statBonus = {def = 0.05, hp = 0.03}},
        description = "A root infused with technological energy.",
    },
    
    chaos_berry = {
        id = "chaos_berry",
        name = "Chaos Berry",
        rarity = "Rare",
        element = "Chaos",
        growthTime = 120,
        mutationChance = 0.05,
        rewards = {randomStat = {min = 0.05, max = 0.10}},
        description = "A mysterious berry with random effects.",
    },
    
    ancient_acorn = {
        id = "ancient_acorn",
        name = "Ancient Acorn",
        rarity = "Rare",
        element = "Nature",
        growthTime = 120,
        mutationChance = 0.03,
        rewards = {statBonus = {hp = 0.07}},
        description = "An acorn from an ancient forest.",
    },
    
    ----- EPIC SEEDS -----
    void_mushroom = {
        id = "void_mushroom",
        name = "Void Mushroom",
        rarity = "Epic",
        element = "Chaos",
        growthTime = 300,
        mutationChance = 0.08,
        rewards = {passive = "shadow_step", statBonus = {spd = 0.05}},
        description = "A mushroom from the void dimension.",
    },
    
    prismatic_bulb = {
        id = "prismatic_bulb",
        name = "Prismatic Bulb",
        rarity = "Epic",
        element = "Nature",
        growthTime = 300,
        mutationChance = 0.08,
        rewards = {statBonus = {hp = 0.05, atk = 0.05, def = 0.05, spd = 0.05}},
        description = "A rainbow bulb that enhances all stats.",
    },
    
    plasma_core = {
        id = "plasma_core",
        name = "Plasma Core",
        rarity = "Epic",
        element = "Tech",
        growthTime = 300,
        mutationChance = 0.08,
        rewards = {passive = "energy_shield", statBonus = {def = 0.08}},
        description = "A core of pure plasma energy.",
    },
    
    inferno_heart = {
        id = "inferno_heart",
        name = "Inferno Heart",
        rarity = "Epic",
        element = "Fire",
        growthTime = 300,
        mutationChance = 0.08,
        rewards = {passive = "burn_aura", statBonus = {atk = 0.10}},
        description = "The burning heart of a fire elemental.",
    },
    
    ----- LEGENDARY SEEDS -----
    dragon_fruit = {
        id = "dragon_fruit",
        name = "Dragon Fruit",
        rarity = "Legendary",
        element = "Fire",
        growthTime = 600,
        mutationChance = 0.15,
        rewards = {passive = "dragons_might", statBonus = {atk = 0.15, hp = 0.10}},
        description = "Fruit of the legendary fire dragon.",
    },
    
    quantum_seed = {
        id = "quantum_seed",
        name = "Quantum Seed",
        rarity = "Legendary",
        element = "Tech",
        growthTime = 600,
        mutationChance = 0.15,
        rewards = {passive = "quantum_shift", statBonus = {spd = 0.15, def = 0.10}},
        description = "A seed that exists in multiple dimensions.",
    },
    
    world_tree_sapling = {
        id = "world_tree_sapling",
        name = "World Tree Sapling",
        rarity = "Legendary",
        element = "Nature",
        growthTime = 600,
        mutationChance = 0.15,
        rewards = {passive = "life_force", statBonus = {hp = 0.20, def = 0.10}},
        description = "A sapling from the mythical World Tree.",
    },
    
    void_crystal = {
        id = "void_crystal",
        name = "Void Crystal",
        rarity = "Legendary",
        element = "Chaos",
        growthTime = 600,
        mutationChance = 0.20,
        rewards = {passive = "void_corruption", statBonus = {atk = 0.12, spd = 0.12}},
        description = "A crystal formed in the heart of the void.",
    },
}

function SeedData.GetSeed(id: string)
    return SeedData.Seeds[id]
end

function SeedData.GetSeedsByElement(element: string): {any}
    local result = {}
    for _, seed in pairs(SeedData.Seeds) do
        if seed.element == element then
            table.insert(result, seed)
        end
    end
    return result
end

function SeedData.GetSeedsByRarity(rarity: string): {any}
    local result = {}
    for _, seed in pairs(SeedData.Seeds) do
        if seed.rarity == rarity then
            table.insert(result, seed)
        end
    end
    return result
end

return SeedData
