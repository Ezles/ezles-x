--[[
    Ezles-X BSS - Bee Swarm Simulator Script
    A comprehensive automation script for Bee Swarm Simulator

    Features:
    - Auto Farm (Pollen Collection)
    - Auto Convert (Pollen to Honey)
    - Auto Feed (Feed Bees)
    - Auto Quests
    - Field Teleports
    - Auto Collect Tokens/Items
    - Auto Dispenser (Free Items)
    - Mob Killer
    - Anti-AFK

    Usage: loadstring(game:HttpGet("RAW_URL"))()
]]

if getgenv and getgenv().EzlesBSSLoaded then
    warn("[Ezles-X BSS] Already loaded!")
    return
end

if getgenv then
    getgenv().EzlesBSSLoaded = true
end

local Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    TweenService = game:GetService("TweenService"),
    VirtualUser = game:GetService("VirtualUser"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
    StarterGui = game:GetService("StarterGui"),
    TeleportService = game:GetService("TeleportService"),
    CollectionService = game:GetService("CollectionService"),
}

local LocalPlayer = Services.Players.LocalPlayer
local Camera = Services.Workspace.CurrentCamera

local State = {
    Connections = {},
    Loops = {},
    FarmState = {
        Running = false,
        CurrentField = nil,
        FieldZone = nil,
        FlowerPositions = {},
        LastTokenCollect = 0,
        IsConverting = false,
    },
    Settings = {
        AutoFarm = {
            Enabled = false,
            Field = "Sunflower",
            ReturnWhenFull = true,
            ConvertAtHive = true,
            CollectTokens = true,
            AvoidMobs = false,
            FarmMode = "Walk",
            WalkSpeed = 50,
            UseSprinklers = true,
            SprinklerInterval = 30,
            PatternMode = "Random",
        },
        AutoConvert = {
            Enabled = false,
            ConvertPercent = 95,
        },
        AutoFeed = {
            Enabled = false,
            FeedType = "Treats",
            Interval = 60,
        },
        AutoQuest = {
            Enabled = false,
            QuestGiver = "Black Bear",
        },
        AutoDispenser = {
            Enabled = false,
            Dispensers = {
                HoneyDispenser = true,
                TreatDispenser = true,
                RoyalJellyDispenser = true,
                BlueberryDispenser = true,
                StrawberryDispenser = true,
                GlueDispenser = true,
                TicketDispenser = true,
            },
        },
        AutoTokens = {
            Enabled = false,
            CollectRadius = 50,
        },
        MobKiller = {
            Enabled = false,
            TargetMobs = {"Ladybug", "Rhino Beetle", "Spider", "Mantis", "Scorpion", "Werewolf"},
            AutoTarget = true,
        },
        AntiAFK = {
            Enabled = true,
        },
        Movement = {
            FlyEnabled = false,
            FlySpeed = 60,
            NoclipEnabled = false,
            SpeedEnabled = false,
            SpeedValue = 70,
        },
    },
}

local Fields = {
    "Sunflower",
    "Dandelion",
    "Mushroom",
    "Blue Flower",
    "Clover",
    "Spider",
    "Strawberry",
    "Bamboo",
    "Pineapple",
    "Stump",
    "Cactus",
    "Pumpkin",
    "Pine Tree",
    "Rose",
    "Mountain Top",
    "Coconut",
    "Pepper",
}

local QuestGivers = {
    "Black Bear",
    "Brown Bear",
    "Mother Bear",
    "Panda Bear",
    "Science Bear",
    "Polar Bear",
    "Spirit Bear",
    "Onett",
    "Bee Bear",
    "Sun Bear",
    "Gummy Bear",
    "Stick Bug",
    "Bucko Bee",
    "Riley Bee",
}

local Mobs = {
    "Ladybug",
    "Rhino Beetle",
    "Spider",
    "Mantis",
    "Scorpion",
    "Werewolf",
    "Cave Monster",
    "King Beetle",
    "Tunnel Bear",
    "Stump Snail",
    "Coconut Crab",
    "Mondo Chick",
    "Commando Chick",
    "Wild Windy Bee",
    "Rogue Vicious Bee",
}

local Utilities = {}

function Utilities.Notify(title, text, duration)
    pcall(function()
        Services.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
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
    return humanoid and humanoid.Health > 0
end

function Utilities.GetDistance(pos1, pos2)
    if typeof(pos1) == "Instance" then pos1 = pos1.Position end
    if typeof(pos2) == "Instance" then pos2 = pos2.Position end
    return (pos1 - pos2).Magnitude
end

function Utilities.TweenTo(targetCFrame, duration)
    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    duration = duration or 1
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = Services.TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

function Utilities.TeleportTo(position)
    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    if typeof(position) == "Vector3" then
        rootPart.CFrame = CFrame.new(position)
    elseif typeof(position) == "CFrame" then
        rootPart.CFrame = position
    elseif typeof(position) == "Instance" then
        rootPart.CFrame = position.CFrame
    end
end

function Utilities.WalkTo(position)
    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        if typeof(position) == "Instance" then
            position = position.Position
        end
        humanoid:MoveTo(position)
    end
end

local function AddConnection(name, connection)
    if State.Connections[name] then
        State.Connections[name]:Disconnect()
    end
    State.Connections[name] = connection
end

local function RemoveConnection(name)
    if State.Connections[name] then
        State.Connections[name]:Disconnect()
        State.Connections[name] = nil
    end
end

local function StartLoop(name, interval, callback)
    if State.Loops[name] then
        State.Loops[name].Running = false
    end

    State.Loops[name] = {
        Running = true,
        Thread = task.spawn(function()
            while State.Loops[name] and State.Loops[name].Running do
                local success, err = pcall(callback)
                if not success then
                    warn("[Ezles-X BSS] Loop error (" .. name .. "): " .. tostring(err))
                end
                task.wait(interval)
            end
        end)
    }
end

local function StopLoop(name)
    if State.Loops[name] then
        State.Loops[name].Running = false
        State.Loops[name] = nil
    end
end

local BSS = {}

local FieldNames = {
    ["Sunflower"] = "Sunflower Field",
    ["Dandelion"] = "Dandelion Field",
    ["Mushroom"] = "Mushroom Field",
    ["Blue Flower"] = "Blue Flower Field",
    ["Clover"] = "Clover Field",
    ["Spider"] = "Spider Field",
    ["Strawberry"] = "Strawberry Field",
    ["Bamboo"] = "Bamboo Field",
    ["Pineapple"] = "Pineapple Patch",
    ["Stump"] = "Stump Field",
    ["Cactus"] = "Cactus Field",
    ["Pumpkin"] = "Pumpkin Patch",
    ["Pine Tree"] = "Pine Tree Forest",
    ["Rose"] = "Rose Field",
    ["Mountain Top"] = "Mountain Top Field",
    ["Coconut"] = "Coconut Field",
    ["Pepper"] = "Pepper Patch",
}

function BSS.GetFieldZone(fieldName)
    local flowerZones = Services.Workspace:FindFirstChild("FlowerZones")
    if not flowerZones then return nil end

    local zoneName = FieldNames[fieldName] or fieldName .. " Field"
    local zone = flowerZones:FindFirstChild(zoneName)

    if not zone then
        for _, child in pairs(flowerZones:GetChildren()) do
            if child.Name:lower():find(fieldName:lower()) then
                zone = child
                break
            end
        end
    end

    return zone
end

function BSS.GetFieldBounds(fieldZone)
    if not fieldZone or not fieldZone:IsA("BasePart") then return nil end

    local pos = fieldZone.Position
    local size = fieldZone.Size

    return {
        MinX = pos.X - (size.X / 2) + 5,
        MaxX = pos.X + (size.X / 2) - 5,
        MinZ = pos.Z - (size.Z / 2) + 5,
        MaxZ = pos.Z + (size.Z / 2) - 5,
        Y = pos.Y + 2,
        Center = pos,
        Size = size,
    }
end

function BSS.GetRandomFieldPosition(fieldName)
    local zone = BSS.GetFieldZone(fieldName)
    if not zone then
        return BSS.GetFieldPosition(fieldName)
    end

    local bounds = BSS.GetFieldBounds(zone)
    if not bounds then
        return BSS.GetFieldPosition(fieldName)
    end

    local randomX = math.random() * (bounds.MaxX - bounds.MinX) + bounds.MinX
    local randomZ = math.random() * (bounds.MaxZ - bounds.MinZ) + bounds.MinZ

    return CFrame.new(randomX, bounds.Y, randomZ)
end

function BSS.GetFieldPosition(fieldName)
    local zone = BSS.GetFieldZone(fieldName)
    if zone and zone:IsA("BasePart") then
        return CFrame.new(zone.Position + Vector3.new(0, 2, 0))
    end

    local fieldPositions = {
        ["Sunflower"] = CFrame.new(-177, 4, 76),
        ["Dandelion"] = CFrame.new(-248, 4, 178),
        ["Mushroom"] = CFrame.new(-102, 4, 84),
        ["Blue Flower"] = CFrame.new(-317, 4, 179),
        ["Clover"] = CFrame.new(-214, 4, 214),
        ["Spider"] = CFrame.new(-39, 19, 122),
        ["Strawberry"] = CFrame.new(-71, 19, 186),
        ["Bamboo"] = CFrame.new(-15, 19, 228),
        ["Pineapple"] = CFrame.new(79, 36, 204),
        ["Stump"] = CFrame.new(-23, 36, 100),
        ["Cactus"] = CFrame.new(12, 68, 228),
        ["Pumpkin"] = CFrame.new(-81, 68, 242),
        ["Pine Tree"] = CFrame.new(-58, 68, 148),
        ["Rose"] = CFrame.new(-297, 68, 171),
        ["Mountain Top"] = CFrame.new(-1, 105, 487),
        ["Coconut"] = CFrame.new(251, 48, 427),
        ["Pepper"] = CFrame.new(295, 68, 259),
    }
    return fieldPositions[fieldName]
end

function BSS.GetHivePosition()
    return CFrame.new(-256, 7, -20)
end

function BSS.GetPollenCount()
    local playerStats = Services.ReplicatedStorage:FindFirstChild("PlayerStats")
    if playerStats then
        local myStats = playerStats:FindFirstChild(LocalPlayer.Name)
        if myStats then
            local pollen = myStats:FindFirstChild("Pollen")
            if pollen then
                return pollen.Value
            end
        end
    end

    local gui = LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
    if gui then
        local pollenLabel = gui:FindFirstChild("Pollen", true)
        if pollenLabel and pollenLabel:IsA("TextLabel") then
            local text = pollenLabel.Text:gsub(",", "")
            return tonumber(text) or 0
        end
    end

    return 0
end

function BSS.GetMaxPollen()
    local playerStats = Services.ReplicatedStorage:FindFirstChild("PlayerStats")
    if playerStats then
        local myStats = playerStats:FindFirstChild(LocalPlayer.Name)
        if myStats then
            local maxPollen = myStats:FindFirstChild("MaxPollen")
            if maxPollen then
                return maxPollen.Value
            end
        end
    end
    return 1000000
end

function BSS.IsBackpackFull()
    local pollen = BSS.GetPollenCount()
    local maxPollen = BSS.GetMaxPollen()
    local settings = State.Settings.AutoConvert
    return pollen >= (maxPollen * (settings.ConvertPercent / 100))
end

function BSS.GetFlowers(fieldName)
    local flowers = {}
    local zone = BSS.GetFieldZone(fieldName)
    local bounds = zone and BSS.GetFieldBounds(zone)

    local flowerFolder = Services.Workspace:FindFirstChild("Flowers")
    if flowerFolder then
        for _, flower in pairs(flowerFolder:GetDescendants()) do
            if flower:IsA("BasePart") then
                if bounds then
                    local pos = flower.Position
                    if pos.X >= bounds.MinX and pos.X <= bounds.MaxX and
                       pos.Z >= bounds.MinZ and pos.Z <= bounds.MaxZ then
                        table.insert(flowers, flower.Position)
                    end
                else
                    local fieldPos = BSS.GetFieldPosition(fieldName)
                    if fieldPos and Utilities.GetDistance(flower.Position, fieldPos.Position) < 60 then
                        table.insert(flowers, flower.Position)
                    end
                end
            end
        end
    end

    return flowers
end

function BSS.EquipBestCollector()
    local humanoid = Utilities.GetHumanoid()
    local character = Utilities.GetCharacter()
    if not humanoid or not character then return nil end

    local currentTool = character:FindFirstChildOfClass("Tool")
    if currentTool then return currentTool end

    local backpack = LocalPlayer.Backpack
    local collectors = {}
    local priority = {
        ["Tide Popper"] = 10,
        ["Gummy Baller"] = 9,
        ["Dark Scythe"] = 8,
        ["Petal Wand"] = 7,
        ["Porcelain Dipper"] = 6,
        ["Scythe"] = 5,
        ["Bubble Wand"] = 4,
        ["Pulsar"] = 3,
        ["Vacuum"] = 2,
        ["Collector"] = 1,
        ["Scoop"] = 1,
    }

    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            for name, prio in pairs(priority) do
                if item.Name:find(name) then
                    table.insert(collectors, {tool = item, priority = prio})
                    break
                end
            end
        end
    end

    table.sort(collectors, function(a, b) return a.priority > b.priority end)

    if #collectors > 0 then
        humanoid:EquipTool(collectors[1].tool)
        task.wait(0.3)
        return collectors[1].tool
    end

    return nil
end

function BSS.WalkToPosition(targetPos, timeout)
    local humanoid = Utilities.GetHumanoid()
    local rootPart = Utilities.GetRootPart()
    if not humanoid or not rootPart then return false end

    timeout = timeout or 10
    local startTime = tick()

    if typeof(targetPos) == "CFrame" then
        targetPos = targetPos.Position
    end

    humanoid.AutoRotate = false

    local speed = State.Settings.AutoFarm.WalkSpeed or 50
    if State.Settings.Movement.SpeedEnabled then
        humanoid.WalkSpeed = State.Settings.Movement.SpeedValue
    else
        humanoid.WalkSpeed = math.min(speed, 70)
    end

    humanoid:MoveTo(targetPos)

    local reached = false
    local moveConn
    moveConn = humanoid.MoveToFinished:Connect(function(success)
        reached = success
    end)

    while not reached and (tick() - startTime) < timeout do
        if not State.Settings.AutoFarm.Enabled then
            moveConn:Disconnect()
            humanoid.AutoRotate = true
            return false
        end

        local dist = Utilities.GetDistance(rootPart.Position, targetPos)
        if dist <= 5 then
            reached = true
            break
        end

        humanoid:MoveTo(targetPos)
        task.wait(0.1)
    end

    moveConn:Disconnect()
    humanoid.AutoRotate = true
    return reached
end

function BSS.UseSprinkler()
    local events = Services.ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActives = events:FindFirstChild("PlayerActivesCommand")
        if playerActives then
            pcall(function()
                playerActives:FireServer({["Name"] = "Sprinkler Builder"})
            end)
            return true
        end
    end
    return false
end

function BSS.UseGlider()
    local events = Services.ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActives = events:FindFirstChild("PlayerActivesCommand")
        if playerActives then
            pcall(function()
                playerActives:FireServer({["Name"] = "Glider"})
            end)
            return true
        end
    end
    return false
end

function BSS.CollectPollen(fieldName)
    if State.FarmState.IsConverting then return end

    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    local humanoid = Utilities.GetHumanoid()
    if not humanoid then return end

    local tool = BSS.EquipBestCollector()
    if not tool then
        Utilities.Notify("Auto Farm", "No collector found!", 3)
        return
    end

    local targetPos = BSS.GetRandomFieldPosition(fieldName)
    if not targetPos then return end

    local farmMode = State.Settings.AutoFarm.FarmMode

    if farmMode == "Walk" then
        local distance = Utilities.GetDistance(rootPart.Position, targetPos.Position)

        if distance > 100 then
            rootPart.CFrame = targetPos
            task.wait(0.2)
        else
            BSS.WalkToPosition(targetPos, 5)
        end
    else
        rootPart.CFrame = targetPos
    end

    if tool and tool.Activate then
        tool:Activate()
    end

    if State.Settings.AutoFarm.UseSprinklers then
        local now = tick()
        if not State.FarmState.LastSprinkler or (now - State.FarmState.LastSprinkler) >= State.Settings.AutoFarm.SprinklerInterval then
            BSS.UseSprinkler()
            State.FarmState.LastSprinkler = now
        end
    end

    if State.Settings.AutoFarm.CollectTokens then
        local now = tick()
        if (now - State.FarmState.LastTokenCollect) >= 2 then
            BSS.CollectNearbyTokens()
            State.FarmState.LastTokenCollect = now
        end
    end
end

function BSS.IsTokenValid(token)
    if not token then return false end
    if not token.Parent then return false end

    if token:IsA("Model") then
        local root = token.PrimaryPart or token:FindFirstChild("Root") or token:FindFirstChildWhichIsA("BasePart")
        if not root then return false end
    end

    return true
end

function BSS.CollectNearbyTokens()
    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    local tokenFolder = Services.Workspace:FindFirstChild("Collectibles")
    if not tokenFolder then
        tokenFolder = Services.Workspace:FindFirstChild("Particles")
    end
    if not tokenFolder then return end

    local radius = State.Settings.AutoTokens.CollectRadius
    local farmMode = State.Settings.AutoFarm.FarmMode
    local tokens = {}

    for _, token in pairs(tokenFolder:GetChildren()) do
        if BSS.IsTokenValid(token) then
            local tokenPos
            if token:IsA("Model") then
                local root = token.PrimaryPart or token:FindFirstChildWhichIsA("BasePart")
                tokenPos = root and root.Position
            elseif token:IsA("BasePart") then
                tokenPos = token.Position
            end

            if tokenPos then
                local dist = Utilities.GetDistance(rootPart.Position, tokenPos)
                if dist <= radius then
                    table.insert(tokens, {pos = tokenPos, dist = dist, obj = token})
                end
            end
        end
    end

    table.sort(tokens, function(a, b) return a.dist < b.dist end)

    local collected = 0
    local maxCollect = 5

    for _, tokenData in ipairs(tokens) do
        if collected >= maxCollect then break end
        if not State.Settings.AutoFarm.Enabled then break end

        if BSS.IsTokenValid(tokenData.obj) then
            if farmMode == "Walk" then
                local dist = Utilities.GetDistance(rootPart.Position, tokenData.pos)
                if dist <= 15 then
                    BSS.WalkToPosition(tokenData.pos, 2)
                else
                    rootPart.CFrame = CFrame.new(tokenData.pos)
                    task.wait(0.05)
                end
            else
                rootPart.CFrame = CFrame.new(tokenData.pos)
                task.wait(0.05)
            end
            collected = collected + 1
        end
    end
end

function BSS.ConvertAtHive()
    if State.FarmState.IsConverting then return end
    State.FarmState.IsConverting = true

    local hivePos = BSS.GetHivePosition()
    if not hivePos then
        State.FarmState.IsConverting = false
        return
    end

    local rootPart = Utilities.GetRootPart()
    if not rootPart then
        State.FarmState.IsConverting = false
        return
    end

    Utilities.Notify("Auto Farm", "Converting pollen...", 2)

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        local character = Utilities.GetCharacter()
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    local farmMode = State.Settings.AutoFarm.FarmMode
    local distance = Utilities.GetDistance(rootPart.Position, hivePos.Position)

    if farmMode == "Walk" and distance <= 150 then
        BSS.WalkToPosition(hivePos * CFrame.new(0, 5, 0), 15)
    else
        rootPart.CFrame = hivePos * CFrame.new(0, 5, 0)
    end

    local startTime = tick()
    local timeout = 120

    while BSS.GetPollenCount() > 0 and (tick() - startTime) < timeout do
        if not State.Settings.AutoFarm.Enabled then break end

        rootPart.CFrame = hivePos * CFrame.new(0, 5, 0)

        if humanoid then
            humanoid:MoveTo(rootPart.Position)
        end

        task.wait(0.3)
    end

    Utilities.Notify("Auto Farm", "Conversion complete!", 2)
    State.FarmState.IsConverting = false
end

function BSS.StartAutoFarm()
    State.FarmState.Running = true
    State.FarmState.LastTokenCollect = 0
    State.FarmState.LastSprinkler = 0

    StartLoop("AutoFarm", 0.5, function()
        if not State.Settings.AutoFarm.Enabled then return end
        if not Utilities.IsAlive() then return end
        if State.FarmState.IsConverting then return end

        if State.Settings.AutoFarm.ReturnWhenFull and BSS.IsBackpackFull() then
            if State.Settings.AutoFarm.ConvertAtHive then
                BSS.ConvertAtHive()
            end
        else
            BSS.CollectPollen(State.Settings.AutoFarm.Field)
        end
    end)

    StartLoop("AutoFarmTokens", 3, function()
        if not State.Settings.AutoFarm.Enabled then return end
        if not State.Settings.AutoFarm.CollectTokens then return end
        if State.FarmState.IsConverting then return end

        BSS.CollectNearbyTokens()
    end)
end

function BSS.StopAutoFarm()
    State.FarmState.Running = false
    State.FarmState.IsConverting = false
    StopLoop("AutoFarm")
    StopLoop("AutoFarmTokens")

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
        humanoid.AutoRotate = true
    end
end

function BSS.StartAutoConvert()
    StartLoop("AutoConvert", 1, function()
        if not State.Settings.AutoConvert.Enabled then return end
        if not Utilities.IsAlive() then return end

        if BSS.IsBackpackFull() then
            BSS.ConvertAtHive()
        end
    end)
end

function BSS.StopAutoConvert()
    StopLoop("AutoConvert")
end

function BSS.FeedBees(treatType)
    local feedRemote = Services.ReplicatedStorage:FindFirstChild("Events")
    if feedRemote then
        local feed = feedRemote:FindFirstChild("Feed")
        if feed then
            pcall(function()
                feed:FireServer(treatType or "Treat")
            end)
        end
    end

    local backpack = LocalPlayer.Backpack
    local character = Utilities.GetCharacter()

    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and item.Name:lower():find("treat") then
            local humanoid = Utilities.GetHumanoid()
            if humanoid then
                humanoid:EquipTool(item)
                task.wait(0.2)
                item:Activate()
            end
            break
        end
    end
end

function BSS.StartAutoFeed()
    StartLoop("AutoFeed", State.Settings.AutoFeed.Interval, function()
        if not State.Settings.AutoFeed.Enabled then return end
        BSS.FeedBees(State.Settings.AutoFeed.FeedType)
    end)
end

function BSS.StopAutoFeed()
    StopLoop("AutoFeed")
end

function BSS.GetQuestGiverPosition(questGiver)
    local questPositions = {
        ["Black Bear"] = CFrame.new(-233, 4, 123),
        ["Brown Bear"] = CFrame.new(-227, 36, -2),
        ["Mother Bear"] = CFrame.new(-136, 19, 176),
        ["Panda Bear"] = CFrame.new(-95, 36, 208),
        ["Science Bear"] = CFrame.new(-126, 4, 68),
        ["Polar Bear"] = CFrame.new(255, 68, 355),
        ["Spirit Bear"] = CFrame.new(-165, 120, 378),
        ["Onett"] = CFrame.new(21, 236, 497),
        ["Bucko Bee"] = CFrame.new(-322, 68, 199),
        ["Riley Bee"] = CFrame.new(-85, 68, 262),
    }
    return questPositions[questGiver]
end

function BSS.AcceptQuest(questGiver)
    local questPos = BSS.GetQuestGiverPosition(questGiver)
    if not questPos then return end

    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    rootPart.CFrame = questPos * CFrame.new(0, 0, 5)
    task.wait(0.5)

    local npcs = Services.Workspace:FindFirstChild("NPCs")
    if npcs then
        for _, npc in pairs(npcs:GetDescendants()) do
            if npc.Name == questGiver or (npc:IsA("ProximityPrompt")) then
                if npc:IsA("ProximityPrompt") then
                    if fireproximityprompt then
                        fireproximityprompt(npc)
                    else
                        npc.Triggered:Fire(LocalPlayer)
                    end
                elseif npc:IsA("ClickDetector") then
                    fireclickdetector(npc)
                end
            end
        end
    end

    local promptService = game:GetService("ProximityPromptService")
    local prompts = {}

    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local dist = Utilities.GetDistance(rootPart.Position, obj.Parent.Position or Vector3.new(0,0,0))
            if dist < 20 then
                if fireproximityprompt then
                    fireproximityprompt(obj)
                end
            end
        end
    end
end

function BSS.StartAutoQuest()
    StartLoop("AutoQuest", 5, function()
        if not State.Settings.AutoQuest.Enabled then return end
        if not Utilities.IsAlive() then return end
        BSS.AcceptQuest(State.Settings.AutoQuest.QuestGiver)
    end)
end

function BSS.StopAutoQuest()
    StopLoop("AutoQuest")
end

function BSS.GetDispenserPosition(dispenserName)
    local dispenserPositions = {
        ["HoneyDispenser"] = CFrame.new(-263, 4, 82),
        ["TreatDispenser"] = CFrame.new(-262, 4, 95),
        ["RoyalJellyDispenser"] = CFrame.new(76, 36, 172),
        ["BlueberryDispenser"] = CFrame.new(-290, 68, 212),
        ["StrawberryDispenser"] = CFrame.new(-67, 68, 284),
        ["GlueDispenser"] = CFrame.new(-85, 100, 140),
        ["TicketDispenser"] = CFrame.new(-250, 4, 53),
    }
    return dispenserPositions[dispenserName]
end

function BSS.UseDispenser(dispenserName)
    local dispenserPos = BSS.GetDispenserPosition(dispenserName)
    if not dispenserPos then return end

    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    rootPart.CFrame = dispenserPos * CFrame.new(0, 0, 3)
    task.wait(0.5)

    for _, obj in pairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and Utilities.GetDistance(rootPart.Position, obj.Parent.Position or Vector3.new(0,0,0)) < 15 then
            if fireproximityprompt then
                fireproximityprompt(obj)
            end
        elseif obj:IsA("ClickDetector") and Utilities.GetDistance(rootPart.Position, obj.Parent.Position or Vector3.new(0,0,0)) < 15 then
            if fireclickdetector then
                fireclickdetector(obj)
            end
        end
    end
end

function BSS.StartAutoDispenser()
    StartLoop("AutoDispenser", 300, function()
        if not State.Settings.AutoDispenser.Enabled then return end
        if not Utilities.IsAlive() then return end

        local dispensers = State.Settings.AutoDispenser.Dispensers
        for name, enabled in pairs(dispensers) do
            if enabled then
                BSS.UseDispenser(name)
                task.wait(2)
            end
        end
    end)
end

function BSS.StopAutoDispenser()
    StopLoop("AutoDispenser")
end

function BSS.StartAutoTokens()
    StartLoop("AutoTokens", 0.5, function()
        if not State.Settings.AutoTokens.Enabled then return end
        if not Utilities.IsAlive() then return end
        BSS.CollectNearbyTokens()
    end)
end

function BSS.StopAutoTokens()
    StopLoop("AutoTokens")
end

function BSS.GetNearestMob()
    local rootPart = Utilities.GetRootPart()
    if not rootPart then return nil end

    local nearestMob = nil
    local nearestDist = math.huge

    local mobFolder = Services.Workspace:FindFirstChild("Monsters") or Services.Workspace:FindFirstChild("Mobs")
    if not mobFolder then
        for _, child in pairs(Services.Workspace:GetChildren()) do
            if child:IsA("Model") then
                for _, mobName in pairs(State.Settings.MobKiller.TargetMobs) do
                    if child.Name:find(mobName) then
                        local mobRoot = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
                        if mobRoot then
                            local dist = Utilities.GetDistance(rootPart.Position, mobRoot.Position)
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestMob = child
                            end
                        end
                    end
                end
            end
        end
    else
        for _, mob in pairs(mobFolder:GetDescendants()) do
            if mob:IsA("Model") then
                for _, mobName in pairs(State.Settings.MobKiller.TargetMobs) do
                    if mob.Name:find(mobName) then
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
                        if mobRoot then
                            local dist = Utilities.GetDistance(rootPart.Position, mobRoot.Position)
                            if dist < nearestDist then
                                nearestDist = dist
                                nearestMob = mob
                            end
                        end
                    end
                end
            end
        end
    end

    return nearestMob
end

function BSS.AttackMob(mob)
    if not mob then return end

    local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob.PrimaryPart
    if not mobRoot then return end

    local rootPart = Utilities.GetRootPart()
    if not rootPart then return end

    local humanoid = Utilities.GetHumanoid()
    local character = Utilities.GetCharacter()

    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then
        for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
            if item:IsA("Tool") then
                humanoid:EquipTool(item)
                tool = item
                task.wait(0.2)
                break
            end
        end
    end

    if tool then
        rootPart.CFrame = mobRoot.CFrame * CFrame.new(0, 0, 5)
        tool:Activate()
    end
end

function BSS.StartMobKiller()
    StartLoop("MobKiller", 0.2, function()
        if not State.Settings.MobKiller.Enabled then return end
        if not Utilities.IsAlive() then return end

        local mob = BSS.GetNearestMob()
        if mob then
            BSS.AttackMob(mob)
        end
    end)
end

function BSS.StopMobKiller()
    StopLoop("MobKiller")
end

function BSS.StartAntiAFK()
    AddConnection("AntiAFK", Services.Players.LocalPlayer.Idled:Connect(function()
        Services.VirtualUser:CaptureController()
        Services.VirtualUser:ClickButton2(Vector2.new())
    end))

    StartLoop("AntiAFKLoop", 60, function()
        if not State.Settings.AntiAFK.Enabled then return end
        pcall(function()
            Services.VirtualUser:CaptureController()
            Services.VirtualUser:ClickButton2(Vector2.new())

            local rootPart = Utilities.GetRootPart()
            if rootPart then
                local humanoid = Utilities.GetHumanoid()
                if humanoid then
                    humanoid.Jump = true
                end
            end
        end)
    end)
end

function BSS.StopAntiAFK()
    RemoveConnection("AntiAFK")
    StopLoop("AntiAFKLoop")
end

local FlyVelocity = nil
local FlyGyro = nil
local Flying = false

function BSS.StartFly()
    if Flying then return end

    local rootPart = Utilities.GetRootPart()
    local humanoid = Utilities.GetHumanoid()
    if not rootPart or not humanoid then return end

    Flying = true

    FlyVelocity = Instance.new("BodyVelocity")
    FlyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    FlyVelocity.Velocity = Vector3.new(0, 0, 0)
    FlyVelocity.Parent = rootPart

    FlyGyro = Instance.new("BodyGyro")
    FlyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    FlyGyro.P = 9e4
    FlyGyro.CFrame = rootPart.CFrame
    FlyGyro.Parent = rootPart

    AddConnection("Fly", Services.RunService.RenderStepped:Connect(function()
        if not Flying then return end

        local speed = State.Settings.Movement.FlySpeed
        local moveDirection = Vector3.new()

        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + Camera.CFrame.LookVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - Camera.CFrame.LookVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - Camera.CFrame.RightVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + Camera.CFrame.RightVector
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end

        FlyVelocity.Velocity = moveDirection * speed
        FlyGyro.CFrame = Camera.CFrame
    end))
end

function BSS.StopFly()
    Flying = false
    RemoveConnection("Fly")

    if FlyVelocity then
        FlyVelocity:Destroy()
        FlyVelocity = nil
    end
    if FlyGyro then
        FlyGyro:Destroy()
        FlyGyro = nil
    end
end

function BSS.StartNoclip()
    AddConnection("Noclip", Services.RunService.Stepped:Connect(function()
        if not State.Settings.Movement.NoclipEnabled then return end

        local character = Utilities.GetCharacter()
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end))
end

function BSS.StopNoclip()
    RemoveConnection("Noclip")

    local character = Utilities.GetCharacter()
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

function BSS.StartSpeed()
    AddConnection("Speed", Services.RunService.Heartbeat:Connect(function()
        if not State.Settings.Movement.SpeedEnabled then return end

        local humanoid = Utilities.GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = State.Settings.Movement.SpeedValue
        end
    end))
end

function BSS.StopSpeed()
    RemoveConnection("Speed")

    local humanoid = Utilities.GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
    end
end

function BSS.Unload()
    for name, conn in pairs(State.Connections) do
        conn:Disconnect()
    end
    State.Connections = {}

    for name in pairs(State.Loops) do
        StopLoop(name)
    end

    BSS.StopFly()
    BSS.StopNoclip()
    BSS.StopSpeed()

    if getgenv then
        getgenv().EzlesBSSLoaded = false
    end

    Utilities.Notify("Ezles-X BSS", "Unloaded successfully!", 3)
end

Utilities.Notify("Ezles-X BSS", "Loading UI...", 2)

local Rayfield
local success, err = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("[Ezles-X BSS] Failed to load Rayfield: " .. tostring(err))
    Utilities.Notify("Ezles-X BSS", "Failed to load UI!", 5)
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Ezles-X BSS",
    LoadingTitle = "Ezles-X BSS",
    LoadingSubtitle = "Bee Swarm Simulator",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EzlesBSS",
        FileName = "Config"
    },
    KeySystem = false,
})

local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateSection("Pollen Collection")

FarmTab:CreateToggle({
    Name = "Enable Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmEnabled",
    Callback = function(value)
        State.Settings.AutoFarm.Enabled = value
        if value then
            BSS.StartAutoFarm()
            Utilities.Notify("Auto Farm", "Enabled - Farming " .. State.Settings.AutoFarm.Field, 3)
        else
            BSS.StopAutoFarm()
            Utilities.Notify("Auto Farm", "Disabled", 2)
        end
    end,
})

FarmTab:CreateDropdown({
    Name = "Select Field",
    Options = Fields,
    CurrentOption = {State.Settings.AutoFarm.Field},
    Flag = "FarmField",
    Callback = function(options)
        State.Settings.AutoFarm.Field = options[1]
    end,
})

FarmTab:CreateToggle({
    Name = "Return When Full",
    CurrentValue = true,
    Flag = "ReturnWhenFull",
    Callback = function(value)
        State.Settings.AutoFarm.ReturnWhenFull = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Convert at Hive",
    CurrentValue = true,
    Flag = "ConvertAtHive",
    Callback = function(value)
        State.Settings.AutoFarm.ConvertAtHive = value
    end,
})

FarmTab:CreateToggle({
    Name = "Collect Tokens While Farming",
    CurrentValue = true,
    Flag = "CollectTokensFarm",
    Callback = function(value)
        State.Settings.AutoFarm.CollectTokens = value
    end,
})

FarmTab:CreateSection("Farm Mode")

FarmTab:CreateDropdown({
    Name = "Movement Mode",
    Options = {"Walk", "Teleport"},
    CurrentOption = {"Walk"},
    Flag = "FarmMode",
    Callback = function(options)
        State.Settings.AutoFarm.FarmMode = options[1]
    end,
})

FarmTab:CreateSlider({
    Name = "Walk Speed (for Walk mode)",
    Range = {16, 100},
    Increment = 2,
    CurrentValue = 50,
    Flag = "FarmWalkSpeed",
    Callback = function(value)
        State.Settings.AutoFarm.WalkSpeed = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Use Sprinklers",
    CurrentValue = true,
    Flag = "UseSprinklers",
    Callback = function(value)
        State.Settings.AutoFarm.UseSprinklers = value
    end,
})

FarmTab:CreateSlider({
    Name = "Sprinkler Interval (seconds)",
    Range = {10, 120},
    Increment = 5,
    CurrentValue = 30,
    Flag = "SprinklerInterval",
    Callback = function(value)
        State.Settings.AutoFarm.SprinklerInterval = value
    end,
})

FarmTab:CreateSection("Auto Convert")

FarmTab:CreateToggle({
    Name = "Enable Auto Convert",
    CurrentValue = false,
    Flag = "AutoConvertEnabled",
    Callback = function(value)
        State.Settings.AutoConvert.Enabled = value
        if value then
            BSS.StartAutoConvert()
            Utilities.Notify("Auto Convert", "Enabled", 2)
        else
            BSS.StopAutoConvert()
            Utilities.Notify("Auto Convert", "Disabled", 2)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Convert At % Full",
    Range = {50, 100},
    Increment = 5,
    CurrentValue = 95,
    Flag = "ConvertPercent",
    Callback = function(value)
        State.Settings.AutoConvert.ConvertPercent = value
    end,
})

FarmTab:CreateSection("Auto Tokens")

FarmTab:CreateToggle({
    Name = "Enable Auto Token Collection",
    CurrentValue = false,
    Flag = "AutoTokensEnabled",
    Callback = function(value)
        State.Settings.AutoTokens.Enabled = value
        if value then
            BSS.StartAutoTokens()
            Utilities.Notify("Auto Tokens", "Enabled", 2)
        else
            BSS.StopAutoTokens()
            Utilities.Notify("Auto Tokens", "Disabled", 2)
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Collection Radius",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = 50,
    Flag = "TokenRadius",
    Callback = function(value)
        State.Settings.AutoTokens.CollectRadius = value
    end,
})

local QuestTab = Window:CreateTab("Quests & NPCs", 4483362458)

QuestTab:CreateSection("Auto Quest")

QuestTab:CreateToggle({
    Name = "Enable Auto Quest",
    CurrentValue = false,
    Flag = "AutoQuestEnabled",
    Callback = function(value)
        State.Settings.AutoQuest.Enabled = value
        if value then
            BSS.StartAutoQuest()
            Utilities.Notify("Auto Quest", "Enabled - " .. State.Settings.AutoQuest.QuestGiver, 3)
        else
            BSS.StopAutoQuest()
            Utilities.Notify("Auto Quest", "Disabled", 2)
        end
    end,
})

QuestTab:CreateDropdown({
    Name = "Quest Giver",
    Options = QuestGivers,
    CurrentOption = {State.Settings.AutoQuest.QuestGiver},
    Flag = "QuestGiver",
    Callback = function(options)
        State.Settings.AutoQuest.QuestGiver = options[1]
    end,
})

QuestTab:CreateSection("Auto Feed Bees")

QuestTab:CreateToggle({
    Name = "Enable Auto Feed",
    CurrentValue = false,
    Flag = "AutoFeedEnabled",
    Callback = function(value)
        State.Settings.AutoFeed.Enabled = value
        if value then
            BSS.StartAutoFeed()
            Utilities.Notify("Auto Feed", "Enabled", 2)
        else
            BSS.StopAutoFeed()
            Utilities.Notify("Auto Feed", "Disabled", 2)
        end
    end,
})

QuestTab:CreateDropdown({
    Name = "Feed Type",
    Options = {"Treat", "Strawberry", "Blueberry", "Sunflower Seed", "Pineapple", "Neonberry", "Gingerbread Bear", "Moon Charm", "Bitterberry", "Neonberry", "Tropical Drink"},
    CurrentOption = {"Treat"},
    Flag = "FeedType",
    Callback = function(options)
        State.Settings.AutoFeed.FeedType = options[1]
    end,
})

QuestTab:CreateSlider({
    Name = "Feed Interval (seconds)",
    Range = {10, 300},
    Increment = 10,
    CurrentValue = 60,
    Flag = "FeedInterval",
    Callback = function(value)
        State.Settings.AutoFeed.Interval = value
    end,
})

local DispenserTab = Window:CreateTab("Dispensers", 4483362458)

DispenserTab:CreateSection("Auto Dispenser")

DispenserTab:CreateToggle({
    Name = "Enable Auto Dispenser",
    CurrentValue = false,
    Flag = "AutoDispenserEnabled",
    Callback = function(value)
        State.Settings.AutoDispenser.Enabled = value
        if value then
            BSS.StartAutoDispenser()
            Utilities.Notify("Auto Dispenser", "Enabled - Checking every 5 minutes", 3)
        else
            BSS.StopAutoDispenser()
            Utilities.Notify("Auto Dispenser", "Disabled", 2)
        end
    end,
})

DispenserTab:CreateSection("Select Dispensers")

DispenserTab:CreateToggle({
    Name = "Honey Dispenser",
    CurrentValue = true,
    Flag = "HoneyDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.HoneyDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Treat Dispenser",
    CurrentValue = true,
    Flag = "TreatDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.TreatDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Royal Jelly Dispenser",
    CurrentValue = true,
    Flag = "RoyalJellyDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.RoyalJellyDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Blueberry Dispenser",
    CurrentValue = true,
    Flag = "BlueberryDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.BlueberryDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Strawberry Dispenser",
    CurrentValue = true,
    Flag = "StrawberryDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.StrawberryDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Glue Dispenser",
    CurrentValue = true,
    Flag = "GlueDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.GlueDispenser = value
    end,
})

DispenserTab:CreateToggle({
    Name = "Ticket Dispenser",
    CurrentValue = true,
    Flag = "TicketDispenser",
    Callback = function(value)
        State.Settings.AutoDispenser.Dispensers.TicketDispenser = value
    end,
})

DispenserTab:CreateSection("Manual Use")

DispenserTab:CreateButton({
    Name = "Use All Dispensers Now",
    Callback = function()
        Utilities.Notify("Dispensers", "Using all dispensers...", 3)
        for name, enabled in pairs(State.Settings.AutoDispenser.Dispensers) do
            if enabled then
                BSS.UseDispenser(name)
                task.wait(2)
            end
        end
        Utilities.Notify("Dispensers", "Done!", 2)
    end,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateSection("Mob Killer")

CombatTab:CreateToggle({
    Name = "Enable Mob Killer",
    CurrentValue = false,
    Flag = "MobKillerEnabled",
    Callback = function(value)
        State.Settings.MobKiller.Enabled = value
        if value then
            BSS.StartMobKiller()
            Utilities.Notify("Mob Killer", "Enabled", 2)
        else
            BSS.StopMobKiller()
            Utilities.Notify("Mob Killer", "Disabled", 2)
        end
    end,
})

CombatTab:CreateDropdown({
    Name = "Target Mobs",
    Options = Mobs,
    CurrentOption = State.Settings.MobKiller.TargetMobs,
    MultipleOptions = true,
    Flag = "TargetMobs",
    Callback = function(options)
        State.Settings.MobKiller.TargetMobs = options
    end,
})

CombatTab:CreateSection("Quick Mob Teleports")

local mobTeleports = {
    {"Ladybug", CFrame.new(-188, 4, 126)},
    {"Rhino Beetle", CFrame.new(-270, 4, 245)},
    {"Spider", CFrame.new(-12, 19, 106)},
    {"Mantis", CFrame.new(-23, 36, 115)},
    {"Scorpion", CFrame.new(-83, 68, 222)},
    {"Werewolf", CFrame.new(-80, 68, 144)},
    {"King Beetle", CFrame.new(-190, -3, 180)},
    {"Tunnel Bear", CFrame.new(498, 4, -18)},
    {"Stump Snail", CFrame.new(-68, 36, 88)},
    {"Coconut Crab", CFrame.new(255, 10, 460)},
}

for _, mobData in ipairs(mobTeleports) do
    CombatTab:CreateButton({
        Name = "Teleport to " .. mobData[1],
        Callback = function()
            Utilities.TeleportTo(mobData[2])
            Utilities.Notify("Teleport", "Teleported to " .. mobData[1], 2)
        end,
    })
end

local TeleportTab = Window:CreateTab("Teleports", 4483362458)

TeleportTab:CreateSection("Field Teleports")

for _, field in ipairs(Fields) do
    TeleportTab:CreateButton({
        Name = field .. " Field",
        Callback = function()
            local pos = BSS.GetFieldPosition(field)
            if pos then
                Utilities.TeleportTo(pos)
                Utilities.Notify("Teleport", "Teleported to " .. field, 2)
            end
        end,
    })
end

TeleportTab:CreateSection("Important Locations")

local locations = {
    {"Hive", CFrame.new(-256, 7, -20)},
    {"Red HQ", CFrame.new(-335, 68, 229)},
    {"Blue HQ", CFrame.new(78, 68, 168)},
    {"Ticket Shop", CFrame.new(-264, 4, 54)},
    {"Mountain Top Shop", CFrame.new(14, 104, 450)},
    {"Badge Bearer Guild", CFrame.new(-119, 19, 229)},
    {"Top Shop", CFrame.new(-21, 36, 184)},
    {"Pro Shop", CFrame.new(-240, 68, 113)},
    {"Star Hall", CFrame.new(30, 196, 554)},
    {"Wind Shrine", CFrame.new(-75, 170, 470)},
    {"Ant Challenge", CFrame.new(87, 40, 465)},
    {"Stick Bug", CFrame.new(-117, 68, 117)},
    {"Mondo Chick", CFrame.new(-214, 68, 200)},
}

for _, locData in ipairs(locations) do
    TeleportTab:CreateButton({
        Name = locData[1],
        Callback = function()
            Utilities.TeleportTo(locData[2])
            Utilities.Notify("Teleport", "Teleported to " .. locData[1], 2)
        end,
    })
end

local MovementTab = Window:CreateTab("Movement", 4483362458)

MovementTab:CreateSection("Fly")

MovementTab:CreateToggle({
    Name = "Enable Fly",
    CurrentValue = false,
    Flag = "FlyEnabled",
    Callback = function(value)
        State.Settings.Movement.FlyEnabled = value
        if value then
            BSS.StartFly()
            Utilities.Notify("Fly", "Enabled - Use WASD + Space/Ctrl", 3)
        else
            BSS.StopFly()
            Utilities.Notify("Fly", "Disabled", 2)
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 60,
    Flag = "FlySpeed",
    Callback = function(value)
        State.Settings.Movement.FlySpeed = value
    end,
})

MovementTab:CreateSection("Noclip")

MovementTab:CreateToggle({
    Name = "Enable Noclip",
    CurrentValue = false,
    Flag = "NoclipEnabled",
    Callback = function(value)
        State.Settings.Movement.NoclipEnabled = value
        if value then
            BSS.StartNoclip()
            Utilities.Notify("Noclip", "Enabled", 2)
        else
            BSS.StopNoclip()
            Utilities.Notify("Noclip", "Disabled", 2)
        end
    end,
})

MovementTab:CreateSection("Speed")

MovementTab:CreateToggle({
    Name = "Enable Speed Boost",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(value)
        State.Settings.Movement.SpeedEnabled = value
        if value then
            BSS.StartSpeed()
            Utilities.Notify("Speed", "Enabled - " .. State.Settings.Movement.SpeedValue, 2)
        else
            BSS.StopSpeed()
            Utilities.Notify("Speed", "Disabled", 2)
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 70,
    Flag = "WalkSpeed",
    Callback = function(value)
        State.Settings.Movement.SpeedValue = value
    end,
})

local MiscTab = Window:CreateTab("Misc", 4483362458)

MiscTab:CreateSection("Anti-AFK")

MiscTab:CreateToggle({
    Name = "Enable Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFKEnabled",
    Callback = function(value)
        State.Settings.AntiAFK.Enabled = value
        if value then
            BSS.StartAntiAFK()
            Utilities.Notify("Anti-AFK", "Enabled", 2)
        else
            BSS.StopAntiAFK()
            Utilities.Notify("Anti-AFK", "Disabled", 2)
        end
    end,
})

MiscTab:CreateSection("Utilities")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Utilities.Notify("Rejoin", "Rejoining server...", 2)
        Services.TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Utilities.Notify("Server Hop", "Finding new server...", 2)
        local servers = {}
        local success, data = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        end)

        if success then
            local decoded = game:GetService("HttpService"):JSONDecode(data)
            for _, server in ipairs(decoded.data) do
                if server.playing < server.maxPlaying and server.id ~= game.JobId then
                    table.insert(servers, server.id)
                end
            end

            if #servers > 0 then
                Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)])
            else
                Utilities.Notify("Server Hop", "No servers found!", 3)
            end
        end
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

local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateSection("Script Settings")

SettingsTab:CreateButton({
    Name = "Unload Script",
    Callback = function()
        BSS.Unload()
        Rayfield:Destroy()
    end,
})

SettingsTab:CreateLabel("Ezles-X BSS v2.0.0")
SettingsTab:CreateLabel("Made for Bee Swarm Simulator")
SettingsTab:CreateParagraph({
    Title = "Credits",
    Content = "Ezles-X BSS by Ezles\nUI: Rayfield by Sirius"
})

SettingsTab:CreateParagraph({
    Title = "Keybinds",
    Content = "Fly: Enable in Movement tab\nWASD - Move\nSpace - Up\nCtrl/Shift - Down"
})

if State.Settings.AntiAFK.Enabled then
    BSS.StartAntiAFK()
end

Utilities.Notify("Ezles-X BSS", "Loaded successfully!", 5)

return BSS
