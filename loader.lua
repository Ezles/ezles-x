--[[
    Ezles-X BSS Loader
    Bee Swarm Simulator Script

    Usage:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezles/ezles-x/main/loader.lua"))()
]]

local HttpGet = game.HttpGet or game.HttpGetAsync

local function getExecutor()
    if syn then return "Synapse X"
    elseif Seliware then return "Seliware"
    elseif KRNL_LOADED then return "KRNL"
    elseif Delta then return "Delta"
    elseif Fluxus then return "Fluxus"
    elseif getexecutorname then return getexecutorname()
    else return "Unknown"
    end
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local placeId = game.PlaceId
local BSS_PLACE_ID = 1537690962

if placeId ~= BSS_PLACE_ID then
    notify("Ezles-X BSS", "This script is only for Bee Swarm Simulator!", 5)
    warn("[Ezles-X BSS] Wrong game! Expected BSS (1537690962), got: " .. placeId)
    return
end

local executor = getExecutor()
notify("Ezles-X BSS", "Loading on " .. executor .. "...", 3)

local MAIN_URL = "https://raw.githubusercontent.com/Ezles/ezles-x/main/main.lua"

local success, result = pcall(function()
    return loadstring(game:HttpGet(MAIN_URL))()
end)

if not success then
    notify("Ezles-X BSS", "Failed to load: " .. tostring(result), 10)
    warn("[Ezles-X BSS] Load failed: " .. tostring(result))
    return
end

return result
