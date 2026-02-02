--[[
    MyHub Loader
    Usage: loadstring(game:HttpGet("YOUR_RAW_URL"))()

    This is the entry point that users execute.
    It handles environment detection, executor compatibility,
    and loads the main hub script.
]]

-- Environment Detection & Compatibility Layer
local HttpGet = game.HttpGet or game.HttpGetAsync
local request = request or http_request or syn and syn.request or http and http.request

-- Executor Detection
local function getExecutor(): string
    if syn then return "Synapse X"
    elseif SENTINEL_V2 then return "Sentinel"
    elseif Seliware then return "Seliware"
    elseif KRNL_LOADED then return "KRNL"
    elseif Delta then return "Delta"
    elseif Fluxus then return "Fluxus"
    elseif is_sirhurt_closure then return "SirHurt"
    elseif getexecutorname then return getexecutorname()
    else return "Unknown"
    end
end

-- Feature Support Check
local function checkSupport(): {[string]: boolean}
    return {
        hookmetamethod = hookmetamethod ~= nil,
        hookfunction = hookfunction ~= nil or replaceclosure ~= nil,
        getrawmetatable = getrawmetatable ~= nil,
        newcclosure = newcclosure ~= nil,
        getconnections = getconnections ~= nil,
        getgc = getgc ~= nil,
        getupvalue = debug and debug.getupvalue ~= nil or getupvalue ~= nil,
        Drawing = Drawing ~= nil,
        firesignal = firesignal ~= nil,
        fireproximityprompt = fireproximityprompt ~= nil,
    }
end

-- Notification System (works before UI loads)
local function notify(title: string, text: string, duration: number?)
    if Seliware and Seliware.Notify then
        Seliware.Notify(title, text)
    elseif game:GetService("StarterGui") then
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end
end

-- Main Loader Logic
local executor = getExecutor()
local support = checkSupport()

notify("MyHub", "Loading on " .. executor .. "...", 3)

-- Version Check
local CURRENT_VERSION = "1.0.0"
local success, versionData = pcall(function()
    return game:HttpGet("YOUR_VERSION_CHECK_URL")
end)

-- Load Main Hub
local hubUrl = "YOUR_MAIN_HUB_RAW_URL"
local success, result = pcall(function()
    return loadstring(game:HttpGet(hubUrl))()
end)

if not success then
    notify("MyHub Error", "Failed to load: " .. tostring(result), 10)
    error("[MyHub] Load failed: " .. tostring(result))
end

-- Pass environment info to the hub
if result and type(result) == "table" and result.Init then
    result.Init({
        Executor = executor,
        Support = support,
        Version = CURRENT_VERSION
    })
end

return result
