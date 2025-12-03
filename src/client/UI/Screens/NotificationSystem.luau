--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NotificationSystem = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local container: Frame?
local notifications: {Frame} = {}

local TYPE_COLORS = {
    Success = Color3.fromRGB(76, 175, 80),
    Error = Color3.fromRGB(244, 67, 54),
    Info = Color3.fromRGB(33, 150, 243),
    Warning = Color3.fromRGB(255, 152, 0),
    Special = Color3.fromRGB(156, 39, 176),
    LevelUp = Color3.fromRGB(255, 193, 7),
}

local TYPE_ICONS = {
    Success = "✓",
    Error = "✕",
    Info = "ℹ",
    Warning = "⚠",
    Special = "★",
    LevelUp = "⬆",
}

function NotificationSystem:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 320, 0, 400)
    container.Position = UDim2.new(1, -340, 0, 150)
    container.BackgroundTransparency = 1
    container.Parent = screenGui
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container
    
    print("[NotificationSystem] Created")
    return screenGui
end

function NotificationSystem:Show(notificationType: string, message: string, duration: number?)
    if not container then return end
    
    local color = TYPE_COLORS[notificationType] or TYPE_COLORS.Info
    local icon = TYPE_ICONS[notificationType] or TYPE_ICONS.Info
    local dur = duration or 4
    
    -- Limit notifications
    if #notifications >= 5 then
        local oldest = table.remove(notifications, 1)
        if oldest then oldest:Destroy() end
    end
    
    local notif = Instance.new("Frame")
    notif.Name = "Notification"
    notif.Size = UDim2.new(1, 0, 0, 60)
    notif.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    notif.BackgroundTransparency = 0.05
    notif.BorderSizePixel = 0
    notif.ClipsDescendants = true
    notif.Parent = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notif
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = notif
    
    -- Color accent bar
    local colorBar = Instance.new("Frame")
    colorBar.Size = UDim2.new(0, 4, 1, 0)
    colorBar.BackgroundColor3 = color
    colorBar.BorderSizePixel = 0
    colorBar.Parent = notif
    
    local colorBarCorner = Instance.new("UICorner")
    colorBarCorner.CornerRadius = UDim.new(0, 10)
    colorBarCorner.Parent = colorBar
    
    -- Icon
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 36, 0, 36)
    iconLabel.Position = UDim2.new(0, 14, 0.5, -18)
    iconLabel.BackgroundColor3 = color
    iconLabel.BackgroundTransparency = 0.8
    iconLabel.Text = icon
    iconLabel.TextSize = 18
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = color
    iconLabel.Parent = notif
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 8)
    iconCorner.Parent = iconLabel
    
    -- Message
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, -10)
    label.Position = UDim2.new(0, 58, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = true
    label.Parent = notif
    
    table.insert(notifications, notif)
    
    -- Animate in
    notif.Position = UDim2.new(1, 20, 0, 0)
    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Auto remove
    task.delay(dur, function()
        local idx = table.find(notifications, notif)
        if idx then table.remove(notifications, idx) end
        
        local tween = TweenService:Create(notif, TweenInfo.new(0.2), {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1
        })
        tween.Completed:Connect(function()
            notif:Destroy()
        end)
        tween:Play()
    end)
end

function NotificationSystem:Destroy()
    if screenGui then screenGui:Destroy() end
end

return NotificationSystem
