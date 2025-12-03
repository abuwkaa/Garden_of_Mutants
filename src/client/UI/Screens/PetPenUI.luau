--!strict
--[[
    PetPenUI
    Main interface for the Pet Pen breeding system
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data
local Utils = Shared.Utils
local Constants = Shared.Constants

local PetPenUI = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local mainFrame: Frame?
local cellsContainer: Frame?
local detailPanel: Frame?
local isOpen = false
local selectedCellIndex: number? = nil
local timerConnections: {[number]: RBXScriptConnection} = {}
local currentPenData = nil
local currentPlayerPets = nil

local COLORS = {
    Background = Color3.fromRGB(25, 25, 35),
    BackgroundLight = Color3.fromRGB(40, 40, 55),
    Primary = Color3.fromRGB(76, 175, 80),
    Secondary = Color3.fromRGB(33, 150, 243),
    Accent = Color3.fromRGB(255, 193, 7),
    Breeding = Color3.fromRGB(255, 100, 150),
    Rest = Color3.fromRGB(100, 200, 255),
    Empty = Color3.fromRGB(80, 80, 90),
    Locked = Color3.fromRGB(60, 60, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
}

local ELEMENT_ICONS = {
    Nature = "🌿",
    Fire = "🔥",
    Ice = "❄️",
    Tech = "⚡",
    Chaos = "🌀",
}

function PetPenUI:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetPenUI"
    screenGui.ResetOnSpawn = false
    screenGui.Enabled = false
    screenGui.Parent = PlayerGui
    
    -- Backdrop
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.4
    backdrop.Text = ""
    backdrop.Parent = screenGui
    
    backdrop.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 850, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -425, 0.5, -275)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Breeding
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header
    self:CreateHeader()
    
    -- Cells grid (left side)
    self:CreateCellsGrid()
    
    -- Detail panel (right side)
    self:CreateDetailPanel()
    
    print("[PetPenUI] Created")
    return screenGui
end

function PetPenUI:CreateHeader()
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = COLORS.BackgroundLight
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.BackgroundColor3 = COLORS.BackgroundLight
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 300, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🏠 Pet Pen - Breeding Center"
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = COLORS.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Legend
    local legendFrame = Instance.new("Frame")
    legendFrame.Name = "Legend"
    legendFrame.Size = UDim2.new(0, 350, 0, 30)
    legendFrame.Position = UDim2.new(0, 330, 0.5, -15)
    legendFrame.BackgroundTransparency = 1
    legendFrame.Parent = header
    
    local legendLayout = Instance.new("UIListLayout")
    legendLayout.FillDirection = Enum.FillDirection.Horizontal
    legendLayout.Padding = UDim.new(0, 15)
    legendLayout.Parent = legendFrame
    
    local legends = {
        {color = COLORS.Empty, text = "Empty"},
        {color = COLORS.Rest, text = "Resting"},
        {color = COLORS.Breeding, text = "Breeding"},
        {color = COLORS.Locked, text = "Locked"},
    }
    
    for _, legend in ipairs(legends) do
        local item = Instance.new("Frame")
        item.Size = UDim2.new(0, 75, 0, 24)
        item.BackgroundTransparency = 1
        item.Parent = legendFrame
        
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, 0, 0.5, -6)
        dot.BackgroundColor3 = legend.color
        dot.BorderSizePixel = 0
        dot.Parent = item
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -18, 1, 0)
        label.Position = UDim2.new(0, 18, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = legend.text
        label.TextSize = 11
        label.Font = Enum.Font.Gotham
        label.TextColor3 = COLORS.TextDim
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = item
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -55, 0.5, -20)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
end

function PetPenUI:CreateCellsGrid()
    cellsContainer = Instance.new("Frame")
    cellsContainer.Name = "CellsContainer"
    cellsContainer.Size = UDim2.new(0, 520, 0, 460)
    cellsContainer.Position = UDim2.new(0, 15, 0, 75)
    cellsContainer.BackgroundTransparency = 1
    cellsContainer.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 98, 0, 110)
    gridLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = cellsContainer
    
    -- Create 10 cell slots
    for i = 1, Constants.PEN_MAX_CELLS do
        local cellFrame = self:CreateCellSlot(i)
        cellFrame.LayoutOrder = i
        cellFrame.Parent = cellsContainer
    end
end

function PetPenUI:CreateCellSlot(index: number): Frame
    local isLocked = index == 10 -- Cell 10 is VIP
    local unlockLevel = Constants.PEN_CELL_UNLOCK_LEVELS[index] or 0
    
    local cell = Instance.new("TextButton")
    cell.Name = "Cell_" .. index
    cell.Size = UDim2.new(0, 98, 0, 110)
    cell.BackgroundColor3 = isLocked and COLORS.Locked or COLORS.Empty
    cell.BorderSizePixel = 0
    cell.Text = ""
    cell.AutoButtonColor = false
    
    local cellCorner = Instance.new("UICorner")
    cellCorner.CornerRadius = UDim.new(0, 10)
    cellCorner.Parent = cell
    
    local cellStroke = Instance.new("UIStroke")
    cellStroke.Name = "CellStroke"
    cellStroke.Color = COLORS.BackgroundLight
    cellStroke.Thickness = 2
    cellStroke.Parent = cell
    
    -- Cell number
    local numLabel = Instance.new("TextLabel")
    numLabel.Name = "CellNumber"
    numLabel.Size = UDim2.new(0, 24, 0, 24)
    numLabel.Position = UDim2.new(0, 5, 0, 5)
    numLabel.BackgroundColor3 = COLORS.BackgroundLight
    numLabel.Text = tostring(index)
    numLabel.TextSize = 12
    numLabel.Font = Enum.Font.GothamBold
    numLabel.TextColor3 = COLORS.TextDim
    numLabel.Parent = cell
    
    local numCorner = Instance.new("UICorner")
    numCorner.CornerRadius = UDim.new(0, 6)
    numCorner.Parent = numLabel
    
    -- Pet icons container
    local petsContainer = Instance.new("Frame")
    petsContainer.Name = "PetsContainer"
    petsContainer.Size = UDim2.new(1, -10, 0, 40)
    petsContainer.Position = UDim2.new(0, 5, 0, 32)
    petsContainer.BackgroundTransparency = 1
    petsContainer.Parent = cell
    
    local petsLayout = Instance.new("UIListLayout")
    petsLayout.FillDirection = Enum.FillDirection.Horizontal
    petsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    petsLayout.Padding = UDim.new(0, 2)
    petsLayout.Parent = petsContainer
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -10, 0, 18)
    statusLabel.Position = UDim2.new(0, 5, 0, 72)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = isLocked and "🔒 VIP" or "Empty"
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextColor3 = COLORS.TextDim
    statusLabel.Parent = cell
    
    -- Timer label
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.Size = UDim2.new(1, -10, 0, 16)
    timerLabel.Position = UDim2.new(0, 5, 0, 90)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = ""
    timerLabel.TextSize = 10
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.TextColor3 = COLORS.Accent
    timerLabel.Parent = cell
    
    -- Click handler
    cell.MouseButton1Click:Connect(function()
        self:SelectCell(index)
    end)
    
    -- Hover effect
    cell.MouseEnter:Connect(function()
        if not isLocked then
            TweenService:Create(cellStroke, TweenInfo.new(0.1), {
                Color = COLORS.Primary
            }):Play()
        end
    end)
    
    cell.MouseLeave:Connect(function()
        local isSelected = selectedCellIndex == index
        TweenService:Create(cellStroke, TweenInfo.new(0.1), {
            Color = isSelected and COLORS.Primary or COLORS.BackgroundLight
        }):Play()
    end)
    
    return cell
end

function PetPenUI:CreateDetailPanel()
    detailPanel = Instance.new("Frame")
    detailPanel.Name = "DetailPanel"
    detailPanel.Size = UDim2.new(0, 295, 0, 460)
    detailPanel.Position = UDim2.new(0, 540, 0, 75)
    detailPanel.BackgroundColor3 = COLORS.BackgroundLight
    detailPanel.BorderSizePixel = 0
    detailPanel.Parent = mainFrame
    
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = detailPanel
    
    -- Placeholder text
    local placeholder = Instance.new("TextLabel")
    placeholder.Name = "Placeholder"
    placeholder.Size = UDim2.new(1, 0, 1, 0)
    placeholder.BackgroundTransparency = 1
    placeholder.Text = "👆\nSelect a cell\nto view details"
    placeholder.TextSize = 16
    placeholder.Font = Enum.Font.Gotham
    placeholder.TextColor3 = COLORS.TextDim
    placeholder.Parent = detailPanel
end

function PetPenUI:UpdateCells(penData: any, playerPets: {any})
    if not cellsContainer then return end
    
    -- Store for later use
    currentPenData = penData
    currentPlayerPets = playerPets
    
    for i = 1, Constants.PEN_MAX_CELLS do
        local cellFrame = cellsContainer:FindFirstChild("Cell_" .. i)
        if cellFrame then
            local cellData = penData and penData.cells and penData.cells[i]
            self:UpdateCellDisplay(cellFrame, i, cellData, playerPets)
        end
    end
    
    -- If a cell is selected, update its details too
    if selectedCellIndex then
        self:ShowCellDetails(selectedCellIndex, penData, playerPets)
    end
end

function PetPenUI:UpdateCellDisplay(cellFrame: Frame, index: number, cellData: any?, playerPets: {any})
    local isLocked = index == 10
    local statusLabel = cellFrame:FindFirstChild("StatusLabel")
    local timerLabel = cellFrame:FindFirstChild("TimerLabel")
    local petsContainer = cellFrame:FindFirstChild("PetsContainer")
    local cellStroke = cellFrame:FindFirstChild("CellStroke")
    
    -- Clear existing pet icons
    if petsContainer then
        for _, child in ipairs(petsContainer:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end
    end
    
    -- Stop existing timer
    if timerConnections[index] then
        timerConnections[index]:Disconnect()
        timerConnections[index] = nil
    end
    
    if isLocked then
        cellFrame.BackgroundColor3 = COLORS.Locked
        if statusLabel then statusLabel.Text = "🔒 VIP" end
        if timerLabel then timerLabel.Text = "" end
        return
    end
    
    if not cellData or not cellData.pets or #cellData.pets == 0 then
        -- Empty cell
        cellFrame.BackgroundColor3 = COLORS.Empty
        if statusLabel then statusLabel.Text = "Empty" end
        if timerLabel then timerLabel.Text = "Click to add pets" end
    else
        -- Has pets
        local petCount = #cellData.pets
        
        -- Add pet icons
        for _, petUid in ipairs(cellData.pets) do
            local petInstance = self:FindPetByUid(playerPets, petUid)
            if petInstance and petsContainer then
                local template = Data.Pets.GetPet(petInstance.templateId)
                local icon = Instance.new("TextLabel")
                icon.Size = UDim2.new(0, 28, 0, 28)
                icon.BackgroundColor3 = COLORS.Background
                icon.Text = template and ELEMENT_ICONS[template.element] or "🐾"
                icon.TextSize = 18
                icon.Parent = petsContainer
                
                local iconCorner = Instance.new("UICorner")
                iconCorner.CornerRadius = UDim.new(0, 6)
                iconCorner.Parent = icon
            end
        end
        
        if cellData.mode == "Breeding" and cellData.startTime and cellData.duration then
            -- Breeding mode
            cellFrame.BackgroundColor3 = COLORS.Breeding
            if statusLabel then statusLabel.Text = "💕 Breeding" end
            
            -- Start timer update
            timerConnections[index] = RunService.Heartbeat:Connect(function()
                local elapsed = os.time() - cellData.startTime
                local remaining = math.max(0, cellData.duration - elapsed)
                
                if remaining <= 0 then
                    if timerLabel then timerLabel.Text = "✨ Ready!" end
                    cellFrame.BackgroundColor3 = COLORS.Accent
                else
                    if timerLabel then timerLabel.Text = Utils.FormatTime(remaining) end
                end
            end)
        elseif cellData.mode == "Rest" then
            -- Rest mode
            cellFrame.BackgroundColor3 = COLORS.Rest
            if statusLabel then statusLabel.Text = "😴 Resting" end
            if timerLabel then timerLabel.Text = "+XP" end
        else
            -- Just holding pets
            cellFrame.BackgroundColor3 = COLORS.Primary
            if statusLabel then statusLabel.Text = petCount .. " pet(s)" end
            if timerLabel then timerLabel.Text = "" end
        end
    end
end

function PetPenUI:FindPetByUid(pets: {any}, uid: string): any?
    for _, pet in ipairs(pets) do
        if pet.uid == uid then
            return pet
        end
    end
    return nil
end

function PetPenUI:SelectCell(index: number)
    selectedCellIndex = index
    
    -- Update cell highlights
    if cellsContainer then
        for i = 1, Constants.PEN_MAX_CELLS do
            local cellFrame = cellsContainer:FindFirstChild("Cell_" .. i)
            if cellFrame then
                local cellStroke = cellFrame:FindFirstChild("CellStroke")
                if cellStroke then
                    cellStroke.Color = (i == index) and COLORS.Primary or COLORS.BackgroundLight
                end
            end
        end
    end
    
    -- Show cell details with current data
    self:ShowCellDetails(index, currentPenData, currentPlayerPets)
end

function PetPenUI:ShowCellDetails(index: number, penData: any?, playerPets: {any}?)
    if not detailPanel then return end
    
    -- Clear existing content
    for _, child in ipairs(detailPanel:GetChildren()) do
        if not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    local isLocked = index == 10
    local cellData = penData and penData.cells and penData.cells[index]
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "📍 Cell #" .. index
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = COLORS.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = detailPanel
    
    if isLocked then
        -- Locked cell content
        local lockInfo = Instance.new("TextLabel")
        lockInfo.Size = UDim2.new(1, -20, 0, 100)
        lockInfo.Position = UDim2.new(0, 10, 0, 60)
        lockInfo.BackgroundTransparency = 1
        lockInfo.Text = "🔒\n\nThis cell requires\nVIP Gamepass\n\n199 Robux"
        lockInfo.TextSize = 14
        lockInfo.Font = Enum.Font.Gotham
        lockInfo.TextColor3 = COLORS.TextDim
        lockInfo.Parent = detailPanel
        
        local unlockBtn = Instance.new("TextButton")
        unlockBtn.Size = UDim2.new(1, -30, 0, 45)
        unlockBtn.Position = UDim2.new(0, 15, 0, 180)
        unlockBtn.BackgroundColor3 = COLORS.Accent
        unlockBtn.Text = "🛒 Unlock VIP Cell"
        unlockBtn.TextSize = 14
        unlockBtn.Font = Enum.Font.GothamBold
        unlockBtn.TextColor3 = COLORS.Text
        unlockBtn.Parent = detailPanel
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = unlockBtn
        
        return
    end
    
    -- Check cell state
    local hasPets = cellData and cellData.pets and #cellData.pets > 0
    local isBreeding = cellData and cellData.mode == "Breeding"
    local isReady = cellData and cellData.isReady == true
    local petCount = cellData and cellData.pets and #cellData.pets or 0
    
    -- Status info
    local statusInfo = Instance.new("TextLabel")
    statusInfo.Name = "StatusInfo"
    statusInfo.Size = UDim2.new(1, -20, 0, 60)
    statusInfo.Position = UDim2.new(0, 10, 0, 50)
    statusInfo.BackgroundTransparency = 1
    statusInfo.TextSize = 13
    statusInfo.Font = Enum.Font.Gotham
    statusInfo.TextColor3 = COLORS.TextDim
    statusInfo.TextWrapped = true
    statusInfo.Parent = detailPanel
    
    if isReady then
        statusInfo.Text = "✨ Breeding complete!\nClick Collect to get your new pet!"
        statusInfo.TextColor3 = COLORS.Accent
    elseif isBreeding then
        statusInfo.Text = "💕 Breeding in progress...\nWait for the timer to complete."
        statusInfo.TextColor3 = COLORS.Breeding
    elseif hasPets then
        if petCount == 1 then
            statusInfo.Text = "😴 Pet is resting.\nAdd more pets to breed, or let it rest for XP."
        else
            statusInfo.Text = "Ready to breed!\nClick Start Breeding to begin."
        end
    else
        statusInfo.Text = "Add 1-3 pets to this cell.\n1 pet = Rest | 2-3 pets = Breeding"
    end
    
    -- Pet slots (3 slots)
    local slotsFrame = Instance.new("Frame")
    slotsFrame.Name = "PetSlots"
    slotsFrame.Size = UDim2.new(1, -20, 0, 80)
    slotsFrame.Position = UDim2.new(0, 10, 0, 120)
    slotsFrame.BackgroundTransparency = 1
    slotsFrame.Parent = detailPanel
    
    local slotsLayout = Instance.new("UIListLayout")
    slotsLayout.FillDirection = Enum.FillDirection.Horizontal
    slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    slotsLayout.Padding = UDim.new(0, 10)
    slotsLayout.Parent = slotsFrame
    
    for i = 1, 3 do
        local slot = Instance.new("Frame")
        slot.Name = "Slot_" .. i
        slot.Size = UDim2.new(0, 80, 0, 80)
        slot.BackgroundColor3 = COLORS.Background
        slot.BorderSizePixel = 0
        slot.Parent = slotsFrame
        
        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 10)
        slotCorner.Parent = slot
        
        local slotStroke = Instance.new("UIStroke")
        slotStroke.Color = COLORS.BackgroundLight
        slotStroke.Thickness = 2
        slotStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        slotStroke.Parent = slot
        
        -- Show pet in slot if exists
        if cellData and cellData.pets and cellData.pets[i] and playerPets then
            local petUid = cellData.pets[i]
            local petInstance = self:FindPetByUid(playerPets, petUid)
            if petInstance then
                local template = Data.Pets.GetPet(petInstance.templateId)
                local petIcon = Instance.new("TextLabel")
                petIcon.Size = UDim2.new(1, 0, 1, -20)
                petIcon.BackgroundTransparency = 1
                petIcon.Text = ELEMENT_ICONS[template and template.element or "Nature"] or "🐾"
                petIcon.TextSize = 35
                petIcon.Parent = slot
                
                local petName = Instance.new("TextLabel")
                petName.Size = UDim2.new(1, 0, 0, 18)
                petName.Position = UDim2.new(0, 0, 1, -18)
                petName.BackgroundTransparency = 1
                petName.Text = template and template.name or "Pet"
                petName.TextSize = 9
                petName.Font = Enum.Font.Gotham
                petName.TextColor3 = COLORS.TextDim
                petName.TextTruncate = Enum.TextTruncate.AtEnd
                petName.Parent = slot
                
                slotStroke.Color = COLORS.Primary
            end
        else
            local plusLabel = Instance.new("TextLabel")
            plusLabel.Size = UDim2.new(1, 0, 1, 0)
            plusLabel.BackgroundTransparency = 1
            plusLabel.Text = "+"
            plusLabel.TextSize = 30
            plusLabel.Font = Enum.Font.GothamBold
            plusLabel.TextColor3 = COLORS.TextDim
            plusLabel.Parent = slot
        end
    end
    
    -- Action buttons
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Name = "Actions"
    actionsFrame.Size = UDim2.new(1, -20, 0, 160)
    actionsFrame.Position = UDim2.new(0, 10, 1, -175)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Parent = detailPanel
    
    -- COLLECT BUTTON (shown when breeding is ready)
    if isReady then
        local collectBtn = Instance.new("TextButton")
        collectBtn.Name = "CollectBtn"
        collectBtn.Size = UDim2.new(1, 0, 0, 50)
        collectBtn.Position = UDim2.new(0, 0, 0, 0)
        collectBtn.BackgroundColor3 = COLORS.Accent
        collectBtn.Text = "✨ COLLECT NEW PET! ✨"
        collectBtn.TextSize = 16
        collectBtn.Font = Enum.Font.GothamBold
        collectBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
        collectBtn.Parent = actionsFrame
        
        collectBtn.MouseButton1Click:Connect(function()
            print("[PetPenUI] Collect button clicked for cell", index)
            local Remotes = Shared.Remotes
            Remotes.CollectBreeding:FireServer(index)
        end)
        
        local collectCorner = Instance.new("UICorner")
        collectCorner.CornerRadius = UDim.new(0, 10)
        collectCorner.Parent = collectBtn
        
        -- Pulsing animation
        task.spawn(function()
            while collectBtn and collectBtn.Parent do
                TweenService:Create(collectBtn, TweenInfo.new(0.5), {
                    BackgroundColor3 = Color3.fromRGB(255, 220, 100)
                }):Play()
                task.wait(0.5)
                TweenService:Create(collectBtn, TweenInfo.new(0.5), {
                    BackgroundColor3 = COLORS.Accent
                }):Play()
                task.wait(0.5)
            end
        end)
    else
        -- SELECT PETS button
        local selectPetsBtn = Instance.new("TextButton")
        selectPetsBtn.Name = "SelectPetsBtn"
        selectPetsBtn.Size = UDim2.new(1, 0, 0, 42)
        selectPetsBtn.Position = UDim2.new(0, 0, 0, 0)
        selectPetsBtn.BackgroundColor3 = COLORS.Primary
        selectPetsBtn.Text = "🐾 Select Pets"
        selectPetsBtn.TextSize = 14
        selectPetsBtn.Font = Enum.Font.GothamBold
        selectPetsBtn.TextColor3 = COLORS.Text
        selectPetsBtn.Parent = actionsFrame
        
        -- Disable if breeding in progress
        if isBreeding then
            selectPetsBtn.BackgroundColor3 = COLORS.BackgroundLight
            selectPetsBtn.TextColor3 = COLORS.TextDim
        else
            selectPetsBtn.MouseButton1Click:Connect(function()
                local PetPenController = require(script.Parent.Parent.Parent.Controllers.PetPenController)
                PetPenController:OpenPetSelection(index)
            end)
        end
        
        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 8)
        selectCorner.Parent = selectPetsBtn
        
        -- START BREEDING button
        local startBreedingBtn = Instance.new("TextButton")
        startBreedingBtn.Name = "StartBreedingBtn"
        startBreedingBtn.Size = UDim2.new(1, 0, 0, 42)
        startBreedingBtn.Position = UDim2.new(0, 0, 0, 52)
        startBreedingBtn.BackgroundColor3 = COLORS.Breeding
        startBreedingBtn.Text = "💕 Start Breeding"
        startBreedingBtn.TextSize = 14
        startBreedingBtn.Font = Enum.Font.GothamBold
        startBreedingBtn.TextColor3 = COLORS.Text
        startBreedingBtn.Parent = actionsFrame
        
        -- Disable if not enough pets or already breeding
        if petCount < 2 or isBreeding then
            startBreedingBtn.BackgroundColor3 = COLORS.BackgroundLight
            startBreedingBtn.TextColor3 = COLORS.TextDim
        else
            startBreedingBtn.MouseButton1Click:Connect(function()
                local Remotes = Shared.Remotes
                Remotes.StartBreeding:FireServer(index)
            end)
        end
        
        local breedCorner = Instance.new("UICorner")
        breedCorner.CornerRadius = UDim.new(0, 8)
        breedCorner.Parent = startBreedingBtn
        
        -- REMOVE PETS button (only if has pets and not breeding)
        if hasPets and not isBreeding then
            local removeBtn = Instance.new("TextButton")
            removeBtn.Name = "RemoveBtn"
            removeBtn.Size = UDim2.new(1, 0, 0, 36)
            removeBtn.Position = UDim2.new(0, 0, 0, 104)
            removeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
            removeBtn.Text = "Remove Pets"
            removeBtn.TextSize = 12
            removeBtn.Font = Enum.Font.Gotham
            removeBtn.TextColor3 = COLORS.Text
            removeBtn.Parent = actionsFrame
            
            removeBtn.MouseButton1Click:Connect(function()
                local Remotes = Shared.Remotes
                Remotes.RemovePetsFromPen:FireServer(index)
            end)
            
            local removeCorner = Instance.new("UICorner")
            removeCorner.CornerRadius = UDim.new(0, 8)
            removeCorner.Parent = removeBtn
        end
    end
end

function PetPenUI:Open()
    if screenGui then
        screenGui.Enabled = true
    end
    isOpen = true
    
    if mainFrame then
        mainFrame.Size = UDim2.new(0, 850, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 850, 0, 550)
        }):Play()
    end
end

function PetPenUI:Close()
    -- Stop all timers
    for index, connection in pairs(timerConnections) do
        connection:Disconnect()
    end
    timerConnections = {}
    
    if mainFrame then
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 850, 0, 0)
        })
        
        tween.Completed:Connect(function()
            if screenGui then
                screenGui.Enabled = false
            end
        end)
        
        tween:Play()
    end
    
    isOpen = false
    selectedCellIndex = nil
end

function PetPenUI:IsOpen(): boolean
    return isOpen
end

function PetPenUI:GetSelectedCell(): number?
    return selectedCellIndex
end

function PetPenUI:Destroy()
    for _, connection in pairs(timerConnections) do
        connection:Disconnect()
    end
    if screenGui then screenGui:Destroy() end
end

return PetPenUI
