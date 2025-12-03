--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data
local Utils = Shared.Utils

local PlotInfoPanel = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local mainFrame: Frame?
local progressBar: Frame?
local progressText: TextLabel?
local isOpen = false
local currentPlotIndex: number? = nil
local currentPlotData: any? = nil
local updateConnection: RBXScriptConnection?
local onPlantClicked: (() -> ())?
local onHarvestClicked: (() -> ())?
local onWaterClicked: (() -> ())?

local COLORS = {
    Background = Color3.fromRGB(30, 30, 40),
    Primary = Color3.fromRGB(76, 175, 80),
    Secondary = Color3.fromRGB(33, 150, 243),
    Accent = Color3.fromRGB(255, 193, 7),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
}

function PlotInfoPanel:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PlotInfoPanel"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 180)
    mainFrame.Position = UDim2.new(0.5, -160, 1, -200)
    mainFrame.BackgroundColor3 = COLORS.Background
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = COLORS.Primary
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -20, 0, 30)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Plot #1"
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = COLORS.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = mainFrame
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "✕"
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextColor3 = COLORS.TextDim
    closeBtn.Parent = mainFrame
    
    local closeBtnCorner = Instance.new("UICorner")
    closeBtnCorner.CornerRadius = UDim.new(0, 6)
    closeBtnCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 24)
    status.Position = UDim2.new(0, 10, 0, 42)
    status.BackgroundTransparency = 1
    status.Text = "Empty"
    status.TextSize = 14
    status.Font = Enum.Font.Gotham
    status.TextColor3 = COLORS.TextDim
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = mainFrame
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Size = UDim2.new(1, -20, 0, 24)
    progressBg.Position = UDim2.new(0, 10, 0, 72)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    progressBg.BorderSizePixel = 0
    progressBg.Visible = false
    progressBg.Parent = mainFrame
    
    local progressBgCorner = Instance.new("UICorner")
    progressBgCorner.CornerRadius = UDim.new(0, 6)
    progressBgCorner.Parent = progressBg
    
    progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(0, 0, 1, 0)
    progressBar.BackgroundColor3 = COLORS.Primary
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg
    
    local progressBarCorner = Instance.new("UICorner")
    progressBarCorner.CornerRadius = UDim.new(0, 6)
    progressBarCorner.Parent = progressBar
    
    progressText = Instance.new("TextLabel")
    progressText.Name = "ProgressText"
    progressText.Size = UDim2.new(1, 0, 1, 0)
    progressText.BackgroundTransparency = 1
    progressText.Text = "0:00"
    progressText.TextSize = 12
    progressText.Font = Enum.Font.GothamBold
    progressText.TextColor3 = COLORS.Text
    progressText.ZIndex = 2
    progressText.Parent = progressBg
    
    -- Buttons frame
    local btnFrame = Instance.new("Frame")
    btnFrame.Name = "Buttons"
    btnFrame.Size = UDim2.new(1, -20, 0, 44)
    btnFrame.Position = UDim2.new(0, 10, 1, -54)
    btnFrame.BackgroundTransparency = 1
    btnFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.Parent = btnFrame
    
    local plantBtn = self:CreateButton("🌱 Plant", COLORS.Primary)
    plantBtn.Name = "PlantButton"
    plantBtn.Parent = btnFrame
    plantBtn.MouseButton1Click:Connect(function()
        if onPlantClicked then onPlantClicked() end
    end)
    
    local waterBtn = self:CreateButton("💧 Water", COLORS.Secondary)
    waterBtn.Name = "WaterButton"
    waterBtn.Parent = btnFrame
    waterBtn.MouseButton1Click:Connect(function()
        if onWaterClicked then onWaterClicked() end
    end)
    
    local harvestBtn = self:CreateButton("🌾 Harvest", COLORS.Accent)
    harvestBtn.Name = "HarvestButton"
    harvestBtn.Parent = btnFrame
    harvestBtn.MouseButton1Click:Connect(function()
        if onHarvestClicked then onHarvestClicked() end
    end)
    
    print("[PlotInfoPanel] Created")
    return screenGui
end

function PlotInfoPanel:CreateButton(text: string, color: Color3): TextButton
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 40)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 94, 0, 42)
        }):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            Size = UDim2.new(0, 90, 0, 40)
        }):Play()
    end)
    
    return btn
end

function PlotInfoPanel:ShowForPlot(plotIndex: number, plotData: any?)
    currentPlotIndex = plotIndex
    currentPlotData = plotData
    if not mainFrame then return end
    
    local title = mainFrame:FindFirstChild("Title")
    local status = mainFrame:FindFirstChild("Status")
    local progressBg = mainFrame:FindFirstChild("ProgressBackground")
    local buttons = mainFrame:FindFirstChild("Buttons")
    
    if title then title.Text = "🌱 Plot #" .. plotIndex end
    
    local plantBtn = buttons and buttons:FindFirstChild("PlantButton")
    local waterBtn = buttons and buttons:FindFirstChild("WaterButton")
    local harvestBtn = buttons and buttons:FindFirstChild("HarvestButton")
    
    -- Stop previous update loop
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    if plotData and plotData.seedId then
        local seedTemplate = Data.Seeds.GetSeed(plotData.seedId)
        local seedName = seedTemplate and seedTemplate.name or "Unknown"
        
        if status then status.Text = "🌱 " .. seedName end
        if progressBg then progressBg.Visible = true end
        
        -- Start live update loop
        updateConnection = RunService.Heartbeat:Connect(function()
            self:UpdateProgress(plotData, seedTemplate)
        end)
        
        -- Initial update
        self:UpdateProgress(plotData, seedTemplate)
        
        local progress = self:CalculateProgress(plotData, seedTemplate)
        if progress >= 1 then
            if plantBtn then plantBtn.Visible = false end
            if waterBtn then waterBtn.Visible = false end
            if harvestBtn then harvestBtn.Visible = true end
        else
            if plantBtn then plantBtn.Visible = false end
            if waterBtn then waterBtn.Visible = true end
            if harvestBtn then harvestBtn.Visible = false end
        end
    else
        if status then status.Text = "Empty - Ready to plant!" end
        if progressBg then progressBg.Visible = false end
        if plantBtn then plantBtn.Visible = true end
        if waterBtn then waterBtn.Visible = false end
        if harvestBtn then harvestBtn.Visible = false end
    end
    
    self:Open()
end

function PlotInfoPanel:CalculateProgress(plotData: any, seedTemplate: any): number
    if not plotData or not plotData.plantedAt or not seedTemplate then
        return 0
    end
    
    local growthTime = seedTemplate.growthTime
    if plotData.wateredAt then
        growthTime = growthTime * 0.9 -- 10% faster
    end
    
    local elapsed = os.time() - plotData.plantedAt
    return math.min(1, elapsed / growthTime)
end

function PlotInfoPanel:UpdateProgress(plotData: any, seedTemplate: any)
    if not progressBar or not progressText then return end
    if not plotData or not seedTemplate then return end
    
    local growthTime = seedTemplate.growthTime
    if plotData.wateredAt then
        growthTime = growthTime * 0.9
    end
    
    local elapsed = os.time() - plotData.plantedAt
    local progress = math.min(1, elapsed / growthTime)
    local timeRemaining = math.max(0, growthTime - elapsed)
    
    progressBar.Size = UDim2.new(progress, 0, 1, 0)
    
    if progress >= 1 then
        progressBar.BackgroundColor3 = COLORS.Accent
        progressText.Text = "✨ Ready to Harvest!"
        
        -- Update buttons
        local buttons = mainFrame and mainFrame:FindFirstChild("Buttons")
        if buttons then
            local waterBtn = buttons:FindFirstChild("WaterButton")
            local harvestBtn = buttons:FindFirstChild("HarvestButton")
            if waterBtn then waterBtn.Visible = false end
            if harvestBtn then harvestBtn.Visible = true end
        end
    else
        progressBar.BackgroundColor3 = COLORS.Primary
        progressText.Text = "⏱ " .. Utils.FormatTime(timeRemaining)
    end
end

function PlotInfoPanel:SetCallbacks(onPlant: () -> (), onHarvest: () -> (), onWater: () -> ())
    onPlantClicked = onPlant
    onHarvestClicked = onHarvest
    onWaterClicked = onWater
end

function PlotInfoPanel:Open()
    if mainFrame then 
        mainFrame.Visible = true
        mainFrame.Position = UDim2.new(0.5, -160, 1, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Position = UDim2.new(0.5, -160, 1, -200)
        }):Play()
    end
    isOpen = true
end

function PlotInfoPanel:Close()
    if updateConnection then
        updateConnection:Disconnect()
        updateConnection = nil
    end
    
    if mainFrame then
        local tween = TweenService:Create(mainFrame, TweenInfo.new(0.15), {
            Position = UDim2.new(0.5, -160, 1, 0)
        })
        tween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
        tween:Play()
    end
    isOpen = false
    currentPlotIndex = nil
    currentPlotData = nil
end

function PlotInfoPanel:IsOpen(): boolean
    return isOpen
end

function PlotInfoPanel:GetCurrentPlot(): number?
    return currentPlotIndex
end

function PlotInfoPanel:Destroy()
    if updateConnection then
        updateConnection:Disconnect()
    end
    if screenGui then screenGui:Destroy() end
end

return PlotInfoPanel
