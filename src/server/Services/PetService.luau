--!strict
--[[
    PetService
    Handles pet creation, leveling, and management
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Utils = Shared.Utils
local Data = Shared.Data
local Remotes = Shared.Remotes

local PetService = {}

local DataService

----- INITIALIZATION -----
function PetService:Init()
    print("[PetService] Initializing...")
end

function PetService:Start()
    print("[PetService] Starting...")
    
    DataService = require(script.Parent.DataService)
    
    -- Setup remote handlers
    Remotes.EquipPet.OnServerEvent:Connect(function(player, petUid, slot)
        self:EquipPet(player, petUid, slot)
    end)
    
    Remotes.UnequipPet.OnServerEvent:Connect(function(player, petUid)
        self:UnequipPet(player, petUid)
    end)
    
    Remotes.FeedPet.OnServerEvent:Connect(function(player, petUid, seedUid)
        self:FeedPet(player, petUid, seedUid)
    end)
end

----- PET CREATION -----
function PetService:CreatePet(templateId: string, rarity: string?, mutationTier: number?): any
    local template = Data.Pets.GetPet(templateId)
    if not template then
        warn("[PetService] Unknown template:", templateId)
        return nil
    end
    
    local actualRarity = rarity or template.rarity
    local rarityMult = Constants.RARITY_MULTIPLIERS[actualRarity] or 1.0
    
    -- Calculate base stats with rarity multiplier
    local baseStats = template.baseStats
    local stats = {
        hp = math.floor(baseStats.hp * rarityMult),
        atk = math.floor(baseStats.atk * rarityMult),
        def = math.floor(baseStats.def * rarityMult),
        spd = math.floor(baseStats.spd * rarityMult),
    }
    
    local pet = {
        uid = Utils.GenerateUID(),
        templateId = templateId,
        name = template.name,
        element = template.element,
        rarity = actualRarity,
        level = 1,
        xp = 0,
        stats = stats,
        baseStats = Utils.DeepCopy(stats),
        genes = self:GenerateGenes(actualRarity),
        mutationTier = mutationTier or 0,
        equipped = false,
        equippedSlot = nil,
        createdAt = os.time(),
    }
    
    print("[PetService] Created pet:", pet.name, "- Rarity:", pet.rarity)
    return pet
end

function PetService:GenerateGenes(rarity: string): {string}
    local allGenes = {"Power", "Speed", "Luck", "Harmony", "Radiance", "Entropy"}
    local geneCount = 2
    
    if rarity == "Rare" then geneCount = 2
    elseif rarity == "Epic" then geneCount = 3
    elseif rarity == "Legendary" then geneCount = 3
    end
    
    local genes = {}
    local available = Utils.DeepCopy(allGenes)
    
    for i = 1, geneCount do
        if #available == 0 then break end
        local idx = math.random(1, #available)
        table.insert(genes, available[idx])
        table.remove(available, idx)
    end
    
    return genes
end

----- GIVE PET TO PLAYER -----
function PetService:GivePet(player: Player, pet: any): boolean
    local data = DataService:GetData(player)
    if not data then return false end
    
    -- Check pet limit (50 max)
    if #data.pets >= 50 then
        Remotes.Notification:FireClient(player, "Error", "Pet inventory full! (50/50)")
        return false
    end
    
    table.insert(data.pets, pet)
    DataService:SaveData(player)
    DataService:SyncToClient(player)
    
    Remotes.Notification:FireClient(player, "Success", "New pet: " .. pet.name .. " (" .. pet.rarity .. ")!")
    print("[PetService] Gave pet to", player.Name, ":", pet.name)
    
    return true
end

----- PET LEVELING -----
function PetService:AddXP(player: Player, petUid: string, amount: number)
    local data = DataService:GetData(player)
    if not data then return end
    
    local pet = self:FindPet(data.pets, petUid)
    if not pet then return end
    
    pet.xp = pet.xp + amount
    
    -- Check for level up
    local xpRequired = Utils.CalculateXPForLevel(pet.level + 1)
    while pet.xp >= xpRequired and pet.level < Constants.MAX_PET_LEVEL do
        pet.xp = pet.xp - xpRequired
        pet.level = pet.level + 1
        
        -- Recalculate stats
        self:RecalculateStats(pet)
        
        Remotes.Notification:FireClient(player, "Success", pet.name .. " leveled up to " .. pet.level .. "!")
        
        xpRequired = Utils.CalculateXPForLevel(pet.level + 1)
    end
    
    DataService:SyncToClient(player)
end

function PetService:RecalculateStats(pet: any)
    local level = pet.level
    local base = pet.baseStats
    
    pet.stats = {
        hp = math.floor(base.hp * (1 + Constants.HP_SCALE * (level - 1))),
        atk = math.floor(base.atk * (1 + Constants.ATK_SCALE * (level - 1))),
        def = math.floor(base.def * (1 + Constants.DEF_SCALE * (level - 1))),
        spd = math.floor(base.spd * (1 + Constants.SPD_SCALE * (level - 1))),
    }
    
    -- Apply gene bonuses
    for _, gene in ipairs(pet.genes) do
        if gene == "Power" then
            pet.stats.atk = math.floor(pet.stats.atk * 1.1)
        elseif gene == "Speed" then
            pet.stats.spd = math.floor(pet.stats.spd * 1.1)
        elseif gene == "Luck" then
            -- Luck affects drops, not stats
        elseif gene == "Harmony" then
            pet.stats.hp = math.floor(pet.stats.hp * 1.05)
            pet.stats.def = math.floor(pet.stats.def * 1.05)
        elseif gene == "Radiance" then
            pet.stats.hp = math.floor(pet.stats.hp * 1.05)
            pet.stats.atk = math.floor(pet.stats.atk * 1.05)
            pet.stats.def = math.floor(pet.stats.def * 1.05)
            pet.stats.spd = math.floor(pet.stats.spd * 1.05)
        end
    end
    
    -- Apply mutation bonus
    if pet.mutationTier > 0 then
        local mutBonus = 1 + (0.1 * pet.mutationTier)
        pet.stats.hp = math.floor(pet.stats.hp * mutBonus)
        pet.stats.atk = math.floor(pet.stats.atk * mutBonus)
        pet.stats.def = math.floor(pet.stats.def * mutBonus)
        pet.stats.spd = math.floor(pet.stats.spd * mutBonus)
    end
end

----- EQUIP/UNEQUIP -----
function PetService:EquipPet(player: Player, petUid: string, slot: number)
    local data = DataService:GetData(player)
    if not data then return end
    
    if slot < 1 or slot > Constants.MAX_EQUIPPED_PETS then
        return
    end
    
    local pet = self:FindPet(data.pets, petUid)
    if not pet then return end
    
    -- Unequip any pet in this slot
    for _, p in ipairs(data.pets) do
        if p.equippedSlot == slot then
            p.equipped = false
            p.equippedSlot = nil
        end
    end
    
    -- Unequip this pet from any other slot
    pet.equipped = true
    pet.equippedSlot = slot
    
    DataService:SyncToClient(player)
    Remotes.Notification:FireClient(player, "Info", pet.name .. " equipped to slot " .. slot)
end

function PetService:UnequipPet(player: Player, petUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    local pet = self:FindPet(data.pets, petUid)
    if not pet then return end
    
    pet.equipped = false
    pet.equippedSlot = nil
    
    DataService:SyncToClient(player)
end

----- FEED PET (with seeds) -----
function PetService:FeedPet(player: Player, petUid: string, seedUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    local pet = self:FindPet(data.pets, petUid)
    if not pet then return end
    
    -- Find and remove seed
    local seedIndex = nil
    local seed = nil
    for i, s in ipairs(data.seeds) do
        if s.uid == seedUid then
            seedIndex = i
            seed = s
            break
        end
    end
    
    if not seed then
        Remotes.Notification:FireClient(player, "Error", "Seed not found!")
        return
    end
    
    -- Apply seed bonus
    local seedTemplate = Data.Seeds.GetSeed(seed.templateId)
    if seedTemplate then
        local xpGain = 50 * (Constants.RARITY_MULTIPLIERS[seedTemplate.rarity] or 1)
        self:AddXP(player, petUid, xpGain)
    end
    
    -- Remove seed
    table.remove(data.seeds, seedIndex)
    
    DataService:SyncToClient(player)
    Remotes.Notification:FireClient(player, "Success", "Fed " .. pet.name .. "!")
end

----- UTILITY -----
function PetService:FindPet(pets: {any}, uid: string): any?
    for _, pet in ipairs(pets) do
        if pet.uid == uid then
            return pet
        end
    end
    return nil
end

function PetService:GetEquippedPets(player: Player): {any}
    local data = DataService:GetData(player)
    if not data then return {} end
    
    local equipped = {}
    for _, pet in ipairs(data.pets) do
        if pet.equipped then
            table.insert(equipped, pet)
        end
    end
    
    return equipped
end

return PetService
