--!strict
--[[
    PetPenController
    Handles client-side Pet Pen interactions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = Shared.Remotes
local Constants = Shared.Constants

local PetPenController = {}

local LocalPlayer = Players.LocalPlayer
local UIController
local PetPenUI
local PetSelectModal
local PetVisualsController

function PetPenController:Init()
    print("[PetPenController] Initializing...")
end

function PetPenController:Start()
    print("[PetPenController] Starting...")
    
    UIController = require(script.Parent.UIController)
    PetVisualsController = require(script.Parent.PetVisualsController)
    
    local UI = require(script.Parent.Parent.UI)
    PetPenUI = UI.Screens.PetPenUI
    PetSelectModal = UI.Screens.PetSelectModal
    
    -- Create UI
    PetPenUI:Create()
    PetSelectModal:Create()
    
    -- Setup 3D pen interactions
    self:SetupPenInteractions()
    
    print("[PetPenController] Pet Pen interactions setup complete")
end

function PetPenController:SetupPenInteractions()
    local petPen = workspace:WaitForChild("PetPen", 10)
    if not petPen then
        warn("[PetPenController] PetPen not found in workspace!")
        return
    end
    
    local cells = petPen:FindFirstChild("Cells")
    if not cells then return end
    
    for _, cell in ipairs(cells:GetChildren()) do
        local interactZone = cell:FindFirstChild("InteractZone")
        if interactZone then
            local clickDetector = interactZone:FindFirstChild("CellClick")
            if clickDetector then
                clickDetector.MouseClick:Connect(function()
                    self:OnCellClicked(cell)
                end)
            end
        end
    end
end

function PetPenController:OnCellClicked(cell: Model)
    local indexValue = cell:FindFirstChild("CellIndex")
    if not indexValue then return end
    
    local index = indexValue.Value
    print("[PetPenController] Cell clicked:", index)
    
    -- Open Pet Pen UI and select this cell
    self:OpenPetPenUI()
    
    task.wait(0.1)
    PetPenUI:SelectCell(index)
end

function PetPenController:OpenPetPenUI()
    if not PetPenUI then return end
    
    local playerData = UIController:GetPlayerData()
    if not playerData then return end
    
    PetPenUI:UpdateCells(playerData.petPen, playerData.pets)
    PetPenUI:Open()
end

function PetPenController:ClosePetPenUI()
    if PetPenUI then
        PetPenUI:Close()
    end
end

function PetPenController:OpenPetSelection(cellIndex: number)
    local playerData = UIController:GetPlayerData()
    if not playerData then return end
    
    local excludedPets = {}
    if playerData.petPen and playerData.petPen.cells then
        for _, cellData in pairs(playerData.petPen.cells) do
            if cellData.pets then
                for _, petUid in ipairs(cellData.pets) do
                    table.insert(excludedPets, petUid)
                end
            end
        end
    end
    
    PetSelectModal:PopulatePets(playerData.pets, excludedPets)
    PetSelectModal:Open(function(selectedPets)
        self:OnPetsSelected(cellIndex, selectedPets)
    end, Constants.PEN_MAX_PETS_PER_CELL)
end

function PetPenController:OnPetsSelected(cellIndex: number, petUids: {string})
    print("[PetPenController] Pets selected for cell", cellIndex, ":", #petUids, "pets")
    Remotes.AddPetsToPen:FireServer(cellIndex, petUids)
end

function PetPenController:StartBreeding(cellIndex: number)
    print("[PetPenController] Starting breeding in cell:", cellIndex)
    Remotes.StartBreeding:FireServer(cellIndex)
end

function PetPenController:CollectBreedingResult(cellIndex: number)
    print("[PetPenController] Collecting breeding result from cell:", cellIndex)
    Remotes.CollectBreeding:FireServer(cellIndex)
end

function PetPenController:OnDataUpdate(data)
    -- Update UI
    if PetPenUI and PetPenUI:IsOpen() then
        PetPenUI:UpdateCells(data.petPen, data.pets)
    end
    
    -- Update 3D visuals (handled by PetVisualsController via main client script)
end

return PetPenController
