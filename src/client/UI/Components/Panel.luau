--!strict
--[[
    Panel Component
    A reusable container with consistent styling
]]

local Panel = {}
Panel.__index = Panel

type PanelProps = {
    Name: string?,
    Size: UDim2?,
    Position: UDim2?,
    AnchorPoint: Vector2?,
    BackgroundColor3: Color3?,
    Transparency: number?,
    Parent: Instance?,
}

function Panel.new(props: PanelProps)
    local self = setmetatable({}, Panel)
    
    local instance = Instance.new("Frame")
    instance.Name = props.Name or "Panel"
    instance.Size = props.Size or UDim2.new(0, 300, 0, 200)
    instance.Position = props.Position or UDim2.new(0, 0, 0, 0)
    instance.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    instance.BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(40, 40, 40)
    instance.BackgroundTransparency = props.Transparency or 0
    instance.BorderSizePixel = 0
    instance.Parent = props.Parent
    
    -- Rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = instance
    
    self.Instance = instance
    
    return self
end

function Panel:AddPadding(padding: number)
    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, padding)
    uiPadding.PaddingBottom = UDim.new(0, padding)
    uiPadding.PaddingLeft = UDim.new(0, padding)
    uiPadding.PaddingRight = UDim.new(0, padding)
    uiPadding.Parent = self.Instance
end

function Panel:AddListLayout(padding: number, fillDirection: Enum.FillDirection?, horizontalAlignment: Enum.HorizontalAlignment?)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, padding)
    layout.FillDirection = fillDirection or Enum.FillDirection.Vertical
    layout.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = self.Instance
    return layout
end

function Panel:Destroy()
    self.Instance:Destroy()
end

return Panel
