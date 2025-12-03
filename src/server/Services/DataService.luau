--!strict
--[[
    DataService
    Handles player data loading, saving, and syncing
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local Remotes = Shared.Remotes

local DataService = {}

local playerData: {[Player]: any} = {}
local dataStore
local useDataStore = false

local success, err = pcall(function()
    dataStore = DataStoreService:GetDataStore("PetGardenData_v1")
    useDataStore = true
end)

if not success then
    warn("[DataService] DataStore not available (unpublished place) - using local data")
    useDataStore = false
end

function DataService:Init()
    print("[DataService] Initializing...")
end

function DataService:Start()
    print("[DataService] Starting...")
    
    -- Setup GetPlayerData remote function
    Remotes.GetPlayerData.OnServerInvoke = function(player)
        return self:GetData(player)
    end
end

function DataService:OnPlayerJoin(player: Player)
    print("[DataService] Loading data for:", player.Name)
    
    local data = nil
    
    if useDataStore then
        local success, result = pcall(function()
            return dataStore:GetAsync("Player_" .. player.UserId)
        end)
        
        if success and result then
            data = result
        end
    end
    
    if data then
        playerData[player] = data
    else
        -- Create default data
        playerData[player] = Utils.DeepCopy(Constants.DEFAULT_PLAYER_DATA)
        playerData[player].userId = player.UserId
        
        -- Give starter seeds
        self:GiveStarterSeeds(player)
        
        -- Give starter pet for testing
        self:GiveStarterPet(player)
    end
    
    print("[DataService] Data loaded for:", player.Name)
    
    -- Sync to client
    task.wait(0.5)
    self:SyncToClient(player)
end

function DataService:GiveStarterSeeds(player: Player)
    local data = playerData[player]
    if not data then return end
    
    local starterSeeds = {
        {templateId = "sprout_seed", count = 5},
        {templateId = "fire_bud", count = 3},
        {templateId = "ice_bloom", count = 3},
        {templateId = "spark_seed", count = 2},
        {templateId = "shadow_spore", count = 2},
    }
    
    for _, seedInfo in ipairs(starterSeeds) do
        for i = 1, seedInfo.count do
            table.insert(data.seeds, {
                uid = Utils.GenerateUID(),
                templateId = seedInfo.templateId,
            })
        end
    end
    
    print("[DataService] Gave starter seeds to:", player.Name)
end

function DataService:GiveStarterPet(player: Player)
    local data = playerData[player]
    if not data then return end
    
    local PetService = require(script.Parent.PetService)
    
    -- Give one pet of each element for testing
    local starterPets = {"fern_fox", "ember_pup", "frost_bunny", "spark_bot", "shadow_cat"}
    
    for _, templateId in ipairs(starterPets) do
        local pet = PetService:CreatePet(templateId, "Common", 0)
        if pet then
            table.insert(data.pets, pet)
        end
    end
    
    -- Give one rare pet for testing breeding
    local rarePet = PetService:CreatePet("fern_fox", "Rare", 0)
    if rarePet then
        table.insert(data.pets, rarePet)
    end
    
    print("[DataService] Gave starter pets to:", player.Name)
end

function DataService:OnPlayerLeave(player: Player)
    print("[DataService] Saving data for:", player.Name)
    self:SaveData(player)
    playerData[player] = nil
    print("[DataService] Data saved for:", player.Name)
end

function DataService:GetData(player: Player): any?
    return playerData[player]
end

function DataService:UpdateData(player: Player, key: string, value: any)
    if playerData[player] then
        playerData[player][key] = value
    end
end

function DataService:SaveData(player: Player)
    local data = playerData[player]
    if not data then return end
    
    if not useDataStore then
        print("[DataService] Skipping save (no DataStore)")
        return
    end
    
    local success, err = pcall(function()
        dataStore:SetAsync("Player_" .. player.UserId, data)
    end)
    
    if not success then
        warn("[DataService] Failed to save data for", player.Name, ":", err)
    end
end

function DataService:SyncToClient(player: Player)
    local data = playerData[player]
    if data then
        Remotes.DataUpdate:FireClient(player, data)
    end
end

return DataService
