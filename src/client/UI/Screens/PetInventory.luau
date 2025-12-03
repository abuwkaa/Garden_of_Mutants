--!strict
--[[
    PetInventory
    Shows all player's pets in a grid
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data
local Utils = Shared.Utils

local PetInventory = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local mainFrame: Frame?
local petGrid: ScrollingFrame?
local isOpen = false
local selectedPetUid: string? = nil
local onPetSelected: ((string) -> ())?

local COLORS = {
    Background = Color3.fromRGB(25, 25, 35),
    BackgroundLight = Color3.fromRGB(40, 40, 55),
    Primary = Color3.fromRGB(76, 175, 80),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(160, 160, 160),
    Common = Color3.fromRGB(180, 180, 180),
    Rare = Color3.fromRGB(33, 150, 243),
    Epic = Color3.fromRGB(156, 39, 176),
    Legendary = Color3.fromRGB(255, 193, 7),
}

local ELEMENT_COLORS = {
    Nature = Color3.fromRGB(76, 175, 80),
    Fire = Color3.fromRGB(244, 67, 54),
    Ice = Color3.fromRGB(33, 150, 243),
    Tech = Color3.fromRGB(255, 235, 59),
    Chaos = Color3.fromRGB(156, 39, 176),
}

local ELEMENT_ICONS = {
    Nature = "🌿",
    Fire = "🔥",
    Ice = "❄️",
    Tech = "⚡",
    Chaos = "🌀",
}

function PetInventory:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetInventory"
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
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header
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
    title.Size = UDim2.new(1, -120, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐾 My Pets"
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = COLORS.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Pet count
    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "PetCount"
    countLabel.Size = UDim2.new(0, 100, 0, 30)
    countLabel.Position = UDim2.new(1, -180, 0.5, -15)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0/50"
    countLabel.TextSize = 16
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextColor3 = COLORS.TextDim
    countLabel.Parent = header
    
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
    
    -- Filter tabs
    local filterFrame = Instance.new("Frame")
    filterFrame.Name = "Filters"
    filterFrame.Size = UDim2.new(1, -20, 0, 40)
    filterFrame.Position = UDim2.new(0, 10, 0, 70)
    filterFrame.BackgroundTransparency = 1
    filterFrame.Parent = mainFrame
    
    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 8)
    filterLayout.Parent = filterFrame
    
    local filters = {"All", "Nature", "Fire", "Ice", "Tech", "Chaos"}
    for i, filterName in ipairs(filters) do
        local filterBtn = Instance.new("TextButton")
        filterBtn.Name = "Filter_" .. filterName
        filterBtn.Size = UDim2.new(0, 80, 0, 32)
        filterBtn.BackgroundColor3 = i == 1 and COLORS.Primary or COLORS.BackgroundLight
        filterBtn.BorderSizePixel = 0
        filterBtn.Text = filterName
        filterBtn.TextSize = 13
        filterBtn.Font = Enum.Font.GothamBold
        filterBtn.TextColor3 = COLORS.Text
        filterBtn.LayoutOrder = i
        filterBtn.Parent = filterFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = filterBtn
        
        filterBtn.MouseButton1Click:Connect(function()
            self:SetFilter(filterName)
        end)
    end
    
    -- Pet grid
    petGrid = Instance.new("ScrollingFrame")
    petGrid.Name = "PetGrid"
    petGrid.Size = UDim2.new(1, -20, 1, -130)
    petGrid.Position = UDim2.new(0, 10, 0, 120)
    petGrid.BackgroundTransparency = 1
    petGrid.ScrollBarThickness = 6
    petGrid.ScrollBarImageColor3 = COLORS.Primary
    petGrid.CanvasSize = UDim2.new(0, 0, 0, 0)
    petGrid.Parent = mainFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 130, 0, 160)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = petGrid
    
    print("[PetInventory] Created")
    return screenGui
end

function PetInventory:CreatePetCard(petInstance: any): Frame
    local template = Data.Pets.GetPet(petInstance.templateId)
    if not template then return Instance.new("Frame") end
    
    local rarityColor = COLORS[petInstance.rarity] or COLORS.Common
    local elementColor = ELEMENT_COLORS[template.element] or COLORS.Primary
    local elementIcon = ELEMENT_ICONS[template.element] or "❓"
    
    local card = Instance.new("TextButton")
    card.Name = "Pet_" .. petInstance.uid
    card.Size = UDim2.new(0, 130, 0, 160)
    card.BackgroundColor3 = COLORS.BackgroundLight
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = rarityColor
    cardStroke.Thickness = 2
    cardStroke.Parent = card
    
    -- Element bar
    local elementBar = Instance.new("Frame")
    elementBar.Name = "ElementBar"
    elementBar.Size = UDim2.new(1, 0, 0, 4)
    elementBar.BackgroundColor3 = elementColor
    elementBar.BorderSizePixel = 0
    elementBar.Parent = card
    
    local elementBarCorner = Instance.new("UICorner")
    elementBarCorner.CornerRadius = UDim.new(0, 12)
    elementBarCorner.Parent = elementBar
    
    -- Pet icon (emoji placeholder)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(1, 0, 0, 50)
    icon.Position = UDim2.new(0, 0, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = elementIcon
    icon.TextSize = 40
    icon.Parent = card
    
    -- Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -10, 0, 24)
    nameLabel.Position = UDim2.new(0, 5, 0, 62)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = template.name
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Level
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "Level"
    levelLabel.Size = UDim2.new(1, -10, 0, 18)
    levelLabel.Position = UDim2.new(0, 5, 0, 86)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv. " .. (tonumber(petInstance.level) or 1)
    levelLabel.TextSize = 11
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextColor3 = COLORS.TextDim
    levelLabel.Parent = card
    
    -- Rarity badge
    local rarityBadge = Instance.new("Frame")
    rarityBadge.Name = "RarityBadge"
    rarityBadge.Size = UDim2.new(0, 60, 0, 20)
    rarityBadge.Position = UDim2.new(0.5, -30, 0, 106)
    rarityBadge.BackgroundColor3 = rarityColor
    rarityBadge.BorderSizePixel = 0
    rarityBadge.Parent = card
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = rarityBadge
    
    local rarityText = Instance.new("TextLabel")
    rarityText.Size = UDim2.new(1, 0, 1, 0)
    rarityText.BackgroundTransparency = 1
    rarityText.Text = petInstance.rarity
    rarityText.TextSize = 10
    rarityText.Font = Enum.Font.GothamBold
    rarityText.TextColor3 = COLORS.Text
    rarityText.Parent = rarityBadge
    
    -- Mutation indicator
    if petInstance.mutationTier and petInstance.mutationTier > 0 then
        local mutationBadge = Instance.new("TextLabel")
        mutationBadge.Name = "MutationBadge"
        mutationBadge.Size = UDim2.new(0, 24, 0, 24)
        mutationBadge.Position = UDim2.new(1, -28, 0, 8)
        mutationBadge.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
        mutationBadge.BorderSizePixel = 0
        mutationBadge.Text = "M" .. petInstance.mutationTier
        mutationBadge.TextSize = 10
        mutationBadge.Font = Enum.Font.GothamBold
        mutationBadge.TextColor3 = COLORS.Text
        mutationBadge.Parent = card
        
        local mutBadgeCorner = Instance.new("UICorner")
        mutBadgeCorner.CornerRadius = UDim.new(0, 12)
        mutBadgeCorner.Parent = mutationBadge
    end
    
    -- Stats preview
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsPreview"
    statsFrame.Size = UDim2.new(1, -10, 0, 24)
    statsFrame.Position = UDim2.new(0, 5, 1, -30)
    statsFrame.BackgroundTransparency = 1
    statsFrame.Parent = card
    
    local statsLayout = Instance.new("UIListLayout")
    statsLayout.FillDirection = Enum.FillDirection.Horizontal
    statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    statsLayout.Padding = UDim.new(0, 8)
    statsLayout.Parent = statsFrame
    
    local stats = {
        {icon = "❤️", value = petInstance.stats.hp},
        {icon = "⚔️", value = petInstance.stats.atk},
    }
    
    for _, stat in ipairs(stats) do
        local statLabel = Instance.new("TextLabel")
        statLabel.Size = UDim2.new(0, 45, 0, 20)
        statLabel.BackgroundTransparency = 1
        statLabel.Text = stat.icon .. stat.value
        statLabel.TextSize = 10
        statLabel.Font = Enum.Font.Gotham
        statLabel.TextColor3 = COLORS.TextDim
        statLabel.Parent = statsFrame
    end
    
    -- Click handler
    card.MouseButton1Click:Connect(function()
        self:SelectPet(petInstance.uid)
    end)
    
    -- Hover effect
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(55, 55, 75)
        }):Play()
    end)
    
    card.MouseLeave:Connect(function()
        TweenService:Create(card, TweenInfo.new(0.15), {
            BackgroundColor3 = COLORS.BackgroundLight
        }):Play()
    end)
    
    return card
end

function PetInventory:PopulatePets(pets: {any}, filter: string?)
    if not petGrid then return end
    
    -- Clear existing
    for _, child in ipairs(petGrid:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Filter and add pets
    local count = 0
    for _, pet in ipairs(pets) do
        local template = Data.Pets.GetPet(pet.templateId)
        local shouldShow = not filter or filter == "All" or (template and template.element == filter)
        
        if shouldShow then
            local card = self:CreatePetCard(pet)
            card.LayoutOrder = count
            card.Parent = petGrid
            count = count + 1
        end
    end
    
    -- Update canvas size
    local cols = 5
    local rows = math.ceil(count / cols)
    petGrid.CanvasSize = UDim2.new(0, 0, 0, rows * 170)
    
    -- Update count
    local header = mainFrame and mainFrame:FindFirstChild("Header")
    local countLabel = header and header:FindFirstChild("PetCount")
    if countLabel then
        countLabel.Text = count .. "/50"
    end
    
    -- Empty message
    if count == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyMessage"
        emptyLabel.Size = UDim2.new(1, 0, 0, 100)
        emptyLabel.Position = UDim2.new(0, 0, 0, 50)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text = "No pets yet!\nBreed pets in the Pet Pen or harvest rare plants."
        emptyLabel.TextSize = 16
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.TextColor3 = COLORS.TextDim
        emptyLabel.Parent = petGrid
    end
end

function PetInventory:SetFilter(filterName: string)
    if not mainFrame then return end
    
    local filterFrame = mainFrame:FindFirstChild("Filters")
    if filterFrame then
        for _, btn in ipairs(filterFrame:GetChildren()) do
            if btn:IsA("TextButton") then
                local isSelected = btn.Name == "Filter_" .. filterName
                btn.BackgroundColor3 = isSelected and COLORS.Primary or COLORS.BackgroundLight
            end
        end
    end
    
    -- Re-populate with filter
    -- This would be called by UIController with current pet data
    if onPetSelected then
        -- Trigger refresh through controller
    end
end

function PetInventory:SelectPet(petUid: string)
    selectedPetUid = petUid
    
    if onPetSelected then
        onPetSelected(petUid)
    end
end

function PetInventory:Open(callback: ((string) -> ())?)
    onPetSelected = callback
    
    if screenGui then
        screenGui.Enabled = true
    end
    isOpen = true
    
    -- Animate in
    if mainFrame then
        mainFrame.Position = UDim2.new(0.5, -350, 0.5, -200)
        mainFrame.Size = UDim2.new(0, 700, 0, 0)
        
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 700, 0, 500),
            Position = UDim2.new(0.5, -350, 0.5, -250)
        }):Play()
    end
end

function PetInventory:Close()
    if mainFrame then
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 700, 0, 0),
            Position = UDim2.new(0.5, -350, 0.5, -200)
        })
        
        tween.Completed:Connect(function()
            if screenGui then
                screenGui.Enabled = false
            end
        end)
        
        tween:Play()
    end
    
    isOpen = false
    selectedPetUid = nil
end

function PetInventory:IsOpen(): boolean
    return isOpen
end

function PetInventory:Destroy()
    if screenGui then screenGui:Destroy() end
end

return PetInventory
