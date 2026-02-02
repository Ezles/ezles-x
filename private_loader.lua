--[[
    EZLES-X PRIVATE LOADER

    SETUP:
    1. Va sur GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
    2. Generate new token (classic) > Coche "repo" > Generate
    3. Remplace TON_TOKEN_ICI par ton token
]]

local TOKEN = "TON_TOKEN_ICI"
local RAW_URL = "https://raw.githubusercontent.com/Ezles/ezles-x/main/main.lua"

local function fetch(url)
    local response = (syn and syn.request or http_request or request)({
        Url = url,
        Method = "GET",
        Headers = {
            ["Authorization"] = "token " .. TOKEN
        }
    })
    return response and response.Body
end

local code = fetch(RAW_URL)
if code then
    loadstring(code)()
else
    warn("[EZLES-X] Failed to load - check your token")
end
