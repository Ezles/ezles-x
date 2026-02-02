--[[
    MyHub - Main Entry Point
    A complete hub script framework for educational purposes

    Usage via loader:
    loadstring(game:HttpGet("YOUR_RAW_URL/loader.lua"))()

    Or direct execution (for testing):
    loadstring(game:HttpGet("YOUR_RAW_URL/main.lua"))()
]]

-- Prevent multiple instances
if getgenv and getgenv().MyHubLoaded then
    warn("[MyHub] Already loaded!")
    return
end

if getgenv then
    getgenv().MyHubLoaded = true
end

-- Base URLs for loading modules (replace with your GitHub raw URLs)
local BASE_URL = "YOUR_GITHUB_RAW_BASE_URL"

-- For local testing, you can inline the modules or use a local server

-- =====================================
-- INLINE LOADING (for single-file distribution)
-- =====================================

-- Core Module
local Hub = {}
Hub.__index = Hub

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
    TeleportService = game:GetService("TeleportService"),
}

local LocalPlayer = Services.Players.LocalPlayer

local State = {
    Initialized = false,
    ExecutorInfo = nil,
    Modules = {},
    Connections = {},
    Loops = {},
    Settings = {},
}

-- Utilities
local Utilities = {}

function Utilities.SafeCall(func, ...)
    return pcall(func, ...)
end

function Utilities.GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function Utilities.GetHumanoid()
    local character = Utilities.GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

function Utilities.GetRootPart()
    local character = Utilities.GetCharacter()
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

function Utilities.IsAlive()
    local humanoid = Utilities.GetHumanoid()
    return humanoid ~= nil and humanoid.Health > 0
end

function Utilities.GetDistance(part1, part2)
    return (part1.Position - part2.Position).Magnitude
end

function Utilities.Notify(title, text, duration)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

function Utilities.RandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local idx = math.random(1, #chars)
        result = result .. chars:sub(idx, idx)
    end
    return result
end

-- Connection Management
function Hub:AddConnection(connection, name)
    local key = name or Utilities.RandomString(8)
    State.Connections[key] = connection
    return key
end

function Hub:RemoveConnection(key)
    local conn = State.Connections[key]
    if conn then
        conn:Disconnect()
        State.Connections[key] = nil
    end
end

function Hub:ClearConnections()
    for key, conn in pairs(State.Connections) do
        conn:Disconnect()
    end
    State.Connections = {}
end

-- Loop Management
function Hub:StartLoop(name, interval, callback)
    if State.Loops[name] then
        self:StopLoop(name)
    end

    State.Loops[name] = {
        Running = true,
        Thread = task.spawn(function()
            while State.Loops[name] and State.Loops[name].Running do
                local success, err = pcall(callback)
                if not success then
                    warn("[MyHub] Loop error in " .. name .. ": " .. tostring(err))
                end
                task.wait(interval)
            end
        end)
    }
end

function Hub:StopLoop(name)
    local loop = State.Loops[name]
    if loop then
        loop.Running = false
        if loop.Thread then
            pcall(function() task.cancel(loop.Thread) end)
        end
        State.Loops[name] = nil
    end
end

function Hub:StopAllLoops()
    for name in pairs(State.Loops) do
        self:StopLoop(name)
    end
end

-- Unload
function Hub:Unload()
    self:ClearConnections()
    self:StopAllLoops()

    for name, module in pairs(State.Modules) do
        if module.Unload then
            pcall(module.Unload)
        end
    end

    State.Modules = {}
    State.Initialized = false

    if getgenv then
        getgenv().MyHubLoaded = false
    end

    Utilities.Notify("MyHub", "Unloaded successfully", 3)
end

Hub.Utilities = Utilities
Hub.Services = Services
Hub.LocalPlayer = LocalPlayer
Hub.State = State

-- =====================================
-- EXECUTOR DETECTION
-- =====================================

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

local function checkSupport()
    return {
        hookmetamethod = hookmetamethod ~= nil,
        hookfunction = hookfunction ~= nil or replaceclosure ~= nil,
        getrawmetatable = getrawmetatable ~= nil,
        newcclosure = newcclosure ~= nil,
        getconnections = getconnections ~= nil,
        Drawing = Drawing ~= nil,
        writefile = writefile ~= nil,
    }
end

State.ExecutorInfo = {
    Executor = getExecutor(),
    Support = checkSupport(),
    Version = "1.0.0"
}

-- =====================================
-- LOAD MODULES (Inline for single file)
-- =====================================

-- You would paste the module code here for single-file distribution
-- For now, we'll create placeholder modules that you can expand

local ESP = { Settings = { ShowBoxes = true, ShowNames = true, ShowHealth = true, ShowDistance = true, ShowTracers = false, TeamCheck = false, MaxDistance = 1000, TracerOrigin = "Bottom", BoxType = "2D", Colors = { Enemy = Color3.fromRGB(255, 0, 0), Team = Color3.fromRGB(0, 255, 0) } }, Enabled = false }
local Aimbot = { Settings = { FOV = 150, ShowFOV = true, FOVColor = Color3.fromRGB(255, 255, 255), TargetPart = "Head", TeamCheck = false, VisibilityCheck = true, Smoothness = 0.1, UseSmoothing = true, UsePrediction = false, PredictionMultiplier = 0.165 }, Enabled = false }
local RemoteSpy = { Settings = { LogEvents = true, LogFunctions = true, PrintToConsole = true }, Enabled = false, Logs = {} }
local Movement = { Fly = { Enabled = false, Speed = 50 }, Noclip = { Enabled = false }, Speed = { Enabled = false, Value = 16 }, JumpPower = { Enabled = false, Value = 50 }, InfiniteJump = { Enabled = false } }

-- =====================================
-- LOAD UI LIBRARY (Rayfield)
-- =====================================

Utilities.Notify("MyHub", "Loading on " .. State.ExecutorInfo.Executor .. "...", 3)

local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("[MyHub] Failed to load Rayfield: " .. tostring(err))
    Utilities.Notify("MyHub", "Failed to load UI - check console", 5)
    return
end

-- =====================================
-- CREATE UI
-- =====================================

local Window = Rayfield:CreateWindow({
    Name = "MyHub",
    LoadingTitle = "MyHub",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MyHub",
        FileName = "Config"
    },
    KeySystem = false,
})

-- Combat Tab
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Flag = "AimbotEnabled",
    Callback = function(value)
        Aimbot.Enabled = value
        Utilities.Notify("Aimbot", value and "Enabled" or "Disabled", 2)
    end,
})

CombatTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = 150,
    Flag = "AimbotFOV",
    Callback = function(value)
        Aimbot.Settings.FOV = value
    end,
})

CombatTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(value)
        Aimbot.Settings.ShowFOV = value
    end,
})

CombatTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "Torso"},
    CurrentOption = {"Head"},
    Flag = "TargetPart",
    Callback = function(options)
        Aimbot.Settings.TargetPart = options[1]
    end,
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = 0.1,
    Flag = "AimbotSmooth",
    Callback = function(value)
        Aimbot.Settings.Smoothness = value
    end,
})

-- Visuals Tab
local VisualsTab = Window:CreateTab("Visuals", 4483362458)

VisualsTab:CreateSection("Player ESP")

VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(value)
        ESP.Enabled = value
        Utilities.Notify("ESP", value and "Enabled" or "Disabled", 2)
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Boxes",
    CurrentValue = true,
    Flag = "ESPBoxes",
    Callback = function(value)
        ESP.Settings.ShowBoxes = value
    end,
})

VisualsTab:CreateDropdown({
    Name = "Box Type",
    Options = {"2D", "Corner"},
    CurrentOption = {"2D"},
    Flag = "BoxType",
    Callback = function(options)
        ESP.Settings.BoxType = options[1]
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Names",
    CurrentValue = true,
    Flag = "ESPNames",
    Callback = function(value)
        ESP.Settings.ShowNames = value
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Health",
    CurrentValue = true,
    Flag = "ESPHealth",
    Callback = function(value)
        ESP.Settings.ShowHealth = value
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ESPDistance",
    Callback = function(value)
        ESP.Settings.ShowDistance = value
    end,
})

VisualsTab:CreateToggle({
    Name = "Show Tracers",
    CurrentValue = false,
    Flag = "ESPTracers",
    Callback = function(value)
        ESP.Settings.ShowTracers = value
    end,
})

VisualsTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 2000},
    Increment = 50,
    CurrentValue = 1000,
    Flag = "ESPMaxDist",
    Callback = function(value)
        ESP.Settings.MaxDistance = value
    end,
})

VisualsTab:CreateColorPicker({
    Name = "Enemy Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPEnemyColor",
    Callback = function(color)
        ESP.Settings.Colors.Enemy = color
    end,
})

-- Movement Tab
local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateSection("Fly")

MovementTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(value)
        Movement.Fly.Enabled = value
        Utilities.Notify("Fly", value and "Enabled" or "Disabled", 2)
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(value)
        Movement.Fly.Speed = value
    end,
})

MovementTab:CreateSection("Noclip")

MovementTab:CreateToggle({
    Name = "Enable Noclip",
    CurrentValue = false,
    Flag = "NoclipEnabled",
    Callback = function(value)
        Movement.Noclip.Enabled = value
        Utilities.Notify("Noclip", value and "Enabled" or "Disabled", 2)
    end,
})

MovementTab:CreateSection("Speed")

MovementTab:CreateToggle({
    Name = "Enable Speed",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(value)
        Movement.Speed.Enabled = value
        Utilities.Notify("Speed", value and "Enabled" or "Disabled", 2)
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 50,
    Flag = "WalkSpeed",
    Callback = function(value)
        Movement.Speed.Value = value
    end,
})

MovementTab:CreateSection("Jump")

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(value)
        Movement.InfiniteJump.Enabled = value
        Utilities.Notify("Infinite Jump", value and "Enabled" or "Disabled", 2)
    end,
})

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 100,
    Flag = "JumpPower",
    Callback = function(value)
        Movement.JumpPower.Value = value
    end,
})

-- Misc Tab
local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Remote Spy")

MiscTab:CreateToggle({
    Name = "Enable Remote Spy",
    CurrentValue = false,
    Flag = "RemoteSpyEnabled",
    Callback = function(value)
        RemoteSpy.Enabled = value
        Utilities.Notify("Remote Spy", value and "Enabled" or "Disabled", 2)
    end,
})

MiscTab:CreateToggle({
    Name = "Print to Console",
    CurrentValue = true,
    Flag = "PrintConsole",
    Callback = function(value)
        RemoteSpy.Settings.PrintToConsole = value
    end,
})

MiscTab:CreateSection("Utilities")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Copy Game ID",
    Callback = function()
        if setclipboard then
            setclipboard(tostring(game.PlaceId))
            Utilities.Notify("Copied", "Game ID: " .. game.PlaceId, 3)
        end
    end,
})

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Hub Settings")

SettingsTab:CreateButton({
    Name = "Unload Hub",
    Callback = function()
        Hub:Unload()
        Rayfield:Destroy()
    end,
})

SettingsTab:CreateLabel("MyHub v1.0.0")
SettingsTab:CreateLabel("Executor: " .. State.ExecutorInfo.Executor)

-- =====================================
-- INITIALIZATION COMPLETE
-- =====================================

State.Initialized = true
Utilities.Notify("MyHub", "Loaded successfully!", 3)

return Hub
