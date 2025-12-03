--!strict
--[[
    PetSelectModal
    Modal for selecting pets (used by PetPenUI)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PetSelectModal = {}

local COLORS = {
    Background = Color3.fromRGB(0, 0, 0),
    Panel = Color3.fromRGB(35, 35, 50),
    Card = Color3.fromRGB(45, 45, 65),
    CardHover = Color3.fromRGB(55, 55, 75),
    CardSelected = Color3.fromRGB(70, 100, 70),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Primary = Color3.fromRGB(100, 200, 100),
    Secondary = Color3.fromRGB(100, 150, 255),
    
    Common = Color3.fromRGB(180, 180, 180),
    Rare = Color3.fromRGB(100, 150, 255),
    Epic = Color3.fromRGB(180, 100, 255),
    Legendary = Color3.fromRGB(255, 180, 50),
    
    Nature = Color3.fromRGB(100, 200, 100),
    Fire = Color3.fromRGB(255, 100, 50),
    Ice = Color3.fromRGB(100, 200, 255),
    Tech = Color3.fromRGB(255, 255, 100),
    Chaos = Color3.fromRGB(180, 100, 255),
}

local ELEMENT_EMOJI = {
    Nature = "🌿",
    Fire = "🔥",
    Ice = "❄️",
    Tech = "⚡",
    Chaos = "💜",
}

local screenGui: ScreenGui?
local mainFrame: Frame?
local petsContainer: ScrollingFrame?
local confirmButton: TextButton?
local isOpen = false
local selectedPets: {string} = {}
local maxSelection = 3
local onConfirmCallback: (({string}) -> ())?
local allPets = {}
local excludedPetUids = {}

function PetSelectModal:Create()
    if screenGui then return end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetSelectModalUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 100
    screenGui.Enabled = false
    screenGui.Parent = PlayerGui
    
    -- Dim background
    local dimBg = Instance.new("Frame")
    dimBg.Name = "DimBackground"
    dimBg.Size = UDim2.new(1, 0, 1, 0)
    dimBg.BackgroundColor3 = COLORS.Background
    dimBg.BackgroundTransparency = 0.5
    dimBg.BorderSizePixel = 0
    dimBg.Parent = screenGui
    
    dimBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:Close()
        end
    end)
    
    -- Main panel
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 500, 0, 450)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.Panel
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = COLORS.Card
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🐾 Select Pets (0/3)"
    title.TextColor3 = COLORS.Text
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -43, 0, 7)
    closeBtn.BackgroundColor3 = COLORS.Card
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Pets container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -120)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundColor3 = COLORS.Card
    content.BorderSizePixel = 0
    content.Parent = mainFrame
    
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = content
    
    petsContainer = Instance.new("ScrollingFrame")
    petsContainer.Name = "PetsContainer"
    petsContainer.Size = UDim2.new(1, -16, 1, -16)
    petsContainer.Position = UDim2.new(0, 8, 0, 8)
    petsContainer.BackgroundTransparency = 1
    petsContainer.ScrollBarThickness = 6
    petsContainer.ScrollBarImageColor3 = COLORS.Primary
    petsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    petsContainer.Parent = content
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 85, 0, 100)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = petsContainer
    
    -- Footer with confirm button
    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.Size = UDim2.new(1, -20, 0, 50)
    footer.Position = UDim2.new(0, 10, 1, -60)
    footer.BackgroundTransparency = 1
    footer.Parent = mainFrame
    
    confirmButton = Instance.new("TextButton")
    confirmButton.Name = "ConfirmBtn"
    confirmButton.Size = UDim2.new(1, 0, 0, 45)
    confirmButton.BackgroundColor3 = COLORS.Primary
    confirmButton.Text = "✓ Confirm Selection"
    confirmButton.TextColor3 = COLORS.Text
    confirmButton.TextSize = 16
    confirmButton.Font = Enum.Font.GothamBold
    confirmButton.Parent = footer
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmButton
    
    confirmButton.MouseButton1Click:Connect(function()
        if #selectedPets > 0 and onConfirmCallback then
            onConfirmCallback(selectedPets)
        end
        self:Close()
    end)
    
    print("[PetSelectModal] Created")
end

function PetSelectModal:Open(callback: (({string}) -> ())?, maxPets: number?)
    if not screenGui then return end
    
    onConfirmCallback = callback
    maxSelection = maxPets or 3
    selectedPets = {}
    
    self:UpdateTitle()
    self:UpdateConfirmButton()
    
    screenGui.Enabled = true
    isOpen = true
    
    -- Animate in
    mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
end

function PetSelectModal:Close()
    if not screenGui then return end
    
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        screenGui.Enabled = false
        isOpen = false
        selectedPets = {}
    end)
end

function PetSelectModal:IsOpen(): boolean
    return isOpen
end

function PetSelectModal:PopulatePets(pets: {any}, excluded: {string}?)
    if not petsContainer then return end
    
    allPets = pets or {}
    excludedPetUids = excluded or {}
    
    -- Clear existing
    for _, child in ipairs(petsContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Create pet cards
    local availableCount = 0
    for i, pet in ipairs(allPets) do
        local isExcluded = table.find(excludedPetUids, pet.uid) ~= nil
        if not isExcluded then
            availableCount = availableCount + 1
            self:CreatePetCard(pet, availableCount)
        end
    end
    
    -- Update canvas size
    local gridLayout = petsContainer:FindFirstChildOfClass("UIGridLayout")
    if gridLayout then
        local cols = 5
        local rows = math.ceil(availableCount / cols)
        petsContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 108)
    end
end

function PetSelectModal:CreatePetCard(pet: any, index: number)
    local rarityColor = COLORS[pet.rarity] or COLORS.Common
    local isSelected = table.find(selectedPets, pet.uid) ~= nil
    
    local card = Instance.new("Frame")
    card.Name = "Pet_" .. pet.uid
    card.Size = UDim2.new(0, 85, 0, 100)
    card.BackgroundColor3 = isSelected and COLORS.CardSelected or COLORS.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = petsContainer
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local rarityStroke = Instance.new("UIStroke")
    rarityStroke.Color = rarityColor
    rarityStroke.Thickness = isSelected and 3 or 2
    rarityStroke.Parent = card
    
    -- Element emoji
    local elementLabel = Instance.new("TextLabel")
    elementLabel.Name = "Element"
    elementLabel.Size = UDim2.new(1, 0, 0, 30)
    elementLabel.Position = UDim2.new(0, 0, 0, 5)
    elementLabel.BackgroundTransparency = 1
    elementLabel.Text = ELEMENT_EMOJI[pet.element] or "❓"
    elementLabel.TextSize = 24
    elementLabel.Parent = card
    
    -- Pet name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.Size = UDim2.new(1, -6, 0, 14)
    nameLabel.Position = UDim2.new(0, 3, 0, 38)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = pet.name
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.TextSize = 10
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card
    
    -- Level
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Name = "Level"
    levelLabel.Size = UDim2.new(1, 0, 0, 14)
    levelLabel.Position = UDim2.new(0, 0, 0, 54)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv." .. pet.level
    levelLabel.TextColor3 = COLORS.TextDim
    levelLabel.TextSize = 11
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.Parent = card
    
    -- Rarity
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, 0, 0, 12)
    rarityLabel.Position = UDim2.new(0, 0, 0, 70)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = pet.rarity
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.TextSize = 9
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = card
    
    -- Selection checkmark
    if isSelected then
        local checkmark = Instance.new("TextLabel")
        checkmark.Name = "Checkmark"
        checkmark.Size = UDim2.new(0, 24, 0, 24)
        checkmark.Position = UDim2.new(1, -26, 0, 2)
        checkmark.BackgroundColor3 = COLORS.Primary
        checkmark.Text = "✓"
        checkmark.TextColor3 = COLORS.Text
        checkmark.TextSize = 14
        checkmark.Font = Enum.Font.GothamBold
        checkmark.Parent = card
        
        local checkCorner = Instance.new("UICorner")
        checkCorner.CornerRadius = UDim.new(0, 12)
        checkCorner.Parent = checkmark
    end
    
    -- Click button
    local button = Instance.new("TextButton")
    button.Name = "ClickArea"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        self:TogglePetSelection(pet.uid)
    end)
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        if not table.find(selectedPets, pet.uid) then
            TweenService:Create(card, TweenInfo.new(0.1), {
                BackgroundColor3 = COLORS.CardHover
            }):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        local isStillSelected = table.find(selectedPets, pet.uid) ~= nil
        TweenService:Create(card, TweenInfo.new(0.1), {
            BackgroundColor3 = isStillSelected and COLORS.CardSelected or COLORS.Card
        }):Play()
    end)
end

function PetSelectModal:TogglePetSelection(petUid: string)
    local index = table.find(selectedPets, petUid)
    
    if index then
        -- Deselect
        table.remove(selectedPets, index)
    else
        -- Select (if not at max)
        if #selectedPets < maxSelection then
            table.insert(selectedPets, petUid)
        else
            -- At max, show feedback
            return
        end
    end
    
    -- Refresh display
    self:PopulatePets(allPets, excludedPetUids)
    self:UpdateTitle()
    self:UpdateConfirmButton()
end

function PetSelectModal:UpdateTitle()
    local header = mainFrame and mainFrame:FindFirstChild("Header")
    local title = header and header:FindFirstChild("Title")
    if title then
        title.Text = "🐾 Select Pets (" .. #selectedPets .. "/" .. maxSelection .. ")"
    end
end

function PetSelectModal:UpdateConfirmButton()
    if confirmButton then
        local canConfirm = #selectedPets > 0
        confirmButton.BackgroundColor3 = canConfirm and COLORS.Primary or COLORS.Card
        confirmButton.Text = canConfirm and ("✓ Confirm (" .. #selectedPets .. " pets)") or "Select at least 1 pet"
    end
end

return PetSelectModal
