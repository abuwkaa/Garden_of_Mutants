--!strict
--[[
    EconomyService
    Handles shop, purchases, eggs, and daily rewards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Types = Shared.Types
local Utils = Shared.Utils
local Remotes = Shared.Remotes
local Data = Shared.Data

local EconomyService = {}

----- PRIVATE VARIABLES -----
local DataService
local PetService

----- INITIALIZATION -----
function EconomyService:Init()
    print("[EconomyService] Initializing...")
    DataService = require(script.Parent.DataService)
    PetService = require(script.Parent.PetService)
end

function EconomyService:Start()
    print("[EconomyService] Starting...")
    
    if Remotes.PurchaseItem then
        Remotes.PurchaseItem.OnServerEvent:Connect(function(player, itemType, itemId)
            self:PurchaseItem(player, itemType, itemId)
        end)
    end
    
    if Remotes.OpenEgg then
        Remotes.OpenEgg.OnServerEvent:Connect(function(player, eggType)
            self:OpenEgg(player, eggType)
        end)
    end
    
    if Remotes.ClaimDailyReward then
        Remotes.ClaimDailyReward.OnServerEvent:Connect(function(player)
            self:ClaimDailyReward(player)
        end)
    end
end

----- ECONOMY FUNCTIONS -----
function EconomyService:PurchaseItem(player: Player, itemType: string, itemId: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- TODO: Implement shop items
    Remotes.Notification:FireClient(player, "Info", "Shop coming soon!")
end

function EconomyService:OpenEgg(player: Player, eggType: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    local eggConfig = Constants.EGG_PRICES[eggType]
    if not eggConfig then
        Remotes.Notification:FireClient(player, "Error", "Invalid egg type!")
        return
    end
    
    -- Check currency
    local currency = eggConfig.currency
    local cost = eggConfig.amount
    
    if data.currencies[currency] < cost then
        Remotes.Notification:FireClient(player, "Error", "Not enough " .. currency .. "!")
        return
    end
    
    -- Deduct cost
    DataService:UpdateCurrency(player, currency, -cost)
    
    -- Roll rarity
    local rarity = Utils.RollRarity()
    
    -- Boost rarity for premium eggs
    if eggType == "Premium" then
        if rarity == "Common" and math.random() < 0.5 then
            rarity = "Rare"
        end
    elseif eggType == "Legendary" then
        if rarity == "Common" then
            rarity = "Rare"
        end
        if rarity == "Rare" and math.random() < 0.3 then
            rarity = "Epic"
        end
    end
    
    -- Get random pet of that rarity
    local petsOfRarity = Data.Pets.GetPetsByRarity(rarity)
    if #petsOfRarity == 0 then
        petsOfRarity = Data.Pets.GetPetsByRarity("Common")
    end
    
    local randomPet = petsOfRarity[math.random(1, #petsOfRarity)]
    local newPet = PetService:CreatePet(randomPet.id)
    
    if newPet then
        DataService:AddPet(player, newPet)
        Remotes.Notification:FireClient(player, "Success", "You got " .. randomPet.name .. " (" .. rarity .. ")!")
    end
end

function EconomyService:ClaimDailyReward(player: Player)
    local data = DataService:GetData(player)
    if not data then return end
    
    local currentTime = os.time()
    local lastLogin = data.lastLoginTime
    local daysSinceLastLogin = math.floor((currentTime - lastLogin) / 86400)
    
    -- Check if already claimed today
    if daysSinceLastLogin < 1 and lastLogin > 0 then
        Remotes.Notification:FireClient(player, "Error", "Already claimed today!")
        return
    end
    
    -- Reset streak if missed a day
    if daysSinceLastLogin > 1 then
        data.dailyLoginDay = 0
    end
    
    -- Increment day (max 7)
    data.dailyLoginDay = math.min(7, data.dailyLoginDay + 1)
    data.lastLoginTime = currentTime
    
    -- Get reward
    local reward = Constants.DAILY_REWARDS[data.dailyLoginDay]
    if reward then
        if reward.leaves then
            DataService:UpdateCurrency(player, "Leaves", reward.leaves)
        end
        if reward.gems then
            DataService:UpdateCurrency(player, "Gems", reward.gems)
        end
        if reward.bonusSeed then
            local seedsOfRarity = Data.Seeds.GetSeedsByRarity(reward.bonusSeed)
            if #seedsOfRarity > 0 then
                local randomSeed = seedsOfRarity[math.random(1, #seedsOfRarity)]
                DataService:AddSeed(player, randomSeed.id, 1)
            end
        end
        
        Remotes.Notification:FireClient(player, "Success", "Day " .. data.dailyLoginDay .. " reward claimed!")
    end
    
    Remotes.DataUpdate:FireClient(player, data)
end

return EconomyService
