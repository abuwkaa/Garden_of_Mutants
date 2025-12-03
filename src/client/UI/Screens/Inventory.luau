--!strict
--[[
    Inventory Screen
    Displays pets and seeds
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data

local UI = script.Parent.Parent
local Components = require(UI.Components)

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(player: Player)
    local self = setmetatable({}, Inventory)
    
    self.Player = player
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "Inventory"
    self.ScreenGui.Enabled = false
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    
    self.Items = {}
    self.CurrentTab = "Pets" -- Pets, Seeds
    
    self:CreateMainFrame()
    
    return self
end

function Inventory:CreateMainFrame()
    local mainFrame = Components.Panel.new({
        Name = "MainFrame",
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(30, 30, 30),
        Parent = self.ScreenGui
    })
    self.MainFrame = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "INVENTORY"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 24
    title.Parent = mainFrame.Instance
    
    -- Close Button
    local closeBtn = Components.Button.new({
        Name = "CloseBtn",
        Text = "X",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
        Parent = mainFrame.Instance,
        OnClick = function()
            self:SetVisible(false)
        end
    })
    
    -- Tabs
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "Tabs"
    tabContainer.Size = UDim2.new(1, -20, 0, 40)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame.Instance
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 10)
    tabLayout.Parent = tabContainer
    
    local petsTab = Components.Button.new({
        Name = "PetsTab",
        Text = "Pets",
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Parent = tabContainer,
        OnClick = function()
            self:SwitchTab("Pets")
        end
    })
    
    local seedsTab = Components.Button.new({
        Name = "SeedsTab",
        Text = "Seeds",
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Parent = tabContainer,
        OnClick = function()
            self:SwitchTab("Seeds")
        end
    })
    
    -- Grid Container
    local gridScroll = Instance.new("ScrollingFrame")
    gridScroll.Name = "Grid"
    gridScroll.Size = UDim2.new(1, -20, 1, -110)
    gridScroll.Position = UDim2.new(0, 10, 0, 100)
    gridScroll.BackgroundTransparency = 1
    gridScroll.BorderSizePixel = 0
    gridScroll.ScrollBarThickness = 6
    gridScroll.Parent = mainFrame.Instance
    self.GridScroll = gridScroll
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 100, 0, 120)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = gridScroll
end

function Inventory:SwitchTab(tabName: string)
    self.CurrentTab = tabName
    self:Refresh()
end

function Inventory:UpdateData(data: any)
    self.Data = data
    self:Refresh()
end

function Inventory:Refresh()
    if not self.Data then return end
    
    -- Clear grid
    for _, child in ipairs(self.GridScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    if self.CurrentTab == "Pets" then
        for _, pet in ipairs(self.Data.pets) do
            self:CreatePetCard(pet)
        end
    elseif self.CurrentTab == "Seeds" then
        for _, seed in ipairs(self.Data.seeds) do
            self:CreateSeedCard(seed)
        end
    end
end

function Inventory:CreatePetCard(pet: any)
    local template = Data.Pets.GetPet(pet.templateId)
    if not template then return end
    
    local card = Components.Panel.new({
        Name = "PetCard",
        Size = UDim2.new(0, 100, 0, 120),
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        Parent = self.GridScroll
    })
    
    local name = Instance.new("TextLabel")
    name.Text = template.name
    name.Size = UDim2.new(1, 0, 0, 20)
    name.Position = UDim2.new(0, 0, 0, 5)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.new(1, 1, 1)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14
    name.Parent = card.Instance
    
    local level = Instance.new("TextLabel")
    level.Text = "Lvl " .. pet.level
    level.Size = UDim2.new(1, 0, 0, 20)
    level.Position = UDim2.new(0, 0, 1, -25)
    level.BackgroundTransparency = 1
    level.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    level.Font = Enum.Font.Gotham
    level.TextSize = 12
    level.Parent = card.Instance
    
    -- Equip Button (Overlay)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = card.Instance
    
    btn.MouseButton1Click:Connect(function()
        print("Clicked pet:", template.name)
        -- TODO: Show details / equip
    end)
end

function Inventory:CreateSeedCard(seed: any)
    local template = Data.Seeds.GetSeed(seed.templateId)
    if not template then return end
    
    local card = Components.Panel.new({
        Name = "SeedCard",
        Size = UDim2.new(0, 100, 0, 120),
        BackgroundColor3 = Color3.fromRGB(50, 60, 50),
        Parent = self.GridScroll
    })
    
    local name = Instance.new("TextLabel")
    name.Text = template.name
    name.Size = UDim2.new(1, 0, 0, 20)
    name.Position = UDim2.new(0, 0, 0, 5)
    name.BackgroundTransparency = 1
    name.TextColor3 = Color3.new(1, 1, 1)
    name.Font = Enum.Font.GothamBold
    name.TextSize = 14
    name.Parent = card.Instance
    
    local qty = Instance.new("TextLabel")
    qty.Text = "x" .. seed.quantity
    qty.Size = UDim2.new(1, 0, 0, 20)
    qty.Position = UDim2.new(0, 0, 1, -25)
    qty.BackgroundTransparency = 1
    qty.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    qty.Font = Enum.Font.Gotham
    qty.TextSize = 12
    qty.Parent = card.Instance
    
    -- Plant Button (Overlay)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = card.Instance
    
    btn.MouseButton1Click:Connect(function()
        print("Clicked seed:", template.name)
        -- TODO: Select for planting
        self:FireEvent("SelectSeed", seed.uid)
        self:SetVisible(false)
    end)
end

function Inventory:FireEvent(eventName: string, ...)
    if self.OnEvent then
        self.OnEvent(eventName, ...)
    end
end

function Inventory:SetVisible(visible: boolean)
    self.ScreenGui.Enabled = visible
end

return Inventory
