--!strict
--[[
    Ability Data
    All ability definitions
]]

local AbilityData = {}

AbilityData.Abilities = {
    ----- NATURE ABILITIES -----
    leaf_slash = {
        id = "leaf_slash",
        name = "Leaf Slash",
        element = "Nature",
        slot = "Q",
        damage = 15,
        cooldown = 2,
        description = "Slashes the enemy with sharp leaves.",
    },
    
    vine_trap = {
        id = "vine_trap",
        name = "Vine Trap",
        element = "Nature",
        slot = "E",
        damage = 10,
        effect = "root",
        effectDuration = 2,
        cooldown = 8,
        description = "Traps the enemy in vines, rooting them.",
    },
    
    forest_fury = {
        id = "forest_fury",
        name = "Forest Fury",
        element = "Nature",
        slot = "R",
        damage = 50,
        aoe = true,
        cooldown = 20,
        description = "Unleashes the fury of the forest on all enemies.",
    },
    
    bark_slam = {
        id = "bark_slam",
        name = "Bark Slam",
        element = "Nature",
        slot = "Q",
        damage = 12,
        cooldown = 3,
        description = "Slams the ground with bark-covered fists.",
    },
    
    root_shield = {
        id = "root_shield",
        name = "Root Shield",
        element = "Nature",
        slot = "E",
        effect = "shield",
        shieldAmount = 30,
        cooldown = 10,
        description = "Creates a protective shield of roots.",
    },
    
    natures_wrath = {
        id = "natures_wrath",
        name = "Nature's Wrath",
        element = "Nature",
        slot = "R",
        damage = 40,
        heal = 20,
        cooldown = 25,
        description = "Deals damage and heals allies.",
    },
    
    ----- FIRE ABILITIES -----
    flame_bite = {
        id = "flame_bite",
        name = "Flame Bite",
        element = "Fire",
        slot = "Q",
        damage = 18,
        cooldown = 2,
        description = "Bites the enemy with flaming fangs.",
    },
    
    heat_wave = {
        id = "heat_wave",
        name = "Heat Wave",
        element = "Fire",
        slot = "E",
        damage = 15,
        effect = "burn",
        effectDuration = 3,
        cooldown = 8,
        description = "Releases a wave of heat that burns enemies.",
    },
    
    inferno_burst = {
        id = "inferno_burst",
        name = "Inferno Burst",
        element = "Fire",
        slot = "R",
        damage = 60,
        aoe = true,
        cooldown = 20,
        description = "Explodes in a massive burst of fire.",
    },
    
    magma_claw = {
        id = "magma_claw",
        name = "Magma Claw",
        element = "Fire",
        slot = "Q",
        damage = 22,
        cooldown = 2,
        description = "Strikes with claws of molten magma.",
    },
    
    eruption = {
        id = "eruption",
        name = "Eruption",
        element = "Fire",
        slot = "E",
        damage = 25,
        aoe = true,
        cooldown = 10,
        description = "Causes a volcanic eruption beneath enemies.",
    },
    
    dragons_breath = {
        id = "dragons_breath",
        name = "Dragon's Breath",
        element = "Fire",
        slot = "R",
        damage = 70,
        effect = "burn",
        effectDuration = 5,
        cooldown = 22,
        description = "Breathes devastating dragon fire.",
    },
    
    ----- ICE ABILITIES -----
    ice_shard = {
        id = "ice_shard",
        name = "Ice Shard",
        element = "Ice",
        slot = "Q",
        damage = 12,
        cooldown = 2,
        description = "Fires a sharp shard of ice.",
    },
    
    freeze_field = {
        id = "freeze_field",
        name = "Freeze Field",
        element = "Ice",
        slot = "E",
        damage = 8,
        effect = "slow",
        effectDuration = 3,
        aoe = true,
        cooldown = 12,
        description = "Creates a field that slows all enemies.",
    },
    
    blizzard = {
        id = "blizzard",
        name = "Blizzard",
        element = "Ice",
        slot = "R",
        damage = 45,
        effect = "freeze",
        effectDuration = 2,
        aoe = true,
        cooldown = 30,
        description = "Summons a devastating blizzard.",
    },
    
    frost_fang = {
        id = "frost_fang",
        name = "Frost Fang",
        element = "Ice",
        slot = "Q",
        damage = 20,
        cooldown = 2,
        description = "Bites with freezing fangs.",
    },
    
    ice_howl = {
        id = "ice_howl",
        name = "Ice Howl",
        element = "Ice",
        slot = "E",
        effect = "atkDown",
        effectAmount = 0.2,
        effectDuration = 4,
        aoe = true,
        cooldown = 10,
        description = "Howls to reduce enemy attack power.",
    },
    
    arctic_storm = {
        id = "arctic_storm",
        name = "Arctic Storm",
        element = "Ice",
        slot = "R",
        damage = 55,
        effect = "slow",
        effectDuration = 3,
        aoe = true,
        cooldown = 25,
        description = "Unleashes an arctic storm.",
    },
    
    ----- TECH ABILITIES -----
    zap = {
        id = "zap",
        name = "Zap",
        element = "Tech",
        slot = "Q",
        damage = 14,
        cooldown = 3,
        description = "Zaps the enemy with electricity.",
    },
    
    shield_matrix = {
        id = "shield_matrix",
        name = "Shield Matrix",
        element = "Tech",
        slot = "E",
        effect = "shield",
        shieldAmount = 40,
        cooldown = 10,
        description = "Activates a protective energy shield.",
    },
    
    overcharge = {
        id = "overcharge",
        name = "Overcharge",
        element = "Tech",
        slot = "R",
        damage = 35,
        effect = "atkUp",
        effectAmount = 0.3,
        effectDuration = 5,
        cooldown = 25,
        description = "Overcharges systems for massive damage and attack boost.",
    },
    
    laser_strike = {
        id = "laser_strike",
        name = "Laser Strike",
        element = "Tech",
        slot = "Q",
        damage = 25,
        cooldown = 1.5,
        description = "Fires a precise laser beam.",
    },
    
    scan_target = {
        id = "scan_target",
        name = "Scan Target",
        element = "Tech",
        slot = "E",
        effect = "defDown",
        effectAmount = 0.25,
        effectDuration = 5,
        cooldown = 6,
        description = "Scans and marks enemy weak points.",
    },
    
    orbital_dive = {
        id = "orbital_dive",
        name = "Orbital Dive",
        element = "Tech",
        slot = "R",
        damage = 80,
        cooldown = 18,
        description = "Dives from orbit for massive damage.",
    },
    
    ----- CHAOS ABILITIES -----
    dark_claw = {
        id = "dark_claw",
        name = "Dark Claw",
        element = "Chaos",
        slot = "Q",
        damage = 20,
        cooldown = 1.5,
        description = "Slashes with claws of darkness.",
    },
    
    phase_shift = {
        id = "phase_shift",
        name = "Phase Shift",
        element = "Chaos",
        slot = "E",
        effect = "dodge",
        effectDuration = 2,
        cooldown = 6,
        description = "Shifts between dimensions to avoid attacks.",
    },
    
    void_strike = {
        id = "void_strike",
        name = "Void Strike",
        element = "Chaos",
        slot = "R",
        damage = 65,
        effect = "silence",
        effectDuration = 3,
        cooldown = 18,
        description = "Strikes from the void, silencing the target.",
    },
    
    chaos_bite = {
        id = "chaos_bite",
        name = "Chaos Bite",
        element = "Chaos",
        slot = "Q",
        damage = 24,
        cooldown = 2,
        description = "Bites with chaotic energy.",
    },
    
    reality_warp = {
        id = "reality_warp",
        name = "Reality Warp",
        element = "Chaos",
        slot = "E",
        effect = "confuse",
        effectDuration = 3,
        aoe = true,
        cooldown = 10,
        description = "Warps reality to confuse enemies.",
    },
    
    void_consume = {
        id = "void_consume",
        name = "Void Consume",
        element = "Chaos",
        slot = "R",
        damage = 75,
        lifesteal = 0.3,
        cooldown = 22,
        description = "Consumes the target with void energy, healing self.",
    },
}

function AbilityData.GetAbility(id: string)
    return AbilityData.Abilities[id]
end

function AbilityData.GetAbilitiesByElement(element: string): {any}
    local result = {}
    for _, ability in pairs(AbilityData.Abilities) do
        if ability.element == element then
            table.insert(result, ability)
        end
    end
    return result
end

return AbilityData
