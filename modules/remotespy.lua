--[[
    Remote Spy Module
    Intercepts and logs RemoteEvent/RemoteFunction traffic
    Useful for understanding game mechanics and network communication
]]

local RemoteSpy = {
    Enabled = false,
    Settings = {
        LogEvents = true,
        LogFunctions = true,
        LogBindables = false,

        ShowReturnValues = true,
        MaxLogEntries = 500,

        -- Filtering
        IgnoredRemotes = {},  -- Names to ignore
        OnlyRemotes = {},     -- Only log these (empty = log all)

        -- Output
        PrintToConsole = true,
        SaveToFile = false,
        FilePath = "RemoteSpy_Log.txt",
    },

    -- Runtime State
    Logs = {},
    Hooks = {},
    OriginalFunctions = {},
}

local Hub, Utilities, Services
local HttpService = game:GetService("HttpService")

-- Format arguments for display
local function formatValue(value: any, depth: number?): string
    depth = depth or 0
    if depth > 3 then return "..." end

    local valueType = typeof(value)

    if valueType == "string" then
        return string.format('"%s"', value:sub(1, 100))
    elseif valueType == "number" or valueType == "boolean" then
        return tostring(value)
    elseif valueType == "nil" then
        return "nil"
    elseif valueType == "Instance" then
        return string.format("Instance<%s>(%s)", value.ClassName, value:GetFullName())
    elseif valueType == "Vector3" then
        return string.format("Vector3(%.2f, %.2f, %.2f)", value.X, value.Y, value.Z)
    elseif valueType == "CFrame" then
        local pos = value.Position
        return string.format("CFrame(%.2f, %.2f, %.2f)", pos.X, pos.Y, pos.Z)
    elseif valueType == "Color3" then
        return string.format("Color3(%.2f, %.2f, %.2f)", value.R, value.G, value.B)
    elseif valueType == "table" then
        local entries = {}
        local count = 0
        for k, v in value do
            if count >= 5 then
                table.insert(entries, "...")
                break
            end
            local keyStr = type(k) == "string" and k or string.format("[%s]", tostring(k))
            table.insert(entries, string.format("%s = %s", keyStr, formatValue(v, depth + 1)))
            count += 1
        end
        return "{" .. table.concat(entries, ", ") .. "}"
    elseif valueType == "function" then
        return "function()"
    else
        return string.format("%s<%s>", valueType, tostring(value))
    end
end

-- Format arguments array
local function formatArgs(args: {any}): string
    local formatted = {}
    for i, arg in args do
        table.insert(formatted, formatValue(arg))
    end
    return table.concat(formatted, ", ")
end

-- Check if remote should be logged
local function shouldLog(remoteName: string): boolean
    -- Check ignore list
    for _, ignored in RemoteSpy.Settings.IgnoredRemotes do
        if remoteName:lower():find(ignored:lower()) then
            return false
        end
    end

    -- Check only list
    if #RemoteSpy.Settings.OnlyRemotes > 0 then
        for _, allowed in RemoteSpy.Settings.OnlyRemotes do
            if remoteName:lower():find(allowed:lower()) then
                return true
            end
        end
        return false
    end

    return true
end

-- Add log entry
local function addLog(logType: string, remoteName: string, remotePath: string, args: {any}, returnValue: any?)
    if not shouldLog(remoteName) then return end

    local entry = {
        Type = logType,
        Name = remoteName,
        Path = remotePath,
        Args = args,
        ArgsFormatted = formatArgs(args),
        ReturnValue = returnValue,
        Timestamp = os.time(),
        TimeFormatted = os.date("%H:%M:%S"),
    }

    table.insert(RemoteSpy.Logs, 1, entry)

    -- Trim logs if too many
    while #RemoteSpy.Logs > RemoteSpy.Settings.MaxLogEntries do
        table.remove(RemoteSpy.Logs)
    end

    -- Print to console
    if RemoteSpy.Settings.PrintToConsole then
        local returnStr = ""
        if RemoteSpy.Settings.ShowReturnValues and returnValue ~= nil then
            returnStr = string.format(" -> %s", formatValue(returnValue))
        end

        print(string.format(
            "[RemoteSpy] [%s] %s::%s(%s)%s",
            entry.TimeFormatted,
            logType,
            remoteName,
            entry.ArgsFormatted,
            returnStr
        ))
    end

    -- Save to file
    if RemoteSpy.Settings.SaveToFile and writefile then
        local line = string.format(
            "[%s] %s::%s(%s)\n",
            entry.TimeFormatted,
            logType,
            remoteName,
            entry.ArgsFormatted
        )

        if isfile and isfile(RemoteSpy.Settings.FilePath) then
            appendfile(RemoteSpy.Settings.FilePath, line)
        else
            writefile(RemoteSpy.Settings.FilePath, line)
        end
    end
end

-- Hook RemoteEvent:FireServer
local function hookRemoteEvent(remote: RemoteEvent)
    if RemoteSpy.Hooks[remote] then return end

    local originalFire = remote.FireServer

    RemoteSpy.OriginalFunctions[remote] = originalFire

    local hooked
    hooked = hookfunction(remote.FireServer, newcclosure(function(self, ...)
        local args = {...}

        if RemoteSpy.Enabled and RemoteSpy.Settings.LogEvents then
            addLog("Event", remote.Name, remote:GetFullName(), args)
        end

        return originalFire(self, ...)
    end))

    RemoteSpy.Hooks[remote] = hooked
end

-- Hook RemoteFunction:InvokeServer
local function hookRemoteFunction(remote: RemoteFunction)
    if RemoteSpy.Hooks[remote] then return end

    local originalInvoke = remote.InvokeServer

    RemoteSpy.OriginalFunctions[remote] = originalInvoke

    local hooked
    hooked = hookfunction(remote.InvokeServer, newcclosure(function(self, ...)
        local args = {...}
        local result = originalInvoke(self, ...)

        if RemoteSpy.Enabled and RemoteSpy.Settings.LogFunctions then
            addLog("Function", remote.Name, remote:GetFullName(), args, result)
        end

        return result
    end))

    RemoteSpy.Hooks[remote] = hooked
end

-- Alternative: __namecall hook (more universal)
local function setupNamecallHook()
    if not hookmetamethod then
        warn("[RemoteSpy] hookmetamethod not available, using individual hooks")
        return false
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if RemoteSpy.Enabled then
            if method == "FireServer" and self:IsA("RemoteEvent") then
                if RemoteSpy.Settings.LogEvents then
                    addLog("Event", self.Name, self:GetFullName(), args)
                end
            elseif method == "InvokeServer" and self:IsA("RemoteFunction") then
                if RemoteSpy.Settings.LogFunctions then
                    local result = oldNamecall(self, ...)
                    addLog("Function", self.Name, self:GetFullName(), args, result)
                    return result
                end
            end
        end

        return oldNamecall(self, ...)
    end))

    return true
end

-- Scan and hook existing remotes
local function scanRemotes()
    if not hookfunction then
        warn("[RemoteSpy] hookfunction not available")
        return
    end

    local function scanDescendants(parent: Instance)
        for _, child in parent:GetDescendants() do
            if child:IsA("RemoteEvent") then
                hookRemoteEvent(child)
            elseif child:IsA("RemoteFunction") then
                hookRemoteFunction(child)
            end
        end
    end

    -- Scan ReplicatedStorage
    scanDescendants(game:GetService("ReplicatedStorage"))

    -- Scan Workspace (some games put remotes here)
    scanDescendants(workspace)

    -- Watch for new remotes
    Hub:AddConnection(game.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") then
            hookRemoteEvent(descendant)
        elseif descendant:IsA("RemoteFunction") then
            hookRemoteFunction(descendant)
        end
    end), "RemoteSpy_DescendantAdded")
end

-- Generate code to replay a remote call
function RemoteSpy.GenerateScript(logEntry: {}): string
    local code = string.format(
        '-- Remote: %s\n-- Path: %s\n\nlocal remote = game:GetService("ReplicatedStorage"):FindFirstChild("%s", true)\n',
        logEntry.Name,
        logEntry.Path,
        logEntry.Name
    )

    if logEntry.Type == "Event" then
        code ..= string.format("remote:FireServer(%s)", logEntry.ArgsFormatted)
    else
        code ..= string.format("local result = remote:InvokeServer(%s)", logEntry.ArgsFormatted)
    end

    return code
end

-- Clear logs
function RemoteSpy.ClearLogs()
    RemoteSpy.Logs = {}
    Utilities.Notify("RemoteSpy", "Logs cleared", 2)
end

-- Export logs
function RemoteSpy.ExportLogs(): string
    local lines = {}
    for _, entry in RemoteSpy.Logs do
        table.insert(lines, string.format(
            "[%s] %s::%s(%s)",
            entry.TimeFormatted,
            entry.Type,
            entry.Name,
            entry.ArgsFormatted
        ))
    end
    return table.concat(lines, "\n")
end

-- Module Interface
function RemoteSpy.Init(hub, utilities, services)
    Hub = hub
    Utilities = utilities
    Services = services
end

function RemoteSpy.Enable()
    RemoteSpy.Enabled = true

    -- Try namecall hook first (preferred)
    local usingNamecall = setupNamecallHook()

    -- Fall back to individual hooks
    if not usingNamecall then
        scanRemotes()
    end

    Utilities.Notify("RemoteSpy", "Enabled - Monitoring remotes", 2)
end

function RemoteSpy.Disable()
    RemoteSpy.Enabled = false
    Utilities.Notify("RemoteSpy", "Disabled", 2)
end

function RemoteSpy.Toggle()
    if RemoteSpy.Enabled then
        RemoteSpy.Disable()
    else
        RemoteSpy.Enable()
    end
end

function RemoteSpy.Unload()
    RemoteSpy.Disable()
    RemoteSpy.Logs = {}
    RemoteSpy.Hooks = {}
end

return RemoteSpy
