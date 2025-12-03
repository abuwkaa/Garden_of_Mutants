--!strict
--[[
    UIController - Fixed version
    Uses correct remote names: DataUpdate, Notification (not DataUpdated, NotifyReward)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = Shared.Remotes

local UIController = {}

local LocalPlayer = Players.LocalPlayer
local playerData = nil

-- UI Screens
local FarmHUD
local SeedPanel
local PlotInfoPanel
local NotificationSystem
local PetInventory
local PetDetails
local PetPenUI
local EggInventory

function UIController:Init()
    print("[UIController] Initializing...")
    
    local UI = require(script.Parent.Parent.UI)
    local Screens = UI.Screens
    
    FarmHUD = Screens.FarmHUD
    SeedPanel = Screens.SeedPanel
    PlotInfoPanel = Screens.PlotInfoPanel
    NotificationSystem = Screens.NotificationSystem
    PetInventory = Screens.PetInventory
    PetDetails = Screens.PetDetails
    PetPenUI = Screens.PetPenUI
    EggInventory = Screens.EggInventory
end

function UIController:Start()
    print("[UIController] Starting...")
    
    -- Create UI screens
    FarmHUD:Create()
    SeedPanel:Create()
    PlotInfoPanel:Create()
    NotificationSystem:Create()
    PetInventory:Create()
    PetDetails:Create()
    EggInventory:Create()
    
    -- Setup PlotInfoPanel callbacks
    PlotInfoPanel:SetCallbacks(
        function() self:OnPlantRequested() end,
        function() self:OnHarvestRequested() end,
        function() self:OnWaterRequested() end
    )
    
    -- Keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.P then
            self:TogglePetInventory()
        elseif input.KeyCode == Enum.KeyCode.B then
            self:TogglePetPen()
        elseif input.KeyCode == Enum.KeyCode.G then
            self:ToggleEggInventory()
        end
    end)
    
    -- Listen for notifications (FIXED: use "Notification" not "NotifyReward")
    if Remotes.Notification then
        Remotes.Notification.OnClientEvent:Connect(function(notifType, message)
            self:ShowNotification(notifType, message)
        end)
    end
    
    -- Request initial data
    task.spawn(function()
        playerData = Remotes.GetPlayerData:InvokeServer()
        if playerData then
            print("[UIController] Initial data received")
            self:UpdateAllUI()
        end
    end)
    
    print("[UIController] Started")
end

----- DATA UPDATES -----
function UIController:OnDataUpdate(data)
    playerData = data
    self:UpdateAllUI()
end

function UIController:GetPlayerData()
    return playerData
end

----- UI UPDATES -----
function UIController:UpdateAllUI()
    if not playerData then return end
    
    self:UpdateCurrencyUI()
    self:UpdateSeedPanel()
    self:UpdatePetInventory()
    self:UpdateEggInventory()
end

function UIController:UpdateCurrencyUI()
    if playerData and FarmHUD then
        FarmHUD:UpdateCurrencies(playerData.currencies)
    end
end

function UIController:UpdateSeedPanel()
    if playerData and SeedPanel then
        SeedPanel:PopulateSeeds(playerData.seeds)
    end
end

function UIController:UpdatePetInventory()
    if playerData and PetInventory and PetInventory:IsOpen() then
        PetInventory:PopulatePets(playerData.pets)
    end
end

function UIController:UpdateEggInventory()
    if playerData and EggInventory and EggInventory:IsOpen() then
        EggInventory:UpdateData(playerData.eggs or {}, playerData.currencies)
    end
end

----- FARM UI METHODS -----
function UIController:ShowPlotInfo(plotIndex: number, plotData: any?)
    if PlotInfoPanel then
        PlotInfoPanel:ShowForPlot(plotIndex, plotData)
    end
end

function UIController:HidePlotInfo()
    if PlotInfoPanel then
        PlotInfoPanel:Close()
    end
end

function UIController:ShowSeedSelection(callback: (string) -> ())
    if SeedPanel and playerData then
        SeedPanel:PopulateSeeds(playerData.seeds)
        SeedPanel:Open(callback)
    end
end

function UIController:SetWaterIndicator(hasWater: boolean)
    if FarmHUD then
        FarmHUD:SetWaterIndicator(hasWater)
    end
end

----- PET UI METHODS -----
function UIController:TogglePetInventory()
    if PetInventory then
        if PetInventory:IsOpen() then
            PetInventory:Close()
        else
            if playerData then
                PetInventory:PopulatePets(playerData.pets)
            end
            PetInventory:Open(function(petUid)
                self:ShowPetDetails(petUid)
            end)
        end
    end
end

function UIController:ToggleEggInventory()
    if EggInventory then
        if EggInventory:IsOpen() then
            EggInventory:Close()
        else
            if playerData then
                EggInventory:Open(playerData.eggs or {}, playerData.currencies)
            end
        end
    end
end

function UIController:TogglePetPen()
    local PetPenController = require(script.Parent.PetPenController)
    
    if PetPenUI and PetPenUI:IsOpen() then
        PetPenUI:Close()
    else
        PetPenController:OpenPetPenUI()
    end
end

function UIController:ShowPetInventory()
    if PetInventory and playerData then
        PetInventory:PopulatePets(playerData.pets)
        PetInventory:Open(function(petUid)
            self:ShowPetDetails(petUid)
        end)
    end
end

function UIController:ShowPetDetails(petUid: string)
    if not playerData or not PetDetails then return end
    
    local petInstance = nil
    for _, pet in ipairs(playerData.pets) do
        if pet.uid == petUid then
            petInstance = pet
            break
        end
    end
    
    if petInstance then
        PetDetails:ShowPet(petInstance)
    end
end

function UIController:ClosePetDetails()
    if PetDetails then
        PetDetails:Close()
    end
end

----- BUTTON CALLBACKS -----
function UIController:OnPlantRequested()
    local plotIndex = PlotInfoPanel:GetCurrentPlot()
    if not plotIndex then return end
    
    self:ShowSeedSelection(function(seedUid)
        Remotes.PlantSeed:FireServer(plotIndex, seedUid)
        PlotInfoPanel:Close()
    end)
end

function UIController:OnHarvestRequested()
    local plotIndex = PlotInfoPanel:GetCurrentPlot()
    if not plotIndex then return end
    
    Remotes.HarvestPlot:FireServer(plotIndex)
    PlotInfoPanel:Close()
end

function UIController:OnWaterRequested()
    local plotIndex = PlotInfoPanel:GetCurrentPlot()
    if not plotIndex then return end
    
    Remotes.WaterPlot:FireServer(plotIndex)
end

----- NOTIFICATIONS -----
function UIController:ShowNotification(notificationType: string, message: string)
    if NotificationSystem then
        NotificationSystem:Show(notificationType, message)
    end
    print("[UIController] NOTIFICATION [" .. notificationType .. "]:", message)
end

function UIController:OnRewardReceived(reward: any)
    if reward.type == "PetHatched" then
        local rarity = reward.rarity or "Common"
        local name = reward.petName or "Pet"
        local mutantText = reward.isMutant and " 🧬 MUTANT!" or ""
        
        self:ShowNotification("success", "🎉 Hatched: " .. name .. " (" .. rarity .. ")" .. mutantText)
    end
end

return UIController
