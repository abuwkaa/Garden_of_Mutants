--!strict
--[[
    PetPenGenerator
    Creates the 3D Pet Pen with 10 breeding cells
]]

local PetPenGenerator = {}

----- CONFIGURATION -----
local CONFIG = {
    -- Pen position (next to farm)
    PEN_ORIGIN = Vector3.new(60, 0.5, 0),
    
    -- Cell settings
    CELL_SIZE = Vector3.new(12, 1, 12),
    CELL_SPACING = 2,
    CELLS_PER_ROW = 5,
    TOTAL_CELLS = 10,
    
    -- Fence settings
    FENCE_HEIGHT = 4,
    FENCE_THICKNESS = 0.5,
    
    -- Colors
    COLORS = {
        Ground = Color3.fromRGB(34, 139, 34),      -- Forest green
        CellFloor = Color3.fromRGB(210, 180, 140), -- Tan
        CellBorder = Color3.fromRGB(139, 90, 43),  -- Brown wood
        Fence = Color3.fromRGB(160, 120, 80),      -- Light wood
        LockedCell = Color3.fromRGB(80, 80, 80),   -- Gray
        Water = Color3.fromRGB(64, 164, 223),      -- Blue
    }
}

----- MAIN GENERATION -----
function PetPenGenerator.Generate(): Folder
    local penFolder = Instance.new("Folder")
    penFolder.Name = "PetPen"
    penFolder.Parent = workspace
    
    -- Create ground
    PetPenGenerator.CreateGround(penFolder)
    
    -- Create cells
    local cellsFolder = Instance.new("Folder")
    cellsFolder.Name = "Cells"
    cellsFolder.Parent = penFolder
    
    for i = 1, CONFIG.TOTAL_CELLS do
        local cell = PetPenGenerator.CreateCell(i)
        cell.Parent = cellsFolder
    end
    
    -- Create fence around pen
    PetPenGenerator.CreateFence(penFolder)
    
    -- Create decorations
    PetPenGenerator.CreateDecorations(penFolder)
    
    -- Create entrance
    PetPenGenerator.CreateEntrance(penFolder)
    
    print("[PetPenGenerator] Pet Pen created with", CONFIG.TOTAL_CELLS, "cells")
    return penFolder
end

----- GROUND -----
function PetPenGenerator.CreateGround(parent: Folder)
    local totalWidth = CONFIG.CELLS_PER_ROW * (CONFIG.CELL_SIZE.X + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING
    local totalDepth = 2 * (CONFIG.CELL_SIZE.Z + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING + 10
    
    local ground = Instance.new("Part")
    ground.Name = "Ground"
    ground.Size = Vector3.new(totalWidth + 10, 1, totalDepth + 10)
    ground.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2 - 5, 0, totalDepth/2 - 5)
    ground.Anchored = true
    ground.Color = CONFIG.COLORS.Ground
    ground.Material = Enum.Material.Grass
    ground.Parent = parent
end

----- CELLS -----
function PetPenGenerator.CreateCell(index: number): Model
    local cell = Instance.new("Model")
    cell.Name = "Cell_" .. index
    
    -- Calculate position
    local row = math.ceil(index / CONFIG.CELLS_PER_ROW)
    local col = ((index - 1) % CONFIG.CELLS_PER_ROW) + 1
    
    local x = CONFIG.PEN_ORIGIN.X + (col - 1) * (CONFIG.CELL_SIZE.X + CONFIG.CELL_SPACING) + CONFIG.CELL_SIZE.X / 2
    local z = CONFIG.PEN_ORIGIN.Z + (row - 1) * (CONFIG.CELL_SIZE.Z + CONFIG.CELL_SPACING) + CONFIG.CELL_SIZE.Z / 2 + 5
    local y = CONFIG.PEN_ORIGIN.Y + 0.5
    
    local position = Vector3.new(x, y, z)
    
    -- Determine if locked (cell 10 = VIP)
    local isLocked = (index == 10)
    local floorColor = isLocked and CONFIG.COLORS.LockedCell or CONFIG.COLORS.CellFloor
    
    -- Floor
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = CONFIG.CELL_SIZE
    floor.Position = position
    floor.Anchored = true
    floor.Color = floorColor
    floor.Material = isLocked and Enum.Material.Metal or Enum.Material.Wood
    floor.Parent = cell
    
    cell.PrimaryPart = floor
    
    -- Border walls (4 sides, low)
    local borderHeight = 1.5
    local borderThickness = 0.4
    
    -- Front border
    local frontBorder = Instance.new("Part")
    frontBorder.Name = "BorderFront"
    frontBorder.Size = Vector3.new(CONFIG.CELL_SIZE.X, borderHeight, borderThickness)
    frontBorder.Position = position + Vector3.new(0, borderHeight/2, -CONFIG.CELL_SIZE.Z/2 + borderThickness/2)
    frontBorder.Anchored = true
    frontBorder.Color = CONFIG.COLORS.CellBorder
    frontBorder.Material = Enum.Material.Wood
    frontBorder.Parent = cell
    
    -- Back border
    local backBorder = Instance.new("Part")
    backBorder.Name = "BorderBack"
    backBorder.Size = Vector3.new(CONFIG.CELL_SIZE.X, borderHeight, borderThickness)
    backBorder.Position = position + Vector3.new(0, borderHeight/2, CONFIG.CELL_SIZE.Z/2 - borderThickness/2)
    backBorder.Anchored = true
    backBorder.Color = CONFIG.COLORS.CellBorder
    backBorder.Material = Enum.Material.Wood
    backBorder.Parent = cell
    
    -- Left border
    local leftBorder = Instance.new("Part")
    leftBorder.Name = "BorderLeft"
    leftBorder.Size = Vector3.new(borderThickness, borderHeight, CONFIG.CELL_SIZE.Z)
    leftBorder.Position = position + Vector3.new(-CONFIG.CELL_SIZE.X/2 + borderThickness/2, borderHeight/2, 0)
    leftBorder.Anchored = true
    leftBorder.Color = CONFIG.COLORS.CellBorder
    leftBorder.Material = Enum.Material.Wood
    leftBorder.Parent = cell
    
    -- Right border
    local rightBorder = Instance.new("Part")
    rightBorder.Name = "BorderRight"
    rightBorder.Size = Vector3.new(borderThickness, borderHeight, CONFIG.CELL_SIZE.Z)
    rightBorder.Position = position + Vector3.new(CONFIG.CELL_SIZE.X/2 - borderThickness/2, borderHeight/2, 0)
    rightBorder.Anchored = true
    rightBorder.Color = CONFIG.COLORS.CellBorder
    rightBorder.Material = Enum.Material.Wood
    rightBorder.Parent = cell
    
    -- Pet holder positions (up to 3 spots)
    local petHolders = Instance.new("Folder")
    petHolders.Name = "PetHolders"
    petHolders.Parent = cell
    
    local petPositions = {
        Vector3.new(-3, 1.5, 0),
        Vector3.new(0, 1.5, 0),
        Vector3.new(3, 1.5, 0),
    }
    
    for i, offset in ipairs(petPositions) do
        local holder = Instance.new("Part")
        holder.Name = "PetHolder_" .. i
        holder.Size = Vector3.new(0.5, 0.5, 0.5)
        holder.Position = position + offset
        holder.Anchored = true
        holder.Transparency = 1
        holder.CanCollide = false
        holder.Parent = petHolders
    end
    
    -- Interact zone
    local interactZone = Instance.new("Part")
    interactZone.Name = "InteractZone"
    interactZone.Size = Vector3.new(CONFIG.CELL_SIZE.X - 1, 3, CONFIG.CELL_SIZE.Z - 1)
    interactZone.Position = position + Vector3.new(0, 2, 0)
    interactZone.Anchored = true
    interactZone.Transparency = 1
    interactZone.CanCollide = false
    interactZone.Parent = cell
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Name = "CellClick"
    clickDetector.MaxActivationDistance = 20
    clickDetector.Parent = interactZone
    
    -- Cell index value
    local indexValue = Instance.new("IntValue")
    indexValue.Name = "CellIndex"
    indexValue.Value = index
    indexValue.Parent = cell
    
    -- Cell state value
    local stateValue = Instance.new("StringValue")
    stateValue.Name = "CellState"
    stateValue.Value = "Empty" -- Empty, Rest, Breeding
    stateValue.Parent = cell
    
    -- Locked value
    local lockedValue = Instance.new("BoolValue")
    lockedValue.Name = "IsLocked"
    lockedValue.Value = isLocked
    lockedValue.Parent = cell
    
    -- Billboard GUI for status
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "StatusDisplay"
    billboard.Size = UDim2.new(0, 150, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.Adornee = floor
    billboard.AlwaysOnTop = false
    billboard.Enabled = false
    billboard.Parent = cell
    
    local statusBg = Instance.new("Frame")
    statusBg.Name = "Background"
    statusBg.Size = UDim2.new(1, 0, 1, 0)
    statusBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    statusBg.BackgroundTransparency = 0.2
    statusBg.BorderSizePixel = 0
    statusBg.Parent = billboard
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 8)
    statusCorner.Parent = statusBg
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, 0, 0.5, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "Empty"
    statusText.TextSize = 14
    statusText.Font = Enum.Font.GothamBold
    statusText.TextColor3 = Color3.new(1, 1, 1)
    statusText.Parent = statusBg
    
    local timerText = Instance.new("TextLabel")
    timerText.Name = "TimerText"
    timerText.Size = UDim2.new(1, 0, 0.5, 0)
    timerText.Position = UDim2.new(0, 0, 0.5, 0)
    timerText.BackgroundTransparency = 1
    timerText.Text = ""
    timerText.TextSize = 12
    timerText.Font = Enum.Font.Gotham
    timerText.TextColor3 = Color3.fromRGB(180, 180, 180)
    timerText.Parent = statusBg
    
    -- Lock icon for cell 10
    if isLocked then
        local lockIcon = Instance.new("TextLabel")
        lockIcon.Name = "LockIcon"
        lockIcon.Size = UDim2.new(0, 50, 0, 50)
        lockIcon.Position = UDim2.new(0.5, -25, 0.5, -25)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Text = "🔒"
        lockIcon.TextSize = 40
        lockIcon.Parent = statusBg
        
        statusText.Text = "VIP"
        timerText.Text = "Unlock with Gamepass"
        billboard.Enabled = true
    end
    
    return cell
end

----- FENCE -----
function PetPenGenerator.CreateFence(parent: Folder)
    local decorFolder = parent:FindFirstChild("Decorations") or Instance.new("Folder")
    decorFolder.Name = "Decorations"
    decorFolder.Parent = parent
    
    local totalWidth = CONFIG.CELLS_PER_ROW * (CONFIG.CELL_SIZE.X + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING
    local totalDepth = 2 * (CONFIG.CELL_SIZE.Z + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING + 10
    
    local fencePositions = {
        -- Front (with gap for entrance)
        {pos = Vector3.new(totalWidth/4 - 5, CONFIG.FENCE_HEIGHT/2, -2), size = Vector3.new(totalWidth/2 - 8, CONFIG.FENCE_HEIGHT, CONFIG.FENCE_THICKNESS)},
        {pos = Vector3.new(totalWidth - totalWidth/4 + 3, CONFIG.FENCE_HEIGHT/2, -2), size = Vector3.new(totalWidth/2 - 8, CONFIG.FENCE_HEIGHT, CONFIG.FENCE_THICKNESS)},
        -- Back
        {pos = Vector3.new(totalWidth/2 - 2, CONFIG.FENCE_HEIGHT/2, totalDepth + 3), size = Vector3.new(totalWidth + 6, CONFIG.FENCE_HEIGHT, CONFIG.FENCE_THICKNESS)},
        -- Left
        {pos = Vector3.new(-5, CONFIG.FENCE_HEIGHT/2, totalDepth/2), size = Vector3.new(CONFIG.FENCE_THICKNESS, CONFIG.FENCE_HEIGHT, totalDepth + 10)},
        -- Right
        {pos = Vector3.new(totalWidth + 3, CONFIG.FENCE_HEIGHT/2, totalDepth/2), size = Vector3.new(CONFIG.FENCE_THICKNESS, CONFIG.FENCE_HEIGHT, totalDepth + 10)},
    }
    
    for i, fenceData in ipairs(fencePositions) do
        local fence = Instance.new("Part")
        fence.Name = "Fence_" .. i
        fence.Size = fenceData.size
        fence.Position = CONFIG.PEN_ORIGIN + fenceData.pos
        fence.Anchored = true
        fence.Color = CONFIG.COLORS.Fence
        fence.Material = Enum.Material.Wood
        fence.Parent = decorFolder
    end
end

----- DECORATIONS -----
function PetPenGenerator.CreateDecorations(parent: Folder)
    local decorFolder = parent:FindFirstChild("Decorations") or Instance.new("Folder")
    decorFolder.Name = "Decorations"
    decorFolder.Parent = parent
    
    local totalWidth = CONFIG.CELLS_PER_ROW * (CONFIG.CELL_SIZE.X + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING
    
    -- Water trough
    local trough = Instance.new("Part")
    trough.Name = "WaterTrough"
    trough.Size = Vector3.new(8, 1.5, 3)
    trough.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2, 0.75, 2)
    trough.Anchored = true
    trough.Color = CONFIG.COLORS.CellBorder
    trough.Material = Enum.Material.Wood
    trough.Parent = decorFolder
    
    local water = Instance.new("Part")
    water.Name = "Water"
    water.Size = Vector3.new(7.5, 0.5, 2.5)
    water.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2, 1.25, 2)
    water.Anchored = true
    water.Color = CONFIG.COLORS.Water
    water.Material = Enum.Material.Glass
    water.Transparency = 0.3
    water.Parent = decorFolder
    
    -- Hay bales (decorative)
    local hayPositions = {
        Vector3.new(-2, 1, 35),
        Vector3.new(totalWidth + 1, 1, 20),
        Vector3.new(totalWidth + 1, 1, 35),
    }
    
    for i, pos in ipairs(hayPositions) do
        local hay = Instance.new("Part")
        hay.Name = "HayBale_" .. i
        hay.Size = Vector3.new(3, 2, 3)
        hay.Position = CONFIG.PEN_ORIGIN + pos
        hay.Anchored = true
        hay.Color = Color3.fromRGB(218, 165, 32)
        hay.Material = Enum.Material.Fabric
        hay.Parent = decorFolder
    end
    
    -- Sign
    local signPost = Instance.new("Part")
    signPost.Name = "SignPost"
    signPost.Size = Vector3.new(0.5, 5, 0.5)
    signPost.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2 + 8, 2.5, -1)
    signPost.Anchored = true
    signPost.Color = CONFIG.COLORS.CellBorder
    signPost.Material = Enum.Material.Wood
    signPost.Parent = decorFolder
    
    local signBoard = Instance.new("Part")
    signBoard.Name = "SignBoard"
    signBoard.Size = Vector3.new(6, 2, 0.3)
    signBoard.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2 + 8, 4.5, -1)
    signBoard.Anchored = true
    signBoard.Color = CONFIG.COLORS.Fence
    signBoard.Material = Enum.Material.Wood
    signBoard.Parent = decorFolder
    
    local signGui = Instance.new("SurfaceGui")
    signGui.Name = "SignText"
    signGui.Face = Enum.NormalId.Front
    signGui.Parent = signBoard
    
    local signLabel = Instance.new("TextLabel")
    signLabel.Size = UDim2.new(1, 0, 1, 0)
    signLabel.BackgroundTransparency = 1
    signLabel.Text = "🐾 PET PEN 🐾"
    signLabel.TextSize = 32
    signLabel.Font = Enum.Font.GothamBold
    signLabel.TextColor3 = Color3.fromRGB(80, 50, 20)
    signLabel.Parent = signGui
end

----- ENTRANCE -----
function PetPenGenerator.CreateEntrance(parent: Folder)
    local decorFolder = parent:FindFirstChild("Decorations")
    if not decorFolder then return end
    
    local totalWidth = CONFIG.CELLS_PER_ROW * (CONFIG.CELL_SIZE.X + CONFIG.CELL_SPACING) + CONFIG.CELL_SPACING
    
    -- Gate posts
    local leftPost = Instance.new("Part")
    leftPost.Name = "GatePostLeft"
    leftPost.Size = Vector3.new(1, 5, 1)
    leftPost.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2 - 5, 2.5, -2)
    leftPost.Anchored = true
    leftPost.Color = CONFIG.COLORS.CellBorder
    leftPost.Material = Enum.Material.Wood
    leftPost.Parent = decorFolder
    
    local rightPost = Instance.new("Part")
    rightPost.Name = "GatePostRight"
    rightPost.Size = Vector3.new(1, 5, 1)
    rightPost.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2 + 5, 2.5, -2)
    rightPost.Anchored = true
    rightPost.Color = CONFIG.COLORS.CellBorder
    rightPost.Material = Enum.Material.Wood
    rightPost.Parent = decorFolder
    
    -- Gate arch
    local arch = Instance.new("Part")
    arch.Name = "GateArch"
    arch.Size = Vector3.new(11, 1, 1)
    arch.Position = CONFIG.PEN_ORIGIN + Vector3.new(totalWidth/2, 5.5, -2)
    arch.Anchored = true
    arch.Color = CONFIG.COLORS.CellBorder
    arch.Material = Enum.Material.Wood
    arch.Parent = decorFolder
end

return PetPenGenerator
