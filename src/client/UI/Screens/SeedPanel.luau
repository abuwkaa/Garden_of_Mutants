--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data

local SeedPanel = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui: ScreenGui?
local mainFrame: Frame?
local seedList: ScrollingFrame?
local isOpen = false
local onSeedSelected: ((string) -> ())?

function SeedPanel:Create()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SeedPanel"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local backdrop = Instance.new("TextButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.Parent = screenGui
    
    backdrop.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 350, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🌱 Select Seed"
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Parent = mainFrame
    
    seedList = Instance.new("ScrollingFrame")
    seedList.Name = "SeedList"
    seedList.Size = UDim2.new(1, -20, 1, -60)
    seedList.Position = UDim2.new(0, 10, 0, 50)
    seedList.BackgroundTransparency = 1
    seedList.ScrollBarThickness = 6
    seedList.Parent = mainFrame
    
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0, 100, 0, 120)
    grid.CellPadding = UDim2.new(0, 8, 0, 8)
    grid.Parent = seedList
    
    print("[SeedPanel] Created")
    return screenGui
end

function SeedPanel:PopulateSeeds(seeds: {any})
    if not seedList then return end
    
    -- Clear existing
    for _, child in ipairs(seedList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    if not seeds or #seeds == 0 then
        return
    end
    
    -- Filter valid seeds and group by templateId
    local seedCounts = {}
    for _, seed in ipairs(seeds) do
        if seed and seed.templateId then
            seedCounts[seed.templateId] = seedCounts[seed.templateId] or {count = 0, seed = seed}
            seedCounts[seed.templateId].count = seedCounts[seed.templateId].count + 1
        end
    end
    
    -- Convert to array and sort
    local seedListArray = {}
    for templateId, data in pairs(seedCounts) do
        local template = Data.Seeds.GetSeed(templateId)
        if template then
            table.insert(seedListArray, {
                templateId = templateId,
                seed = data.seed,
                count = data.count,
                growthTime = template.growthTime or 60,
            })
        end
    end
    
    -- Sort by growth time (safe comparison)
    table.sort(seedListArray, function(a, b)
        return (a.growthTime or 0) < (b.growthTime or 0)
    end)
    
    -- Create seed cards
    for i, seedData in ipairs(seedListArray) do
        local card = self:CreateSeedCard(seedData.seed, seedData.count)
        if card then
            card.LayoutOrder = i
            card.Parent = seedList
        end
    end
    
    -- Update canvas size
    local rows = math.ceil(#seedListArray / 3)
    seedList.CanvasSize = UDim2.new(0, 0, 0, rows * 130)
end

function SeedPanel:CreateSeedCard(seed: any, count: number): TextButton?
    local template = Data.Seeds.GetSeed(seed.templateId)
    if not template then return nil end
    
    local card = Instance.new("TextButton")
    card.Name = seed.uid
    card.Size = UDim2.new(0, 100, 0, 120)
    card.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    card.BorderSizePixel = 0
    card.Text = ""
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 40)
    icon.Position = UDim2.new(0, 0, 0, 10)
    icon.BackgroundTransparency = 1
    icon.Text = "🌱"
    icon.TextSize = 30
    icon.Parent = card
    
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -10, 0, 30)
    name.Position = UDim2.new(0, 5, 0, 50)
    name.BackgroundTransparency = 1
    name.Text = template.name
    name.TextSize = 11
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = Color3.new(1, 1, 1)
    name.TextWrapped = true
    name.Parent = card
    
    local qty = Instance.new("TextLabel")
    qty.Size = UDim2.new(1, 0, 0, 20)
    qty.Position = UDim2.new(0, 0, 0, 85)
    qty.BackgroundTransparency = 1
    qty.Text = "x" .. count
    qty.TextSize = 12
    qty.Font = Enum.Font.Gotham
    qty.TextColor3 = Color3.fromRGB(180, 180, 180)
    qty.Parent = card
    
    card.MouseButton1Click:Connect(function()
        if onSeedSelected then
            onSeedSelected(seed.uid)
        end
        self:Close()
    end)
    
    return card
end

function SeedPanel:Open(callback: ((string) -> ())?)
    onSeedSelected = callback
    if screenGui then
        local backdrop = screenGui:FindFirstChild("Backdrop")
        if backdrop then backdrop.Visible = true end
    end
    if mainFrame then mainFrame.Visible = true end
    isOpen = true
end

function SeedPanel:Close()
    if screenGui then
        local backdrop = screenGui:FindFirstChild("Backdrop")
        if backdrop then backdrop.Visible = false end
    end
    if mainFrame then mainFrame.Visible = false end
    isOpen = false
end

function SeedPanel:IsOpen(): boolean
    return isOpen
end

function SeedPanel:Destroy()
    if screenGui then screenGui:Destroy() end
end

return SeedPanel
