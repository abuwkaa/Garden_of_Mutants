--!strict
--[[
    Main Client Script
    Initializes all client-side systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = Shared.Remotes

print("[Client] Shared modules loaded")

-- Load controllers
local Controllers = script.Controllers
local loadedControllers = {}

local controllerLoadOrder = {
    "UIController",
    "InputController",
    "PetController",
    "CameraController",
    "FarmController",
    "PetPenController",
    "PetVisualsController",
}

-- Initialize controllers
for _, controllerName in ipairs(controllerLoadOrder) do
    local controllerModule = Controllers:FindFirstChild(controllerName)
    if controllerModule and controllerModule:IsA("ModuleScript") then
        local success, controller = pcall(require, controllerModule)
        if success then
            loadedControllers[controllerName] = controller
            if controller.Init then
                controller:Init()
                print("[Client] Controller initialized:", controllerName)
            end
        else
            warn("[Client] Failed to load controller:", controllerName, controller)
        end
    end
end

-- Start controllers
for _, controllerName in ipairs(controllerLoadOrder) do
    local controller = loadedControllers[controllerName]
    if controller and controller.Start then
        task.spawn(function()
            controller:Start()
            print("[Client] Controller started:", controllerName)
        end)
    end
end

-- Listen for data updates
Remotes.DataUpdate.OnClientEvent:Connect(function(data)
    print("[Client] Received data update")
    
    if loadedControllers.UIController then
        loadedControllers.UIController:OnDataUpdate(data)
    end
    
    if loadedControllers.FarmController and loadedControllers.FarmController.OnDataUpdate then
        loadedControllers.FarmController:OnDataUpdate(data)
    end
    
    if loadedControllers.PetPenController and loadedControllers.PetPenController.OnDataUpdate then
        loadedControllers.PetPenController:OnDataUpdate(data)
    end
    
    -- THIS IS IMPORTANT - Update pet visuals!
    if loadedControllers.PetVisualsController and loadedControllers.PetVisualsController.OnDataUpdate then
        print("[Client] Updating pet visuals...")
        loadedControllers.PetVisualsController:OnDataUpdate(data)
    end
end)

-- Listen for notifications
Remotes.Notification.OnClientEvent:Connect(function(notifType, message)
    print("[Client] Notification:", notifType, message)
    
    if loadedControllers.UIController then
        loadedControllers.UIController:ShowNotification(notifType, message)
    end
end)

print("[Client] ===== CLIENT STARTED =====")
print("[Client] Player:", LocalPlayer.Name)
