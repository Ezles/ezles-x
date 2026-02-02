--[[
    Main UI Module
    Integrates with Rayfield UI Library for the hub interface
    Documentation: https://docs.sirius.menu/rayfield
]]

local UI = {}

local Hub, Utilities, Services
local Rayfield

-- Load Rayfield UI Library
local function loadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
    end)

    if success then
        return result
    else
        warn("[MyHub UI] Failed to load Rayfield: " .. tostring(result))
        return nil
    end
end

-- Create the main window and tabs
function UI.Create(modules: {ESP: any, Aimbot: any, RemoteSpy: any, Movement: any})
    Rayfield = loadRayfield()

    if not Rayfield then
        Utilities.Notify("MyHub", "Failed to load UI library", 5)
        return nil
    end

    -- Main Window
    local Window = Rayfield:CreateWindow({
        Name = "MyHub",
        LoadingTitle = "MyHub",
        LoadingSubtitle = "by YourName",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "MyHub",
            FileName = "Config"
        },
        Discord = {
            Enabled = false,
        },
        KeySystem = false,
    })

    -- =====================================
    -- COMBAT TAB
    -- =====================================
    local CombatTab = Window:CreateTab("Combat", 4483362458)

    -- Aimbot Section
    local AimbotSection = CombatTab:CreateSection("Aimbot")

    CombatTab:CreateToggle({
        Name = "Enable Aimbot",
        CurrentValue = false,
        Flag = "AimbotEnabled",
        Callback = function(value)
            if value then
                modules.Aimbot.Enable()
            else
                modules.Aimbot.Disable()
            end
        end,
    })

    CombatTab:CreateSlider({
        Name = "FOV Size",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = 150,
        Flag = "AimbotFOV",
        Callback = function(value)
            modules.Aimbot.Settings.FOV = value
        end,
    })

    CombatTab:CreateToggle({
        Name = "Show FOV Circle",
        CurrentValue = true,
        Flag = "ShowFOV",
        Callback = function(value)
            modules.Aimbot.Settings.ShowFOV = value
        end,
    })

    CombatTab:CreateDropdown({
        Name = "Target Part",
        Options = {"Head", "HumanoidRootPart", "Torso"},
        CurrentOption = {"Head"},
        Flag = "TargetPart",
        Callback = function(options)
            modules.Aimbot.Settings.TargetPart = options[1]
        end,
    })

    CombatTab:CreateSlider({
        Name = "Smoothness",
        Range = {0.01, 1},
        Increment = 0.01,
        CurrentValue = 0.1,
        Flag = "AimbotSmooth",
        Callback = function(value)
            modules.Aimbot.Settings.Smoothness = value
        end,
    })

    CombatTab:CreateToggle({
        Name = "Use Smoothing",
        CurrentValue = true,
        Flag = "UseSmoothing",
        Callback = function(value)
            modules.Aimbot.Settings.UseSmoothing = value
        end,
    })

    CombatTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = false,
        Flag = "AimbotTeamCheck",
        Callback = function(value)
            modules.Aimbot.Settings.TeamCheck = value
        end,
    })

    CombatTab:CreateToggle({
        Name = "Visibility Check",
        CurrentValue = true,
        Flag = "AimbotVisCheck",
        Callback = function(value)
            modules.Aimbot.Settings.VisibilityCheck = value
        end,
    })

    CombatTab:CreateToggle({
        Name = "Use Prediction",
        CurrentValue = false,
        Flag = "UsePrediction",
        Callback = function(value)
            modules.Aimbot.Settings.UsePrediction = value
        end,
    })

    CombatTab:CreateSlider({
        Name = "Prediction Multiplier",
        Range = {0.05, 0.5},
        Increment = 0.005,
        CurrentValue = 0.165,
        Flag = "PredictionMult",
        Callback = function(value)
            modules.Aimbot.Settings.PredictionMultiplier = value
        end,
    })

    -- =====================================
    -- VISUALS TAB
    -- =====================================
    local VisualsTab = Window:CreateTab("Visuals", 4483362458)

    -- ESP Section
    local ESPSection = VisualsTab:CreateSection("Player ESP")

    VisualsTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = false,
        Flag = "ESPEnabled",
        Callback = function(value)
            if value then
                modules.ESP.Enable()
            else
                modules.ESP.Disable()
            end
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Show Boxes",
        CurrentValue = true,
        Flag = "ESPBoxes",
        Callback = function(value)
            modules.ESP.Settings.ShowBoxes = value
        end,
    })

    VisualsTab:CreateDropdown({
        Name = "Box Type",
        Options = {"2D", "Corner"},
        CurrentOption = {"2D"},
        Flag = "BoxType",
        Callback = function(options)
            modules.ESP.Settings.BoxType = options[1]
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = true,
        Flag = "ESPNames",
        Callback = function(value)
            modules.ESP.Settings.ShowNames = value
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Show Health",
        CurrentValue = true,
        Flag = "ESPHealth",
        Callback = function(value)
            modules.ESP.Settings.ShowHealth = value
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = true,
        Flag = "ESPDistance",
        Callback = function(value)
            modules.ESP.Settings.ShowDistance = value
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Show Tracers",
        CurrentValue = false,
        Flag = "ESPTracers",
        Callback = function(value)
            modules.ESP.Settings.ShowTracers = value
        end,
    })

    VisualsTab:CreateDropdown({
        Name = "Tracer Origin",
        Options = {"Bottom", "Center", "Mouse"},
        CurrentOption = {"Bottom"},
        Flag = "TracerOrigin",
        Callback = function(options)
            modules.ESP.Settings.TracerOrigin = options[1]
        end,
    })

    VisualsTab:CreateSlider({
        Name = "Max Distance",
        Range = {100, 2000},
        Increment = 50,
        CurrentValue = 1000,
        Flag = "ESPMaxDist",
        Callback = function(value)
            modules.ESP.Settings.MaxDistance = value
        end,
    })

    VisualsTab:CreateToggle({
        Name = "Team Check",
        CurrentValue = false,
        Flag = "ESPTeamCheck",
        Callback = function(value)
            modules.ESP.Settings.TeamCheck = value
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Enemy Color",
        Color = Color3.fromRGB(255, 0, 0),
        Flag = "ESPEnemyColor",
        Callback = function(color)
            modules.ESP.Settings.Colors.Enemy = color
        end,
    })

    VisualsTab:CreateColorPicker({
        Name = "Team Color",
        Color = Color3.fromRGB(0, 255, 0),
        Flag = "ESPTeamColor",
        Callback = function(color)
            modules.ESP.Settings.Colors.Team = color
        end,
    })

    -- =====================================
    -- MOVEMENT TAB
    -- =====================================
    local MovementTab = Window:CreateTab("Movement", 4483362458)

    -- Fly Section
    local FlySection = MovementTab:CreateSection("Fly")

    MovementTab:CreateToggle({
        Name = "Enable Fly",
        CurrentValue = false,
        Flag = "FlyEnabled",
        Callback = function(value)
            if value then
                modules.Movement.EnableFly()
            else
                modules.Movement.DisableFly()
            end
        end,
    })

    MovementTab:CreateSlider({
        Name = "Fly Speed",
        Range = {10, 200},
        Increment = 5,
        CurrentValue = 50,
        Flag = "FlySpeed",
        Callback = function(value)
            modules.Movement.SetFlySpeed(value)
        end,
    })

    -- Noclip Section
    local NoclipSection = MovementTab:CreateSection("Noclip")

    MovementTab:CreateToggle({
        Name = "Enable Noclip",
        CurrentValue = false,
        Flag = "NoclipEnabled",
        Callback = function(value)
            if value then
                modules.Movement.EnableNoclip()
            else
                modules.Movement.DisableNoclip()
            end
        end,
    })

    -- Speed Section
    local SpeedSection = MovementTab:CreateSection("Speed")

    MovementTab:CreateToggle({
        Name = "Enable Speed",
        CurrentValue = false,
        Flag = "SpeedEnabled",
        Callback = function(value)
            if value then
                modules.Movement.EnableSpeed()
            else
                modules.Movement.DisableSpeed()
            end
        end,
    })

    MovementTab:CreateSlider({
        Name = "Walk Speed",
        Range = {16, 200},
        Increment = 1,
        CurrentValue = 16,
        Flag = "WalkSpeed",
        Callback = function(value)
            modules.Movement.SetSpeed(value)
        end,
    })

    -- Jump Section
    local JumpSection = MovementTab:CreateSection("Jump")

    MovementTab:CreateToggle({
        Name = "Enable Jump Power",
        CurrentValue = false,
        Flag = "JumpPowerEnabled",
        Callback = function(value)
            if value then
                modules.Movement.EnableJumpPower()
            else
                modules.Movement.DisableJumpPower()
            end
        end,
    })

    MovementTab:CreateSlider({
        Name = "Jump Power",
        Range = {50, 300},
        Increment = 5,
        CurrentValue = 50,
        Flag = "JumpPower",
        Callback = function(value)
            modules.Movement.SetJumpPower(value)
        end,
    })

    MovementTab:CreateToggle({
        Name = "Infinite Jump",
        CurrentValue = false,
        Flag = "InfiniteJump",
        Callback = function(value)
            if value then
                modules.Movement.EnableInfiniteJump()
            else
                modules.Movement.DisableInfiniteJump()
            end
        end,
    })

    -- =====================================
    -- MISC TAB
    -- =====================================
    local MiscTab = Window:CreateTab("Misc", 4483362458)

    -- Remote Spy Section
    local RemoteSection = MiscTab:CreateSection("Remote Spy")

    MiscTab:CreateToggle({
        Name = "Enable Remote Spy",
        CurrentValue = false,
        Flag = "RemoteSpyEnabled",
        Callback = function(value)
            if value then
                modules.RemoteSpy.Enable()
            else
                modules.RemoteSpy.Disable()
            end
        end,
    })

    MiscTab:CreateToggle({
        Name = "Log Events",
        CurrentValue = true,
        Flag = "LogEvents",
        Callback = function(value)
            modules.RemoteSpy.Settings.LogEvents = value
        end,
    })

    MiscTab:CreateToggle({
        Name = "Log Functions",
        CurrentValue = true,
        Flag = "LogFunctions",
        Callback = function(value)
            modules.RemoteSpy.Settings.LogFunctions = value
        end,
    })

    MiscTab:CreateToggle({
        Name = "Print to Console",
        CurrentValue = true,
        Flag = "PrintConsole",
        Callback = function(value)
            modules.RemoteSpy.Settings.PrintToConsole = value
        end,
    })

    MiscTab:CreateButton({
        Name = "Clear Logs",
        Callback = function()
            modules.RemoteSpy.ClearLogs()
        end,
    })

    MiscTab:CreateButton({
        Name = "Export Logs to File",
        Callback = function()
            if writefile then
                local logs = modules.RemoteSpy.ExportLogs()
                writefile("MyHub_RemoteLogs.txt", logs)
                Utilities.Notify("Remote Spy", "Logs exported to file", 3)
            else
                Utilities.Notify("Remote Spy", "writefile not available", 3)
            end
        end,
    })

    -- Utility Section
    local UtilitySection = MiscTab:CreateSection("Utilities")

    MiscTab:CreateButton({
        Name = "Rejoin Server",
        Callback = function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, Hub.LocalPlayer)
        end,
    })

    MiscTab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            local servers = game:GetService("HttpService"):JSONDecode(
                game:HttpGet(
                    string.format(
                        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                        game.PlaceId
                    )
                )
            )

            for _, server in servers.data do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(
                        game.PlaceId,
                        server.id,
                        Hub.LocalPlayer
                    )
                    break
                end
            end
        end,
    })

    MiscTab:CreateButton({
        Name = "Copy Game ID",
        Callback = function()
            setclipboard(tostring(game.PlaceId))
            Utilities.Notify("Copied", "Game ID: " .. game.PlaceId, 3)
        end,
    })

    -- =====================================
    -- SETTINGS TAB
    -- =====================================
    local SettingsTab = Window:CreateTab("Settings", 4483362458)

    SettingsTab:CreateSection("Hub Settings")

    SettingsTab:CreateKeybind({
        Name = "Toggle UI Key",
        CurrentKeybind = "RightControl",
        Flag = "UIToggleKey",
        Callback = function()
            -- Rayfield handles this internally
        end,
    })

    SettingsTab:CreateButton({
        Name = "Unload Hub",
        Callback = function()
            Hub:Unload()
            Rayfield:Destroy()
        end,
    })

    SettingsTab:CreateLabel("MyHub v1.0.0")
    SettingsTab:CreateLabel("Executor: " .. (Hub.State.ExecutorInfo and Hub.State.ExecutorInfo.Executor or "Unknown"))

    return Window
end

function UI.Init(hub, utilities, services)
    Hub = hub
    Utilities = utilities
    Services = services
end

return UI
