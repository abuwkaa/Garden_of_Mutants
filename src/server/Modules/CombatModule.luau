--!strict
--[[
    CombatModule
    Handles combat calculations and logic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local Data = Shared.Data

local CombatModule = {}

function CombatModule.CalculateDamage(attacker: any, defender: any): number
    local attackerTemplate = Data.Pets.GetPet(attacker.templateId)
    local defenderTemplate = Data.Pets.GetPet(defender.templateId)
    
    if not attackerTemplate or not defenderTemplate then
        return 0
    end
    
    local attackerStats = Utils.CalculateStats(
        attackerTemplate.baseStats,
        attacker.level,
        Utils.GetRarityMultiplier(attackerTemplate.rarity)
    )
    
    local defenderStats = Utils.CalculateStats(
        defenderTemplate.baseStats,
        defender.level,
        Utils.GetRarityMultiplier(defenderTemplate.rarity)
    )
    
    local elementBonus = Utils.GetElementBonus(attackerTemplate.element, defenderTemplate.element)
    local damage = Utils.CalculateDamage(attackerStats.atk, defenderStats.def, elementBonus)
    
    -- Apply mutation bonus
    local mutationTier = Constants.MUTATION_TIERS[attacker.mutationTier]
    if mutationTier then
        damage = math.floor(damage * mutationTier.multiplier)
    end
    
    return damage
end

function CombatModule.ApplyAbility(ability: any, attacker: any, targets: {any}): {any}
    local results = {}
    
    local abilityData = Data.Abilities.GetAbility(ability)
    if not abilityData then
        return results
    end
    
    for _, target in ipairs(targets) do
        local result = {
            targetId = target.uid,
            damage = 0,
            effects = {},
        }
        
        if abilityData.damage then
            result.damage = abilityData.damage
        end
        
        if abilityData.effect then
            table.insert(result.effects, {
                type = abilityData.effect,
                duration = abilityData.effectDuration or 0,
            })
        end
        
        table.insert(results, result)
    end
    
    return results
end

return CombatModule
