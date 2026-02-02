--[[
    Aimbot Module
    Provides aim assistance with multiple targeting modes
    Supports prediction, smoothing, and silent aim concepts
]]

local Aimbot = {
    Enabled = false,
    Settings = {
        -- Targeting
        TargetPart = "Head",  -- "Head", "HumanoidRootPart", "Torso"
        FOV = 150,
        ShowFOV = true,
        FOVColor = Color3.fromRGB(255, 255, 255),

        -- Behavior
        TeamCheck = false,
        VisibilityCheck = true,
        MaxDistance = 500,

        -- Smoothing (lower = snappier, higher = smoother)
        Smoothness = 0.1,
        UseSmoothing = true,

        -- Prediction
        UsePrediction = false,
        PredictionMultiplier = 0.165,

        -- Input
        AimKey = Enum.UserInputType.MouseButton2,  -- Right click
        ToggleMode = false,  -- Hold vs Toggle

        -- Silent Aim (conceptual - requires hookmetamethod)
        SilentAim = false,
        SilentHitChance = 100,
    },

    -- Runtime State
    Target = nil,
    Aiming = false,
    FOVCircle = nil,
}

local Hub, Utilities, Services
local Camera = workspace.CurrentCamera

-- Initialize FOV circle
local function initFOVCircle()
    if not Drawing then return end

    Aimbot.FOVCircle = Drawing.new("Circle")
    Aimbot.FOVCircle.Thickness = 1
    Aimbot.FOVCircle.NumSides = 64
    Aimbot.FOVCircle.Filled = false
    Aimbot.FOVCircle.Transparency = 0.7
    Aimbot.FOVCircle.Color = Aimbot.Settings.FOVColor
    Aimbot.FOVCircle.Visible = false
end

-- Update FOV circle position
local function updateFOVCircle()
    if not Aimbot.FOVCircle then return end

    local mousePos = Services.UserInputService:GetMouseLocation()
    Aimbot.FOVCircle.Position = mousePos
    Aimbot.FOVCircle.Radius = Aimbot.Settings.FOV
    Aimbot.FOVCircle.Color = Aimbot.Settings.FOVColor
    Aimbot.FOVCircle.Visible = Aimbot.Settings.ShowFOV and Aimbot.Enabled
end

-- Check if player is on same team
local function isTeammate(player: Player): boolean
    local localPlayer = Hub.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return false
    end
    return localPlayer.Team == player.Team
end

-- Check visibility using raycast
local function isVisible(targetPart: BasePart): boolean
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Hub.LocalPlayer.Character, targetPart.Parent}

    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

-- Get target part from character
local function getTargetPart(character: Model): BasePart?
    local partName = Aimbot.Settings.TargetPart

    if partName == "Torso" then
        return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    end

    return character:FindFirstChild(partName)
end

-- Calculate predicted position
local function getPredictedPosition(targetPart: BasePart, rootPart: BasePart?): Vector3
    if not Aimbot.Settings.UsePrediction or not rootPart then
        return targetPart.Position
    end

    local velocity = rootPart.AssemblyLinearVelocity or rootPart.Velocity or Vector3.zero
    local prediction = velocity * Aimbot.Settings.PredictionMultiplier

    return targetPart.Position + prediction
end

-- Check if position is within FOV
local function isInFOV(screenPos: Vector2): boolean
    local mousePos = Services.UserInputService:GetMouseLocation()
    local distance = (screenPos - mousePos).Magnitude
    return distance <= Aimbot.Settings.FOV
end

-- Find best target
local function findTarget(): (Player?, BasePart?)
    local localRoot = Utilities.GetRootPart()
    if not localRoot then return nil, nil end

    local mousePos = Services.UserInputService:GetMouseLocation()
    local closestDistance = math.huge
    local bestTarget = nil
    local bestPart = nil

    for _, player in Services.Players:GetPlayers() do
        if player == Hub.LocalPlayer then continue end

        -- Team check
        if Aimbot.Settings.TeamCheck and isTeammate(player) then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local targetPart = getTargetPart(character)
        if not targetPart then continue end

        -- Distance check
        local worldDistance = Utilities.GetDistance(targetPart, localRoot)
        if worldDistance > Aimbot.Settings.MaxDistance then continue end

        -- Screen position
        local screenPos, onScreen = Camera:WorldToScreenPoint(targetPart.Position)
        if not onScreen then continue end

        local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)

        -- FOV check
        if not isInFOV(screenPos2D) then continue end

        -- Visibility check
        if Aimbot.Settings.VisibilityCheck and not isVisible(targetPart) then continue end

        -- Distance to mouse (for target selection)
        local mouseDistance = (screenPos2D - mousePos).Magnitude

        if mouseDistance < closestDistance then
            closestDistance = mouseDistance
            bestTarget = player
            bestPart = targetPart
        end
    end

    return bestTarget, bestPart
end

-- Aim at target
local function aimAt(targetPart: BasePart)
    local rootPart = targetPart.Parent and targetPart.Parent:FindFirstChild("HumanoidRootPart")
    local targetPos = getPredictedPosition(targetPart, rootPart)

    local screenPos = Camera:WorldToScreenPoint(targetPos)
    local mousePos = Services.UserInputService:GetMouseLocation()

    local deltaX = screenPos.X - mousePos.X
    local deltaY = screenPos.Y - mousePos.Y

    if Aimbot.Settings.UseSmoothing then
        deltaX = deltaX * Aimbot.Settings.Smoothness
        deltaY = deltaY * Aimbot.Settings.Smoothness
    end

    -- Move mouse
    mousemoverel(deltaX, deltaY)
end

-- Main aim loop
local function aimLoop()
    Camera = workspace.CurrentCamera
    updateFOVCircle()

    if not Aimbot.Aiming then
        Aimbot.Target = nil
        return
    end

    if not Utilities.IsAlive() then return end

    -- Find or validate target
    if not Aimbot.Target then
        local target, part = findTarget()
        Aimbot.Target = target
    end

    if Aimbot.Target then
        local character = Aimbot.Target.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        -- Validate target is still valid
        if not character or not humanoid or humanoid.Health <= 0 then
            Aimbot.Target = nil
            return
        end

        local targetPart = getTargetPart(character)
        if targetPart then
            aimAt(targetPart)
        end
    end
end

-- Input handling
local function onInputBegan(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end

    local isAimKey = input.UserInputType == Aimbot.Settings.AimKey or
                     input.KeyCode == Aimbot.Settings.AimKey

    if isAimKey and Aimbot.Enabled then
        if Aimbot.Settings.ToggleMode then
            Aimbot.Aiming = not Aimbot.Aiming
        else
            Aimbot.Aiming = true
        end
    end
end

local function onInputEnded(input: InputObject)
    local isAimKey = input.UserInputType == Aimbot.Settings.AimKey or
                     input.KeyCode == Aimbot.Settings.AimKey

    if isAimKey and not Aimbot.Settings.ToggleMode then
        Aimbot.Aiming = false
        Aimbot.Target = nil
    end
end

-- Silent Aim Hook (conceptual implementation)
local function setupSilentAim()
    if not hookmetamethod or not Aimbot.Settings.SilentAim then return end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        -- Example: Hook FindPartOnRay for hitscan weapons
        if method == "FindPartOnRay" or method == "Raycast" then
            if Aimbot.Target and Aimbot.Target.Character then
                -- Check hit chance
                if math.random(1, 100) <= Aimbot.Settings.SilentHitChance then
                    local targetPart = getTargetPart(Aimbot.Target.Character)
                    if targetPart then
                        -- Modify ray direction to hit target
                        -- Implementation depends on game specifics
                    end
                end
            end
        end

        return oldNamecall(self, ...)
    end))
end

-- Module Interface
function Aimbot.Init(hub, utilities, services)
    Hub = hub
    Utilities = utilities
    Services = services

    initFOVCircle()

    Hub:AddConnection(Services.UserInputService.InputBegan:Connect(onInputBegan), "Aimbot_InputBegan")
    Hub:AddConnection(Services.UserInputService.InputEnded:Connect(onInputEnded), "Aimbot_InputEnded")
end

function Aimbot.Enable()
    Aimbot.Enabled = true
    Hub:StartLoop("Aimbot_Aim", 0, aimLoop)

    if Aimbot.Settings.SilentAim then
        setupSilentAim()
    end

    Utilities.Notify("Aimbot", "Enabled", 2)
end

function Aimbot.Disable()
    Aimbot.Enabled = false
    Aimbot.Aiming = false
    Aimbot.Target = nil

    Hub:StopLoop("Aimbot_Aim")

    if Aimbot.FOVCircle then
        Aimbot.FOVCircle.Visible = false
    end

    Utilities.Notify("Aimbot", "Disabled", 2)
end

function Aimbot.Toggle()
    if Aimbot.Enabled then
        Aimbot.Disable()
    else
        Aimbot.Enable()
    end
end

function Aimbot.Unload()
    Aimbot.Disable()
    if Aimbot.FOVCircle then
        Aimbot.FOVCircle:Remove()
        Aimbot.FOVCircle = nil
    end
end

return Aimbot
