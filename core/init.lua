--[[
    MyHub Core Module
    Central hub that coordinates all modules and UI
]]

local MyHub = {}
MyHub.__index = MyHub

-- Services (cached for performance)
local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
}

-- Local Player Reference
local LocalPlayer = Services.Players.LocalPlayer

-- Hub State
local State = {
    Initialized = false,
    ExecutorInfo = nil,
    Modules = {},
    Connections = {},
    Loops = {},
    Settings = {},
}

-- Utility Functions
local Utilities = {}

function Utilities.SafeCall(func: () -> any, ...: any): (boolean, any)
    return pcall(func, ...)
end

function Utilities.WaitForChild(parent: Instance, name: string, timeout: number?): Instance?
    local child = parent:FindFirstChild(name)
    if child then return child end

    local elapsed = 0
    local maxTime = timeout or 5

    while elapsed < maxTime do
        child = parent:FindFirstChild(name)
        if child then return child end
        elapsed += task.wait(0.1)
    end

    return nil
end

function Utilities.GetCharacter(): Model?
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

function Utilities.GetHumanoid(): Humanoid?
    local character = Utilities.GetCharacter()
    return character and character:FindFirstChildOfClass("Humanoid")
end

function Utilities.GetRootPart(): BasePart?
    local character = Utilities.GetCharacter()
    return character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
end

function Utilities.IsAlive(): boolean
    local humanoid = Utilities.GetHumanoid()
    return humanoid ~= nil and humanoid.Health > 0
end

function Utilities.GetPlayers(excludeSelf: boolean?): {Player}
    local players = {}
    for _, player in Services.Players:GetPlayers() do
        if not excludeSelf or player ~= LocalPlayer then
            table.insert(players, player)
        end
    end
    return players
end

function Utilities.GetDistance(part1: BasePart, part2: BasePart): number
    return (part1.Position - part2.Position).Magnitude
end

function Utilities.WorldToScreen(position: Vector3): (Vector2, boolean)
    local camera = workspace.CurrentCamera
    local screenPoint, onScreen = camera:WorldToScreenPoint(position)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

function Utilities.Notify(title: string, text: string, duration: number?)
    Services.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

function Utilities.RandomString(length: number): string
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length do
        local idx = math.random(1, #chars)
        result ..= chars:sub(idx, idx)
    end
    return result
end

-- Connection Management
function MyHub:AddConnection(connection: RBXScriptConnection, name: string?)
    local key = name or Utilities.RandomString(8)
    State.Connections[key] = connection
    return key
end

function MyHub:RemoveConnection(key: string)
    local conn = State.Connections[key]
    if conn then
        conn:Disconnect()
        State.Connections[key] = nil
    end
end

function MyHub:ClearConnections()
    for key, conn in State.Connections do
        conn:Disconnect()
    end
    State.Connections = {}
end

-- Loop Management (for features that need continuous updates)
function MyHub:StartLoop(name: string, interval: number, callback: () -> ())
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

function MyHub:StopLoop(name: string)
    local loop = State.Loops[name]
    if loop then
        loop.Running = false
        if loop.Thread then
            task.cancel(loop.Thread)
        end
        State.Loops[name] = nil
    end
end

function MyHub:StopAllLoops()
    for name in State.Loops do
        self:StopLoop(name)
    end
end

-- Module System
function MyHub:LoadModule(name: string, moduleData: {})
    State.Modules[name] = moduleData
    if moduleData.Init then
        moduleData.Init(self, Utilities, Services)
    end
    return moduleData
end

function MyHub:GetModule(name: string): {}?
    return State.Modules[name]
end

-- Settings Management
function MyHub:SetSetting(key: string, value: any)
    State.Settings[key] = value
end

function MyHub:GetSetting(key: string, default: any?): any
    local value = State.Settings[key]
    if value == nil then return default end
    return value
end

function MyHub:SaveSettings()
    if writefile then
        local json = Services.HttpService:JSONEncode(State.Settings)
        writefile("MyHub_Settings.json", json)
    end
end

function MyHub:LoadSettings()
    if isfile and readfile and isfile("MyHub_Settings.json") then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile("MyHub_Settings.json"))
        end)
        if success and type(data) == "table" then
            State.Settings = data
        end
    end
end

-- Initialization
function MyHub.Init(envInfo: {Executor: string, Support: {[string]: boolean}, Version: string}?)
    if State.Initialized then
        return MyHub
    end

    State.ExecutorInfo = envInfo or {
        Executor = "Unknown",
        Support = {},
        Version = "1.0.0"
    }

    MyHub:LoadSettings()
    State.Initialized = true

    Utilities.Notify("MyHub", "Successfully loaded!", 3)

    return MyHub
end

-- Cleanup on unload
function MyHub:Unload()
    self:ClearConnections()
    self:StopAllLoops()
    self:SaveSettings()

    for name, module in State.Modules do
        if module.Unload then
            pcall(module.Unload)
        end
    end

    State.Modules = {}
    State.Initialized = false

    Utilities.Notify("MyHub", "Unloaded successfully", 3)
end

-- Export utilities and services for modules
MyHub.Utilities = Utilities
MyHub.Services = Services
MyHub.LocalPlayer = LocalPlayer
MyHub.State = State

return MyHub
