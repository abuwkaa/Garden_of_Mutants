--!strict
--[[
    EggInventory UI
    Shows all eggs and hatching controls
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local EggInventory = {}

-- Colors
local COLORS = {
    Background = Color3.fromRGB(20, 20, 30),
    Panel = Color3.fromRGB(35, 35, 50),
    Card = Color3.fromRGB(45, 45, 65),
    CardHover = Color3.fromRGB(55, 55, 75),
    CardReady = Color3.fromRGB(60, 80, 60),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Primary = Color3.fromRGB(100, 200, 100),
    Secondary = Color3.fromRGB(100, 150, 255),
    Warning = Color3.fromRGB(255, 200, 100),
    Gems = Color3.fromRGB(200, 100, 255),
    
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
local eggsContainer: ScrollingFrame?
local detailsPanel: Frame?
local isOpen = false
local currentEggs = {}
local currentCurrencies = {}
local selectedEggUid: string? = nil
local onCloseCallback: (() -> ())? = nil
local updateConnection: RBXScriptConnection?

function EggInventory:Create()
    if screenGui then return end
    
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "EggInventoryUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Enabled = false
    screenGui.Parent = PlayerGui
    
    -- Main frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 700, 0, 500)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = COLORS.Background
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
    header.BackgroundColor3 = COLORS.Panel
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 300, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🥚 Egg Incubator"
    title.TextColor3 = COLORS.Text
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 40, 0, 40)
    closeBtn.Position = UDim2.new(1, -45, 0, 5)
    closeBtn.BackgroundColor3 = COLORS.Card
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -60)
    content.Position = UDim2.new(0, 10, 0, 55)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Eggs grid (left side)
    local eggsFrame = Instance.new("Frame")
    eggsFrame.Name = "EggsFrame"
    eggsFrame.Size = UDim2.new(0, 380, 1, 0)
    eggsFrame.BackgroundColor3 = COLORS.Panel
    eggsFrame.BorderSizePixel = 0
    eggsFrame.Parent = content
    
    local eggsFrameCorner = Instance.new("UICorner")
    eggsFrameCorner.CornerRadius = UDim.new(0, 8)
    eggsFrameCorner.Parent = eggsFrame
    
    -- Eggs scroll container
    eggsContainer = Instance.new("ScrollingFrame")
    eggsContainer.Name = "EggsContainer"
    eggsContainer.Size = UDim2.new(1, -16, 1, -16)
    eggsContainer.Position = UDim2.new(0, 8, 0, 8)
    eggsContainer.BackgroundTransparency = 1
    eggsContainer.ScrollBarThickness = 6
    eggsContainer.ScrollBarImageColor3 = COLORS.Primary
    eggsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    eggsContainer.Parent = eggsFrame
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 110, 0, 130)
    gridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = eggsContainer
    
    -- Details panel (right side)
    detailsPanel = Instance.new("Frame")
    detailsPanel.Name = "DetailsPanel"
    detailsPanel.Size = UDim2.new(0, 280, 1, 0)
    detailsPanel.Position = UDim2.new(0, 395, 0, 0)
    detailsPanel.BackgroundColor3 = COLORS.Panel
    detailsPanel.BorderSizePixel = 0
    detailsPanel.Parent = content
    
    local detailsCorner = Instance.new("UICorner")
    detailsCorner.CornerRadius = UDim.new(0, 8)
    detailsCorner.Parent = detailsPanel
    
    self:ShowEmptyDetails()
    
    print("[EggInventory] UI Created")
end

function EggInventory:Open(eggs: {any}, currencies: any, closeCallback: (() -> ())?)
    if not screenGui then return end
    
    currentEggs = eggs or {}
    currentCurrencies = currencies or {}
    onCloseCallback = closeCallback
    
    self:PopulateEggs()
    
    screenGui.Enabled = true
    isOpen = true
    
    -- Start update loop for timers
    if updateConnection then
        updateConnection:Disconnect()
    end
    updateConnection = game:GetService("RunService").Heartbeat:Connect(function()
        self:UpdateTimers()
    end)
    
    -- Animate in
    mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0.5, 0)
    })
    tween:Play()
end

function EggInventory:Close()
    if not screenGui then return end
    
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    local tween = TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, 0, 1.5, 0)
    })
    tween:Play()
    tween.Completed:Connect(function()
        screenGui.Enabled = false
        isOpen = false
        selectedEggUid = nil
        
        if onCloseCallback then
            onCloseCallback()
        end
    end)
end

function EggInventory:IsOpen(): boolean
    return isOpen
end

function EggInventory:UpdateData(eggs: {any}, currencies: any)
    currentEggs = eggs or {}
    currentCurrencies = currencies or {}
    
    if isOpen then
        self:PopulateEggs()
        
        if selectedEggUid then
            local egg = self:FindEggByUid(selectedEggUid)
            if egg then
                self:ShowEggDetails(egg)
            else
                selectedEggUid = nil
                self:ShowEmptyDetails()
            end
        end
    end
end

function EggInventory:PopulateEggs()
    if not eggsContainer then return end
    
    for _, child in ipairs(eggsContainer:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if #currentEggs == 0 then
        local noEggs = Instance.new("TextLabel")
        noEggs.Name = "NoEggs"
        noEggs.Size = UDim2.new(1, 0, 0, 100)
        noEggs.BackgroundTransparency = 1
        noEggs.Text = "🥚 No eggs yet!\n\nBreed pets to get eggs."
        noEggs.TextColor3 = COLORS.TextDim
        noEggs.TextSize = 16
        noEggs.Font = Enum.Font.Gotham
        noEggs.TextWrapped = true
        noEggs.Parent = eggsContainer
        return
    end
    
    for i, egg in ipairs(currentEggs) do
        self:CreateEggCard(egg, i)
    end
    
    local gridLayout = eggsContainer:FindFirstChildOfClass("UIGridLayout")
    if gridLayout then
        local rows = math.ceil(#currentEggs / 3)
        eggsContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 138)
    end
end

function EggInventory:CreateEggCard(egg: any, index: number)
    local rarityColor = COLORS[egg.rarity] or COLORS.Common
    local isHatching = egg.hatchingStartedAt ~= nil
    local isReady = self:IsEggReady(egg)
    
    local card = Instance.new("Frame")
    card.Name = "Egg_" .. egg.uid
    card.Size = UDim2.new(0, 110, 0, 130)
    card.BackgroundColor3 = isReady and COLORS.CardReady or COLORS.Card
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = eggsContainer
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local rarityStroke = Instance.new("UIStroke")
    rarityStroke.Color = rarityColor
    rarityStroke.Thickness = 2
    rarityStroke.Parent = card
    
    local eggIcon = Instance.new("TextLabel")
    eggIcon.Name = "EggIcon"
    eggIcon.Size = UDim2.new(1, 0, 0, 50)
    eggIcon.Position = UDim2.new(0, 0, 0, 5)
    eggIcon.BackgroundTransparency = 1
    eggIcon.Text = "🥚"
    eggIcon.TextSize = 40
    eggIcon.Font = Enum.Font.GothamBold
    eggIcon.Parent = card
    
    local elementLabel = Instance.new("TextLabel")
    elementLabel.Name = "Element"
    elementLabel.Size = UDim2.new(0, 24, 0, 24)
    elementLabel.Position = UDim2.new(1, -28, 0, 4)
    elementLabel.BackgroundTransparency = 1
    elementLabel.Text = ELEMENT_EMOJI[egg.element] or "❓"
    elementLabel.TextSize = 18
    elementLabel.Parent = card
    
    if egg.isMutant then
        local mutantBadge = Instance.new("TextLabel")
        mutantBadge.Name = "MutantBadge"
        mutantBadge.Size = UDim2.new(0, 24, 0, 24)
        mutantBadge.Position = UDim2.new(0, 4, 0, 4)
        mutantBadge.BackgroundTransparency = 1
        mutantBadge.Text = "🧬"
        mutantBadge.TextSize = 16
        mutantBadge.Parent = card
    end
    
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -8, 0, 18)
    rarityLabel.Position = UDim2.new(0, 4, 0, 55)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = egg.rarity
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.TextSize = 12
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = card
    
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, -8, 0, 20)
    statusLabel.Position = UDim2.new(0, 4, 0, 75)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = card
    
    if isReady then
        statusLabel.Text = "✨ Ready!"
        statusLabel.TextColor3 = COLORS.Primary
    elseif isHatching then
        statusLabel.Text = "⏳ Hatching..."
        statusLabel.TextColor3 = COLORS.Warning
    else
        statusLabel.Text = "💤 Not started"
        statusLabel.TextColor3 = COLORS.TextDim
    end
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(1, -8, 0, 18)
    timerLabel.Position = UDim2.new(0, 4, 0, 95)
    timerLabel.BackgroundTransparency = 1
    timerLabel.TextSize = 14
    timerLabel.Font = Enum.Font.GothamBold
    timerLabel.Parent = card
    
    if isHatching and not isReady then
        local remaining = self:GetRemainingTime(egg)
        timerLabel.Text = self:FormatTime(remaining)
        timerLabel.TextColor3 = COLORS.Warning
    elseif isReady then
        timerLabel.Text = "HATCH NOW!"
        timerLabel.TextColor3 = COLORS.Primary
    else
        timerLabel.Text = self:FormatTime(egg.hatchTime or Constants.EGG_BASE_HATCH_TIME)
        timerLabel.TextColor3 = COLORS.TextDim
    end
    
    local button = Instance.new("TextButton")
    button.Name = "ClickArea"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = card
    
    button.MouseButton1Click:Connect(function()
        selectedEggUid = egg.uid
        self:ShowEggDetails(egg)
        self:HighlightSelectedCard(card)
    end)
    
    button.MouseEnter:Connect(function()
        if selectedEggUid ~= egg.uid then
            TweenService:Create(card, TweenInfo.new(0.1), {
                BackgroundColor3 = COLORS.CardHover
            }):Play()
        end
    end)
    
    button.MouseLeave:Connect(function()
        if selectedEggUid ~= egg.uid then
            TweenService:Create(card, TweenInfo.new(0.1), {
                BackgroundColor3 = isReady and COLORS.CardReady or COLORS.Card
            }):Play()
        end
    end)
    
    -- Pulse animation for ready eggs
    if isReady then
        task.spawn(function()
            while card and card.Parent and isOpen do
                local pulse = TweenService:Create(eggIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextSize = 45
                })
                pulse:Play()
                pulse.Completed:Wait()
                
                local unpulse = TweenService:Create(eggIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextSize = 40
                })
                unpulse:Play()
                unpulse.Completed:Wait()
            end
        end)
    end
end

function EggInventory:HighlightSelectedCard(selectedCard: Frame)
    if not eggsContainer then return end
    
    for _, child in ipairs(eggsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Egg_") then
            local isSelected = child == selectedCard
            local stroke = child:FindFirstChildOfClass("UIStroke")
            if stroke then
                stroke.Thickness = isSelected and 3 or 2
            end
        end
    end
end

function EggInventory:ShowEmptyDetails()
    if not detailsPanel then return end
    
    for _, child in ipairs(detailsPanel:GetChildren()) do
        if not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    local emptyLabel = Instance.new("TextLabel")
    emptyLabel.Name = "EmptyLabel"
    emptyLabel.Size = UDim2.new(1, -20, 1, -20)
    emptyLabel.Position = UDim2.new(0, 10, 0, 10)
    emptyLabel.BackgroundTransparency = 1
    emptyLabel.Text = "🥚\n\nSelect an egg\nto see details"
    emptyLabel.TextColor3 = COLORS.TextDim
    emptyLabel.TextSize = 16
    emptyLabel.Font = Enum.Font.Gotham
    emptyLabel.TextWrapped = true
    emptyLabel.Parent = detailsPanel
end

function EggInventory:ShowEggDetails(egg: any)
    if not detailsPanel then return end
    
    for _, child in ipairs(detailsPanel:GetChildren()) do
        if not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    local rarityColor = COLORS[egg.rarity] or COLORS.Common
    local elementColor = COLORS[egg.element] or COLORS.Nature
    local isHatching = egg.hatchingStartedAt ~= nil
    local isReady = self:IsEggReady(egg)
    
    local yOffset = 15
    
    -- Large egg icon
    local eggIcon = Instance.new("TextLabel")
    eggIcon.Name = "EggIcon"
    eggIcon.Size = UDim2.new(1, 0, 0, 80)
    eggIcon.Position = UDim2.new(0, 0, 0, yOffset)
    eggIcon.BackgroundTransparency = 1
    eggIcon.Text = "🥚"
    eggIcon.TextSize = 60
    eggIcon.Font = Enum.Font.GothamBold
    eggIcon.Parent = detailsPanel
    yOffset = yOffset + 90
    
    -- Rarity
    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.Size = UDim2.new(1, -20, 0, 24)
    rarityLabel.Position = UDim2.new(0, 10, 0, yOffset)
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.Text = "⭐ " .. egg.rarity .. " Egg"
    rarityLabel.TextColor3 = rarityColor
    rarityLabel.TextSize = 18
    rarityLabel.Font = Enum.Font.GothamBold
    rarityLabel.Parent = detailsPanel
    yOffset = yOffset + 30
    
    -- Element
    local elementLabel = Instance.new("TextLabel")
    elementLabel.Name = "Element"
    elementLabel.Size = UDim2.new(1, -20, 0, 20)
    elementLabel.Position = UDim2.new(0, 10, 0, yOffset)
    elementLabel.BackgroundTransparency = 1
    elementLabel.Text = (ELEMENT_EMOJI[egg.element] or "❓") .. " " .. (egg.element or "Unknown") .. " Element"
    elementLabel.TextColor3 = elementColor
    elementLabel.TextSize = 14
    elementLabel.Font = Enum.Font.Gotham
    elementLabel.Parent = detailsPanel
    yOffset = yOffset + 25
    
    -- Mutation status
    if egg.isMutant then
        local mutantLabel = Instance.new("TextLabel")
        mutantLabel.Name = "Mutant"
        mutantLabel.Size = UDim2.new(1, -20, 0, 20)
        mutantLabel.Position = UDim2.new(0, 10, 0, yOffset)
        mutantLabel.BackgroundTransparency = 1
        mutantLabel.Text = "🧬 Mutant Tier " .. (egg.mutationTier or 1)
        mutantLabel.TextColor3 = COLORS.Epic
        mutantLabel.TextSize = 14
        mutantLabel.Font = Enum.Font.GothamBold
        mutantLabel.Parent = detailsPanel
        yOffset = yOffset + 25
    end
    
    yOffset = yOffset + 10
    
    -- Divider
    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, -30, 0, 1)
    divider.Position = UDim2.new(0, 15, 0, yOffset)
    divider.BackgroundColor3 = COLORS.Card
    divider.BorderSizePixel = 0
    divider.Parent = detailsPanel
    yOffset = yOffset + 15
    
    -- Status section
    local statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "StatusTitle"
    statusTitle.Size = UDim2.new(1, -20, 0, 20)
    statusTitle.Position = UDim2.new(0, 10, 0, yOffset)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "Status"
    statusTitle.TextColor3 = COLORS.TextDim
    statusTitle.TextSize = 12
    statusTitle.Font = Enum.Font.Gotham
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.Parent = detailsPanel
    yOffset = yOffset + 22
    
    local statusText = Instance.new("TextLabel")
    statusText.Name = "StatusText"
    statusText.Size = UDim2.new(1, -20, 0, 24)
    statusText.Position = UDim2.new(0, 10, 0, yOffset)
    statusText.BackgroundTransparency = 1
    statusText.TextSize = 16
    statusText.Font = Enum.Font.GothamBold
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = detailsPanel
    
    if isReady then
        statusText.Text = "✨ Ready to Hatch!"
        statusText.TextColor3 = COLORS.Primary
    elseif isHatching then
        local remaining = self:GetRemainingTime(egg)
        statusText.Text = "⏳ " .. self:FormatTime(remaining) .. " remaining"
        statusText.TextColor3 = COLORS.Warning
    else
        statusText.Text = "💤 Not started"
        statusText.TextColor3 = COLORS.TextDim
    end
    yOffset = yOffset + 40
    
    -- Action buttons
    if isReady then
        local hatchBtn = self:CreateButton("✨ HATCH NOW!", COLORS.Primary, yOffset)
        hatchBtn.Parent = detailsPanel
        
        hatchBtn.MouseButton1Click:Connect(function()
            local Remotes = require(Shared:WaitForChild("Remotes"))
            Remotes.CollectHatchedPet:FireServer(egg.uid)
            print("[EggInventory] Collecting hatched pet:", egg.uid)
        end)
        yOffset = yOffset + 50
        
    elseif isHatching then
        local cost = Constants.EGG_SPEED_UP_COST or 100
        local canAfford = currentCurrencies and currentCurrencies.gems and currentCurrencies.gems >= cost
        
        local speedBtn = self:CreateButton("⚡ Speed Up (" .. cost .. " 💎)", 
            canAfford and COLORS.Gems or COLORS.Card, yOffset)
        speedBtn.Parent = detailsPanel
        
        if canAfford then
            speedBtn.MouseButton1Click:Connect(function()
                local Remotes = require(Shared:WaitForChild("Remotes"))
                Remotes.SpeedUpHatching:FireServer(egg.uid)
                print("[EggInventory] Speeding up hatching:", egg.uid)
            end)
        end
        yOffset = yOffset + 50
        
    else
        local startBtn = self:CreateButton("🔥 Start Hatching", COLORS.Secondary, yOffset)
        startBtn.Parent = detailsPanel
        
        startBtn.MouseButton1Click:Connect(function()
            local Remotes = require(Shared:WaitForChild("Remotes"))
            Remotes.StartHatching:FireServer(egg.uid)
            print("[EggInventory] Starting hatching:", egg.uid)
        end)
        yOffset = yOffset + 50
        
        local timeInfo = Instance.new("TextLabel")
        timeInfo.Name = "TimeInfo"
        timeInfo.Size = UDim2.new(1, -20, 0, 20)
        timeInfo.Position = UDim2.new(0, 10, 0, yOffset)
        timeInfo.BackgroundTransparency = 1
        timeInfo.Text = "⏱️ Hatch time: " .. self:FormatTime(egg.hatchTime or Constants.EGG_BASE_HATCH_TIME)
        timeInfo.TextColor3 = COLORS.TextDim
        timeInfo.TextSize = 12
        timeInfo.Font = Enum.Font.Gotham
        timeInfo.Parent = detailsPanel
    end
end

function EggInventory:CreateButton(text: string, color: Color3, yOffset: number): TextButton
    local btn = Instance.new("TextButton")
    btn.Name = "ActionBtn"
    btn.Size = UDim2.new(1, -30, 0, 40)
    btn.Position = UDim2.new(0, 15, 0, yOffset)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = COLORS.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    return btn
end

function EggInventory:UpdateTimers()
    if not isOpen or not eggsContainer then return end
    
    for _, child in ipairs(eggsContainer:GetChildren()) do
        if child:IsA("Frame") and child.Name:match("^Egg_") then
            local uid = child.Name:gsub("Egg_", "")
            local egg = self:FindEggByUid(uid)
            
            if egg and egg.hatchingStartedAt then
                local timerLabel = child:FindFirstChild("Timer")
                local statusLabel = child:FindFirstChild("Status")
                local isReady = self:IsEggReady(egg)
                
                if timerLabel then
                    if isReady then
                        timerLabel.Text = "HATCH NOW!"
                        timerLabel.TextColor3 = COLORS.Primary
                    else
                        local remaining = self:GetRemainingTime(egg)
                        timerLabel.Text = self:FormatTime(remaining)
                        timerLabel.TextColor3 = COLORS.Warning
                    end
                end
                
                if statusLabel then
                    if isReady then
                        statusLabel.Text = "✨ Ready!"
                        statusLabel.TextColor3 = COLORS.Primary
                    else
                        statusLabel.Text = "⏳ Hatching..."
                        statusLabel.TextColor3 = COLORS.Warning
                    end
                end
            end
        end
    end
    
    -- Update details panel timer
    if selectedEggUid then
        local egg = self:FindEggByUid(selectedEggUid)
        if egg and egg.hatchingStartedAt and not self:IsEggReady(egg) then
            local statusText = detailsPanel and detailsPanel:FindFirstChild("StatusText")
            if statusText then
                local remaining = self:GetRemainingTime(egg)
                statusText.Text = "⏳ " .. self:FormatTime(remaining) .. " remaining"
            end
        end
    end
end

function EggInventory:IsEggReady(egg: any): boolean
    if not egg.hatchingStartedAt then return false end
    local hatchTime = egg.hatchTime or Constants.EGG_BASE_HATCH_TIME
    local elapsed = os.time() - egg.hatchingStartedAt
    return elapsed >= hatchTime
end

function EggInventory:GetRemainingTime(egg: any): number
    if not egg.hatchingStartedAt then
        return egg.hatchTime or Constants.EGG_BASE_HATCH_TIME
    end
    local hatchTime = egg.hatchTime or Constants.EGG_BASE_HATCH_TIME
    local elapsed = os.time() - egg.hatchingStartedAt
    return math.max(0, hatchTime - elapsed)
end

function EggInventory:FormatTime(seconds: number): string
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%d:%02d", mins, secs)
end

function EggInventory:FindEggByUid(uid: string): any?
    for _, egg in ipairs(currentEggs) do
        if egg.uid == uid then
            return egg
        end
    end
    return nil
end

return EggInventory
