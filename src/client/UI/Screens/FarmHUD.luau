--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Utils = Shared.Utils

local FarmHUD = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local leavesLabel: TextLabel?
local gemsLabel: TextLabel?
local shardsLabel: TextLabel?
local waterIndicator: Frame?

local COLORS = {
    Background = Color3.fromRGB(30, 30, 40),
    Primary = Color3.fromRGB(76, 175, 80),
    Secondary = Color3.fromRGB(33, 150, 243),
    Accent = Color3.fromRGB(255, 193, 7),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Water = Color3.fromRGB(33, 150, 243),
}

function FarmHUD:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FarmHUD"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    -- Currency Frame
    local frame = Instance.new("Frame")
    frame.Name = "CurrencyFrame"
    frame.Size = UDim2.new(0, 280, 0, 110)
    frame.Position = UDim2.new(1, -300, 0, 20)
    frame.BackgroundColor3 = COLORS.Background
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = frame
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 15)
    padding.Parent = frame
    
    leavesLabel = self:CreateRow("🍃 Leaves:", "0", COLORS.Primary, 1)
    leavesLabel.Parent = frame
    
    gemsLabel = self:CreateRow("💎 Gems:", "0", COLORS.Secondary, 2)
    gemsLabel.Parent = frame
    
    shardsLabel = self:CreateRow("✨ Shards:", "0", COLORS.Accent, 3)
    shardsLabel.Parent = frame
    
    -- Water Indicator
    waterIndicator = Instance.new("Frame")
    waterIndicator.Name = "WaterIndicator"
    waterIndicator.Size = UDim2.new(0, 180, 0, 50)
    waterIndicator.Position = UDim2.new(0.5, -90, 0, 20)
    waterIndicator.BackgroundColor3 = COLORS.Background
    waterIndicator.BackgroundTransparency = 0.2
    waterIndicator.BorderSizePixel = 0
    waterIndicator.Visible = false
    waterIndicator.Parent = screenGui
    
    local waterCorner = Instance.new("UICorner")
    waterCorner.CornerRadius = UDim.new(0, 10)
    waterCorner.Parent = waterIndicator
    
    local waterStroke = Instance.new("UIStroke")
    waterStroke.Color = COLORS.Water
    waterStroke.Thickness = 2
    waterStroke.Parent = waterIndicator
    
    local waterIcon = Instance.new("TextLabel")
    waterIcon.Name = "Icon"
    waterIcon.Size = UDim2.new(0, 40, 1, 0)
    waterIcon.Position = UDim2.new(0, 10, 0, 0)
    waterIcon.BackgroundTransparency = 1
    waterIcon.Text = "💧"
    waterIcon.TextSize = 28
    waterIcon.Font = Enum.Font.GothamBold
    waterIcon.Parent = waterIndicator
    
    local waterText = Instance.new("TextLabel")
    waterText.Name = "Text"
    waterText.Size = UDim2.new(1, -60, 1, 0)
    waterText.Position = UDim2.new(0, 50, 0, 0)
    waterText.BackgroundTransparency = 1
    waterText.Text = "Water Ready!"
    waterText.TextSize = 16
    waterText.Font = Enum.Font.GothamBold
    waterText.TextColor3 = COLORS.Water
    waterText.TextXAlignment = Enum.TextXAlignment.Left
    waterText.Parent = waterIndicator
    
    -- Animate water indicator
    task.spawn(function()
        while waterIndicator do
            if waterIndicator.Visible then
                TweenService:Create(waterIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(0.5, -90, 0, 25)
                }):Play()
                task.wait(0.5)
                TweenService:Create(waterIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(0.5, -90, 0, 20)
                }):Play()
                task.wait(0.5)
            else
                task.wait(0.1)
            end
        end
    end)
    
    print("[FarmHUD] Created")
    return screenGui
end

function FarmHUD:CreateRow(label: string, value: string, color: Color3, order: number): Frame
    local row = Instance.new("Frame")
    row.Name = label
    row.Size = UDim2.new(1, -20, 0, 28)
    row.BackgroundTransparency = 1
    row.LayoutOrder = order
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 120, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = color
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 100, 1, 0)
    valueLabel.Position = UDim2.new(1, -100, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = value
    valueLabel.TextSize = 18
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextColor3 = COLORS.Text
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = row
    
    return row
end

function FarmHUD:UpdateCurrencies(currencies: {Leaves: number, Gems: number, MutationShards: number})
    if leavesLabel then
        local v = leavesLabel:FindFirstChild("Value")
        if v then 
            local oldValue = tonumber((v.Text:gsub(",", ""))) or 0
            local newValue = currencies.Leaves
            v.Text = Utils.FormatNumber(newValue)
            
            -- Flash effect if increased
            if newValue > oldValue then
                self:FlashLabel(v, COLORS.Primary)
            end
        end
    end
    if gemsLabel then
        local v = gemsLabel:FindFirstChild("Value")
        if v then v.Text = Utils.FormatNumber(currencies.Gems) end
    end
    if shardsLabel then
        local v = shardsLabel:FindFirstChild("Value")
        if v then 
            local oldValue = tonumber((v.Text:gsub(",", ""))) or 0
            local newValue = currencies.MutationShards
            v.Text = Utils.FormatNumber(newValue)
            
            if newValue > oldValue then
                self:FlashLabel(v, COLORS.Accent)
            end
        end
    end
end

function FarmHUD:FlashLabel(label: TextLabel, color: Color3)
    local originalColor = label.TextColor3
    label.TextColor3 = color
    label.TextSize = 22
    
    TweenService:Create(label, TweenInfo.new(0.3), {
        TextColor3 = originalColor,
        TextSize = 18
    }):Play()
end

function FarmHUD:SetWaterIndicator(hasWater: boolean)
    if waterIndicator then
        if hasWater and not waterIndicator.Visible then
            waterIndicator.Visible = true
            waterIndicator.Size = UDim2.new(0, 0, 0, 50)
            TweenService:Create(waterIndicator, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                Size = UDim2.new(0, 180, 0, 50)
            }):Play()
        elseif not hasWater and waterIndicator.Visible then
            local tween = TweenService:Create(waterIndicator, TweenInfo.new(0.15), {
                Size = UDim2.new(0, 0, 0, 50)
            })
            tween.Completed:Connect(function()
                waterIndicator.Visible = false
            end)
            tween:Play()
        end
    end
end

function FarmHUD:Destroy()
    if screenGui then screenGui:Destroy() end
end

return FarmHUD
