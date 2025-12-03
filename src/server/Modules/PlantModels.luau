--!strict
--[[
    PlantModels
    Creates visual plant models for each growth stage
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Data = Shared.Data

local PlantModels = {}

----- CONFIGURATION -----
local GROWTH_STAGES = 4 -- Seed, Sprout, Growing, Ready
local ELEMENT_COLORS = {
    Nature = Color3.fromRGB(76, 175, 80),
    Fire = Color3.fromRGB(244, 67, 54),
    Ice = Color3.fromRGB(33, 150, 243),
    Tech = Color3.fromRGB(255, 235, 59),
    Chaos = Color3.fromRGB(156, 39, 176),
}

----- CREATE PLANT MODEL -----
function PlantModels.CreatePlant(seedId: string, stage: number): Model
    local seedData = Data.Seeds.GetSeed(seedId)
    if not seedData then
        return PlantModels.CreateDefaultPlant(stage)
    end
    
    local element = seedData.element
    local color = ELEMENT_COLORS[element] or ELEMENT_COLORS.Nature
    
    local plant = Instance.new("Model")
    plant.Name = "Plant_" .. seedId
    
    if stage == 1 then
        -- Seed stage: small mound
        local mound = Instance.new("Part")
        mound.Name = "Mound"
        mound.Shape = Enum.PartType.Ball
        mound.Size = Vector3.new(1, 0.5, 1)
        mound.Position = Vector3.new(0, 0.25, 0)
        mound.Anchored = true
        mound.Color = Color3.fromRGB(101, 67, 33)
        mound.Material = Enum.Material.Ground
        mound.Parent = plant
        plant.PrimaryPart = mound
        
    elseif stage == 2 then
        -- Sprout stage: small stem with tiny leaves
        local stem = Instance.new("Part")
        stem.Name = "Stem"
        stem.Size = Vector3.new(0.2, 1, 0.2)
        stem.Position = Vector3.new(0, 0.5, 0)
        stem.Anchored = true
        stem.Color = Color3.fromRGB(34, 139, 34)
        stem.Material = Enum.Material.Grass
        stem.Parent = plant
        
        local leaf1 = Instance.new("Part")
        leaf1.Name = "Leaf1"
        leaf1.Size = Vector3.new(0.5, 0.1, 0.3)
        leaf1.Position = Vector3.new(0.3, 0.8, 0)
        leaf1.Anchored = true
        leaf1.Color = color
        leaf1.Material = Enum.Material.Grass
        leaf1.Parent = plant
        
        local leaf2 = Instance.new("Part")
        leaf2.Name = "Leaf2"
        leaf2.Size = Vector3.new(0.5, 0.1, 0.3)
        leaf2.Position = Vector3.new(-0.3, 0.7, 0)
        leaf2.Anchored = true
        leaf2.Color = color
        leaf2.Material = Enum.Material.Grass
        leaf2.Parent = plant
        
        plant.PrimaryPart = stem
        
    elseif stage == 3 then
        -- Growing stage: taller with more leaves
        local stem = Instance.new("Part")
        stem.Name = "Stem"
        stem.Size = Vector3.new(0.3, 2, 0.3)
        stem.Position = Vector3.new(0, 1, 0)
        stem.Anchored = true
        stem.Color = Color3.fromRGB(34, 139, 34)
        stem.Material = Enum.Material.Grass
        stem.Parent = plant
        
        for i = 1, 4 do
            local leaf = Instance.new("Part")
            leaf.Name = "Leaf" .. i
            leaf.Size = Vector3.new(0.8, 0.15, 0.4)
            local angle = math.rad(90 * i)
            leaf.Position = Vector3.new(math.cos(angle) * 0.5, 0.5 + (i * 0.4), math.sin(angle) * 0.3)
            leaf.Anchored = true
            leaf.Color = color
            leaf.Material = Enum.Material.Grass
            leaf.Parent = plant
        end
        
        plant.PrimaryPart = stem
        
    else
        -- Ready stage: full plant with glowing fruit/flower
        local stem = Instance.new("Part")
        stem.Name = "Stem"
        stem.Size = Vector3.new(0.4, 3, 0.4)
        stem.Position = Vector3.new(0, 1.5, 0)
        stem.Anchored = true
        stem.Color = Color3.fromRGB(34, 139, 34)
        stem.Material = Enum.Material.Grass
        stem.Parent = plant
        
        -- Leaves
        for i = 1, 6 do
            local leaf = Instance.new("Part")
            leaf.Name = "Leaf" .. i
            leaf.Size = Vector3.new(1.2, 0.2, 0.6)
            local angle = math.rad(60 * i)
            local height = 0.5 + (i * 0.4)
            leaf.Position = Vector3.new(math.cos(angle) * 0.7, height, math.sin(angle) * 0.4)
            leaf.Anchored = true
            leaf.Color = color
            leaf.Material = Enum.Material.Grass
            leaf.Parent = plant
        end
        
        -- Fruit/Flower (glowing)
        local fruit = Instance.new("Part")
        fruit.Name = "Fruit"
        fruit.Shape = Enum.PartType.Ball
        fruit.Size = Vector3.new(1.2, 1.2, 1.2)
        fruit.Position = Vector3.new(0, 3.5, 0)
        fruit.Anchored = true
        fruit.Color = color
        fruit.Material = Enum.Material.Neon
        fruit.Parent = plant
        
        -- Point light for glow effect
        local light = Instance.new("PointLight")
        light.Name = "FruitGlow"
        light.Color = color
        light.Brightness = 1
        light.Range = 8
        light.Parent = fruit
        
        -- Sparkles for ready indicator
        local sparkles = Instance.new("ParticleEmitter")
        sparkles.Name = "ReadySparkles"
        sparkles.Color = ColorSequence.new(color)
        sparkles.Size = NumberSequence.new(0.3)
        sparkles.Lifetime = NumberRange.new(0.5, 1)
        sparkles.Rate = 10
        sparkles.Speed = NumberRange.new(1, 2)
        sparkles.SpreadAngle = Vector2.new(180, 180)
        sparkles.Parent = fruit
        
        plant.PrimaryPart = stem
    end
    
    return plant
end

function PlantModels.CreateDefaultPlant(stage: number): Model
    return PlantModels.CreatePlant("sprout_seed", stage)
end

function PlantModels.GetStageFromProgress(progress: number): number
    if progress < 0.25 then
        return 1
    elseif progress < 0.5 then
        return 2
    elseif progress < 1.0 then
        return 3
    else
        return 4
    end
end

return PlantModels
