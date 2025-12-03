--!strict
--[[
    PvEService
    Handles PvE lane defense mode
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Types = Shared.Types
local Utils = Shared.Utils
local Remotes = Shared.Remotes
local Data = Shared.Data

local PvEService = {}

----- PRIVATE VARIABLES -----
local DataService
local activeSessions: {[Player]: any} = {}

----- INITIALIZATION -----
function PvEService:Init()
    print("[PvEService] Initializing...")
    DataService = require(script.Parent.DataService)
end

function PvEService:Start()
    print("[PvEService] Starting...")
    
    if Remotes.JoinPvE then
        Remotes.JoinPvE.OnServerEvent:Connect(function(player, biome)
            self:StartSession(player, biome)
        end)
    end
    
    if Remotes.LeavePvE then
        Remotes.LeavePvE.OnServerEvent:Connect(function(player)
            self:EndSession(player)
        end)
    end
    
    if Remotes.PlacePetPvE then
        Remotes.PlacePetPvE.OnServerEvent:Connect(function(player, petUid, lane, slot)
            self:PlacePet(player, petUid, lane, slot)
        end)
    end
    
    if Remotes.UseAbilityPvE then
        Remotes.UseAbilityPvE.OnServerEvent:Connect(function(player, petUid, abilitySlot)
            self:UseAbility(player, petUid, abilitySlot)
        end)
    end
end

----- PVE FUNCTIONS -----
function PvEService:StartSession(player: Player, biome: string)
    if activeSessions[player] then
        Remotes.Notification:FireClient(player, "Error", "Already in a PvE session!")
        return
    end
    
    local data = DataService:GetData(player)
    if not data then return end
    
    -- Check biome unlocked
    if not table.find(data.farm.unlockedBiomes, biome) then
        Remotes.Notification:FireClient(player, "Error", "Biome not unlocked!")
        return
    end
    
    activeSessions[player] = {
        biome = biome,
        wave = 1,
        lanes = {{}, {}, {}, {}, {}},
        enemies = {},
        startTime = os.time(),
    }
    
    Remotes.Notification:FireClient(player, "Success", "PvE session started in " .. biome)
    self:StartWave(player)
end

function PvEService:EndSession(player: Player)
    local session = activeSessions[player]
    if not session then return end
    
    -- Calculate rewards based on waves completed
    local wavesCompleted = session.wave - 1
    local leavesReward = wavesCompleted * 50
    local shardsReward = wavesCompleted * 5
    
    DataService:UpdateCurrency(player, "Leaves", leavesReward)
    DataService:UpdateCurrency(player, "MutationShards", shardsReward)
    
    activeSessions[player] = nil
    
    Remotes.Notification:FireClient(player, "Success", "Session ended! Waves: " .. wavesCompleted .. ", Rewards: " .. leavesReward .. " Leaves")
end

function PvEService:StartWave(player: Player)
    local session = activeSessions[player]
    if not session then return end
    
    local wave = session.wave
    local enemyCount = math.min(3 + wave, 20)
    local isBoss = wave % 5 == 0
    
    local waveData = {
        waveNumber = wave,
        enemyCount = enemyCount,
        isBoss = isBoss,
    }
    
    Remotes.PvEWaveStart:FireClient(player, waveData)
    Remotes.Notification:FireClient(player, "Info", "Wave " .. wave .. " started!")
end

function PvEService:PlacePet(player: Player, petUid: string, lane: number, slot: number)
    local session = activeSessions[player]
    if not session then return end
    
    if lane < 1 or lane > Constants.PVE_LANES then
        Remotes.Notification:FireClient(player, "Error", "Invalid lane!")
        return
    end
    
    if slot < 1 or slot > Constants.PETS_PER_LANE then
        Remotes.Notification:FireClient(player, "Error", "Invalid slot!")
        return
    end
    
    -- TODO: Validate pet ownership and placement logic
    session.lanes[lane][slot] = petUid
    Remotes.Notification:FireClient(player, "Success", "Pet placed!")
end

function PvEService:UseAbility(player: Player, petUid: string, abilitySlot: string)
    local session = activeSessions[player]
    if not session then return end
    
    -- TODO: Implement ability usage with cooldowns
    Remotes.Notification:FireClient(player, "Info", "Ability used!")
end

function PvEService:CompleteWave(player: Player)
    local session = activeSessions[player]
    if not session then return end
    
    local wave = session.wave
    
    -- Check for wave rewards
    local waveReward = Constants.WAVE_REWARDS[wave]
    if waveReward then
        if waveReward.leaves then
            DataService:UpdateCurrency(player, "Leaves", waveReward.leaves)
        end
        if waveReward.shards then
            DataService:UpdateCurrency(player, "MutationShards", waveReward.shards)
        end
    end
    
    session.wave = wave + 1
    Remotes.PvEWaveEnd:FireClient(player, {waveCompleted = wave, rewards = waveReward})
    
    -- Start next wave after delay
    task.delay(3, function()
        if activeSessions[player] then
            self:StartWave(player)
        end
    end)
end

return PvEService
