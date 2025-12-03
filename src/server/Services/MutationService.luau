--!strict
--[[
    MutationService
    Handles pet mutations and gene system
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Types = Shared.Types
local Utils = Shared.Utils
local Remotes = Shared.Remotes
local Data = Shared.Data

local MutationService = {}

----- PRIVATE VARIABLES -----
local DataService
local PetService
local activeMutations: {[Player]: {startTime: number, petUid: string, components: any}} = {}

----- INITIALIZATION -----
function MutationService:Init()
    print("[MutationService] Initializing...")
    DataService = require(script.Parent.DataService)
    PetService = require(script.Parent.PetService)
end

function MutationService:Start()
    print("[MutationService] Starting...")
    
    if Remotes.StartMutation then
        Remotes.StartMutation.OnServerEvent:Connect(function(player, petUid, seedUids, useCatalyst)
            self:StartMutation(player, petUid, seedUids, useCatalyst)
        end)
    end
    
    if Remotes.ClaimMutation then
        Remotes.ClaimMutation.OnServerEvent:Connect(function(player)
            self:ClaimMutation(player)
        end)
    end
    
    if Remotes.GetMutationPreview then
        Remotes.GetMutationPreview.OnServerInvoke = function(player, petUid, seedUids, useCatalyst)
            return self:GetMutationPreview(player, petUid, seedUids, useCatalyst)
        end
    end
end

----- MUTATION LOGIC -----
function MutationService:CalculateMutationChance(petRarity: string, seedRarities: {string}, useCatalyst: boolean, pityAttempts: number): {epic: number, legendary: number}
    local baseChance = Constants.MUTATION_BASE_CHANCE.CommonCommon
    
    -- Determine best rarity combo
    local hasRare = false
    local hasEpic = false
    
    if petRarity == "Rare" or petRarity == "Epic" or petRarity == "Legendary" then
        hasRare = true
    end
    if petRarity == "Epic" or petRarity == "Legendary" then
        hasEpic = true
    end
    
    for _, rarity in ipairs(seedRarities) do
        if rarity == "Rare" or rarity == "Epic" or rarity == "Legendary" then
            hasRare = true
        end
        if rarity == "Epic" or rarity == "Legendary" then
            hasEpic = true
        end
    end
    
    if hasEpic then
        baseChance = Constants.MUTATION_BASE_CHANCE.EpicEpic
    elseif hasRare then
        baseChance = Constants.MUTATION_BASE_CHANCE.RareRare
    end
    
    local epicChance = baseChance.epic
    local legendaryChance = baseChance.legendary
    
    -- Apply catalyst bonus
    if useCatalyst then
        epicChance = epicChance * Constants.MUTATION_CATALYST_MULTIPLIER
        legendaryChance = legendaryChance * Constants.MUTATION_CATALYST_MULTIPLIER
    end
    
    -- Apply pity bonus
    if pityAttempts >= Constants.PITY_THRESHOLD then
        local pityBonus = (pityAttempts - Constants.PITY_THRESHOLD) * Constants.PITY_BONUS_PER_ATTEMPT
        epicChance = epicChance + pityBonus
        legendaryChance = legendaryChance + (pityBonus * 0.5)
    end
    
    -- Guaranteed pity
    if pityAttempts >= Constants.GUARANTEED_LEGENDARY_AT then
        legendaryChance = 1.0
    elseif pityAttempts >= Constants.GUARANTEED_EPIC_AT then
        epicChance = 1.0
    end
    
    return {
        epic = math.min(1.0, epicChance),
        legendary = math.min(1.0, legendaryChance),
    }
end

function MutationService:GetMutationPreview(player: Player, petUid: string, seedUids: {string}, useCatalyst: boolean): any
    local data = DataService:GetData(player)
    if not data then return nil end
    
    -- Find pet
    local pet: Types.PetInstance? = nil
    for _, p in ipairs(data.pets) do
        if p.uid == petUid then
            pet = p
            break
        end
    end
    
    if not pet then return nil end
    
    local petTemplate = Data.Pets.GetPet(pet.templateId)
    if not petTemplate then return nil end
    
    -- Get seed rarities
    local seedRarities = {}
    for _, seedUid in ipairs(seedUids) do
        for _, seed in ipairs(data.seeds) do
            if seed.uid == seedUid then
                local seedTemplate = Data.Seeds.GetSeed(seed.templateId)
                if seedTemplate then
                    table.insert(seedRarities, seedTemplate.rarity)
                end
                break
            end
        end
    end
    
    local chances = self:CalculateMutationChance(
        petTemplate.rarity,
        seedRarities,
        useCatalyst,
        data.mutationPity.attempts
    )
    
    return {
        epicChance = chances.epic,
        legendaryChance = chances.legendary,
        duration = Constants.MUTATION_DURATION,
        pityAttempts = data.mutationPity.attempts,
    }
end

function MutationService:StartMutation(player: Player, petUid: string, seedUids: {string}, useCatalyst: boolean)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Check if already mutating
    if activeMutations[player] then
        Remotes.Notification:FireClient(player, "Error", "Mutation already in progress!")
        return
    end
    
    -- Validate inputs
    if #seedUids < 2 or #seedUids > 5 then
        Remotes.Notification:FireClient(player, "Error", "Need 2-5 seeds for mutation!")
        return
    end
    
    -- TODO: Validate pet and seeds exist, consume resources
    
    activeMutations[player] = {
        startTime = os.time(),
        petUid = petUid,
        components = {seedUids = seedUids, useCatalyst = useCatalyst},
    }
    
    data.mutationPity.attempts = data.mutationPity.attempts + 1
    Remotes.DataUpdate:FireClient(player, data)
    Remotes.Notification:FireClient(player, "Success", "Mutation started! Check back later.")
end

function MutationService:ClaimMutation(player: Player)
    local mutation = activeMutations[player]
    if not mutation then
        Remotes.Notification:FireClient(player, "Error", "No mutation in progress!")
        return
    end
    
    local elapsed = os.time() - mutation.startTime
    if elapsed < Constants.MUTATION_DURATION then
        local remaining = Constants.MUTATION_DURATION - elapsed
        Remotes.Notification:FireClient(player, "Error", "Mutation not ready! " .. Utils.FormatTimeHMS(remaining) .. " remaining")
        return
    end
    
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Calculate result
    -- TODO: Full mutation logic
    local roll = math.random()
    local resultTier = 1 -- Mutant I by default
    
    if roll < 0.05 then
        resultTier = 3 -- Prismatic
        data.mutationPity.attempts = 0
    elseif roll < 0.15 then
        resultTier = 2 -- Mutant II
        data.mutationPity.attempts = 0
    end
    
    -- Update pet
    for _, pet in ipairs(data.pets) do
        if pet.uid == mutation.petUid then
            pet.mutationTier = resultTier
            break
        end
    end
    
    activeMutations[player] = nil
    
    local tierName = Constants.MUTATION_TIERS[resultTier].name
    Remotes.DataUpdate:FireClient(player, data)
    Remotes.MutationComplete:FireClient(player, {tier = resultTier, tierName = tierName})
    Remotes.Notification:FireClient(player, "Success", "Mutation complete! Result: " .. tierName)
end

return MutationService
