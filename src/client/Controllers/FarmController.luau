--!strict
--[[
    FarmController
    Handles client-side farm interactions
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Remotes = Shared.Remotes
local Data = Shared.Data

local FarmController = {}

local LocalPlayer = Players.LocalPlayer
local selectedPlotIndex: number? = nil
local hasWater = false
local UIController

function FarmController:Init()
    print("[FarmController] Initializing...")
end

function FarmController:Start()
    print("[FarmController] Starting...")
    
    -- Get UIController reference
    UIController = require(script.Parent.UIController)
    
    -- Wait for farm to be created
    local farm = workspace:WaitForChild("Farm", 10)
    if not farm then
        warn("[FarmController] Farm not found!")
        return
    end
    
    local plots = farm:WaitForChild("Plots")
    
    -- Setup click handlers for plots
    for _, plot in ipairs(plots:GetChildren()) do
        self:SetupPlotInteraction(plot)
    end
    
    -- Setup well interaction
    local decorations = farm:FindFirstChild("Decorations")
    if decorations then
        local well = decorations:FindFirstChild("WaterWell")
        if well then
            self:SetupWellInteraction(well)
        end
    end
    
    print("[FarmController] Farm interactions setup complete")
end

function FarmController:SetupPlotInteraction(plot: Model)
    local interactZone = plot:FindFirstChild("InteractZone")
    if not interactZone then return end
    
    local clickDetector = interactZone:FindFirstChild("PlotClick")
    if not clickDetector then return end
    
    local plotIndex = plot:FindFirstChild("PlotIndex")
    if not plotIndex then return end
    
    clickDetector.MouseClick:Connect(function()
        self:OnPlotClicked(plotIndex.Value, plot)
    end)
    
    clickDetector.MouseHoverEnter:Connect(function()
        self:OnPlotHover(plot, true)
    end)
    
    clickDetector.MouseHoverLeave:Connect(function()
        self:OnPlotHover(plot, false)
    end)
end

function FarmController:OnPlotClicked(index: number, plot: Model)
    print("[FarmController] Plot clicked:", index)
    selectedPlotIndex = index
    
    local state = plot:FindFirstChild("PlotState")
    local stateValue = state and state.Value or "Empty"
    
    print("[FarmController] Plot state:", stateValue)
    
    -- Get plot data from player data
    local playerData = UIController:GetPlayerData()
    local plotData = nil
    
    if playerData then
        for _, p in ipairs(playerData.farm.plots) do
            if p.index == index then
                plotData = p
                break
            end
        end
    end
    
    if stateValue == "Ready" then
        -- Harvest directly
        Remotes.HarvestPlot:FireServer(index)
        
        -- Use water if we have it (for next plant)
        if hasWater then
            self:UseWater()
        end
    elseif stateValue == "Growing" then
        -- If has water, water the plot
        if hasWater then
            Remotes.WaterPlot:FireServer(index)
            self:UseWater()
        else
            -- Show plot info
            UIController:ShowPlotInfo(index, plotData)
        end
    else
        -- Empty - show plot info to plant
        UIController:ShowPlotInfo(index, plotData)
    end
end

function FarmController:OnPlotHover(plot: Model, isHovering: boolean)
    local base = plot:FindFirstChild("Base")
    local state = plot:FindFirstChild("PlotState")
    local stateValue = state and state.Value or "Empty"
    
    if base and base:IsA("BasePart") then
        if isHovering then
            if stateValue == "Ready" then
                base.Color = Color3.fromRGB(180, 150, 50) -- Gold tint for ready
            elseif stateValue == "Growing" then
                base.Color = Color3.fromRGB(100, 130, 80) -- Green tint for growing
            else
                base.Color = Color3.fromRGB(130, 90, 50) -- Normal highlight
            end
        else
            base.Color = Color3.fromRGB(101, 67, 33) -- Original dirt color
        end
    end
end

function FarmController:SetupWellInteraction(well: Model)
    local base = well.PrimaryPart
    if not base then return end
    
    local proximityPrompt = base:FindFirstChild("WaterPrompt")
    if proximityPrompt then
        proximityPrompt.Triggered:Connect(function()
            self:OnWellUsed()
        end)
    end
    
    local clickDetector = base:FindFirstChild("WellClick")
    if clickDetector then
        clickDetector.MouseClick:Connect(function()
            self:OnWellUsed()
        end)
    end
end

function FarmController:OnWellUsed()
    if hasWater then
        UIController:ShowNotification("Info", "You already have water!")
        return
    end
    
    hasWater = true
    UIController:SetWaterIndicator(true)
    UIController:ShowNotification("Success", "💧 Got water! Click a growing plant to water it.")
end

function FarmController:GetSelectedPlot(): number?
    return selectedPlotIndex
end

function FarmController:HasWater(): boolean
    return hasWater
end

function FarmController:UseWater()
    hasWater = false
    UIController:SetWaterIndicator(false)
end

function FarmController:OnDataUpdate(data)
    -- Could update local state here if needed
end

return FarmController
