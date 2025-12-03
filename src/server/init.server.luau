--!strict
--[[
    Main Server Script
    Initializes all server-side systems
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
print("[Server] Shared modules loaded")

-- Load all modules first
local Modules = script.Modules
local loadedModules = {}

for _, module in ipairs(Modules:GetChildren()) do
    if module:IsA("ModuleScript") then
        local success, result = pcall(require, module)
        if success then
            loadedModules[module.Name] = result
            print("[Server] Module loaded:", module.Name)
        else
            warn("[Server] Failed to load module:", module.Name, result)
        end
    end
end

-- Generate Farm
if loadedModules.FarmMapGenerator then
    loadedModules.FarmMapGenerator.Generate()
end

-- Generate Pet Pen
if loadedModules.PetPenGenerator then
    loadedModules.PetPenGenerator.Generate()
end

-- Load and initialize services
local Services = script.Services
local loadedServices = {}

local serviceLoadOrder = {
    "DataService",
    "PetService",
    "EggService",
    "BreedingService",
    "FarmService",
    "MutationService",
    "EconomyService",
    "PvEService",
    "PvPService",
}

-- Initialize services in order
for _, serviceName in ipairs(serviceLoadOrder) do
    local serviceModule = Services:FindFirstChild(serviceName)
    if serviceModule and serviceModule:IsA("ModuleScript") then
        local success, service = pcall(require, serviceModule)
        if success then
            loadedServices[serviceName] = service
            if service.Init then
                service:Init()
                print("[Server] Service initialized:", serviceName)
            end
        else
            warn("[Server] Failed to load service:", serviceName, service)
        end
    end
end

-- Start services
for _, serviceName in ipairs(serviceLoadOrder) do
    local service = loadedServices[serviceName]
    if service and service.Start then
        task.spawn(function()
            service:Start()
            print("[Server] Service started:", serviceName)
        end)
    end
end

-- Handle player connections
Players.PlayerAdded:Connect(function(player)
    print("[Server] Player joined:", player.Name)
    
    if loadedServices.DataService then
        loadedServices.DataService:OnPlayerJoin(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    print("[Server] Player leaving:", player.Name)
    
    if loadedServices.DataService then
        loadedServices.DataService:OnPlayerLeave(player)
    end
    
    if loadedServices.EggService and loadedServices.EggService.OnPlayerLeaving then
        loadedServices.EggService:OnPlayerLeaving(player)
    end
end)

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(function()
        if loadedServices.DataService then
            loadedServices.DataService:OnPlayerJoin(player)
        end
    end)
end

print("[Server] ===== SERVER STARTED =====")
