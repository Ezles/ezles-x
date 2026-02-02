--[[
    Movement Module
    Provides fly, noclip, speed, and other movement modifications
]]

local Movement = {
    -- Feature States
    Fly = {
        Enabled = false,
        Speed = 50,
        BodyGyro = nil,
        BodyVelocity = nil,
    },

    Noclip = {
        Enabled = false,
        OriginalCanCollide = {},
    },

    Speed = {
        Enabled = false,
        Value = 16,  -- Default Roblox WalkSpeed
        Original = 16,
    },

    JumpPower = {
        Enabled = false,
        Value = 50,  -- Default Roblox JumpPower
        Original = 50,
    },

    InfiniteJump = {
        Enabled = false,
    },

    Settings = {
        FlyKey = Enum.KeyCode.F,
        NoclipKey = Enum.KeyCode.N,
        SpeedKey = Enum.KeyCode.LeftShift,
    },
}

local Hub, Utilities, Services
local Camera = workspace.CurrentCamera

-- =====================
-- FLY SYSTEM
-- =====================

local function createFlyObjects()
    local character = Utilities.GetCharacter()
    local rootPart = Utilities.GetRootPart()
    local humanoid = Utilities.GetHumanoid()

    if not character or not rootPart or not humanoid then return false end

    -- Create BodyGyro for rotation control
    Movement.Fly.BodyGyro = Instance.new("BodyGyro")
    Movement.Fly.BodyGyro.P = 9e4
    Movement.Fly.BodyGyro.D = 500
    Movement.Fly.BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    Movement.Fly.BodyGyro.Parent = rootPart

    -- Create BodyVelocity for movement
    Movement.Fly.BodyVelocity = Instance.new("BodyVelocity")
    Movement.Fly.BodyVelocity.Velocity = Vector3.zero
    Movement.Fly.BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    Movement.Fly.BodyVelocity.Parent = rootPart

    -- Disable gravity effect
    humanoid.PlatformStand = true

    return true
end

local function destroyFlyObjects()
    if Movement.Fly.BodyGyro then
        Movement.Fly.BodyGyro:Destroy()
        Movement.Fly.BodyGyro = nil
    end

    if Movement.Fly.BodyVelocity then
        Movement.Fly.BodyVelocity:Destroy()
        Movement.Fly.BodyVelocity = nil
    end

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid.PlatformStand = false
    end
end

local function flyLoop()
    if not Movement.Fly.Enabled then return end

    local rootPart = Utilities.GetRootPart()
    if not rootPart or not Movement.Fly.BodyVelocity or not Movement.Fly.BodyGyro then
        return
    end

    Camera = workspace.CurrentCamera

    -- Calculate movement direction based on input
    local moveDirection = Vector3.zero
    local UIS = Services.UserInputService

    if UIS:IsKeyDown(Enum.KeyCode.W) then
        moveDirection += Camera.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.S) then
        moveDirection -= Camera.CFrame.LookVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.A) then
        moveDirection -= Camera.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.D) then
        moveDirection += Camera.CFrame.RightVector
    end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        moveDirection += Vector3.new(0, 1, 0)
    end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveDirection -= Vector3.new(0, 1, 0)
    end

    -- Normalize and apply speed
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit * Movement.Fly.Speed
    end

    Movement.Fly.BodyVelocity.Velocity = moveDirection
    Movement.Fly.BodyGyro.CFrame = Camera.CFrame
end

function Movement.EnableFly()
    if Movement.Fly.Enabled then return end

    if createFlyObjects() then
        Movement.Fly.Enabled = true
        Hub:StartLoop("Movement_Fly", 0, flyLoop)
        Utilities.Notify("Fly", "Enabled (Speed: " .. Movement.Fly.Speed .. ")", 2)
    else
        Utilities.Notify("Fly", "Failed to enable - no character", 2)
    end
end

function Movement.DisableFly()
    if not Movement.Fly.Enabled then return end

    Movement.Fly.Enabled = false
    Hub:StopLoop("Movement_Fly")
    destroyFlyObjects()
    Utilities.Notify("Fly", "Disabled", 2)
end

function Movement.ToggleFly()
    if Movement.Fly.Enabled then
        Movement.DisableFly()
    else
        Movement.EnableFly()
    end
end

function Movement.SetFlySpeed(speed: number)
    Movement.Fly.Speed = speed
end

-- =====================
-- NOCLIP SYSTEM
-- =====================

local function noclipLoop()
    if not Movement.Noclip.Enabled then return end

    local character = Utilities.GetCharacter()
    if not character then return end

    for _, part in character:GetDescendants() do
        if part:IsA("BasePart") then
            -- Store original if not stored
            if Movement.Noclip.OriginalCanCollide[part] == nil then
                Movement.Noclip.OriginalCanCollide[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end

local function restoreCollisions()
    local character = Utilities.GetCharacter()
    if not character then return end

    for part, original in Movement.Noclip.OriginalCanCollide do
        if part and part.Parent then
            part.CanCollide = original
        end
    end

    Movement.Noclip.OriginalCanCollide = {}
end

function Movement.EnableNoclip()
    if Movement.Noclip.Enabled then return end

    Movement.Noclip.Enabled = true
    Hub:StartLoop("Movement_Noclip", 0, noclipLoop)
    Utilities.Notify("Noclip", "Enabled", 2)
end

function Movement.DisableNoclip()
    if not Movement.Noclip.Enabled then return end

    Movement.Noclip.Enabled = false
    Hub:StopLoop("Movement_Noclip")
    restoreCollisions()
    Utilities.Notify("Noclip", "Disabled", 2)
end

function Movement.ToggleNoclip()
    if Movement.Noclip.Enabled then
        Movement.DisableNoclip()
    else
        Movement.EnableNoclip()
    end
end

-- =====================
-- SPEED MODIFICATION
-- =====================

function Movement.EnableSpeed()
    if Movement.Speed.Enabled then return end

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        Movement.Speed.Original = humanoid.WalkSpeed
        Movement.Speed.Enabled = true

        Hub:StartLoop("Movement_Speed", 0.1, function()
            local h = Utilities.GetHumanoid()
            if h then
                h.WalkSpeed = Movement.Speed.Value
            end
        end)

        Utilities.Notify("Speed", "Enabled (Speed: " .. Movement.Speed.Value .. ")", 2)
    end
end

function Movement.DisableSpeed()
    if not Movement.Speed.Enabled then return end

    Movement.Speed.Enabled = false
    Hub:StopLoop("Movement_Speed")

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = Movement.Speed.Original
    end

    Utilities.Notify("Speed", "Disabled", 2)
end

function Movement.ToggleSpeed()
    if Movement.Speed.Enabled then
        Movement.DisableSpeed()
    else
        Movement.EnableSpeed()
    end
end

function Movement.SetSpeed(value: number)
    Movement.Speed.Value = value
    local humanoid = Utilities.GetHumanoid()
    if humanoid and Movement.Speed.Enabled then
        humanoid.WalkSpeed = value
    end
end

-- =====================
-- JUMP POWER MODIFICATION
-- =====================

function Movement.EnableJumpPower()
    if Movement.JumpPower.Enabled then return end

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        Movement.JumpPower.Original = humanoid.JumpPower
        Movement.JumpPower.Enabled = true

        Hub:StartLoop("Movement_JumpPower", 0.1, function()
            local h = Utilities.GetHumanoid()
            if h then
                h.JumpPower = Movement.JumpPower.Value
                h.UseJumpPower = true
            end
        end)

        Utilities.Notify("JumpPower", "Enabled (Power: " .. Movement.JumpPower.Value .. ")", 2)
    end
end

function Movement.DisableJumpPower()
    if not Movement.JumpPower.Enabled then return end

    Movement.JumpPower.Enabled = false
    Hub:StopLoop("Movement_JumpPower")

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid.JumpPower = Movement.JumpPower.Original
    end

    Utilities.Notify("JumpPower", "Disabled", 2)
end

function Movement.ToggleJumpPower()
    if Movement.JumpPower.Enabled then
        Movement.DisableJumpPower()
    else
        Movement.EnableJumpPower()
    end
end

function Movement.SetJumpPower(value: number)
    Movement.JumpPower.Value = value
end

-- =====================
-- INFINITE JUMP
-- =====================

local function onJumpRequest()
    if not Movement.InfiniteJump.Enabled then return end

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

function Movement.EnableInfiniteJump()
    if Movement.InfiniteJump.Enabled then return end

    Movement.InfiniteJump.Enabled = true

    Hub:AddConnection(
        Services.UserInputService.JumpRequest:Connect(onJumpRequest),
        "Movement_InfiniteJump"
    )

    Utilities.Notify("Infinite Jump", "Enabled", 2)
end

function Movement.DisableInfiniteJump()
    if not Movement.InfiniteJump.Enabled then return end

    Movement.InfiniteJump.Enabled = false
    Hub:RemoveConnection("Movement_InfiniteJump")

    Utilities.Notify("Infinite Jump", "Disabled", 2)
end

function Movement.ToggleInfiniteJump()
    if Movement.InfiniteJump.Enabled then
        Movement.DisableInfiniteJump()
    else
        Movement.EnableInfiniteJump()
    end
end

-- =====================
-- INPUT HANDLING
-- =====================

local function onInputBegan(input: InputObject, gameProcessed: boolean)
    if gameProcessed then return end

    if input.KeyCode == Movement.Settings.FlyKey then
        Movement.ToggleFly()
    elseif input.KeyCode == Movement.Settings.NoclipKey then
        Movement.ToggleNoclip()
    end
end

-- =====================
-- MODULE INTERFACE
-- =====================

function Movement.Init(hub, utilities, services)
    Hub = hub
    Utilities = utilities
    Services = services

    Hub:AddConnection(
        Services.UserInputService.InputBegan:Connect(onInputBegan),
        "Movement_Input"
    )

    -- Handle respawn
    Hub:AddConnection(
        Hub.LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)

            -- Re-enable features after respawn
            if Movement.Fly.Enabled then
                Movement.Fly.Enabled = false
                Movement.EnableFly()
            end

            if Movement.Noclip.Enabled then
                Movement.Noclip.OriginalCanCollide = {}
            end
        end),
        "Movement_CharacterAdded"
    )
end

function Movement.Unload()
    Movement.DisableFly()
    Movement.DisableNoclip()
    Movement.DisableSpeed()
    Movement.DisableJumpPower()
    Movement.DisableInfiniteJump()
end

return Movement
