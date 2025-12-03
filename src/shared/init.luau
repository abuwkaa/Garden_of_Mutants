--!strict
--[[
    Shared Module
    Entry point for all shared code
]]

local Shared = {}

Shared.Constants = require(script.Constants)
Shared.Types = require(script.Types)
Shared.Utils = require(script.Utils)
Shared.Remotes = require(script.Remotes)
Shared.Data = require(script.Data)

return Shared
