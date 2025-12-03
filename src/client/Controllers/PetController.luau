--!strict
--[[
    PetController
    Handles pet display and animations on client
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data

local PetController = {}

----- PRIVATE VARIABLES -----
local LocalPlayer = Players.LocalPlayer
local activePets: {[string]: any} = {}

----- INITIALIZATION -----
function PetController:Init()
    print("[PetController] Initializing...")
end

function PetController:Start()
    print("[PetController] Starting...")
end

----- PET MANAGEMENT -----
function PetController:SpawnPet(petInstance: any, position: Vector3)
    local template = Data.Pets.GetPet(petInstance.templateId)
    if not template then return end
    
    -- TODO: Create pet model and animations
    print("[PetController] Spawning pet:", template.name)
    
    activePets[petInstance.uid] = {
        instance = petInstance,
        template = template,
        position = position,
    }
end

function PetController:DespawnPet(petUid: string)
    local pet = activePets[petUid]
    if pet then
        -- TODO: Remove pet model
        print("[PetController] Despawning pet:", pet.template.name)
        activePets[petUid] = nil
    end
end

function PetController:UpdatePetPosition(petUid: string, position: Vector3)
    local pet = activePets[petUid]
    if pet then
        pet.position = position
        -- TODO: Update model position
    end
end

function PetController:PlayAbilityAnimation(petUid: string, abilitySlot: string)
    local pet = activePets[petUid]
    if pet then
        -- TODO: Play ability animation
        print("[PetController] Playing ability:", abilitySlot, "for", pet.template.name)
    end
end

function PetController:OnDataUpdate(data)
    -- Update equipped pets display
    -- TODO: Sync with equipped pets
end

return PetController
