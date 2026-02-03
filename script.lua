-- Auto Farm Script pour Bee Swarm Simulator
-- Repository: Ezles/ezles-x

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local AutoFarmEnabled = false

local function AutoFarm()
    local ReplantFlowerEvent = ReplicatedStorage:FindFirstChild("ReplantFlowerEvent")

    if not ReplantFlowerEvent then
        warn("ReplantFlowerEvent non trouve - verifiez le nom de l'event")
        return
    end

    print("[AutoFarm] Active!")
    AutoFarmEnabled = true

    while AutoFarmEnabled do
        -- Logique de farming - a adapter selon les events du jeu
        pcall(function()
            ReplantFlowerEvent:FireServer()
        end)

        task.wait(0.5)
    end
end

local function StopAutoFarm()
    AutoFarmEnabled = false
    print("[AutoFarm] Desactive!")
end

-- Demarrage
AutoFarm()
