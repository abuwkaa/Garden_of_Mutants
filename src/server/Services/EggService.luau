--!strict
--[[
    EggService
    Handles egg hatching logic
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local Data = Shared.Data

local EggService = {}

local DataService
local PetService

-- Hatching state per player
local hatchingTimers: {[Player]: {[string]: number}} = {} -- player -> {eggUid -> startTime}

function EggService:Init()
    print("[EggService] Initializing...")
    
    DataService = require(script.Parent.DataService)
    PetService = require(script.Parent.PetService)
end

function EggService:Start()
    print("[EggService] Starting...")
    
    -- Setup remotes
    local Remotes = Shared.Remotes
    
    Remotes.StartHatching.OnServerEvent:Connect(function(player, eggUid)
        self:StartHatching(player, eggUid)
    end)
    
    Remotes.CollectHatchedPet.OnServerEvent:Connect(function(player, eggUid)
        self:CollectHatchedPet(player, eggUid)
    end)
    
    Remotes.SpeedUpHatching.OnServerEvent:Connect(function(player, eggUid)
        self:SpeedUpHatching(player, eggUid)
    end)
    
    -- Update loop for hatching timers
    task.spawn(function()
        while true do
            task.wait(1)
            self:UpdateAllHatching()
        end
    end)
    
    print("[EggService] Started")
end

function EggService:StartHatching(player: Player, eggUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Find egg
    local eggIndex, egg = self:FindEggByUid(data.eggs, eggUid)
    if not egg then
        warn("[EggService] Egg not found:", eggUid)
        return
    end
    
    -- Check if already hatching
    if egg.hatchingStartedAt then
        warn("[EggService] Egg already hatching:", eggUid)
        return
    end
    
    -- Start hatching
    egg.hatchingStartedAt = os.time()
    
    -- Initialize timer tracking
    if not hatchingTimers[player] then
        hatchingTimers[player] = {}
    end
    hatchingTimers[player][eggUid] = os.time()
    
    print("[EggService]", player.Name, "started hatching egg:", eggUid)
    
    -- Sync data
    DataService:SyncToClient(player)
end

function EggService:UpdateAllHatching()
    for player, eggs in pairs(hatchingTimers) do
        if not player.Parent then
            -- Player left
            hatchingTimers[player] = nil
            continue
        end
        
        local data = DataService:GetData(player)
        if not data then continue end
        
        local needsSync = false
        
        for eggUid, startTime in pairs(eggs) do
            local _, egg = self:FindEggByUid(data.eggs, eggUid)
            if egg and egg.hatchingStartedAt then
                local elapsed = os.time() - egg.hatchingStartedAt
                local hatchTime = egg.hatchTime or Constants.EGG_BASE_HATCH_TIME
                
                if elapsed >= hatchTime then
                    -- Mark as ready
                    egg.isReady = true
                    needsSync = true
                end
            end
        end
        
        if needsSync then
            DataService:SyncToClient(player)
        end
    end
end

function EggService:CollectHatchedPet(player: Player, eggUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Find egg
    local eggIndex, egg = self:FindEggByUid(data.eggs, eggUid)
    if not egg then
        warn("[EggService] Egg not found:", eggUid)
        return
    end
    
    -- Check if ready
    if not egg.hatchingStartedAt then
        warn("[EggService] Egg not hatching:", eggUid)
        return
    end
    
    local elapsed = os.time() - egg.hatchingStartedAt
    local hatchTime = egg.hatchTime or Constants.EGG_BASE_HATCH_TIME
    
    if elapsed < hatchTime then
        warn("[EggService] Egg not ready yet:", eggUid)
        return
    end
    
    -- Create pet from egg
    local newPet = self:CreatePetFromEgg(egg)
    
    -- Give pet to player
    PetService:GivePet(player, newPet)
    
    -- Remove egg
    table.remove(data.eggs, eggIndex)
    
    -- Clean up timer
    if hatchingTimers[player] then
        hatchingTimers[player][eggUid] = nil
    end
    
    print("[EggService]", player.Name, "hatched egg:", egg.rarity, egg.element, "-> Pet:", newPet.name)
    
    -- Notify client (FIXED: use "Notification" not "NotifyReward")
    -- Notify client (FIXED: use "Notification" not "NotifyReward")
    local Remotes = Shared.Remotes
    local mutantText = ""
    local tier = tonumber(newPet.mutationTier) or 0
    if tier > 0 then
        mutantText = " 🧬"
    end
    
    Remotes.Notification:FireClient(player, "Success", "New pet: " .. newPet.name .. " (" .. newPet.rarity .. ")!" .. mutantText)
    
    -- Sync data
    DataService:SyncToClient(player)
end

function EggService:SpeedUpHatching(player: Player, eggUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Find egg
    local eggIndex, egg = self:FindEggByUid(data.eggs, eggUid)
    if not egg then return end
    
    -- Check if hatching
    if not egg.hatchingStartedAt then return end
    
    -- Check gems
    local cost = Constants.EGG_SPEED_UP_COST or 100
    if data.currencies.gems < cost then
        warn("[EggService] Not enough gems for speed up")
        return
    end
    
    -- Deduct gems
    data.currencies.gems = data.currencies.gems - cost
    
    -- Instant complete
    egg.hatchingStartedAt = os.time() - (egg.hatchTime or Constants.EGG_BASE_HATCH_TIME) - 1
    egg.isReady = true
    
    print("[EggService]", player.Name, "sped up hatching for", cost, "gems")
    
    -- Sync
    DataService:SyncToClient(player)
end

function EggService:CreatePetFromEgg(egg: any): any
    local eggElement = egg.element or "Nature"
    local eggRarity = egg.rarity or "Common"
    
    print("[EggService] Creating pet from egg - Element:", eggElement, "Rarity:", eggRarity)
    
    -- Try to find matching template
    local template = nil
    
    -- 1. Try exact match (element + rarity)
    local exactMatches = Data.Pets.GetPetsByElementAndRarity(eggElement, eggRarity)
    if exactMatches and #exactMatches > 0 then
        template = exactMatches[math.random(1, #exactMatches)]
        print("[EggService] Found exact match:", template.name)
    end
    
    -- 2. Fallback: same rarity, any element
    if not template then
        local rarityMatches = Data.Pets.GetPetsByRarity(eggRarity)
        if rarityMatches and #rarityMatches > 0 then
            template = rarityMatches[math.random(1, #rarityMatches)]
            print("[EggService] Found rarity match:", template.name)
        end
    end
    
    -- 3. Fallback: same element, any rarity
    if not template then
        local elementMatches = Data.Pets.GetPetsByElement(eggElement)
        if elementMatches and #elementMatches > 0 then
            template = elementMatches[math.random(1, #elementMatches)]
            print("[EggService] Found element match:", template.name)
        end
    end
    
    -- 4. Final fallback: any pet
    if not template then
        local allPets = Data.Pets.GetAllPets()
        if allPets and #allPets > 0 then
            template = allPets[math.random(1, #allPets)]
            print("[EggService] Using random pet:", template.name)
        end
    end
    
    -- 5. Emergency fallback: hardcoded default
    if not template then
        warn("[EggService] No pet templates found! Using hardcoded default.")
        template = {
            id = "fern_fox",
            name = "Fern Fox",
            element = "Nature",
            rarity = "Common",
            baseStats = { hp = 100, atk = 20, def = 10, spd = 5 },
        }
    end
    
    -- Get mutation tier from egg
    local mutationTier = 0
    if egg.isMutant and egg.mutationTier then
        mutationTier = tonumber(egg.mutationTier) or 0
    end
    
    -- =====================================================
    -- CRITICAL FIX: PetService:CreatePet has only 3 params!
    -- Signature: CreatePet(templateId, rarity, mutationTier)
    -- NO element parameter - element comes from template!
    -- =====================================================
    
    local pet = PetService:CreatePet(
        template.id,    -- 1st: templateId (string)
        eggRarity,      -- 2nd: rarity (string: "Common", "Rare", "Epic", "Legendary")
        mutationTier    -- 3rd: mutationTier (number: 0, 1, 2, 3, 4)
    )
    
    if not pet then
        warn("[EggService] Failed to create pet from egg!")
        return nil
    end
    
    -- Override element from egg (template uses its own element, but egg may specify different)
    pet.element = eggElement
    
    -- Apply inherited genes if any
    if egg.genes and #egg.genes > 0 then
        pet.genes = egg.genes
        if PetService.RecalculateStats then
            PetService:RecalculateStats(pet)
        end
    end
    
    print("[EggService] Created pet:", pet.name, "- Element:", pet.element, "- Rarity:", pet.rarity, "- Level:", pet.level)
    
    return pet
end

function EggService:FindEggByUid(eggs: {any}, uid: string): (number?, any?)
    for i, egg in ipairs(eggs) do
        if egg.uid == uid then
            return i, egg
        end
    end
    return nil, nil
end

-- Called when player leaves
function EggService:OnPlayerLeaving(player: Player)
    hatchingTimers[player] = nil
end

return EggService
