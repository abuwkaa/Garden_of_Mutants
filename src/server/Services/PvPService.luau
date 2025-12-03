--!strict
--[[
    PvPService
    Handles PvP matchmaking and arena battles
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local Types = Shared.Types
local Utils = Shared.Utils
local Remotes = Shared.Remotes

local PvPService = {}

----- PRIVATE VARIABLES -----
local DataService
local matchmakingQueue: {Player} = {}
local activeMatches: {[string]: Types.MatchData} = {}

----- INITIALIZATION -----
function PvPService:Init()
    print("[PvPService] Initializing...")
    DataService = require(script.Parent.DataService)
end

function PvPService:Start()
    print("[PvPService] Starting...")
    
    if Remotes.JoinPvPQueue then
        Remotes.JoinPvPQueue.OnServerEvent:Connect(function(player)
            self:JoinQueue(player)
        end)
    end
    
    if Remotes.LeavePvPQueue then
        Remotes.LeavePvPQueue.OnServerEvent:Connect(function(player)
            self:LeaveQueue(player)
        end)
    end
    
    if Remotes.PvPInput then
        Remotes.PvPInput.OnServerEvent:Connect(function(player, inputType, inputData)
            self:HandleInput(player, inputType, inputData)
        end)
    end
    
    -- Matchmaking loop
    task.spawn(function()
        while true do
            self:ProcessMatchmaking()
            task.wait(2)
        end
    end)
end

----- MATCHMAKING -----
function PvPService:JoinQueue(player: Player)
    if table.find(matchmakingQueue, player) then
        Remotes.Notification:FireClient(player, "Error", "Already in queue!")
        return
    end
    
    table.insert(matchmakingQueue, player)
    Remotes.Notification:FireClient(player, "Info", "Joined PvP queue... (" .. #matchmakingQueue .. " in queue)")
end

function PvPService:LeaveQueue(player: Player)
    local index = table.find(matchmakingQueue, player)
    if index then
        table.remove(matchmakingQueue, index)
        Remotes.Notification:FireClient(player, "Info", "Left PvP queue")
    end
end

function PvPService:ProcessMatchmaking()
    if #matchmakingQueue < 2 then return end
    
    -- Simple FIFO matchmaking for now
    -- TODO: MMR-based matchmaking
    local player1 = table.remove(matchmakingQueue, 1)
    local player2 = table.remove(matchmakingQueue, 1)
    
    if player1 and player2 then
        self:CreateMatch(player1, player2)
    end
end

function PvPService:CreateMatch(player1: Player, player2: Player)
    local matchId = Utils.GenerateUID()
    
    local matchData: Types.MatchData = {
        matchId = matchId,
        player1 = player1,
        player2 = player2,
        startTime = os.time(),
    }
    
    activeMatches[matchId] = matchData
    
    Remotes.PvPMatchStart:FireClient(player1, {matchId = matchId, opponent = player2.Name})
    Remotes.PvPMatchStart:FireClient(player2, {matchId = matchId, opponent = player1.Name})
    
    Remotes.Notification:FireClient(player1, "Success", "Match found! VS " .. player2.Name)
    Remotes.Notification:FireClient(player2, "Success", "Match found! VS " .. player1.Name)
    
    -- Match timer
    task.delay(Constants.MATCH_DURATION, function()
        self:EndMatch(matchId, nil) -- Draw if no winner
    end)
end

function PvPService:HandleInput(player: Player, inputType: string, inputData: any)
    -- Find player's match
    for matchId, match in pairs(activeMatches) do
        if match.player1 == player or match.player2 == player then
            -- TODO: Process combat input
            return
        end
    end
end

function PvPService:EndMatch(matchId: string, winner: Player?)
    local match = activeMatches[matchId]
    if not match then return end
    
    local player1 = match.player1
    local player2 = match.player2
    
    local data1 = DataService:GetData(player1)
    local data2 = DataService:GetData(player2)
    
    if winner then
        local loser = winner == player1 and player2 or player1
        local winnerData = winner == player1 and data1 or data2
        local loserData = winner == player1 and data2 or data1
        
        if winnerData and loserData then
            -- Update MMR
            local mmrChange = Utils.CalculateMmrChange(winnerData.pvp.mmr, loserData.pvp.mmr)
            winnerData.pvp.mmr = winnerData.pvp.mmr + mmrChange
            loserData.pvp.mmr = math.max(0, loserData.pvp.mmr - mmrChange)
            
            -- Update ranks
            winnerData.pvp.rank = Utils.GetRankFromMmr(winnerData.pvp.mmr)
            loserData.pvp.rank = Utils.GetRankFromMmr(loserData.pvp.mmr)
            
            -- Update wins/losses
            winnerData.pvp.seasonWins = winnerData.pvp.seasonWins + 1
            loserData.pvp.seasonLosses = loserData.pvp.seasonLosses + 1
            
            -- Give rewards
            DataService:UpdateCurrency(winner, "PvPTokens", Constants.PVP_REWARDS.Win.tokens)
            DataService:UpdateCurrency(loser, "PvPTokens", Constants.PVP_REWARDS.Lose.tokens)
        end
        
        Remotes.PvPMatchEnd:FireClient(winner, {result = "Win", mmrChange = mmrChange})
        Remotes.PvPMatchEnd:FireClient(loser, {result = "Lose", mmrChange = -mmrChange})
    else
        -- Draw
        Remotes.PvPMatchEnd:FireClient(player1, {result = "Draw", mmrChange = 0})
        Remotes.PvPMatchEnd:FireClient(player2, {result = "Draw", mmrChange = 0})
    end
    
    activeMatches[matchId] = nil
end

return PvPService
