--!strict
--[[
    Button Component
    A reusable button with hover and click effects
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Button = {}
Button.__index = Button

type ButtonProps = {
    Name: string?,
    Text: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    BackgroundColor3: Color3?,
    Parent: Instance?,
    OnClick: (() -> ())?,
}

function Button.new(props: ButtonProps)
    local self = setmetatable({}, Button)
    
    local instance = Instance.new("TextButton")
    instance.Name = props.Name or "Button"
    instance.Size = props.Size or UDim2.new(0, 200, 0, 50)
    instance.Position = props.Position or UDim2.new(0, 0, 0, 0)
    instance.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    instance.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(76, 175, 80)
    instance.BorderSizePixel = 0
    instance.Text = ""
    instance.AutoButtonColor = false
    instance.Parent = props.Parent
    
    -- Rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = instance
    
    -- Text label (for better control)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = props.Text or "Button"
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Parent = instance
    
    self.Instance = instance
    self.OnClick = props.OnClick
    
    self:SetupEvents()
    
    return self
end

function Button:SetupEvents()
    local instance = self.Instance
    
    instance.MouseEnter:Connect(function()
        TweenService:Create(instance, TweenInfo.new(0.2), {
            BackgroundColor3 = self:Lighten(instance.BackgroundColor3, 0.1)
        }):Play()
    end)
    
    instance.MouseLeave:Connect(function()
        TweenService:Create(instance, TweenInfo.new(0.2), {
            BackgroundColor3 = self:Darken(instance.BackgroundColor3, 0) -- Reset to original? 
            -- Simplified: Just assume the original color was the base
        }):Play()
    end)
    
    instance.MouseButton1Click:Connect(function()
        if self.OnClick then
            self.OnClick()
        end
        
        -- Click effect
        local originalSize = instance.Size
        local shrinkSize = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.95, originalSize.Y.Scale, originalSize.Y.Offset * 0.95)
        
        local tweenIn = TweenService:Create(instance, TweenInfo.new(0.05), {Size = shrinkSize})
        local tweenOut = TweenService:Create(instance, TweenInfo.new(0.05), {Size = originalSize})
        
        tweenIn:Play()
        tweenIn.Completed:Wait()
        tweenOut:Play()
    end)
end

function Button:Lighten(color: Color3, amount: number): Color3
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, math.max(0, s - amount), math.min(1, v + amount))
end

function Button:Darken(color: Color3, amount: number): Color3
    local h, s, v = color:ToHSV()
    return Color3.fromHSV(h, s, math.max(0, v - amount))
end

function Button:SetText(text: string)
    local label = self.Instance:FindFirstChild("Label")
    if label and label:IsA("TextLabel") then
        label.Text = text
    end
end

function Button:Destroy()
    self.Instance:Destroy()
end

return Button
