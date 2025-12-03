--!strict
--[[
    HUD Screen
    Main Heads-Up Display
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Utils = Shared.Utils

local UI = script.Parent.Parent
local Components = require(UI.Components)

local HUD = {}
HUD.__index = HUD

function HUD.new(player: Player)
    local self = setmetatable({}, HUD)
    
    self.Player = player
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "HUD"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.Parent = player:WaitForChild("PlayerGui")
    
    self.CurrencyLabels = {}
    self.Buttons = {}
    
    self:CreateCurrencyDisplay()
    self:CreateSideMenu()
    
    return self
end

function HUD:CreateCurrencyDisplay()
    local container = Components.Panel.new({
        Name = "CurrencyContainer",
        Size = UDim2.new(0, 300, 0, 40),
        Position = UDim2.new(0.5, 0, 0, 10),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        Transparency = 0.5,
        Parent = self.ScreenGui
    })
    
    local layout = container:AddListLayout(10, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    
    -- Leaves
    self:CreateCurrencyLabel(container.Instance, "Leaves", Color3.fromRGB(100, 255, 100))
    -- Gems
    self:CreateCurrencyLabel(container.Instance, "Gems", Color3.fromRGB(100, 200, 255))
    -- Shards
    self:CreateCurrencyLabel(container.Instance, "MutationShards", Color3.fromRGB(200, 100, 255))
end

function HUD:CreateCurrencyLabel(parent: Instance, currencyName: string, color: Color3)
    local label = Instance.new("TextLabel")
    label.Name = currencyName
    label.Size = UDim2.new(0, 80, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "0"
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    -- Icon placeholder (text for now)
    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 20, 1, 0)
    icon.Position = UDim2.new(0, -25, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = string.sub(currencyName, 1, 1)
    icon.TextColor3 = color
    icon.Font = Enum.Font.GothamBlack
    icon.TextSize = 20
    icon.Parent = label
    
    self.CurrencyLabels[currencyName] = label
end

function HUD:CreateSideMenu()
    local container = Instance.new("Frame")
    container.Name = "SideMenu"
    container.Size = UDim2.new(0, 60, 0, 300)
    container.Position = UDim2.new(0, 10, 0.5, 0)
    container.AnchorPoint = Vector2.new(0, 0.5)
    container.BackgroundTransparency = 1
    container.Parent = self.ScreenGui
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = container
    
    -- Inventory Button
    local invBtn = Components.Button.new({
        Name = "InventoryBtn",
        Text = "INV",
        Size = UDim2.new(0, 50, 0, 50),
        BackgroundColor3 = Color3.fromRGB(255, 152, 0),
        Parent = container,
        OnClick = function()
            self:FireEvent("ToggleInventory")
        end
    })
    
    -- Shop Button
    local shopBtn = Components.Button.new({
        Name = "ShopBtn",
        Text = "SHOP",
        Size = UDim2.new(0, 50, 0, 50),
        BackgroundColor3 = Color3.fromRGB(33, 150, 243),
        Parent = container,
        OnClick = function()
            self:FireEvent("ToggleShop")
        end
    })
    
    -- PvP Button
    local pvpBtn = Components.Button.new({
        Name = "PvPBtn",
        Text = "PVP",
        Size = UDim2.new(0, 50, 0, 50),
        BackgroundColor3 = Color3.fromRGB(244, 67, 54),
        Parent = container,
        OnClick = function()
            self:FireEvent("TogglePvP")
        end
    })
end

function HUD:UpdateCurrency(currencyData: {[string]: number})
    for name, label in pairs(self.CurrencyLabels) do
        local value = currencyData[name] or 0
        label.Text = Utils.FormatNumber(value)
    end
end

function HUD:FireEvent(eventName: string, ...)
    -- This would typically use a Signal, but we'll just use a callback system in UIController
    if self.OnEvent then
        self.OnEvent(eventName, ...)
    end
end

function HUD:SetVisible(visible: boolean)
    self.ScreenGui.Enabled = visible
end

return HUD
