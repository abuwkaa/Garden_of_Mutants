--!strict
--[[
    Enemy Data
    All enemy (Brainrot) definitions for PvE
]]

local EnemyData = {}

EnemyData.Enemies = {
    ----- BASIC ENEMIES -----
    brainrot_basic = {
        id = "brainrot_basic",
        name = "Brainrot",
        element = "Chaos",
        baseHp = 50,
        baseAtk = 5,
        baseSpd = 1,
        special = nil,
        description = "A basic corrupted creature.",
    },
    
    brainrot_speeder = {
        id = "brainrot_speeder",
        name = "Brainrot Speeder",
        element = "Chaos",
        baseHp = 30,
        baseAtk = 3,
        baseSpd = 3,
        special = "fast",
        description = "A quick corrupted creature.",
    },
    
    brainrot_tank = {
        id = "brainrot_tank",
        name = "Brainrot Tank",
        element = "Chaos",
        baseHp = 150,
        baseAtk = 8,
        baseSpd = 0.5,
        special = "armor",
        description = "A heavily armored corrupted creature.",
    },
    
    brainrot_bomber = {
        id = "brainrot_bomber",
        name = "Brainrot Bomber",
        element = "Chaos",
        baseHp = 40,
        baseAtk = 20,
        baseSpd = 1,
        special = "explode",
        description = "Explodes on death dealing AoE damage.",
    },
    
    brainrot_healer = {
        id = "brainrot_healer",
        name = "Brainrot Healer",
        element = "Chaos",
        baseHp = 60,
        baseAtk = 2,
        baseSpd = 1,
        special = "heal",
        description = "Heals nearby enemies.",
    },
    
    ----- ELEMENTAL ENEMIES -----
    flame_brainrot = {
        id = "flame_brainrot",
        name = "Flame Brainrot",
        element = "Fire",
        baseHp = 70,
        baseAtk = 12,
        baseSpd = 1.2,
        special = "burn",
        description = "A fire-infused corrupted creature.",
    },
    
    frost_brainrot = {
        id = "frost_brainrot",
        name = "Frost Brainrot",
        element = "Ice",
        baseHp = 70,
        baseAtk = 8,
        baseSpd = 0.8,
        special = "slow",
        description = "An ice-infused corrupted creature.",
    },
    
    tech_brainrot = {
        id = "tech_brainrot",
        name = "Tech Brainrot",
        element = "Tech",
        baseHp = 80,
        baseAtk = 10,
        baseSpd = 1,
        special = "shield",
        description = "A tech-infused corrupted creature.",
    },
    
    nature_brainrot = {
        id = "nature_brainrot",
        name = "Nature Brainrot",
        element = "Nature",
        baseHp = 90,
        baseAtk = 6,
        baseSpd = 1,
        special = "regen",
        description = "A nature-infused corrupted creature.",
    },
    
    ----- BOSSES -----
    brainrot_boss = {
        id = "brainrot_boss",
        name = "Brainrot Overlord",
        element = "Chaos",
        baseHp = 500,
        baseAtk = 15,
        baseSpd = 1,
        special = "summon",
        isBoss = true,
        description = "The leader of the Brainrot horde.",
    },
    
    inferno_boss = {
        id = "inferno_boss",
        name = "Inferno Lord",
        element = "Fire",
        baseHp = 600,
        baseAtk = 20,
        baseSpd = 1.2,
        special = "meteor",
        isBoss = true,
        description = "A massive fire elemental boss.",
    },
    
    glacier_boss = {
        id = "glacier_boss",
        name = "Glacier Titan",
        element = "Ice",
        baseHp = 700,
        baseAtk = 12,
        baseSpd = 0.7,
        special = "freeze_all",
        isBoss = true,
        description = "An enormous ice titan.",
    },
    
    mech_boss = {
        id = "mech_boss",
        name = "Mech Destroyer",
        element = "Tech",
        baseHp = 650,
        baseAtk = 18,
        baseSpd = 1,
        special = "laser_barrage",
        isBoss = true,
        description = "A massive war machine.",
    },
    
    void_boss = {
        id = "void_boss",
        name = "Void Emperor",
        element = "Chaos",
        baseHp = 800,
        baseAtk = 25,
        baseSpd = 1.5,
        special = "void_rift",
        isBoss = true,
        description = "The ultimate chaos entity.",
    },
}

function EnemyData.GetEnemy(id: string)
    return EnemyData.Enemies[id]
end

function EnemyData.GetEnemiesByElement(element: string): {any}
    local result = {}
    for _, enemy in pairs(EnemyData.Enemies) do
        if enemy.element == element then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetBosses(): {any}
    local result = {}
    for _, enemy in pairs(EnemyData.Enemies) do
        if enemy.isBoss then
            table.insert(result, enemy)
        end
    end
    return result
end

function EnemyData.GetRegularEnemies(): {any}
    local result = {}
    for _, enemy in pairs(EnemyData.Enemies) do
        if not enemy.isBoss then
            table.insert(result, enemy)
        end
    end
    return result
end

return EnemyData
