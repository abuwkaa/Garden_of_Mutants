--!strict
--[[
    Utils
    Shared utility functions
]]

local Utils = {}

function Utils.GenerateUID(): string
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local uid = ""
    for i = 1, 16 do
        local idx = math.random(1, #chars)
        uid = uid .. chars:sub(idx, idx)
    end
    return uid
end

function Utils.FormatNumber(num: number): string
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return tostring(math.floor(num))
    end
end

function Utils.FormatTime(seconds: number): string
    if seconds <= 0 then
        return "0:00"
    end
    
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    
    if mins >= 60 then
        local hours = math.floor(mins / 60)
        mins = mins % 60
        return string.format("%d:%02d:%02d", hours, mins, secs)
    end
    
    return string.format("%d:%02d", mins, secs)
end

function Utils.DeepCopy(original: any): any
    if type(original) ~= "table" then
        return original
    end
    
    local copy = {}
    for key, value in pairs(original) do
        copy[Utils.DeepCopy(key)] = Utils.DeepCopy(value)
    end
    
    return copy
end

function Utils.GetRarityMultiplier(rarity: string): number
    local multipliers = {
        Common = 1.0,
        Rare = 1.3,
        Epic = 1.7,
        Legendary = 2.2,
    }
    return multipliers[rarity] or 1.0
end

function Utils.CalculateXPForLevel(level: number): number
    return math.floor(50 * level ^ 1.5)
end

function Utils.CalculateStatForLevel(baseStat: number, level: number, scale: number): number
    return math.floor(baseStat * (1 + scale * (level - 1)))
end

return Utils
