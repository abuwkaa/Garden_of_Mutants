--!strict
--[[
    RewardModule
    Handles reward calculations and distribution
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils

local RewardModule = {}

function RewardModule.CalculatePvERewards(wave: number, biome: string): {leaves: number, shards: number, seeds: {string}?}
    local baseLeaves = 50
    local baseShards = 5
    
    local rewards = {
        leaves = baseLeaves * wave,
        shards = baseShards * wave,
        seeds = nil,
    }
    
    -- Bonus rewards at milestone waves
    local milestoneReward = Constants.WAVE_REWARDS[wave]
    if milestoneReward then
        rewards.leaves = rewards.leaves + (milestoneReward.leaves or 0)
        rewards.shards = rewards.shards + (milestoneReward.shards or 0)
    end
    
    return rewards
end

function RewardModule.CalculatePvPRewards(isWinner: boolean, winStreak: number): {tokens: number, leaves: number}
    local rewards
    if isWinner then
        rewards = Utils.DeepCopy(Constants.PVP_REWARDS.Win)
        if winStreak >= 3 then
            rewards.tokens = math.floor(rewards.tokens * (1 + Constants.PVP_REWARDS.WinStreakBonus))
        end
    else
        rewards = Utils.DeepCopy(Constants.PVP_REWARDS.Lose)
    end
    
    return rewards
end

function RewardModule.CalculateHarvestRewards(seedRarity: string, isWatered: boolean, isFertilized: boolean): {leaves: number, shards: number}
    local baseLeaves = 50
    local baseShards = 5
    
    local multiplier = Utils.GetRarityMultiplier(seedRarity)
    
    local rewards = {
        leaves = math.floor(baseLeaves * multiplier),
        shards = math.floor(baseShards * multiplier),
    }
    
    if isFertilized then
        rewards.leaves = math.floor(rewards.leaves * (1 + Constants.FERTILIZE_REWARD_BONUS))
        rewards.shards = math.floor(rewards.shards * (1 + Constants.FERTILIZE_REWARD_BONUS))
    end
    
    return rewards
end

return RewardModule
