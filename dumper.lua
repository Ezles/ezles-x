--[[
    Delta Executor Compatible Dumper
    Version simplifiée pour Delta/Fluxus/etc.

    INSTRUCTIONS:
    1. Exécute ce script EN PREMIER
    2. Puis exécute le script Atlas BSS
    3. Attends 5-10 secondes
    4. Exécute: GetDump()

    Le résultat sera sauvegardé dans un fichier ET copié au clipboard
]]

-- Storage
local Strings = {}
local Functions = {}
local Calls = {}
local LogCount = 0
local MaxLogs = 5000

-- Vérifier les capacités de l'executor
local hasGetConstants = debug and debug.getconstants
local hasGetUpvalues = debug and debug.getupvalues
local hasGetGC = getgc ~= nil
local hasWriteFile = writefile ~= nil
local hasClipboard = setclipboard ~= nil

print("=== Delta Dumper ===")
print("getconstants: " .. tostring(hasGetConstants))
print("getupvalues: " .. tostring(hasGetUpvalues))
print("getgc: " .. tostring(hasGetGC))
print("writefile: " .. tostring(hasWriteFile))
print("clipboard: " .. tostring(hasClipboard))
print("")

-- Logger une string
local function logString(str, source)
    if type(str) ~= "string" then return end
    if #str < 3 or #str > 500 then return end
    if Strings[str] then return end

    -- Filtrer le bruit
    if str:match("^[%d%.%-]+$") then return end -- Nombres
    if str:match("^%s*$") then return end -- Espaces

    Strings[str] = source or "unknown"
    LogCount = LogCount + 1
end

-- Extraire les constantes d'une fonction
local function extractFunction(func, name)
    if type(func) ~= "function" then return end
    if Functions[tostring(func)] then return end
    Functions[tostring(func)] = true

    -- Constantes
    if hasGetConstants then
        local ok, consts = pcall(debug.getconstants, func)
        if ok and consts then
            for _, v in pairs(consts) do
                logString(v, "const:" .. (name or "?"))
            end
        end
    end

    -- Upvalues
    if hasGetUpvalues then
        local ok, upvals = pcall(debug.getupvalues, func)
        if ok and upvals then
            for _, v in pairs(upvals) do
                if type(v) == "string" then
                    logString(v, "upval:" .. (name or "?"))
                elseif type(v) == "function" then
                    extractFunction(v, name .. "_up")
                end
            end
        end
    end
end

-- Hook les fonctions globales
local oldLoadstring = loadstring
getgenv().loadstring = function(code, ...)
    -- Logger le code passé à loadstring
    if type(code) == "string" and #code < 10000 then
        logString(code:sub(1, 500), "loadstring")
    end
    return oldLoadstring(code, ...)
end

-- Hook require si disponible
if require then
    local oldRequire = require
    getgenv().require = function(module, ...)
        logString(tostring(module), "require")
        return oldRequire(module, ...)
    end
end

-- Scanner le GC
local function scanGC()
    if not hasGetGC then return end

    print("[Dumper] Scanning GC...")
    local gc = getgc(true)
    local count = 0

    for _, obj in ipairs(gc) do
        if LogCount > MaxLogs then break end

        if type(obj) == "function" then
            extractFunction(obj, "gc")
            count = count + 1
        elseif type(obj) == "table" then
            for k, v in pairs(obj) do
                if type(k) == "string" then
                    logString(k, "table_key")
                end
                if type(v) == "string" then
                    logString(v, "table_val")
                elseif type(v) == "function" then
                    extractFunction(v, tostring(k))
                end
            end
        elseif type(obj) == "string" then
            logString(obj, "gc_string")
        end
    end

    print("[Dumper] Scanned " .. count .. " functions")
end

-- Scanner l'environnement
local function scanEnv()
    print("[Dumper] Scanning environment...")

    local envs = {_G, shared}
    if getgenv then table.insert(envs, getgenv()) end
    if getrenv then table.insert(envs, getrenv()) end

    for _, env in ipairs(envs) do
        if type(env) == "table" then
            for k, v in pairs(env) do
                if LogCount > MaxLogs then break end

                if type(k) == "string" then
                    logString(k, "env_key")
                end
                if type(v) == "function" then
                    extractFunction(v, tostring(k))
                elseif type(v) == "string" then
                    logString(v, "env_val")
                elseif type(v) == "table" then
                    for k2, v2 in pairs(v) do
                        if type(v2) == "function" then
                            extractFunction(v2, tostring(k) .. "." .. tostring(k2))
                        elseif type(v2) == "string" then
                            logString(v2, tostring(k))
                        end
                    end
                end
            end
        end
    end
end

-- Formatter le résultat
local function formatResult()
    local lines = {
        "-- ================================",
        "-- ATLAS BSS DUMP",
        "-- Strings: " .. LogCount,
        "-- ================================",
        ""
    }

    -- Grouper par source
    local bySource = {}
    for str, source in pairs(Strings) do
        bySource[source] = bySource[source] or {}
        table.insert(bySource[source], str)
    end

    -- Trier et afficher
    for source, strs in pairs(bySource) do
        table.insert(lines, "-- [" .. source .. "]")
        table.sort(strs, function(a, b) return #a > #b end)
        for i, str in ipairs(strs) do
            if i <= 100 then -- Limiter par source
                -- Escape les caractères spéciaux
                local safe = str:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub('"', '\\"')
                table.insert(lines, '"' .. safe .. '"')
            end
        end
        table.insert(lines, "")
    end

    return table.concat(lines, "\n")
end

-- Fonction principale pour récupérer le dump
getgenv().GetDump = function()
    print("[Dumper] Generating dump...")

    -- Scanner
    scanEnv()
    scanGC()

    -- Formatter
    local result = formatResult()

    -- Sauvegarder
    if hasWriteFile then
        local ok, err = pcall(writefile, "atlas_dump.txt", result)
        if ok then
            print("[Dumper] Saved to atlas_dump.txt")
        else
            warn("[Dumper] writefile failed: " .. tostring(err))
        end
    end

    -- Clipboard
    if hasClipboard then
        local ok = pcall(setclipboard, result)
        if ok then
            print("[Dumper] Copied to clipboard!")
        end
    end

    print("[Dumper] Total strings: " .. LogCount)
    return result
end

-- Alias
getgenv().ExportDump = getgenv().GetDump

-- Auto-scan après un délai
task.spawn(function()
    task.wait(10) -- Attendre que Atlas charge
    print("[Dumper] Auto-scanning...")
    scanEnv()
    scanGC()
    print("[Dumper] Ready! Call GetDump() to export")
end)

print("")
print("[Dumper] Loaded! Now execute the Atlas script.")
print("[Dumper] Then call GetDump() after a few seconds.")
print("")
