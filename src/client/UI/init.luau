--!strict
--[[
    UI Module
    Entry point for UI components
]]

local UI = {}

UI.Components = require(script.Components)
UI.Screens = {
    FarmHUD = require(script.Screens.FarmHUD),
    SeedPanel = require(script.Screens.SeedPanel),
    PlotInfoPanel = require(script.Screens.PlotInfoPanel),
    NotificationSystem = require(script.Screens.NotificationSystem),
    PetInventory = require(script.Screens.PetInventory),
    PetDetails = require(script.Screens.PetDetails),
    PetPenUI = require(script.Screens.PetPenUI),
    PetSelectModal = require(script.Screens.PetSelectModal),
    EggInventory = require(script.Screens.EggInventory),
}

return UI
