--!strict
--[[
    InputController
    Handles player input
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = Shared.Remotes

local InputController = {}

----- PRIVATE VARIABLES -----
local isEnabled = true

----- INITIALIZATION -----
function InputController:Init()
    print("[InputController] Initializing...")
end

function InputController:Start()
    print("[InputController] Starting...")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not isEnabled then return end
        
        self:HandleInput(input)
    end)
end

----- INPUT HANDLING -----
function InputController:HandleInput(input: InputObject)
    if input.KeyCode == Enum.KeyCode.Q then
        self:OnAbilityPressed("Q")
    elseif input.KeyCode == Enum.KeyCode.E then
        self:OnAbilityPressed("E")
    elseif input.KeyCode == Enum.KeyCode.R then
        self:OnAbilityPressed("R")
    elseif input.KeyCode == Enum.KeyCode.Tab then
        self:OnSwitchPet()
    elseif input.KeyCode == Enum.KeyCode.Space then
        self:OnDodge()
    end
end

function InputController:OnAbilityPressed(slot: string)
    print("[InputController] Ability pressed:", slot)
    -- TODO: Send to appropriate service based on game mode
end

function InputController:OnSwitchPet()
    print("[InputController] Switch pet")
end

function InputController:OnDodge()
    print("[InputController] Dodge")
end

function InputController:SetEnabled(enabled: boolean)
    isEnabled = enabled
end

return InputController
