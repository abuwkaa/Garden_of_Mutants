--!strict
--[[
    PetModels
    Creates visual models for pets
]]

local PetModels = {}

----- PET DEFINITIONS -----
local PET_DATA = {
    -- Nature element
    fern_fox = {
        name = "Fern Fox",
        element = "Nature",
        primaryColor = Color3.fromRGB(76, 175, 80),
        secondaryColor = Color3.fromRGB(139, 195, 74),
        accentColor = Color3.fromRGB(255, 255, 255),
        bodyScale = 1.0,
    },
    -- Fire element
    ember_pup = {
        name = "Ember Pup",
        element = "Fire",
        primaryColor = Color3.fromRGB(244, 67, 54),
        secondaryColor = Color3.fromRGB(255, 152, 0),
        accentColor = Color3.fromRGB(255, 235, 59),
        bodyScale = 0.9,
    },
    -- Ice element
    frost_bunny = {
        name = "Frost Bunny",
        element = "Ice",
        primaryColor = Color3.fromRGB(33, 150, 243),
        secondaryColor = Color3.fromRGB(144, 202, 249),
        accentColor = Color3.fromRGB(255, 255, 255),
        bodyScale = 0.8,
    },
    -- Tech element
    spark_bot = {
        name = "Spark Bot",
        element = "Tech",
        primaryColor = Color3.fromRGB(255, 235, 59),
        secondaryColor = Color3.fromRGB(158, 158, 158),
        accentColor = Color3.fromRGB(33, 150, 243),
        bodyScale = 0.85,
    },
    -- Chaos element
    shadow_cat = {
        name = "Shadow Cat",
        element = "Chaos",
        primaryColor = Color3.fromRGB(156, 39, 176),
        secondaryColor = Color3.fromRGB(74, 20, 140),
        accentColor = Color3.fromRGB(224, 64, 251),
        bodyScale = 0.9,
    },
}

local ELEMENT_EFFECTS = {
    Nature = {particleColor = Color3.fromRGB(76, 175, 80), particleTexture = "rbxassetid://243660364"},
    Fire = {particleColor = Color3.fromRGB(255, 100, 0), particleTexture = "rbxassetid://243660364"},
    Ice = {particleColor = Color3.fromRGB(200, 230, 255), particleTexture = "rbxassetid://243660364"},
    Tech = {particleColor = Color3.fromRGB(255, 235, 59), particleTexture = "rbxassetid://243660364"},
    Chaos = {particleColor = Color3.fromRGB(180, 0, 255), particleTexture = "rbxassetid://243660364"},
}

local RARITY_GLOW = {
    Common = nil,
    Rare = Color3.fromRGB(33, 150, 243),
    Epic = Color3.fromRGB(156, 39, 176),
    Legendary = Color3.fromRGB(255, 193, 7),
}

----- MODEL CREATION -----
function PetModels.CreatePet(petId: string, rarity: string?, mutationTier: number?): Model
    local data = PET_DATA[petId]
    if not data then
        warn("[PetModels] Unknown pet:", petId)
        data = PET_DATA.fern_fox -- fallback
    end
    
    local model = Instance.new("Model")
    model.Name = data.name
    
    local scale = data.bodyScale
    
    -- Body
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Size = Vector3.new(2 * scale, 1.5 * scale, 3 * scale)
    body.Position = Vector3.new(0, 1.5 * scale, 0)
    body.Anchored = true
    body.CanCollide = false
    body.Color = data.primaryColor
    body.Material = Enum.Material.SmoothPlastic
    body.Shape = Enum.PartType.Block
    body.Parent = model
    
    model.PrimaryPart = body
    
    -- Round the body
    local bodyMesh = Instance.new("SpecialMesh")
    bodyMesh.MeshType = Enum.MeshType.Sphere
    bodyMesh.Scale = Vector3.new(1, 0.8, 1.2)
    bodyMesh.Parent = body
    
    -- Head
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5 * scale, 1.5 * scale, 1.5 * scale)
    head.Position = Vector3.new(0, 2.2 * scale, 1.5 * scale)
    head.Anchored = true
    head.CanCollide = false
    head.Color = data.primaryColor
    head.Material = Enum.Material.SmoothPlastic
    head.Shape = Enum.PartType.Ball
    head.Parent = model
    
    -- Eyes
    local eyeOffset = 0.4 * scale
    for i, xOffset in ipairs({-eyeOffset, eyeOffset}) do
        local eye = Instance.new("Part")
        eye.Name = "Eye_" .. i
        eye.Size = Vector3.new(0.3 * scale, 0.4 * scale, 0.2 * scale)
        eye.Position = head.Position + Vector3.new(xOffset, 0.2 * scale, 0.6 * scale)
        eye.Anchored = true
        eye.CanCollide = false
        eye.Color = Color3.new(0, 0, 0)
        eye.Material = Enum.Material.SmoothPlastic
        eye.Shape = Enum.PartType.Ball
        eye.Parent = model
        
        -- Eye shine
        local shine = Instance.new("Part")
        shine.Name = "EyeShine_" .. i
        shine.Size = Vector3.new(0.1 * scale, 0.1 * scale, 0.1 * scale)
        shine.Position = eye.Position + Vector3.new(0.05 * scale, 0.1 * scale, 0.1 * scale)
        shine.Anchored = true
        shine.CanCollide = false
        shine.Color = Color3.new(1, 1, 1)
        shine.Material = Enum.Material.Neon
        shine.Shape = Enum.PartType.Ball
        shine.Parent = model
    end
    
    -- Ears (based on pet type)
    PetModels.AddEars(model, data, scale)
    
    -- Tail
    PetModels.AddTail(model, data, scale)
    
    -- Legs
    PetModels.AddLegs(model, data, scale)
    
    -- Element effect
    PetModels.AddElementEffect(model, data.element)
    
    -- Rarity glow
    if rarity and RARITY_GLOW[rarity] then
        PetModels.AddRarityGlow(model, RARITY_GLOW[rarity])
    end
    
    -- Mutation effect
    if mutationTier and mutationTier > 0 then
        PetModels.AddMutationEffect(model, mutationTier)
    end
    
    -- Humanoid for animations
    local humanoid = Instance.new("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.Parent = model
    
    return model
end

----- BODY PARTS -----
function PetModels.AddEars(model: Model, data: any, scale: number)
    local head = model:FindFirstChild("Head")
    if not head then return end
    
    for i, xOffset in ipairs({-0.5 * scale, 0.5 * scale}) do
        local ear = Instance.new("Part")
        ear.Name = "Ear_" .. i
        ear.Size = Vector3.new(0.3 * scale, 0.6 * scale, 0.2 * scale)
        ear.Position = head.Position + Vector3.new(xOffset, 0.8 * scale, 0)
        ear.Anchored = true
        ear.CanCollide = false
        ear.Color = data.secondaryColor
        ear.Material = Enum.Material.SmoothPlastic
        ear.Parent = model
        
        -- Wedge shape for ears
        local earMesh = Instance.new("SpecialMesh")
        earMesh.MeshType = Enum.MeshType.Wedge
        earMesh.Scale = Vector3.new(1, 1, 1)
        earMesh.Parent = ear
        
        ear.Rotation = Vector3.new(0, 0, xOffset > 0 and -15 or 15)
    end
end

function PetModels.AddTail(model: Model, data: any, scale: number)
    local body = model:FindFirstChild("Body")
    if not body then return end
    
    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(0.4 * scale, 0.4 * scale, 1.2 * scale)
    tail.Position = body.Position + Vector3.new(0, 0.3 * scale, -1.8 * scale)
    tail.Anchored = true
    tail.CanCollide = false
    tail.Color = data.secondaryColor
    tail.Material = Enum.Material.SmoothPlastic
    tail.Parent = model
    
    local tailMesh = Instance.new("SpecialMesh")
    tailMesh.MeshType = Enum.MeshType.Sphere
    tailMesh.Scale = Vector3.new(1, 1, 2)
    tailMesh.Parent = tail
    
    tail.Rotation = Vector3.new(-30, 0, 0)
end

function PetModels.AddLegs(model: Model, data: any, scale: number)
    local body = model:FindFirstChild("Body")
    if not body then return end
    
    local legPositions = {
        Vector3.new(-0.6 * scale, -0.5 * scale, 0.8 * scale),
        Vector3.new(0.6 * scale, -0.5 * scale, 0.8 * scale),
        Vector3.new(-0.6 * scale, -0.5 * scale, -0.8 * scale),
        Vector3.new(0.6 * scale, -0.5 * scale, -0.8 * scale),
    }
    
    for i, offset in ipairs(legPositions) do
        local leg = Instance.new("Part")
        leg.Name = "Leg_" .. i
        leg.Size = Vector3.new(0.4 * scale, 1 * scale, 0.4 * scale)
        leg.Position = body.Position + offset
        leg.Anchored = true
        leg.CanCollide = false
        leg.Color = data.primaryColor
        leg.Material = Enum.Material.SmoothPlastic
        leg.Shape = Enum.PartType.Cylinder
        leg.Rotation = Vector3.new(0, 0, 90)
        leg.Parent = model
    end
end

----- EFFECTS -----
function PetModels.AddElementEffect(model: Model, element: string)
    local body = model:FindFirstChild("Body")
    if not body then return end
    
    local effectData = ELEMENT_EFFECTS[element]
    if not effectData then return end
    
    local particles = Instance.new("ParticleEmitter")
    particles.Name = "ElementParticles"
    particles.Color = ColorSequence.new(effectData.particleColor)
    particles.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(1, 0),
    })
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Rate = 5
    particles.Speed = NumberRange.new(1, 2)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1),
    })
    particles.Parent = body
end

function PetModels.AddRarityGlow(model: Model, color: Color3)
    local body = model:FindFirstChild("Body")
    if not body then return end
    
    local light = Instance.new("PointLight")
    light.Name = "RarityGlow"
    light.Color = color
    light.Brightness = 1
    light.Range = 6
    light.Parent = body
end

function PetModels.AddMutationEffect(model: Model, tier: number)
    local body = model:FindFirstChild("Body")
    if not body then return end
    
    local mutationColors = {
        [1] = Color3.fromRGB(100, 255, 100),   -- Tier 1: Green glow
        [2] = Color3.fromRGB(100, 200, 255),   -- Tier 2: Blue glow
        [3] = Color3.fromRGB(255, 100, 255),   -- Tier 3: Prismatic
        [4] = Color3.fromRGB(50, 0, 80),       -- Tier 4: Void
    }
    
    local color = mutationColors[tier] or mutationColors[1]
    
    -- Mutation aura
    local aura = Instance.new("ParticleEmitter")
    aura.Name = "MutationAura"
    aura.Color = ColorSequence.new(color)
    aura.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    aura.Lifetime = NumberRange.new(1, 2)
    aura.Rate = 10 * tier
    aura.Speed = NumberRange.new(0.5, 1.5)
    aura.SpreadAngle = Vector2.new(360, 360)
    aura.LightEmission = 0.5
    aura.Parent = body
    
    -- Extra glow for higher tiers
    if tier >= 3 then
        local light = Instance.new("PointLight")
        light.Name = "MutationLight"
        light.Color = color
        light.Brightness = tier
        light.Range = 8
        light.Parent = body
    end
end

----- UTILITY -----
function PetModels.GetPetData(petId: string)
    return PET_DATA[petId]
end

function PetModels.GetAllPetIds(): {string}
    local ids = {}
    for id in pairs(PET_DATA) do
        table.insert(ids, id)
    end
    return ids
end

return PetModels
