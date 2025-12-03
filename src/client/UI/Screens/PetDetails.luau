--!strict
--[[
    PetDetails
    Shows detailed information about a selected pet
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data
local Utils = Shared.Utils
local Constants = Shared.Constants

local PetDetails = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local mainFrame: Frame?
local isOpen = false
local currentPetUid: string? = nil

local COLORS = {
    Background = Color3.fromRGB(25, 25, 35),
    BackgroundLight = Color3.fromRGB(40, 40, 55),
    Primary = Color3.fromRGB(76, 175, 80),
    Secondary = Color3.fromRGB(33, 150, 243),
    Accent = Color3.fromRGB(255, 193, 7),
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

function PetDetails:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PetDetails"
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
    mainFrame.Size = UDim2.new(0, 450, 0, 550)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -275)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = mainFrame
    
    print("[PetDetails] Created")
    return screenGui
end

function PetDetails:ShowPet(petInstance: any)
    if not mainFrame then return end
    currentPetUid = petInstance.uid
    
    -- Clear existing content
    for _, child in ipairs(mainFrame:GetChildren()) do
        if not child:IsA("UICorner") then
            child:Destroy()
        end
    end
    
    local template = Data.Pets.GetPet(petInstance.templateId)
    if not template then return end
    
    local rarityColor = COLORS[petInstance.rarity] or COLORS.Common
    local elementColor = ELEMENT_COLORS[template.element] or COLORS.Primary
    
    -- Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = rarityColor
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Header with pet preview
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 150)
    header.BackgroundColor3 = elementColor
    header.BackgroundTransparency = 0.7
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header
    
    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 20)
    headerFix.Position = UDim2.new(0, 0, 1, -20)
    headerFix.BackgroundColor3 = elementColor
    headerFix.BackgroundTransparency = 0.7
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -46, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    closeBtn.BackgroundTransparency = 0.5
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = COLORS.Text
    closeBtn.Parent = header
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 8)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Pet icon (large)
    local petIcon = Instance.new("TextLabel")
    petIcon.Name = "PetIcon"
    petIcon.Size = UDim2.new(0, 80, 0, 80)
    petIcon.Position = UDim2.new(0.5, -40, 0, 20)
    petIcon.BackgroundTransparency = 1
    petIcon.Text = "🐾"
    petIcon.TextSize = 60
    petIcon.Parent = header
    
    -- Pet name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "PetName"
    nameLabel.Size = UDim2.new(1, 0, 0, 30)
    nameLabel.Position = UDim2.new(0, 0, 0, 105)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = template.name
    nameLabel.TextSize = 22
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = COLORS.Text
    nameLabel.Parent = header
    
    -- Content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -30, 1, -170)
    content.Position = UDim2.new(0, 15, 0, 160)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Info row (Level, Rarity, Element)
    local infoRow = Instance.new("Frame")
    infoRow.Name = "InfoRow"
    infoRow.Size = UDim2.new(1, 0, 0, 40)
    infoRow.BackgroundTransparency = 1
    infoRow.Parent = content
    
    local infoLayout = Instance.new("UIListLayout")
    infoLayout.FillDirection = Enum.FillDirection.Horizontal
    infoLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    infoLayout.Padding = UDim.new(0, 15)
    infoLayout.Parent = infoRow
    
    -- Level badge
    local levelBadge = self:CreateInfoBadge("Lv. " .. petInstance.level, COLORS.Primary)
    levelBadge.Parent = infoRow
    
    -- Rarity badge
    local rarityBadge = self:CreateInfoBadge(petInstance.rarity, rarityColor)
    rarityBadge.Parent = infoRow
    
    -- Element badge
    local elementBadge = self:CreateInfoBadge(template.element, elementColor)
    elementBadge.Parent = infoRow
    
    -- Mutation badge (if applicable)
    if petInstance.mutationTier and petInstance.mutationTier > 0 then
        local mutBadge = self:CreateInfoBadge("Mutant T" .. petInstance.mutationTier, Color3.fromRGB(255, 0, 255))
        mutBadge.Parent = infoRow
    end
    
    -- Stats section
    local statsTitle = Instance.new("TextLabel")
    statsTitle.Name = "StatsTitle"
    statsTitle.Size = UDim2.new(1, 0, 0, 30)
    statsTitle.Position = UDim2.new(0, 0, 0, 50)
    statsTitle.BackgroundTransparency = 1
    statsTitle.Text = "📊 Stats"
    statsTitle.TextSize = 16
    statsTitle.Font = Enum.Font.GothamBold
    statsTitle.TextColor3 = COLORS.Text
    statsTitle.TextXAlignment = Enum.TextXAlignment.Left
    statsTitle.Parent = content
    
    local statsFrame = Instance.new("Frame")
    statsFrame.Name = "StatsFrame"
    statsFrame.Size = UDim2.new(1, 0, 0, 120)
    statsFrame.Position = UDim2.new(0, 0, 0, 80)
    statsFrame.BackgroundColor3 = COLORS.BackgroundLight
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = content
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 10)
    statsCorner.Parent = statsFrame
    
    -- Individual stats
    local stats = {
        {name = "HP", value = petInstance.stats.hp, max = 500, color = Color3.fromRGB(244, 67, 54)},
        {name = "ATK", value = petInstance.stats.atk, max = 100, color = Color3.fromRGB(255, 152, 0)},
        {name = "DEF", value = petInstance.stats.def, max = 100, color = Color3.fromRGB(33, 150, 243)},
        {name = "SPD", value = petInstance.stats.spd, max = 50, color = Color3.fromRGB(76, 175, 80)},
    }
    
    for i, stat in ipairs(stats) do
        self:CreateStatBar(statsFrame, stat, i)
    end
    
    -- XP Progress
    local xpTitle = Instance.new("TextLabel")
    xpTitle.Name = "XPTitle"
    xpTitle.Size = UDim2.new(1, 0, 0, 25)
    xpTitle.Position = UDim2.new(0, 0, 0, 210)
    xpTitle.BackgroundTransparency = 1
    xpTitle.Text = "✨ Experience"
    xpTitle.TextSize = 14
    xpTitle.Font = Enum.Font.GothamBold
    xpTitle.TextColor3 = COLORS.Text
    xpTitle.TextXAlignment = Enum.TextXAlignment.Left
    xpTitle.Parent = content
    
    local xpRequired = Utils.CalculateXPForLevel(petInstance.level + 1)
    local xpProgress = petInstance.xp / xpRequired
    
    local xpBarBg = Instance.new("Frame")
    xpBarBg.Name = "XPBarBg"
    xpBarBg.Size = UDim2.new(1, 0, 0, 20)
    xpBarBg.Position = UDim2.new(0, 0, 0, 235)
    xpBarBg.BackgroundColor3 = COLORS.BackgroundLight
    xpBarBg.BorderSizePixel = 0
    xpBarBg.Parent = content
    
    local xpBarCorner = Instance.new("UICorner")
    xpBarCorner.CornerRadius = UDim.new(0, 6)
    xpBarCorner.Parent = xpBarBg
    
    local xpBar = Instance.new("Frame")
    xpBar.Name = "XPBar"
    xpBar.Size = UDim2.new(math.min(1, xpProgress), 0, 1, 0)
    xpBar.BackgroundColor3 = COLORS.Accent
    xpBar.BorderSizePixel = 0
    xpBar.Parent = xpBarBg
    
    local xpBarFillCorner = Instance.new("UICorner")
    xpBarFillCorner.CornerRadius = UDim.new(0, 6)
    xpBarFillCorner.Parent = xpBar
    
    local xpText = Instance.new("TextLabel")
    xpText.Size = UDim2.new(1, 0, 1, 0)
    xpText.BackgroundTransparency = 1
    xpText.Text = petInstance.xp .. " / " .. xpRequired .. " XP"
    xpText.TextSize = 11
    xpText.Font = Enum.Font.GothamBold
    xpText.TextColor3 = COLORS.Text
    xpText.Parent = xpBarBg
    
    -- Abilities section
    local abilitiesTitle = Instance.new("TextLabel")
    abilitiesTitle.Name = "AbilitiesTitle"
    abilitiesTitle.Size = UDim2.new(1, 0, 0, 25)
    abilitiesTitle.Position = UDim2.new(0, 0, 0, 270)
    abilitiesTitle.BackgroundTransparency = 1
    abilitiesTitle.Text = "⚔️ Abilities"
    abilitiesTitle.TextSize = 14
    abilitiesTitle.Font = Enum.Font.GothamBold
    abilitiesTitle.TextColor3 = COLORS.Text
    abilitiesTitle.TextXAlignment = Enum.TextXAlignment.Left
    abilitiesTitle.Parent = content
    
    local abilitiesFrame = Instance.new("Frame")
    abilitiesFrame.Name = "AbilitiesFrame"
    abilitiesFrame.Size = UDim2.new(1, 0, 0, 40)
    abilitiesFrame.Position = UDim2.new(0, 0, 0, 295)
    abilitiesFrame.BackgroundTransparency = 1
    abilitiesFrame.Parent = content
    
    local abLayout = Instance.new("UIListLayout")
    abLayout.FillDirection = Enum.FillDirection.Horizontal
    abLayout.Padding = UDim.new(0, 10)
    abLayout.Parent = abilitiesFrame
    
    local abilityKeys = {"Q", "E", "R"}
    local abilityColors = {
        Q = Color3.fromRGB(76, 175, 80),
        E = Color3.fromRGB(33, 150, 243),
        R = Color3.fromRGB(255, 193, 7),
    }
    
    for _, key in ipairs(abilityKeys) do
        local abilityId = template.abilities[key]
        local abilityBtn = Instance.new("Frame")
        abilityBtn.Name = "Ability_" .. key
        abilityBtn.Size = UDim2.new(0, 130, 0, 36)
        abilityBtn.BackgroundColor3 = COLORS.BackgroundLight
        abilityBtn.BorderSizePixel = 0
        abilityBtn.Parent = abilitiesFrame
        
        local abCorner = Instance.new("UICorner")
        abCorner.CornerRadius = UDim.new(0, 8)
        abCorner.Parent = abilityBtn
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0, 30, 1, 0)
        keyLabel.BackgroundColor3 = abilityColors[key]
        keyLabel.Text = key
        keyLabel.TextSize = 14
        keyLabel.Font = Enum.Font.GothamBold
        keyLabel.TextColor3 = COLORS.Text
        keyLabel.Parent = abilityBtn
        
        local keyCorner = Instance.new("UICorner")
        keyCorner.CornerRadius = UDim.new(0, 8)
        keyCorner.Parent = keyLabel
        
        local abilityName = Instance.new("TextLabel")
        abilityName.Size = UDim2.new(1, -35, 1, 0)
        abilityName.Position = UDim2.new(0, 35, 0, 0)
        abilityName.BackgroundTransparency = 1
        abilityName.Text = abilityId:gsub("_", " "):gsub("^%l", string.upper)
        abilityName.TextSize = 11
        abilityName.Font = Enum.Font.Gotham
        abilityName.TextColor3 = COLORS.Text
        abilityName.TextTruncate = Enum.TextTruncate.AtEnd
        abilityName.TextXAlignment = Enum.TextXAlignment.Left
        abilityName.Parent = abilityBtn
    end
    
    -- Action buttons
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Name = "Actions"
    actionsFrame.Size = UDim2.new(1, 0, 0, 45)
    actionsFrame.Position = UDim2.new(0, 0, 1, -55)
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Parent = content
    
    local actionsLayout = Instance.new("UIListLayout")
    actionsLayout.FillDirection = Enum.FillDirection.Horizontal
    actionsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    actionsLayout.Padding = UDim.new(0, 15)
    actionsLayout.Parent = actionsFrame
    
    local equipBtn = self:CreateActionButton("📌 Equip", COLORS.Primary)
    equipBtn.Parent = actionsFrame
    
    -- Connect equip button
    equipBtn.MouseButton1Click:Connect(function()
        if currentPetUid then
            local Remotes = require(ReplicatedStorage:WaitForChild("Shared")).Remotes
            -- Equip to slot 1 by default (can be expanded later)
            Remotes.EquipPet:FireServer(currentPetUid, 1)
            self:Close()
        end
    end)
    
    local penBtn = self:CreateActionButton("🏠 To Pen", COLORS.Secondary)
    penBtn.Parent = actionsFrame
    
    -- Connect pen button
    penBtn.MouseButton1Click:Connect(function()
        if currentPetUid then
            -- Open Pet Pen UI
            self:Close()
            local PetPenController = require(script.Parent.Parent.Parent.Controllers.PetPenController)
            PetPenController:OpenPetPenUI()
        end
    end)
    
    self:Open()
end

function PetDetails:CreateInfoBadge(text: string, color: Color3): Frame
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 80, 0, 28)
    badge.BackgroundColor3 = color
    badge.BackgroundTransparency = 0.3
    badge.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = badge
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Parent = badge
    
    return badge
end

function PetDetails:CreateStatBar(parent: Frame, stat: any, index: number)
    local yPos = (index - 1) * 28 + 10
    
    local row = Instance.new("Frame")
    row.Name = stat.name .. "Row"
    row.Size = UDim2.new(1, -20, 0, 24)
    row.Position = UDim2.new(0, 10, 0, yPos)
    row.BackgroundTransparency = 1
    row.Parent = parent
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 40, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = stat.name
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = stat.color
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -100, 0, 12)
    barBg.Position = UDim2.new(0, 45, 0.5, -6)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = row
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = barBg
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(math.min(1, stat.value / stat.max), 0, 1, 0)
    bar.BackgroundColor3 = stat.color
    bar.BorderSizePixel = 0
    bar.Parent = barBg
    
    local barFillCorner = Instance.new("UICorner")
    barFillCorner.CornerRadius = UDim.new(0, 4)
    barFillCorner.Parent = bar
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 45, 1, 0)
    valueLabel.Position = UDim2.new(1, -45, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(stat.value)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row
end

function PetDetails:CreateActionButton(text: string, color: Color3): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 120, 0, 40)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 125, 0, 42)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 120, 0, 40)
        }):Play()
    end)
    
    return btn
end

function PetDetails:Open()
    if screenGui then
        screenGui.Enabled = true
    end
    isOpen = true
    
    if mainFrame then
        mainFrame.Size = UDim2.new(0, 450, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 450, 0, 550)
        }):Play()
    end
end

function PetDetails:Close()
    if mainFrame then
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 450, 0, 0)
        })
        
        tween.Completed:Connect(function()
            if screenGui then
                screenGui.Enabled = false
            end
        end)
        
        tween:Play()
    end
    
    isOpen = false
    currentPetUid = nil
end

function PetDetails:IsOpen(): boolean
    return isOpen
end

function PetDetails:GetCurrentPet(): string?
    return currentPetUid
end

function PetDetails:Destroy()
    if screenGui then screenGui:Destroy() end
end

return PetDetails
