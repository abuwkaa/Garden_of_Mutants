--!strict
--[[
    PetVisualsController
    Handles 3D pet visualization in the world
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data
local Constants = Shared.Constants

local PetVisualsController = {}

local LocalPlayer = Players.LocalPlayer
local character: Model?
local humanoidRootPart: BasePart?

-- Storage for spawned pets
local penPetModels: {[number]: {Model}} = {} -- cellIndex -> {pet models}
local followingPets: {Model} = {} -- equipped pets following player
local breedingEffects: {[number]: {any}} = {} -- cellIndex -> effects

-- Update connection
local updateConnection: RBXScriptConnection?

local COLORS = {
    Nature = Color3.fromRGB(76, 175, 80),
    Fire = Color3.fromRGB(244, 67, 54),
    Ice = Color3.fromRGB(33, 150, 243),
    Tech = Color3.fromRGB(255, 235, 59),
    Chaos = Color3.fromRGB(156, 39, 176),
}

local RARITY_GLOW = {
    Common = nil,
    Rare = Color3.fromRGB(33, 150, 243),
    Epic = Color3.fromRGB(156, 39, 176),
    Legendary = Color3.fromRGB(255, 193, 7),
}

function PetVisualsController:Init()
    print("[PetVisualsController] Initializing...")
end

function PetVisualsController:Start()
    print("[PetVisualsController] Starting...")
    
    -- Get character
    character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        character = newChar
        humanoidRootPart = newChar:WaitForChild("HumanoidRootPart")
        
        -- Re-spawn following pets
        self:ClearFollowingPets()
    end)
    
    -- Start update loop for following pets
    updateConnection = RunService.Heartbeat:Connect(function(dt)
        self:UpdateFollowingPets(dt)
    end)
    
    print("[PetVisualsController] Started")
end

----- PEN PETS -----
function PetVisualsController:UpdatePenPets(penData: any, playerPets: {any})
    print("[PetVisualsController] UpdatePenPets called")
    
    if not penData or not penData.cells then 
        print("[PetVisualsController] No pen cells data")
        return 
    end
    
    -- Clear all existing pen pets first
    self:ClearAllPenPets()
    
    -- Spawn pets for each cell
    for cellIndex, cellData in pairs(penData.cells) do
        print("[PetVisualsController] Processing cell", cellIndex, "pets:", cellData.pets and #cellData.pets or 0)
        
        if cellData.pets and #cellData.pets > 0 then
            self:SpawnPetsInCell(cellIndex, cellData, playerPets)
            
            -- Add breeding effects if breeding
            if cellData.mode == "Breeding" then
                self:AddBreedingEffects(cellIndex)
            end
        end
    end
end

function PetVisualsController:SpawnPetsInCell(cellIndex: number, cellData: any, playerPets: {any})
    local petPen = workspace:FindFirstChild("PetPen")
    if not petPen then return end
    
    local cells = petPen:FindFirstChild("Cells")
    if not cells then return end
    
    local cell = cells:FindFirstChild("Cell_" .. cellIndex)
    if not cell then return end
    
    local petHolders = cell:FindFirstChild("PetHolders")
    if not petHolders then return end
    
    penPetModels[cellIndex] = {}
    
    for i, petUid in ipairs(cellData.pets) do
        -- Find pet data
        local petInstance = self:FindPetByUid(playerPets, petUid)
        if petInstance then
            local holder = petHolders:FindFirstChild("PetHolder_" .. i)
            if holder then
                local model = self:CreatePetModel(petInstance)
                if model then
                    model:PivotTo(holder.CFrame)
                    model.Parent = cell
                    table.insert(penPetModels[cellIndex], model)
                    
                    -- Start idle animation
                    self:StartIdleAnimation(model)
                end
            end
        end
    end
    
    -- Update cell billboard
    self:UpdateCellBillboard(cell, cellData)
end

function PetVisualsController:UpdateCellBillboard(cell: Model, cellData: any)
    local billboard = cell:FindFirstChild("StatusDisplay")
    if not billboard then return end
    
    local bg = billboard:FindFirstChild("Background")
    if not bg then return end
    
    local statusText = bg:FindFirstChild("StatusText")
    local timerText = bg:FindFirstChild("TimerText")
    
    billboard.Enabled = true
    
    if cellData.mode == "Breeding" then
        if statusText then statusText.Text = "💕 Breeding" end
        if timerText and cellData.startTime and cellData.duration then
            local remaining = math.max(0, cellData.duration - (os.time() - cellData.startTime))
            if remaining <= 0 then
                timerText.Text = "✨ Ready!"
            else
                local mins = math.floor(remaining / 60)
                local secs = remaining % 60
                timerText.Text = string.format("%d:%02d", mins, secs)
            end
        end
    elseif cellData.mode == "Rest" then
        if statusText then statusText.Text = "😴 Resting" end
        if timerText then timerText.Text = "+XP" end
    else
        if statusText then statusText.Text = #cellData.pets .. " Pet(s)" end
        if timerText then timerText.Text = "" end
    end
end

function PetVisualsController:ClearPenPets(cellIndex: number)
    if penPetModels[cellIndex] then
        for _, model in ipairs(penPetModels[cellIndex]) do
            if model then
                model:Destroy()
            end
        end
        penPetModels[cellIndex] = nil
    end
    
    -- Clear breeding effects
    if breedingEffects[cellIndex] then
        for _, effect in ipairs(breedingEffects[cellIndex]) do
            if effect then
                effect:Destroy()
            end
        end
        breedingEffects[cellIndex] = nil
    end
end

function PetVisualsController:ClearAllPenPets()
    for cellIndex, _ in pairs(penPetModels) do
        self:ClearPenPets(cellIndex)
    end
    penPetModels = {}
    breedingEffects = {}
end

----- FOLLOWING PETS -----
function PetVisualsController:UpdateEquippedPets(playerPets: {any})
    -- Clear existing following pets
    self:ClearFollowingPets()
    
    -- Find equipped pets
    local equipped = {}
    for _, pet in ipairs(playerPets) do
        if pet.equipped then
            table.insert(equipped, pet)
        end
    end
    
    -- Sort by slot
    table.sort(equipped, function(a, b)
        return (a.equippedSlot or 0) < (b.equippedSlot or 0)
    end)
    
    -- Spawn following pets
    for i, petInstance in ipairs(equipped) do
        local model = self:CreatePetModel(petInstance)
        if model then
            model.Name = "FollowingPet_" .. i
            model.Parent = workspace
            
            -- Store follow data
            model:SetAttribute("FollowIndex", i)
            model:SetAttribute("TargetOffset", Vector3.new(0, 0, 0))
            
            table.insert(followingPets, model)
            
            -- Start idle animation
            self:StartIdleAnimation(model)
        end
    end
end

function PetVisualsController:UpdateFollowingPets(dt: number)
    if not humanoidRootPart then return end
    
    local playerPos = humanoidRootPart.Position
    local playerLook = humanoidRootPart.CFrame.LookVector
    
    for i, petModel in ipairs(followingPets) do
        if petModel and petModel.PrimaryPart then
            -- Calculate target position (behind and to the side of player)
            local angle = math.rad(-90 + (i - 1) * 60) -- Spread pets in arc behind player
            local distance = 4 + (i - 1) * 1.5
            
            local offset = CFrame.Angles(0, angle, 0) * Vector3.new(0, 0, -distance)
            local targetPos = playerPos + humanoidRootPart.CFrame:VectorToWorldSpace(Vector3.new(offset.X, 0, offset.Z))
            targetPos = Vector3.new(targetPos.X, playerPos.Y - 1, targetPos.Z)
            
            -- Smooth movement
            local currentPos = petModel.PrimaryPart.Position
            local newPos = currentPos:Lerp(targetPos, math.min(1, dt * 5))
            
            -- Look at player
            local lookAt = CFrame.lookAt(newPos, Vector3.new(playerPos.X, newPos.Y, playerPos.Z))
            
            petModel:PivotTo(lookAt)
            
            -- Bobbing animation
            local bob = math.sin(os.clock() * 3 + i) * 0.2
            petModel:PivotTo(petModel.PrimaryPart.CFrame + Vector3.new(0, bob, 0))
        end
    end
end

function PetVisualsController:ClearFollowingPets()
    for _, model in ipairs(followingPets) do
        if model then
            model:Destroy()
        end
    end
    followingPets = {}
end

----- PET MODEL CREATION -----
function PetVisualsController:CreatePetModel(petInstance: any): Model?
    local template = Data.Pets.GetPet(petInstance.templateId)
    if not template then return nil end
    
    local element = template.element
    local rarity = petInstance.rarity
    local mutationTier = petInstance.mutationTier or 0
    
    local primaryColor = COLORS[element] or COLORS.Nature
    local secondaryColor = primaryColor:Lerp(Color3.new(1, 1, 1), 0.3)
    
    local model = Instance.new("Model")
    model.Name = template.name
    
    local scale = 0.8
    if rarity == "Rare" then scale = 0.9
    elseif rarity == "Epic" then scale = 1.0
    elseif rarity == "Legendary" then scale = 1.1
    end
    
    -- Apply mutation scale
    if mutationTier > 0 then
        scale = scale * (1 + mutationTier * 0.05)
    end
    
    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2 * scale, 1.5 * scale, 2.5 * scale)
    body.CFrame = CFrame.new(0, 1.5 * scale, 0)
    body.Anchored = true
    body.CanCollide = false
    body.Color = primaryColor
    body.Material = Enum.Material.SmoothPlastic
    body.Parent = model
    
    local bodyMesh = Instance.new("SpecialMesh")
    bodyMesh.MeshType = Enum.MeshType.Sphere
    bodyMesh.Scale = Vector3.new(1, 0.8, 1.1)
    bodyMesh.Parent = body
    
    model.PrimaryPart = body
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.3 * scale, 1.3 * scale, 1.3 * scale)
    head.CFrame = CFrame.new(0, 2.2 * scale, 1.2 * scale)
    head.Anchored = true
    head.CanCollide = false
    head.Color = primaryColor
    head.Material = Enum.Material.SmoothPlastic
    head.Shape = Enum.PartType.Ball
    head.Parent = model
    
    -- Eyes
    for i, xOffset in ipairs({-0.3 * scale, 0.3 * scale}) do
        local eye = Instance.new("Part")
        eye.Name = "Eye_" .. i
        eye.Size = Vector3.new(0.25 * scale, 0.35 * scale, 0.15 * scale)
        eye.CFrame = head.CFrame * CFrame.new(xOffset, 0.15 * scale, 0.5 * scale)
        eye.Anchored = true
        eye.CanCollide = false
        eye.Color = Color3.new(0.1, 0.1, 0.1)
        eye.Material = Enum.Material.SmoothPlastic
        eye.Shape = Enum.PartType.Ball
        eye.Parent = model
        
        -- Eye shine
        local shine = Instance.new("Part")
        shine.Name = "Shine_" .. i
        shine.Size = Vector3.new(0.08 * scale, 0.08 * scale, 0.08 * scale)
        shine.CFrame = eye.CFrame * CFrame.new(0.05 * scale, 0.08 * scale, 0.05 * scale)
        shine.Anchored = true
        shine.CanCollide = false
        shine.Color = Color3.new(1, 1, 1)
        shine.Material = Enum.Material.Neon
        shine.Shape = Enum.PartType.Ball
        shine.Parent = model
    end
    
    -- Ears
    for i, xOffset in ipairs({-0.4 * scale, 0.4 * scale}) do
        local ear = Instance.new("Part")
        ear.Name = "Ear_" .. i
        ear.Size = Vector3.new(0.25 * scale, 0.5 * scale, 0.15 * scale)
        ear.CFrame = head.CFrame * CFrame.new(xOffset, 0.6 * scale, 0) * CFrame.Angles(0, 0, xOffset > 0 and math.rad(-15) or math.rad(15))
        ear.Anchored = true
        ear.CanCollide = false
        ear.Color = secondaryColor
        ear.Material = Enum.Material.SmoothPlastic
        ear.Parent = model
        
        local earMesh = Instance.new("SpecialMesh")
        earMesh.MeshType = Enum.MeshType.Wedge
        earMesh.Parent = ear
    end
    
    -- Tail
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.35 * scale, 0.35 * scale, 1 * scale)
    tail.CFrame = body.CFrame * CFrame.new(0, 0.2 * scale, -1.5 * scale) * CFrame.Angles(math.rad(-20), 0, 0)
    tail.Anchored = true
    tail.CanCollide = false
    tail.Color = secondaryColor
    tail.Material = Enum.Material.SmoothPlastic
    tail.Parent = model
    
    local tailMesh = Instance.new("SpecialMesh")
    tailMesh.MeshType = Enum.MeshType.Sphere
    tailMesh.Scale = Vector3.new(1, 1, 2)
    tailMesh.Parent = tail
    
    -- Legs
    local legPositions = {
        {x = -0.5, z = 0.6},
        {x = 0.5, z = 0.6},
        {x = -0.5, z = -0.6},
        {x = 0.5, z = -0.6},
    }
    
    for i, pos in ipairs(legPositions) do
        local leg = Instance.new("Part")
        leg.Name = "Leg_" .. i
        leg.Size = Vector3.new(0.3 * scale, 0.8 * scale, 0.3 * scale)
        leg.CFrame = body.CFrame * CFrame.new(pos.x * scale, -0.8 * scale, pos.z * scale)
        leg.Anchored = true
        leg.CanCollide = false
        leg.Color = primaryColor
        leg.Material = Enum.Material.SmoothPlastic
        leg.Parent = model
    end
    
    -- Element particles
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "ElementParticles"
    particles.Color = ColorSequence.new(primaryColor)
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Rate = 3
    particles.Speed = NumberRange.new(0.5, 1)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Parent = body
    
    -- Rarity glow
    local glowColor = RARITY_GLOW[rarity]
    if glowColor then
        local light = Instance.new("PointLight")
        light.Name = "RarityGlow"
        light.Color = glowColor
        light.Brightness = 0.8
        light.Range = 5
        light.Parent = body
    end
    
    -- Mutation effects
    if mutationTier > 0 then
        self:AddMutationVisuals(model, mutationTier)
    end
    
    -- Name billboard
    local nameBillboard = Instance.new("BillboardGui")
    nameBillboard.Name = "NameTag"
    nameBillboard.Size = UDim2.new(0, 100, 0, 30)
    nameBillboard.StudsOffset = Vector3.new(0, 3, 0)
    nameBillboard.Adornee = body
    nameBillboard.AlwaysOnTop = false
    nameBillboard.Parent = model
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = template.name
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.Parent = nameBillboard
    
    -- Level indicator
    local levelLabel = Instance.new("TextLabel")
    levelLabel.Size = UDim2.new(1, 0, 0, 15)
    levelLabel.Position = UDim2.new(0, 0, 1, 0)
    levelLabel.BackgroundTransparency = 1
    levelLabel.Text = "Lv." .. petInstance.level
    levelLabel.TextSize = 10
    levelLabel.Font = Enum.Font.Gotham
    levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    levelLabel.TextStrokeTransparency = 0.7
    levelLabel.Parent = nameBillboard
    
    return model
end

function PetVisualsController:AddMutationVisuals(model: Model, tier: number)
    local body = model.PrimaryPart
    if not body then return end
    
    local colors = {
        [1] = Color3.fromRGB(100, 255, 100),
        [2] = Color3.fromRGB(100, 200, 255),
        [3] = Color3.fromRGB(255, 150, 255),
        [4] = Color3.fromRGB(80, 0, 120),
    }
    
    local color = colors[tier] or colors[1]
    
    -- Mutation aura
    local aura = Instance.new("ParticleEmitter")
    aura.Name = "MutationAura"
    aura.Color = ColorSequence.new(color)
    aura.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0),
    })
    aura.Lifetime = NumberRange.new(1, 1.5)
    aura.Rate = 8 * tier
    aura.Speed = NumberRange.new(0.3, 0.8)
    aura.SpreadAngle = Vector2.new(360, 360)
    aura.LightEmission = 0.5
    aura.Parent = body
    
    -- Glow for higher tiers
    if tier >= 2 then
        local glow = Instance.new("PointLight")
        glow.Name = "MutationGlow"
        glow.Color = color
        glow.Brightness = tier * 0.5
        glow.Range = 6
        glow.Parent = body
    end
    
    -- Ring effect for tier 3+
    if tier >= 3 then
        local ring = Instance.new("Part")
        ring.Name = "MutationRing"
        ring.Size = Vector3.new(3, 0.1, 3)
        ring.CFrame = body.CFrame * CFrame.new(0, -1, 0)
        ring.Anchored = true
        ring.CanCollide = false
        ring.Transparency = 0.5
        ring.Color = color
        ring.Material = Enum.Material.Neon
        ring.Shape = Enum.PartType.Cylinder
        ring.Orientation = Vector3.new(0, 0, 90)
        ring.Parent = model
        
        -- Rotate ring
        task.spawn(function()
            while ring and ring.Parent do
                ring.CFrame = ring.CFrame * CFrame.Angles(0, math.rad(2), 0)
                task.wait()
            end
        end)
    end
end

----- ANIMATIONS -----
function PetVisualsController:StartIdleAnimation(model: Model)
    task.spawn(function()
        local body = model.PrimaryPart
        if not body then return end
        
        local startY = body.Position.Y
        local time = 0
        local speed = 2 + math.random() * 0.5
        
        while model and model.Parent and body and body.Parent do
            time = time + task.wait()
            
            -- Gentle bobbing
            local bob = math.sin(time * speed) * 0.15
            local tilt = math.sin(time * speed * 0.5) * 0.02
            
            -- Apply to whole model
            local currentCFrame = model:GetPivot()
            local newCFrame = CFrame.new(currentCFrame.Position.X, startY + bob, currentCFrame.Position.Z) 
                * CFrame.Angles(tilt, currentCFrame:ToEulerAnglesYXZ())
            
            -- Only update Y position for bobbing
            body.CFrame = body.CFrame * CFrame.new(0, bob * 0.1, 0)
        end
    end)
end

----- BREEDING EFFECTS -----
function PetVisualsController:AddBreedingEffects(cellIndex: number)
    local petPen = workspace:FindFirstChild("PetPen")
    if not petPen then return end
    
    local cells = petPen:FindFirstChild("Cells")
    if not cells then return end
    
    local cell = cells:FindFirstChild("Cell_" .. cellIndex)
    if not cell then return end
    
    local floor = cell:FindFirstChild("Floor")
    if not floor then return end
    
    breedingEffects[cellIndex] = {}
    
    -- Heart particles
    local hearts = Instance.new("ParticleEmitter")
    hearts.Name = "BreedingHearts"
    hearts.Texture = "rbxassetid://7857866928" -- Heart texture
    hearts.Color = ColorSequence.new(Color3.fromRGB(255, 100, 150))
    hearts.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    hearts.Lifetime = NumberRange.new(1.5, 2.5)
    hearts.Rate = 5
    hearts.Speed = NumberRange.new(2, 4)
    hearts.SpreadAngle = Vector2.new(30, 30)
    hearts.EmissionDirection = Enum.NormalId.Top
    hearts.Parent = floor
    
    table.insert(breedingEffects[cellIndex], hearts)
    
    -- Sparkle particles
    local sparkles = Instance.new("ParticleEmitter")
    sparkles.Name = "BreedingSparkles"
    sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 220, 100))
    sparkles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0),
    })
    sparkles.Lifetime = NumberRange.new(0.5, 1)
    sparkles.Rate = 10
    sparkles.Speed = NumberRange.new(1, 3)
    sparkles.SpreadAngle = Vector2.new(180, 180)
    sparkles.LightEmission = 1
    sparkles.Parent = floor
    
    table.insert(breedingEffects[cellIndex], sparkles)
    
    -- Glow light
    local glow = Instance.new("PointLight")
    glow.Name = "BreedingGlow"
    glow.Color = Color3.fromRGB(255, 150, 200)
    glow.Brightness = 1
    glow.Range = 10
    glow.Parent = floor
    
    table.insert(breedingEffects[cellIndex], glow)
end

----- UTILITY -----
function PetVisualsController:FindPetByUid(pets: {any}, uid: string): any?
    for _, pet in ipairs(pets) do
        if pet.uid == uid then
            return pet
        end
    end
    return nil
end

function PetVisualsController:OnDataUpdate(data: any)
    print("[PetVisualsController] OnDataUpdate called")
    
    if not data then 
        print("[PetVisualsController] No data!")
        return 
    end
    
    -- Update pen pets
    if data.petPen then
        print("[PetVisualsController] Updating pen pets, cells:", data.petPen.cells and "exists" or "nil")
        self:UpdatePenPets(data.petPen, data.pets)
    else
        print("[PetVisualsController] No petPen data")
    end
    
    -- Update following pets
    if data.pets then
        print("[PetVisualsController] Updating following pets, count:", #data.pets)
        self:UpdateEquippedPets(data.pets)
    end
end

function PetVisualsController:Destroy()
    if updateConnection then
        updateConnection:Disconnect()
    end
    self:ClearAllPenPets()
    self:ClearFollowingPets()
end

return PetVisualsController
