--[[
    ESP Module
    Provides visual overlays for players and objects
    Supports both Drawing API and GUI-based rendering
]]

local ESP = {
    Enabled = false,
    Settings = {
        ShowBoxes = true,
        ShowNames = true,
        ShowHealth = true,
        ShowDistance = true,
        ShowTracers = false,
        ShowSkeletons = false,

        TeamCheck = false,
        VisibilityCheck = false,

        BoxType = "2D",  -- "2D", "3D", "Corner"
        TracerOrigin = "Bottom",  -- "Bottom", "Center", "Mouse"

        MaxDistance = 1000,

        Colors = {
            Enemy = Color3.fromRGB(255, 0, 0),
            Team = Color3.fromRGB(0, 255, 0),
            Visible = Color3.fromRGB(255, 255, 0),
        },

        TextSize = 14,
        BoxThickness = 1,
    },

    Objects = {},  -- Stores drawing objects per player
}

local Hub, Utilities, Services
local Camera = workspace.CurrentCamera

-- Drawing Object Creation
local function createDrawing(type: string, properties: {[string]: any}): any
    local drawing = Drawing.new(type)
    for prop, value in properties do
        drawing[prop] = value
    end
    return drawing
end

-- Create ESP objects for a player
local function createESPObjects(player: Player): {}
    local objects = {
        Box = createDrawing("Square", {
            Thickness = ESP.Settings.BoxThickness,
            Filled = false,
            Visible = false,
        }),
        BoxOutline = createDrawing("Square", {
            Thickness = ESP.Settings.BoxThickness + 2,
            Color = Color3.new(0, 0, 0),
            Filled = false,
            Visible = false,
        }),
        Name = createDrawing("Text", {
            Size = ESP.Settings.TextSize,
            Center = true,
            Outline = true,
            Visible = false,
        }),
        Distance = createDrawing("Text", {
            Size = ESP.Settings.TextSize - 2,
            Center = true,
            Outline = true,
            Visible = false,
        }),
        HealthBar = createDrawing("Square", {
            Thickness = 1,
            Filled = true,
            Visible = false,
        }),
        HealthBarOutline = createDrawing("Square", {
            Thickness = 1,
            Color = Color3.new(0, 0, 0),
            Filled = false,
            Visible = false,
        }),
        Tracer = createDrawing("Line", {
            Thickness = 1,
            Visible = false,
        }),
    }

    -- Corner box lines (4 corners x 2 lines each = 8 lines)
    objects.CornerLines = {}
    for i = 1, 8 do
        objects.CornerLines[i] = createDrawing("Line", {
            Thickness = ESP.Settings.BoxThickness,
            Visible = false,
        })
    end

    return objects
end

-- Remove ESP objects for a player
local function removeESPObjects(player: Player)
    local objects = ESP.Objects[player]
    if not objects then return end

    for name, obj in objects do
        if type(obj) == "table" then
            for _, line in obj do
                line:Remove()
            end
        else
            obj:Remove()
        end
    end

    ESP.Objects[player] = nil
end

-- Get bounding box for character
local function getBoundingBox(character: Model): (Vector2?, Vector2?, Vector3?)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil, nil, nil end

    local cframe = rootPart.CFrame
    local size = Vector3.new(4, 5, 0)  -- Approximate player size

    local corners = {
        cframe * CFrame.new(size.X/2, size.Y/2, 0),
        cframe * CFrame.new(-size.X/2, size.Y/2, 0),
        cframe * CFrame.new(size.X/2, -size.Y/2, 0),
        cframe * CFrame.new(-size.X/2, -size.Y/2, 0),
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local allOnScreen = true

    for _, corner in corners do
        local screenPos, onScreen = Camera:WorldToScreenPoint(corner.Position)
        if not onScreen then
            allOnScreen = false
        end
        minX = math.min(minX, screenPos.X)
        minY = math.min(minY, screenPos.Y)
        maxX = math.max(maxX, screenPos.X)
        maxY = math.max(maxY, screenPos.Y)
    end

    if not allOnScreen then
        return nil, nil, nil
    end

    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY), rootPart.Position
end

-- Get tracer origin position
local function getTracerOrigin(): Vector2
    local viewport = Camera.ViewportSize
    local origin = ESP.Settings.TracerOrigin

    if origin == "Bottom" then
        return Vector2.new(viewport.X / 2, viewport.Y)
    elseif origin == "Center" then
        return Vector2.new(viewport.X / 2, viewport.Y / 2)
    elseif origin == "Mouse" then
        local mousePos = Services.UserInputService:GetMouseLocation()
        return Vector2.new(mousePos.X, mousePos.Y)
    end

    return Vector2.new(viewport.X / 2, viewport.Y)
end

-- Check if player is on same team
local function isTeammate(player: Player): boolean
    local localPlayer = Hub.LocalPlayer
    if not localPlayer.Team or not player.Team then
        return false
    end
    return localPlayer.Team == player.Team
end

-- Check visibility (raycast)
local function isVisible(targetPart: BasePart): boolean
    local rootPart = Utilities.GetRootPart()
    if not rootPart then return false end

    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {Hub.LocalPlayer.Character}

    local result = workspace:Raycast(origin, direction, params)

    if result then
        return result.Instance:IsDescendantOf(targetPart.Parent)
    end

    return true
end

-- Update ESP for a single player
local function updatePlayer(player: Player)
    local objects = ESP.Objects[player]
    if not objects then
        objects = createESPObjects(player)
        ESP.Objects[player] = objects
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    -- Hide all if conditions not met
    local function hideAll()
        for name, obj in objects do
            if type(obj) == "table" then
                for _, line in obj do
                    line.Visible = false
                end
            else
                obj.Visible = false
            end
        end
    end

    -- Basic checks
    if not ESP.Enabled or not character or not humanoid or not rootPart then
        hideAll()
        return
    end

    if humanoid.Health <= 0 then
        hideAll()
        return
    end

    -- Distance check
    local localRoot = Utilities.GetRootPart()
    if not localRoot then
        hideAll()
        return
    end

    local distance = Utilities.GetDistance(rootPart, localRoot)
    if distance > ESP.Settings.MaxDistance then
        hideAll()
        return
    end

    -- Team check
    local teammate = isTeammate(player)
    if ESP.Settings.TeamCheck and teammate then
        hideAll()
        return
    end

    -- Get bounding box
    local boxPos, boxSize, worldPos = getBoundingBox(character)
    if not boxPos or not boxSize then
        hideAll()
        return
    end

    -- Determine color
    local visible = ESP.Settings.VisibilityCheck and isVisible(rootPart) or false
    local color
    if visible and ESP.Settings.VisibilityCheck then
        color = ESP.Settings.Colors.Visible
    elseif teammate then
        color = ESP.Settings.Colors.Team
    else
        color = ESP.Settings.Colors.Enemy
    end

    -- Update Box
    if ESP.Settings.ShowBoxes then
        if ESP.Settings.BoxType == "2D" then
            objects.BoxOutline.Size = boxSize
            objects.BoxOutline.Position = boxPos
            objects.BoxOutline.Visible = true

            objects.Box.Size = boxSize
            objects.Box.Position = boxPos
            objects.Box.Color = color
            objects.Box.Visible = true

            for _, line in objects.CornerLines do
                line.Visible = false
            end

        elseif ESP.Settings.BoxType == "Corner" then
            objects.Box.Visible = false
            objects.BoxOutline.Visible = false

            local cornerLength = math.min(boxSize.X, boxSize.Y) / 4
            local corners = {
                {boxPos, Vector2.new(cornerLength, 0), Vector2.new(0, cornerLength)},
                {boxPos + Vector2.new(boxSize.X, 0), Vector2.new(-cornerLength, 0), Vector2.new(0, cornerLength)},
                {boxPos + Vector2.new(0, boxSize.Y), Vector2.new(cornerLength, 0), Vector2.new(0, -cornerLength)},
                {boxPos + boxSize, Vector2.new(-cornerLength, 0), Vector2.new(0, -cornerLength)},
            }

            for i, corner in corners do
                local idx = (i - 1) * 2 + 1
                objects.CornerLines[idx].From = corner[1]
                objects.CornerLines[idx].To = corner[1] + corner[2]
                objects.CornerLines[idx].Color = color
                objects.CornerLines[idx].Visible = true

                objects.CornerLines[idx + 1].From = corner[1]
                objects.CornerLines[idx + 1].To = corner[1] + corner[3]
                objects.CornerLines[idx + 1].Color = color
                objects.CornerLines[idx + 1].Visible = true
            end
        end
    else
        objects.Box.Visible = false
        objects.BoxOutline.Visible = false
        for _, line in objects.CornerLines do
            line.Visible = false
        end
    end

    -- Update Name
    if ESP.Settings.ShowNames then
        objects.Name.Text = player.Name
        objects.Name.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y - ESP.Settings.TextSize - 2)
        objects.Name.Color = color
        objects.Name.Visible = true
    else
        objects.Name.Visible = false
    end

    -- Update Distance
    if ESP.Settings.ShowDistance then
        objects.Distance.Text = string.format("[%dm]", math.floor(distance))
        objects.Distance.Position = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y + 2)
        objects.Distance.Color = color
        objects.Distance.Visible = true
    else
        objects.Distance.Visible = false
    end

    -- Update Health Bar
    if ESP.Settings.ShowHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local barHeight = boxSize.Y
        local barWidth = 3

        objects.HealthBarOutline.Size = Vector2.new(barWidth + 2, barHeight + 2)
        objects.HealthBarOutline.Position = Vector2.new(boxPos.X - barWidth - 4, boxPos.Y - 1)
        objects.HealthBarOutline.Visible = true

        objects.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
        objects.HealthBar.Position = Vector2.new(boxPos.X - barWidth - 3, boxPos.Y + barHeight * (1 - healthPercent))
        objects.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        objects.HealthBar.Visible = true
    else
        objects.HealthBar.Visible = false
        objects.HealthBarOutline.Visible = false
    end

    -- Update Tracer
    if ESP.Settings.ShowTracers then
        local tracerOrigin = getTracerOrigin()
        local tracerEnd = Vector2.new(boxPos.X + boxSize.X / 2, boxPos.Y + boxSize.Y)

        objects.Tracer.From = tracerOrigin
        objects.Tracer.To = tracerEnd
        objects.Tracer.Color = color
        objects.Tracer.Visible = true
    else
        objects.Tracer.Visible = false
    end
end

-- Main render loop
local function renderLoop()
    Camera = workspace.CurrentCamera

    for _, player in Services.Players:GetPlayers() do
        if player ~= Hub.LocalPlayer then
            updatePlayer(player)
        end
    end
end

-- Module Interface
function ESP.Init(hub, utilities, services)
    Hub = hub
    Utilities = utilities
    Services = services

    -- Handle player removal
    Hub:AddConnection(Services.Players.PlayerRemoving:Connect(function(player)
        removeESPObjects(player)
    end), "ESP_PlayerRemoving")
end

function ESP.Enable()
    ESP.Enabled = true
    Hub:StartLoop("ESP_Render", 0, renderLoop)
    Utilities.Notify("ESP", "Enabled", 2)
end

function ESP.Disable()
    ESP.Enabled = false
    Hub:StopLoop("ESP_Render")

    -- Hide all objects
    for player, objects in ESP.Objects do
        for name, obj in objects do
            if type(obj) == "table" then
                for _, line in obj do
                    line.Visible = false
                end
            else
                obj.Visible = false
            end
        end
    end

    Utilities.Notify("ESP", "Disabled", 2)
end

function ESP.Toggle()
    if ESP.Enabled then
        ESP.Disable()
    else
        ESP.Enable()
    end
end

function ESP.Unload()
    ESP.Disable()
    for player in ESP.Objects do
        removeESPObjects(player)
    end
end

return ESP
