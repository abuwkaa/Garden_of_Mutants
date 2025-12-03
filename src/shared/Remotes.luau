--!strict
--[[
    Remotes
    Creates and stores all RemoteEvents and RemoteFunctions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

-- Create Remotes folder
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

-- Remote Events list
local eventNames = {
    -- Data
    "DataUpdate",
    "Notification",
    
    -- Farm
    "PlantSeed",
    "HarvestPlot",
    "WaterPlot",
    
    -- Pets
    "EquipPet",
    "UnequipPet",
    "FeedPet",
    
    -- Pet Pen / Breeding
    "AddPetsToPen",
    "RemovePetsFromPen",
    "StartBreeding",
    "CollectBreeding",
    
    -- Eggs (NEW)
    "StartHatching",
    "CollectHatchedPet",
    "SpeedUpHatching",
    
    -- Economy
    "Purchase",
    "OpenEgg",
    
    -- PvE
    "JoinPvE",
    "LeavePvE",
    "UseAbility",
    
    -- PvP
    "JoinPvP",
    "LeavePvP",
}

-- Remote Functions list
local functionNames = {
    "GetPlayerData",
    "GetLeaderboard",
}

-- Create RemoteEvents
for _, name in ipairs(eventNames) do
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    Remotes[name] = remote
end

-- Create RemoteFunctions
for _, name in ipairs(functionNames) do
    local remote = remotesFolder:FindFirstChild(name)
    if not remote then
        remote = Instance.new("RemoteFunction")
        remote.Name = name
        remote.Parent = remotesFolder
    end
    Remotes[name] = remote
end

return Remotes
