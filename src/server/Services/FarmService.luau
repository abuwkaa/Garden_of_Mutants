--!strict
--[[
    FarmService
    Handles farming, planting, and harvesting
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Types = Shared.Types
local Utils = Shared.Utils
local Remotes = Shared.Remotes
local Data = Shared.Data

local FarmService = {}

local DataService
local PlantModels

local plotVisuals: {[number]: {model: Model?, stage: number}} = {}

function FarmService:Init()
    print("[FarmService] Initializing...")
    DataService = require(script.Parent.DataService)
    
    local Modules = script.Parent.Parent.Modules
    PlantModels = require(Modules.PlantModels)
end

function FarmService:Start()
    print("[FarmService] Starting...")
    
    Remotes.PlantSeed.OnServerEvent:Connect(function(player, plotIndex, seedUid)
        self:PlantSeed(player, plotIndex, seedUid)
    end)
    
    Remotes.HarvestPlot.OnServerEvent:Connect(function(player, plotIndex)
        self:HarvestPlot(player, plotIndex)
    end)
    
    Remotes.WaterPlot.OnServerEvent:Connect(function(player, plotIndex)
        self:WaterPlot(player, plotIndex)
    end)
    
    -- Start growth update loop
    task.spawn(function()
        while true do
            self:UpdateAllPlots()
            task.wait(1)
        end
    end)
end

function FarmService:PlantSeed(player: Player, plotIndex: number, seedUid: string)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Validate plot index
    if plotIndex < 1 or plotIndex > Constants.MAX_FARM_PLOTS then
        Remotes.Notification:FireClient(player, "Error", "Invalid plot!")
        return
    end
    
    -- Find seed in inventory (seeds use uid, not quantity in this version)
    local seedIdx: number? = nil
    local seedInstance = nil
    for i, s in ipairs(data.seeds) do
        if s.uid == seedUid then
            seedIdx = i
            seedInstance = s
            break
        end
    end
    
    if not seedInstance or not seedIdx then
        Remotes.Notification:FireClient(player, "Error", "Seed not found!")
        return
    end
    
    -- Check if seed has quantity field (stacked) or is single item
    local isStacked = seedInstance.quantity ~= nil
    
    if isStacked and seedInstance.quantity < 1 then
        Remotes.Notification:FireClient(player, "Error", "No seeds left!")
        return
    end
    
    -- Find or create plot data
    local plotData = nil
    for _, p in ipairs(data.farm.plots) do
        if p.index == plotIndex then
            plotData = p
            break
        end
    end
    
    if not plotData then
        plotData = {
            index = plotIndex,
            seedId = nil,
            plantedAt = nil,
            wateredAt = nil,
        }
        table.insert(data.farm.plots, plotData)
    end
    
    -- Check if plot is empty
    if plotData.seedId then
        Remotes.Notification:FireClient(player, "Error", "Plot is not empty!")
        return
    end
    
    -- Get seed template
    local seedTemplate = Data.Seeds.GetSeed(seedInstance.templateId)
    if not seedTemplate then
        Remotes.Notification:FireClient(player, "Error", "Invalid seed type!")
        return
    end
    
    -- Plant the seed
    plotData.seedId = seedInstance.templateId
    plotData.plantedAt = os.time()
    plotData.wateredAt = nil
    
    -- Remove seed from inventory
    if isStacked then
        seedInstance.quantity = seedInstance.quantity - 1
        if seedInstance.quantity <= 0 then
            table.remove(data.seeds, seedIdx)
        end
    else
        -- Single seed item, remove entirely
        table.remove(data.seeds, seedIdx)
    end
    
    -- Update visual
    self:UpdatePlotVisual(plotIndex, plotData.seedId, 0)
    
    -- Sync data
    Remotes.DataUpdate:FireClient(player, data)
    Remotes.Notification:FireClient(player, "Success", "Planted " .. seedTemplate.name .. "!")
    
    print("[FarmService] Player", player.Name, "planted", seedTemplate.name, "in plot", plotIndex)
end

function FarmService:HarvestPlot(player: Player, plotIndex: number)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Find plot
    local plotData: Types.PlotData? = nil
    local plotIdx: number? = nil
    for i, p in ipairs(data.farm.plots) do
        if p.index == plotIndex then
            plotData = p
            plotIdx = i
            break
        end
    end
    
    if not plotData or not plotData.seedId or not plotData.plantedAt then
        Remotes.Notification:FireClient(player, "Error", "Nothing to harvest!")
        return
    end
    
    -- Get seed template
    local seedTemplate = Data.Seeds.GetSeed(plotData.seedId)
    if not seedTemplate then
        Remotes.Notification:FireClient(player, "Error", "Invalid seed!")
        return
    end
    
    -- Check if ready
    local growthTime = seedTemplate.growthTime or 60
    if plotData.wateredAt then
        growthTime = growthTime * (1 - Constants.WATER_SPEED_BONUS)
    end
    
    local elapsed = os.time() - plotData.plantedAt
    if elapsed < growthTime then
        local remaining = math.ceil(growthTime - elapsed)
        Remotes.Notification:FireClient(player, "Error", "Not ready! " .. remaining .. "s remaining")
        return
    end
    
    -- Calculate rewards
    local rarityMult = Utils.GetRarityMultiplier(seedTemplate.rarity)
    local leavesReward = math.floor(50 * rarityMult)
    local shardsReward = math.floor(5 * rarityMult)
    local xpReward = math.floor(20 * rarityMult)
    
    -- Apply rewards
    data.currencies.Leaves = data.currencies.Leaves + leavesReward
    data.currencies.MutationShards = data.currencies.MutationShards + shardsReward
    data.xp = data.xp + xpReward
    
    -- Check for bonus seed drop
    local dropRoll = math.random()
    if dropRoll < 0.3 then -- 30% chance
        local bonusSeedId = seedTemplate.id
        self:GiveSeed(player, data, bonusSeedId, 1)
    end
    
    -- Clear plot
    local seedName = seedTemplate.name
    plotData.seedId = nil
    plotData.plantedAt = nil
    plotData.wateredAt = nil
    
    -- Clear visual
    self:ClearPlotVisual(plotIndex)
    
    -- Sync data
    Remotes.DataUpdate:FireClient(player, data)
    Remotes.Notification:FireClient(player, "Success", "Harvested " .. seedName .. "! +" .. leavesReward .. " Leaves, +" .. shardsReward .. " Shards")
    
    print("[FarmService] Player", player.Name, "harvested from plot", plotIndex)
end

function FarmService:WaterPlot(player: Player, plotIndex: number)
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Find plot
    local plotData: Types.PlotData? = nil
    for _, p in ipairs(data.farm.plots) do
        if p.index == plotIndex then
            plotData = p
            break
        end
    end
    
    if not plotData or not plotData.seedId then
        Remotes.Notification:FireClient(player, "Error", "Nothing to water!")
        return
    end
    
    -- Check cooldown
    if plotData.wateredAt then
        local elapsed = os.time() - plotData.wateredAt
        if elapsed < Constants.WATER_COOLDOWN then
            local remaining = Constants.WATER_COOLDOWN - elapsed
            Remotes.Notification:FireClient(player, "Error", "Wait " .. math.ceil(remaining) .. "s to water again")
            return
        end
    end
    
    -- Water the plot
    plotData.wateredAt = os.time()
    
    -- Sync data
    Remotes.DataUpdate:FireClient(player, data)
    Remotes.Notification:FireClient(player, "Success", "Watered! Growth speed +10%")
    
    print("[FarmService] Player", player.Name, "watered plot", plotIndex)
end

function FarmService:GiveSeed(player: Player, data: Types.PlayerData, seedId: string, quantity: number)
    -- Find existing stack
    for _, seed in ipairs(data.seeds) do
        if seed.templateId == seedId then
            seed.quantity = (seed.quantity or 0) + quantity
            return
        end
    end
    
    -- Create new stack
    local newSeed: Types.SeedInstance = {
        uid = Utils.GenerateUID(),
        templateId = seedId,
        quantity = quantity,
    }
    table.insert(data.seeds, newSeed)
end

function FarmService:UpdateAllPlots()
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local plots = farm:FindFirstChild("Plots")
    if not plots then return end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        local data = DataService:GetData(player)
        if data then
            for _, plotData in ipairs(data.farm.plots) do
                if plotData.seedId and plotData.plantedAt then
                    local seedTemplate = Data.Seeds.GetSeed(plotData.seedId)
                    if seedTemplate then
                        local growthTime = seedTemplate.growthTime or 60
                        if plotData.wateredAt then
                            growthTime = growthTime * (1 - Constants.WATER_SPEED_BONUS)
                        end
                        
                        local elapsed = os.time() - plotData.plantedAt
                        local progress = math.min(1, elapsed / growthTime)
                        local stage = PlantModels.GetStageFromProgress(progress)
                        
                        -- Update visual if stage changed
                        local currentVisual = plotVisuals[plotData.index]
                        if not currentVisual or currentVisual.stage ~= stage then
                            self:UpdatePlotVisual(plotData.index, plotData.seedId, progress)
                        end
                        
                        -- Update progress bar
                        self:UpdatePlotProgress(plotData.index, progress, growthTime - elapsed)
                    end
                end
            end
        end
    end
end

function FarmService:UpdatePlotVisual(plotIndex: number, seedId: string, progress: number)
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local plots = farm:FindFirstChild("Plots")
    if not plots then return end
    
    local plot = plots:FindFirstChild("Plot_" .. plotIndex)
    if not plot then return end
    
    local plantHolder = plot:FindFirstChild("PlantHolder")
    if not plantHolder then return end
    
    -- Remove old plant
    for _, child in ipairs(plantHolder:GetChildren()) do
        if child:IsA("Model") then
            child:Destroy()
        end
    end
    
    -- Create new plant at current stage
    local stage = PlantModels.GetStageFromProgress(progress)
    local plantModel = PlantModels.CreatePlant(seedId, stage)
    
    if plantModel.PrimaryPart then
        plantModel:SetPrimaryPartCFrame(CFrame.new(plantHolder.Position))
    else
        plantModel:MoveTo(plantHolder.Position)
    end
    
    plantModel.Parent = plantHolder
    
    -- Update state value
    local stateValue = plot:FindFirstChild("PlotState")
    if stateValue then
        if progress >= 1 then
            stateValue.Value = "Ready"
        else
            stateValue.Value = "Growing"
        end
    end
    
    local seedValue = plot:FindFirstChild("SeedId")
    if seedValue then
        seedValue.Value = seedId
    end
    
    -- Store visual info
    plotVisuals[plotIndex] = {
        model = plantModel,
        stage = stage,
    }
    
    -- Show progress bar
    local billboard = plot:FindFirstChild("ProgressDisplay")
    if billboard then
        billboard.Enabled = true
    end
end

function FarmService:UpdatePlotProgress(plotIndex: number, progress: number, timeRemaining: number)
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local plots = farm:FindFirstChild("Plots")
    if not plots then return end
    
    local plot = plots:FindFirstChild("Plot_" .. plotIndex)
    if not plot then return end
    
    local billboard = plot:FindFirstChild("ProgressDisplay")
    if not billboard then return end
    
    local bg = billboard:FindFirstChild("Background")
    if not bg then return end
    
    local bar = bg:FindFirstChild("Bar")
    local text = bg:FindFirstChild("Text")
    
    if bar then
        bar.Size = UDim2.new(progress, 0, 1, 0)
        
        if progress >= 1 then
            bar.BackgroundColor3 = Color3.fromRGB(255, 193, 7) -- Gold when ready
        else
            bar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Green when growing
        end
    end
    
    if text then
        if progress >= 1 then
            text.Text = "Ready!"
        else
            text.Text = Utils.FormatTime(math.max(0, timeRemaining))
        end
    end
end

function FarmService:ClearPlotVisual(plotIndex: number)
    local farm = workspace:FindFirstChild("Farm")
    if not farm then return end
    
    local plots = farm:FindFirstChild("Plots")
    if not plots then return end
    
    local plot = plots:FindFirstChild("Plot_" .. plotIndex)
    if not plot then return end
    
    local plantHolder = plot:FindFirstChild("PlantHolder")
    if plantHolder then
        for _, child in ipairs(plantHolder:GetChildren()) do
            if child:IsA("Model") then
                child:Destroy()
            end
        end
    end
    
    -- Update state
    local stateValue = plot:FindFirstChild("PlotState")
    if stateValue then
        stateValue.Value = "Empty"
    end
    
    local seedValue = plot:FindFirstChild("SeedId")
    if seedValue then
        seedValue.Value = ""
    end
    
    -- Hide progress bar
    local billboard = plot:FindFirstChild("ProgressDisplay")
    if billboard then
        billboard.Enabled = false
    end
    
    -- Clear stored visual
    plotVisuals[plotIndex] = nil
end

return FarmService
