--!strict
--[[
    FarmMapGenerator
    Creates the 3D farm environment
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local FarmMapGenerator = {}

----- CONFIGURATION -----
local PLOT_SIZE = Vector3.new(8, 1, 8)
local PLOT_SPACING = 2
local PLOTS_PER_ROW = 4
local TOTAL_ROWS = 3
local FARM_ORIGIN = Vector3.new(0, 0.5, 0)

local COLORS = {
    Dirt = Color3.fromRGB(101, 67, 33),
    DirtDark = Color3.fromRGB(80, 50, 25),
    Grass = Color3.fromRGB(76, 153, 76),
    Water = Color3.fromRGB(64, 164, 223),
    Wood = Color3.fromRGB(139, 90, 43),
    Stone = Color3.fromRGB(128, 128, 128),
}

----- MAIN FUNCTION -----
function FarmMapGenerator.Generate(): Folder
    local farmFolder = Instance.new("Folder")
    farmFolder.Name = "Farm"
    
    -- Create base ground
    local ground = FarmMapGenerator.CreateGround()
    ground.Parent = farmFolder
    
    -- Create plots
    local plotsFolder = Instance.new("Folder")
    plotsFolder.Name = "Plots"
    plotsFolder.Parent = farmFolder
    
    local plotIndex = 1
    for row = 1, TOTAL_ROWS do
        for col = 1, PLOTS_PER_ROW do
            local plot = FarmMapGenerator.CreatePlot(plotIndex, row, col)
            plot.Parent = plotsFolder
            plotIndex = plotIndex + 1
        end
    end
    
    -- Create decorations
    local decorFolder = Instance.new("Folder")
    decorFolder.Name = "Decorations"
    decorFolder.Parent = farmFolder
    
    FarmMapGenerator.CreateFence(decorFolder)
    FarmMapGenerator.CreateWaterWell(decorFolder)
    FarmMapGenerator.CreateShed(decorFolder)
    
    -- Create spawn point
    local spawn = FarmMapGenerator.CreateSpawnPoint()
    spawn.Parent = farmFolder
    
    farmFolder.Parent = workspace
    
    print("[FarmMapGenerator] Farm created with", plotIndex - 1, "plots")
    return farmFolder
end

----- GROUND -----
function FarmMapGenerator.CreateGround(): Model
    local ground = Instance.new("Model")
    ground.Name = "Ground"
    
    -- Main grass area
    local grass = Instance.new("Part")
    grass.Name = "Grass"
    grass.Size = Vector3.new(100, 1, 100)
    grass.Position = Vector3.new(0, -0.5, 0)
    grass.Anchored = true
    grass.Color = COLORS.Grass
    grass.Material = Enum.Material.Grass
    grass.Parent = ground
    
    -- Farm dirt area
    local dirtWidth = (PLOTS_PER_ROW * PLOT_SIZE.X) + ((PLOTS_PER_ROW - 1) * PLOT_SPACING) + 10
    local dirtLength = (TOTAL_ROWS * PLOT_SIZE.Z) + ((TOTAL_ROWS - 1) * PLOT_SPACING) + 10
    
    local dirt = Instance.new("Part")
    dirt.Name = "FarmDirt"
    dirt.Size = Vector3.new(dirtWidth, 1.01, dirtLength)
    dirt.Position = Vector3.new(
        FARM_ORIGIN.X + (dirtWidth / 2) - 5,
        -0.49,
        FARM_ORIGIN.Z + (dirtLength / 2) - 5
    )
    dirt.Anchored = true
    dirt.Color = COLORS.DirtDark
    dirt.Material = Enum.Material.Ground
    dirt.Parent = ground
    
    return ground
end

----- PLOTS -----
function FarmMapGenerator.CreatePlot(index: number, row: number, col: number): Model
    local plot = Instance.new("Model")
    plot.Name = "Plot_" .. index
    
    -- Calculate position
    local xPos = FARM_ORIGIN.X + ((col - 1) * (PLOT_SIZE.X + PLOT_SPACING)) + (PLOT_SIZE.X / 2)
    local zPos = FARM_ORIGIN.Z + ((row - 1) * (PLOT_SIZE.Z + PLOT_SPACING)) + (PLOT_SIZE.Z / 2)
    local position = Vector3.new(xPos, FARM_ORIGIN.Y, zPos)
    
    -- Plot base (dirt)
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = PLOT_SIZE
    base.Position = position
    base.Anchored = true
    base.Color = COLORS.Dirt
    base.Material = Enum.Material.Ground
    base.Parent = plot
    
    -- Plot border
    local borderThickness = 0.3
    local borderHeight = 0.5
    
    local borders = {
        {name = "BorderFront", size = Vector3.new(PLOT_SIZE.X + borderThickness * 2, borderHeight, borderThickness), offset = Vector3.new(0, borderHeight / 2, -PLOT_SIZE.Z / 2 - borderThickness / 2)},
        {name = "BorderBack", size = Vector3.new(PLOT_SIZE.X + borderThickness * 2, borderHeight, borderThickness), offset = Vector3.new(0, borderHeight / 2, PLOT_SIZE.Z / 2 + borderThickness / 2)},
        {name = "BorderLeft", size = Vector3.new(borderThickness, borderHeight, PLOT_SIZE.Z), offset = Vector3.new(-PLOT_SIZE.X / 2 - borderThickness / 2, borderHeight / 2, 0)},
        {name = "BorderRight", size = Vector3.new(borderThickness, borderHeight, PLOT_SIZE.Z), offset = Vector3.new(PLOT_SIZE.X / 2 + borderThickness / 2, borderHeight / 2, 0)},
    }
    
    for _, borderData in ipairs(borders) do
        local border = Instance.new("Part")
        border.Name = borderData.name
        border.Size = borderData.size
        border.Position = position + borderData.offset
        border.Anchored = true
        border.Color = COLORS.Wood
        border.Material = Enum.Material.Wood
        border.Parent = plot
    end
    
    -- Interaction point (invisible, for click detection)
    local interactPart = Instance.new("Part")
    interactPart.Name = "InteractZone"
    interactPart.Size = Vector3.new(PLOT_SIZE.X - 0.5, 2, PLOT_SIZE.Z - 0.5)
    interactPart.Position = position + Vector3.new(0, 1.5, 0)
    interactPart.Anchored = true
    interactPart.Transparency = 1
    interactPart.CanCollide = false
    interactPart.Parent = plot
    
    -- Click detector
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Name = "PlotClick"
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = interactPart
    
    -- Plant holder (where the plant model will appear)
    local plantHolder = Instance.new("Part")
    plantHolder.Name = "PlantHolder"
    plantHolder.Size = Vector3.new(1, 1, 1)
    plantHolder.Position = position + Vector3.new(0, 1, 0)
    plantHolder.Anchored = true
    plantHolder.Transparency = 1
    plantHolder.CanCollide = false
    plantHolder.Parent = plot
    
    -- Store plot index
    local indexValue = Instance.new("IntValue")
    indexValue.Name = "PlotIndex"
    indexValue.Value = index
    indexValue.Parent = plot
    
    -- Store plot state
    local stateValue = Instance.new("StringValue")
    stateValue.Name = "PlotState"
    stateValue.Value = "Empty" -- Empty, Growing, Ready
    stateValue.Parent = plot
    
    -- Store seed ID (if planted)
    local seedValue = Instance.new("StringValue")
    seedValue.Name = "SeedId"
    seedValue.Value = ""
    seedValue.Parent = plot
    
    -- Progress bar (BillboardGui)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProgressDisplay"
    billboard.Size = UDim2.new(0, 100, 0, 20)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = plantHolder
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    billboard.Parent = plot
    
    local progressBg = Instance.new("Frame")
    progressBg.Name = "Background"
    progressBg.Size = UDim2.new(1, 0, 1, 0)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = billboard
    
    local progressBar = Instance.new("Frame")
    progressBar.Name = "Bar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressText = Instance.new("TextLabel")
    progressText.Name = "Text"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.TextColor3 = Color3.new(1, 1, 1)
    progressText.TextScaled = true
    progressText.Font = Enum.Font.GothamBold
    progressText.Text = "0%"
    progressText.Parent = progressBg
    
    -- Set PrimaryPart
    plot.PrimaryPart = base
    
    return plot
end

----- DECORATIONS -----
function FarmMapGenerator.CreateFence(parent: Folder)
    local fenceFolder = Instance.new("Folder")
    fenceFolder.Name = "Fence"
    fenceFolder.Parent = parent
    
    local farmWidth = (PLOTS_PER_ROW * PLOT_SIZE.X) + ((PLOTS_PER_ROW - 1) * PLOT_SPACING) + 16
    local farmLength = (TOTAL_ROWS * PLOT_SIZE.Z) + ((TOTAL_ROWS - 1) * PLOT_SPACING) + 16
    
    local fenceHeight = 3
    local fenceThickness = 0.5
    
    local fencePositions = {
        {name = "FenceFront", size = Vector3.new(farmWidth, fenceHeight, fenceThickness), pos = Vector3.new(farmWidth/2 - 8, fenceHeight/2, -8)},
        {name = "FenceBack", size = Vector3.new(farmWidth, fenceHeight, fenceThickness), pos = Vector3.new(farmWidth/2 - 8, fenceHeight/2, farmLength - 8)},
        {name = "FenceLeft", size = Vector3.new(fenceThickness, fenceHeight, farmLength), pos = Vector3.new(-8, fenceHeight/2, farmLength/2 - 8)},
        {name = "FenceRight", size = Vector3.new(fenceThickness, fenceHeight, farmLength), pos = Vector3.new(farmWidth - 8, fenceHeight/2, farmLength/2 - 8)},
    }
    
    for _, fenceData in ipairs(fencePositions) do
        local fence = Instance.new("Part")
        fence.Name = fenceData.name
        fence.Size = fenceData.size
        fence.Position = fenceData.pos
        fence.Anchored = true
        fence.Color = COLORS.Wood
        fence.Material = Enum.Material.Wood
        fence.Parent = fenceFolder
    end
end

function FarmMapGenerator.CreateWaterWell(parent: Folder)
    local well = Instance.new("Model")
    well.Name = "WaterWell"
    
    local wellPos = Vector3.new(-15, 0, 10)
    
    -- Base
    local base = Instance.new("Part")
    base.Name = "Base"
    base.Shape = Enum.PartType.Cylinder
    base.Size = Vector3.new(2, 6, 6)
    base.CFrame = CFrame.new(wellPos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90))
    base.Anchored = true
    base.Color = COLORS.Stone
    base.Material = Enum.Material.Cobblestone
    base.Parent = well
    
    -- Water inside
    local water = Instance.new("Part")
    water.Name = "Water"
    water.Shape = Enum.PartType.Cylinder
    water.Size = Vector3.new(0.5, 5, 5)
    water.CFrame = CFrame.new(wellPos + Vector3.new(0, 1.8, 0)) * CFrame.Angles(0, 0, math.rad(90))
    water.Anchored = true
    water.Color = COLORS.Water
    water.Material = Enum.Material.Glass
    water.Transparency = 0.3
    water.Parent = well
    
    -- Roof supports
    for i = 1, 4 do
        local angle = math.rad(90 * i)
        local post = Instance.new("Part")
        post.Name = "Post" .. i
        post.Size = Vector3.new(0.4, 4, 0.4)
        post.Position = wellPos + Vector3.new(math.cos(angle) * 2.5, 4, math.sin(angle) * 2.5)
        post.Anchored = true
        post.Color = COLORS.Wood
        post.Material = Enum.Material.Wood
        post.Parent = well
    end
    
    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(7, 0.5, 7)
    roof.Position = wellPos + Vector3.new(0, 6.25, 0)
    roof.Anchored = true
    roof.Color = COLORS.Wood
    roof.Material = Enum.Material.Wood
    roof.Parent = well
    
    -- Click detector for watering
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Name = "WellClick"
    clickDetector.MaxActivationDistance = 15
    clickDetector.Parent = base
    
    -- Proximity prompt as alternative
    local proximityPrompt = Instance.new("ProximityPrompt")
    proximityPrompt.Name = "WaterPrompt"
    proximityPrompt.ActionText = "Get Water"
    proximityPrompt.ObjectText = "Well"
    proximityPrompt.HoldDuration = 0.5
    proximityPrompt.MaxActivationDistance = 10
    proximityPrompt.Parent = base
    
    well.PrimaryPart = base
    well.Parent = parent
end

function FarmMapGenerator.CreateShed(parent: Folder)
    local shed = Instance.new("Model")
    shed.Name = "Shed"
    
    local shedPos = Vector3.new(50, 0, 10)
    local shedSize = Vector3.new(12, 8, 10)
    
    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(shedSize.X, 0.5, shedSize.Z)
    floor.Position = shedPos + Vector3.new(0, 0.25, 0)
    floor.Anchored = true
    floor.Color = COLORS.Wood
    floor.Material = Enum.Material.WoodPlanks
    floor.Parent = shed
    
    -- Walls
    local walls = {
        {name = "WallBack", size = Vector3.new(shedSize.X, shedSize.Y, 0.5), offset = Vector3.new(0, shedSize.Y/2, shedSize.Z/2)},
        {name = "WallLeft", size = Vector3.new(0.5, shedSize.Y, shedSize.Z), offset = Vector3.new(-shedSize.X/2, shedSize.Y/2, 0)},
        {name = "WallRight", size = Vector3.new(0.5, shedSize.Y, shedSize.Z), offset = Vector3.new(shedSize.X/2, shedSize.Y/2, 0)},
    }
    
    for _, wallData in ipairs(walls) do
        local wall = Instance.new("Part")
        wall.Name = wallData.name
        wall.Size = wallData.size
        wall.Position = shedPos + wallData.offset
        wall.Anchored = true
        wall.Color = COLORS.Wood
        wall.Material = Enum.Material.WoodPlanks
        wall.Parent = shed
    end
    
    -- Roof
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Size = Vector3.new(shedSize.X + 2, 0.5, shedSize.Z + 2)
    roof.Position = shedPos + Vector3.new(0, shedSize.Y + 0.25, 0)
    roof.Anchored = true
    roof.Color = Color3.fromRGB(100, 60, 30)
    roof.Material = Enum.Material.WoodPlanks
    roof.Parent = shed
    
    shed.PrimaryPart = floor
    shed.Parent = parent
end

----- SPAWN POINT -----
function FarmMapGenerator.CreateSpawnPoint(): SpawnLocation
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "FarmSpawn"
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.Position = Vector3.new(-5, 0.5, -15)
    spawn.Anchored = true
    spawn.Color = Color3.fromRGB(100, 100, 100)
    spawn.Material = Enum.Material.SmoothPlastic
    spawn.Neutral = true
    spawn.CanCollide = true
    spawn.Transparency = 0.5
    
    return spawn
end

return FarmMapGenerator
