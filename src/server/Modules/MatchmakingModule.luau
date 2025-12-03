--!strict
--[[
    MatchmakingModule
    Handles MMR-based matchmaking logic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local MatchmakingModule = {}

function MatchmakingModule.FindMatch(player: Player, queue: {any}): Player?
    -- TODO: Implement MMR-based matching
    -- For now, return first available opponent
    for _, queuedPlayer in ipairs(queue) do
        if queuedPlayer ~= player then
            return queuedPlayer
        end
    end
    return nil
end

function MatchmakingModule.CalculateMMRDifference(mmr1: number, mmr2: number): number
    return math.abs(mmr1 - mmr2)
end

function MatchmakingModule.IsValidMatch(mmr1: number, mmr2: number, waitTime: number): boolean
    local baseTolerance = 100
    local tolerancePerSecond = 10
    local maxTolerance = 500
    
    local tolerance = math.min(maxTolerance, baseTolerance + (waitTime * tolerancePerSecond))
    local difference = MatchmakingModule.CalculateMMRDifference(mmr1, mmr2)
    
    return difference <= tolerance
end

return MatchmakingModule
