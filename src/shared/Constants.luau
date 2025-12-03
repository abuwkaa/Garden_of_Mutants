--!strict
--[[
    Constants
    All game constants and configuration values
]]

local Constants = {}

-- Gameplay
Constants.MAX_PET_LEVEL = 50
Constants.MAX_EQUIPPED_PETS = 3
Constants.MAX_FARM_PLOTS = 12

-- Stat Scaling
Constants.HP_SCALE = 0.05
Constants.ATK_SCALE = 0.04
Constants.DEF_SCALE = 0.03
Constants.SPD_SCALE = 0.02
Constants.XP_EXPONENT = 1.5
Constants.XP_BASE = 50

-- Farm
Constants.WATER_SPEED_BONUS = 0.1
Constants.WATER_COOLDOWN = 30

-- Pet Pen
Constants.PEN_MAX_CELLS = 10
Constants.PEN_MAX_PETS_PER_CELL = 3
Constants.PEN_CELL_UNLOCK_LEVELS = {
    [1] = 0, [2] = 0, [3] = 0, [4] = 0,
    [5] = 10, [6] = 10,
    [7] = 20, [8] = 20,
    [9] = 30,
    [10] = -1, -- VIP only
}

-- Breeding
Constants.BREEDING_BASE_TIME_2_PETS = 3600 -- 60 minutes (seconds)
Constants.BREEDING_BASE_TIME_3_PETS = 2880 -- 48 minutes
Constants.BREEDING_RARITY_MULTIPLIERS = {
    Common = 1.0,
    Rare = 1.5,
    Epic = 2.0,
    Legendary = 3.0,
}

-- Mutation
Constants.MUTATION_BASE_CHANCE = 0.05
Constants.MUTATION_3_PET_BONUS = 0.10
Constants.MUTATION_MUTANT_PARENT_BONUS = 0.10
Constants.MUTATION_DIFFERENT_ELEMENTS_BONUS = 0.05
Constants.MUTATION_LEGENDARY_BONUS = 0.10
Constants.MUTATION_MAX_CHANCE = 0.50

-- Breeding Outcomes
Constants.OUTCOME_GOLDEN_EGG_CHANCE = 0.01
Constants.OUTCOME_TWINS_CHANCE = 0.04
Constants.OUTCOME_BABY_PET_CHANCE = 0.25
Constants.OUTCOME_EGG_CHANCE = 0.70

-- Rest Mode
Constants.REST_ENERGY_PER_MINUTE = 5
Constants.REST_XP_PER_MINUTE = 1

-- Egg Hatching
Constants.EGG_BASE_HATCH_TIME = 30 -- 30 seconds for testing (change to 1800 for production = 30 min)
Constants.EGG_SPEED_UP_COST = 100 -- Gems to instant-hatch

-- Economy
Constants.DEFAULT_PLAYER_DATA = {
    userId = 0,
    level = 1,
    xp = 0,
    currencies = {
        Leaves = 1000,
        Gems = 100,
        PvPTokens = 0,
        MutationShards = 0,
    },
    pets = {},
    seeds = {},
    eggs = {},
    farm = {
        plots = {},
        unlockedBiomes = {"Meadow"},
    },
    petPen = {
        cells = {},
    },
    pvp = {
        mmr = 1000,
        rank = "Bronze",
        seasonWins = 0,
    },
}

-- Rarity
Constants.RARITY_MULTIPLIERS = {
    Common = 1.0,
    Rare = 1.3,
    Epic = 1.7,
    Legendary = 2.2,
}

-- Elements
Constants.ELEMENT_CHART = {
    Nature = {strong = "Tech", weak = "Fire"},
    Fire = {strong = "Nature", weak = "Ice"},
    Ice = {strong = "Fire", weak = "Tech"},
    Tech = {strong = "Ice", weak = "Chaos"},
    Chaos = {strong = nil, weak = nil},
}

return Constants
