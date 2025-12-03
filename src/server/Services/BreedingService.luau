--!strict
--[[
    BreedingService
    Handles pet pen breeding mechanics
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local Data = Shared.Data
local Remotes = Shared.Remotes

local BreedingService = {}

local DataService
local PetService

----- INITIALIZATION -----
function BreedingService:Init()
    print("[BreedingService] Initializing...")
end

function BreedingService:Start()
    print("[BreedingService] Starting...")
    
    DataService = require(script.Parent.DataService)
    PetService = require(script.Parent.PetService)
    
    -- Setup remote handlers
    Remotes.AddPetsToPen.OnServerEvent:Connect(function(player, cellIndex, petUids)
        self:AddPetsToPen(player, cellIndex, petUids)
    end)
    
    Remotes.RemovePetsFromPen.OnServerEvent:Connect(function(player, cellIndex)
        self:RemovePetsFromPen(player, cellIndex)
    end)
    
    Remotes.StartBreeding.OnServerEvent:Connect(function(player, cellIndex)
        self:StartBreeding(player, cellIndex)
    end)
    
    Remotes.CollectBreeding.OnServerEvent:Connect(function(player, cellIndex)
        self:CollectBreedingResult(player, cellIndex)
    end)
    
    -- Start breeding tick loop
    task.spawn(function()
        while true do
            self:UpdateAllBreeding()
            task.wait(1)
        end
    end)
end

----- PEN MANAGEMENT -----
function BreedingService:AddPetsToPen(player: Player, cellIndex: number, petUids: {string})
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Validate cell index
    if cellIndex < 1 or cellIndex > Constants.PEN_MAX_CELLS then
        Remotes.Notification:FireClient(player, "Error", "Invalid cell!")
        return
    end
    
    -- Check if cell is locked
    local unlockLevel = Constants.PEN_CELL_UNLOCK_LEVELS[cellIndex]
    if unlockLevel == -1 then
        Remotes.Notification:FireClient(player, "Error", "This cell requires VIP!")
        return
    elseif unlockLevel > data.level then
        Remotes.Notification:FireClient(player, "Error", "Reach level " .. unlockLevel .. " to unlock!")
        return
    end
    
    -- Validate pet count
    if #petUids < 1 or #petUids > Constants.PEN_MAX_PETS_PER_CELL then
        Remotes.Notification:FireClient(player, "Error", "Select 1-3 pets!")
        return
    end
    
    -- Validate pet ownership and availability
    local validPets = {}
    for _, uid in ipairs(petUids) do
        local pet = PetService:FindPet(data.pets, uid)
        if not pet then
            Remotes.Notification:FireClient(player, "Error", "Pet not found!")
            return
        end
        
        -- Check if pet is already in a pen
        if self:IsPetInPen(data, uid) then
            Remotes.Notification:FireClient(player, "Error", pet.name .. " is already in a pen!")
            return
        end
        
        table.insert(validPets, pet)
    end
    
    -- Initialize pen data if needed
    if not data.petPen then
        data.petPen = {cells = {}}
    end
    
    -- Clear existing cell data
    if data.petPen.cells[cellIndex] and data.petPen.cells[cellIndex].mode == "Breeding" then
        Remotes.Notification:FireClient(player, "Error", "Breeding in progress! Collect first.")
        return
    end
    
    -- Determine mode
    local mode = "Rest"
    if #petUids >= 2 then
        mode = "Idle" -- Ready to breed, but not started yet
    end
    
    -- Set cell data
    data.petPen.cells[cellIndex] = {
        pets = petUids,
        mode = mode,
        startTime = nil,
        duration = nil,
        isReady = false,
    }
    
    DataService:SyncToClient(player)
    
    local modeText = #petUids == 1 and "resting" or "ready to breed"
    Remotes.Notification:FireClient(player, "Success", #petUids .. " pet(s) added - " .. modeText)
    print("[BreedingService]", player.Name, "added", #petUids, "pets to cell", cellIndex)
end

function BreedingService:RemovePetsFromPen(player: Player, cellIndex: number)
    local data = DataService:GetData(player)
    if not data or not data.petPen then return end
    
    local cell = data.petPen.cells[cellIndex]
    if not cell then return end
    
    if cell.mode == "Breeding" and not cell.isReady then
        Remotes.Notification:FireClient(player, "Error", "Cannot remove during breeding!")
        return
    end
    
    data.petPen.cells[cellIndex] = nil
    DataService:SyncToClient(player)
    
    Remotes.Notification:FireClient(player, "Info", "Pets removed from cell " .. cellIndex)
end

function BreedingService:IsPetInPen(data: any, petUid: string): boolean
    if not data.petPen or not data.petPen.cells then
        return false
    end
    
    for _, cell in pairs(data.petPen.cells) do
        if cell.pets then
            for _, uid in ipairs(cell.pets) do
                if uid == petUid then
                    return true
                end
            end
        end
    end
    
    return false
end

----- BREEDING -----
function BreedingService:StartBreeding(player: Player, cellIndex: number)
    local data = DataService:GetData(player)
    if not data or not data.petPen then return end
    
    local cell = data.petPen.cells[cellIndex]
    if not cell then
        Remotes.Notification:FireClient(player, "Error", "Cell is empty!")
        return
    end
    
    if not cell.pets or #cell.pets < 2 then
        Remotes.Notification:FireClient(player, "Error", "Need 2-3 pets to breed!")
        return
    end
    
    if cell.mode == "Breeding" then
        Remotes.Notification:FireClient(player, "Error", "Breeding already in progress!")
        return
    end
    
    -- Calculate breeding duration
    local duration = self:CalculateBreedingDuration(data, cell.pets)
    
    -- Start breeding
    cell.mode = "Breeding"
    cell.startTime = os.time()
    cell.duration = duration
    cell.isReady = false
    
    DataService:SyncToClient(player)
    
    local minutes = math.ceil(duration / 60)
    Remotes.Notification:FireClient(player, "Success", "Breeding started! " .. minutes .. " min")
    print("[BreedingService]", player.Name, "started breeding in cell", cellIndex, "- Duration:", duration, "sec")
end

function BreedingService:CalculateBreedingDuration(data: any, petUids: {string}): number
    local petCount = #petUids
    
    -- Base time
    local baseTime = petCount == 2 and Constants.BREEDING_BASE_TIME_2_PETS or Constants.BREEDING_BASE_TIME_3_PETS
    
    -- Find highest rarity
    local highestMult = 1.0
    for _, uid in ipairs(petUids) do
        local pet = PetService:FindPet(data.pets, uid)
        if pet then
            local mult = Constants.BREEDING_RARITY_MULTIPLIERS[pet.rarity] or 1.0
            if mult > highestMult then
                highestMult = mult
            end
        end
    end
    
    -- Apply rarity multiplier
    local duration = baseTime * highestMult
    
    -- For testing, reduce time significantly
    duration = math.max(60, duration / 10) -- Min 1 minute, divide by 10 for testing
    
    return math.floor(duration)
end

function BreedingService:UpdateAllBreeding()
    for _, player in ipairs(Players:GetPlayers()) do
        local data = DataService:GetData(player)
        if data and data.petPen and data.petPen.cells then
            local needsSync = false
            
            for cellIndex, cell in pairs(data.petPen.cells) do
                if cell.mode == "Breeding" and cell.startTime and cell.duration then
                    local elapsed = os.time() - cell.startTime
                    
                    if elapsed >= cell.duration and not cell.isReady then
                        cell.isReady = true
                        needsSync = true
                        
                        Remotes.Notification:FireClient(player, "Success", "Breeding complete in cell " .. cellIndex .. "! 🎉")
                        print("[BreedingService] Breeding complete for", player.Name, "cell", cellIndex)
                    end
                end
            end
            
            if needsSync then
                DataService:SyncToClient(player)
            end
        end
    end
end

----- COLLECT RESULT -----
function BreedingService:CollectBreedingResult(player: Player, cellIndex: number)
    local data = DataService:GetData(player)
    if not data or not data.petPen then return end
    
    local cell = data.petPen.cells[cellIndex]
    if not cell then
        Remotes.Notification:FireClient(player, "Error", "Cell is empty!")
        return
    end
    
    if cell.mode ~= "Breeding" or not cell.isReady then
        Remotes.Notification:FireClient(player, "Error", "Breeding not complete!")
        return
    end
    
    -- Calculate breeding result
    local result = self:CalculateBreedingResult(data, cell.pets)
    
    -- Give rewards based on result
    if result.outcomeType == "Egg" or result.outcomeType == "GoldenEgg" then
        -- Create egg
        local egg = self:CreateEgg(result)
        if not data.eggs then data.eggs = {} end
        table.insert(data.eggs, egg)
        
        local eggType = result.outcomeType == "GoldenEgg" and "Golden Egg" or "Egg"
        Remotes.Notification:FireClient(player, "Success", "Received " .. eggType .. " (" .. result.rarity .. ")!")
        
    elseif result.outcomeType == "BabyPet" then
        -- Create pet directly
        local newPet = self:CreateOffspringPet(data, cell.pets, result)
        if newPet then
            PetService:GivePet(player, newPet)
        end
        
    elseif result.outcomeType == "Twins" then
        -- Create two pets/eggs
        for i = 1, 2 do
            local twinResult = Utils.DeepCopy(result)
            if math.random() < 0.5 then
                local egg = self:CreateEgg(twinResult)
                if not data.eggs then data.eggs = {} end
                table.insert(data.eggs, egg)
            else
                local newPet = self:CreateOffspringPet(data, cell.pets, twinResult)
                if newPet then
                    PetService:GivePet(player, newPet)
                end
            end
        end
        Remotes.Notification:FireClient(player, "Success", "TWINS! 🎉🎉")
    end
    
    -- Clear cell
    data.petPen.cells[cellIndex] = nil
    
    DataService:SyncToClient(player)
    print("[BreedingService]", player.Name, "collected breeding result:", result.outcomeType, result.rarity)
end

function BreedingService:CalculateBreedingResult(data: any, petUids: {string}): any
    local pets = {}
    local rarities = {}
    local elements = {}
    local hasMutant = false
    local hasLegendary = false
    
    for _, uid in ipairs(petUids) do
        local pet = PetService:FindPet(data.pets, uid)
        if pet then
            table.insert(pets, pet)
            table.insert(rarities, pet.rarity)
            table.insert(elements, pet.element)
            
            if pet.mutationTier > 0 then
                hasMutant = true
            end
            if pet.rarity == "Legendary" then
                hasLegendary = true
            end
        end
    end
    
    -- Calculate offspring rarity
    local offspringRarity = self:CalculateOffspringRarity(rarities)
    
    -- Calculate element
    local offspringElement = self:CalculateOffspringElement(elements)
    
    -- Calculate mutation chance
    local mutationChance = Constants.MUTATION_BASE_CHANCE
    if #pets == 3 then
        mutationChance = mutationChance + Constants.MUTATION_3_PET_BONUS
    end
    if hasMutant then
        mutationChance = mutationChance + Constants.MUTATION_MUTANT_PARENT_BONUS
    end
    if self:HasDifferentElements(elements) then
        mutationChance = mutationChance + Constants.MUTATION_DIFFERENT_ELEMENTS_BONUS
    end
    if hasLegendary then
        mutationChance = mutationChance + Constants.MUTATION_LEGENDARY_BONUS
    end
    mutationChance = math.min(mutationChance, Constants.MUTATION_MAX_CHANCE)
    
    local isMutant = math.random() < mutationChance
    local mutationTier = 0
    if isMutant then
        mutationTier = self:RollMutationTier()
    end
    
    -- Determine outcome type
    local outcomeRoll = math.random()
    local outcomeType = "Egg"
    
    if outcomeRoll < Constants.OUTCOME_GOLDEN_EGG_CHANCE then
        outcomeType = "GoldenEgg"
        offspringRarity = "Epic" -- Minimum Epic for golden egg
        if math.random() < 0.3 then
            offspringRarity = "Legendary"
        end
    elseif outcomeRoll < Constants.OUTCOME_GOLDEN_EGG_CHANCE + Constants.OUTCOME_TWINS_CHANCE then
        outcomeType = "Twins"
    elseif outcomeRoll < Constants.OUTCOME_GOLDEN_EGG_CHANCE + Constants.OUTCOME_TWINS_CHANCE + Constants.OUTCOME_BABY_PET_CHANCE then
        outcomeType = "BabyPet"
    end
    
    return {
        outcomeType = outcomeType,
        rarity = offspringRarity,
        element = offspringElement,
        isMutant = isMutant,
        mutationTier = mutationTier,
        parentPets = pets,
    }
end

function BreedingService:CalculateOffspringRarity(rarities: {string}): string
    local rarityValues = {
        Common = 1,
        Rare = 2,
        Epic = 3,
        Legendary = 4,
    }
    local rarityNames = {"Common", "Rare", "Epic", "Legendary"}
    
    -- Calculate average rarity value
    local total = 0
    for _, r in ipairs(rarities) do
        total = total + (rarityValues[r] or 1)
    end
    local avgValue = total / #rarities
    
    -- Roll for offspring rarity
    local roll = math.random()
    
    if avgValue >= 3.5 then
        -- Epic+ parents
        if roll < 0.40 then return "Legendary"
        elseif roll < 0.80 then return "Epic"
        else return "Rare"
        end
    elseif avgValue >= 2.5 then
        -- Rare-Epic parents
        if roll < 0.10 then return "Legendary"
        elseif roll < 0.45 then return "Epic"
        elseif roll < 0.90 then return "Rare"
        else return "Common"
        end
    elseif avgValue >= 1.5 then
        -- Common-Rare parents
        if roll < 0.01 then return "Legendary"
        elseif roll < 0.10 then return "Epic"
        elseif roll < 0.45 then return "Rare"
        else return "Common"
        end
    else
        -- Common parents
        if roll < 0.005 then return "Legendary"
        elseif roll < 0.05 then return "Epic"
        elseif roll < 0.25 then return "Rare"
        else return "Common"
        end
    end
end

function BreedingService:CalculateOffspringElement(elements: {string}): string
    -- Get unique elements
    local unique = {}
    for _, e in ipairs(elements) do
        if not table.find(unique, e) then
            table.insert(unique, e)
        end
    end
    
    if #unique == 1 then
        -- Same element = same element offspring
        return unique[1]
    else
        -- Different elements = random from parents
        return unique[math.random(1, #unique)]
    end
end

function BreedingService:HasDifferentElements(elements: {string}): boolean
    local first = elements[1]
    for _, e in ipairs(elements) do
        if e ~= first then
            return true
        end
    end
    return false
end

function BreedingService:RollMutationTier(): number
    local roll = math.random()
    
    if roll < 0.60 then
        return 1 -- Mutant I
    elseif roll < 0.85 then
        return 2 -- Mutant II
    elseif roll < 0.97 then
        return 3 -- Prismatic
    else
        return 4 -- Void
    end
end

----- EGG CREATION -----
function BreedingService:CreateEgg(result: any): any
    return {
        uid = Utils.GenerateUID(),
        rarity = result.rarity,
        element = result.element,
        isMutant = result.isMutant,
        mutationTier = result.mutationTier,
        hatchTime = Constants.EGG_BASE_HATCH_TIME,
        createdAt = os.time(),
    }
end

----- OFFSPRING PET CREATION -----
function BreedingService:CreateOffspringPet(data: any, parentUids: {string}, result: any): any?
    -- Get available pet templates for the element
    local availablePets = Data.Pets.GetPetsByElement(result.element)
    if not availablePets or next(availablePets) == nil then
        -- Fallback to any pet
        availablePets = Data.Pets.GetAllPets()
    end
    
    -- Pick random template
    local templates = {}
    for id, _ in pairs(availablePets) do
        table.insert(templates, id)
    end
    
    if #templates == 0 then return nil end
    
    local templateId = templates[math.random(1, #templates)]
    
    -- Create pet with inherited properties
    local pet = PetService:CreatePet(templateId, result.rarity, result.isMutant and result.mutationTier or 0)
    
    if pet then
        -- Inherit some genes from parents
        pet.genes = self:InheritGenes(data, parentUids, result.isMutant)
        
        -- Recalculate stats with new genes
        PetService:RecalculateStats(pet)
    end
    
    return pet
end

function BreedingService:InheritGenes(data: any, parentUids: {string}, isMutant: boolean): {string}
    local parentGenes = {}
    
    for _, uid in ipairs(parentUids) do
        local pet = PetService:FindPet(data.pets, uid)
        if pet and pet.genes then
            for _, gene in ipairs(pet.genes) do
                if not table.find(parentGenes, gene) then
                    table.insert(parentGenes, gene)
                end
            end
        end
    end
    
    -- Pick 2-3 genes from parents
    local genes = {}
    local geneCount = math.random(2, 3)
    
    for i = 1, geneCount do
        if #parentGenes == 0 then break end
        local idx = math.random(1, #parentGenes)
        table.insert(genes, parentGenes[idx])
        table.remove(parentGenes, idx)
    end
    
    -- Mutation can add special gene
    if isMutant and math.random() < 0.5 then
        local mutationGenes = {"Radiance", "Entropy"}
        table.insert(genes, mutationGenes[math.random(1, #mutationGenes)])
    end
    
    return genes
end

return BreedingService
