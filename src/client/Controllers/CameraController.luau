--!strict
--[[
    CameraController
    Handles camera positioning and modes
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CameraController = {}

----- PRIVATE VARIABLES -----
local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local currentMode = "Default"

----- INITIALIZATION -----
function CameraController:Init()
    print("[CameraController] Initializing...")
end

function CameraController:Start()
    print("[CameraController] Starting...")
end

----- CAMERA MODES -----
function CameraController:SetMode(mode: string)
    currentMode = mode
    print("[CameraController] Mode set to:", mode)
    
    if mode == "Default" then
        self:SetDefaultCamera()
    elseif mode == "PvE" then
        self:SetPvECamera()
    elseif mode == "PvP" then
        self:SetPvPCamera()
    elseif mode == "Farm" then
        self:SetFarmCamera()
    end
end

function CameraController:SetDefaultCamera()
    camera.CameraType = Enum.CameraType.Custom
end

function CameraController:SetPvECamera()
    -- Top-down view for tower defense
    camera.CameraType = Enum.CameraType.Scriptable
    -- TODO: Position camera for lane view
end

function CameraController:SetPvPCamera()
    -- Third-person combat camera
    camera.CameraType = Enum.CameraType.Custom
    -- TODO: Adjust FOV and distance
end

function CameraController:SetFarmCamera()
    -- Isometric farm view
    camera.CameraType = Enum.CameraType.Scriptable
    -- TODO: Position camera for farm overview
end

function CameraController:GetCurrentMode(): string
    return currentMode
end

return CameraController
