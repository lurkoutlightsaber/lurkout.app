--[[===============================================================
 Lurkout Loader v1.3
 Syncs Roblox player data with the Lurkout.app Appwrite backend.
===============================================================]]

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")

--// ==================== CONFIGURATION ====================
local CONFIG = {
    BACKEND_URL = "https://lurkout.app"  -- Backend proxy endpoint
}

--// ==================== UTILITY ====================
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 6
        })
    end)
end

--// ==================== SAFE HTTP REQUEST ====================
local function httpRequest(method, url, body)
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = method,
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body and HttpService:JSONEncode(body) or nil
        })
    end)

    if not success then
        warn("HTTP Request error:", response)
        return nil
    end

    if response and response.Success then
        if response.Body and #response.Body > 0 then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if ok then
                return decoded
            else
                warn("Failed to decode JSON:", decoded)
                return {}
            end
        else
            return {}
        end
    else
        local statusCode = response and response.StatusCode or "nil"
        local statusMessage = response and response.StatusMessage or "nil"
        local bodyText = response and response.Body or "nil"
        warn("HTTP Request failed:", statusCode, statusMessage, bodyText)
        return nil
    end
end

--// ==================== LOADER LOGIC ====================
local function generateKey()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local key = ""
    for i = 1, 12 do
        local rand = math.random(1, #charset)
        key = key .. string.sub(charset, rand, rand)
    end
    return key
end

local function createUserDocument(userKey, username)
    local url = string.format("%s/api/appwrite/users", CONFIG.BACKEND_URL)

    local body = {
        user_key = userKey,
        username = username
    }

    local response = httpRequest("POST", url, body)
    if response and response.success then
        print("[Lurkout] User document created successfully!")
        notify("Lurkout", "Paired successfully!")
        return true
    else
        local errorMsg = response and response.error or "Unknown error"
        warn("[Lurkout] Failed to create user document:", errorMsg)
        notify("Lurkout", "Error connecting to backend. Check console for details.")
        return false
    end
end

local function sendPlayerList(userKey)
    local url = string.format("%s/api/appwrite/players", CONFIG.BACKEND_URL)

    local players = {}
    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(players, {
            name = player.Name,
            team = player.Team and player.Team.Name or "None"
        })
    end

    local success, placeName = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId).Name
    end)
    local game_name = success and placeName or "Unknown Place"

    local body = {
        user_key = userKey,
        game_name = game_name,
        players = players,  -- Send as array, backend will handle JSON encoding
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    local response = httpRequest("POST", url, body)
    if response and response.success then
        print("[Lurkout] Player list sent successfully.")
        notify("Lurkout", "Player list uploaded!")
    else
        local errorMsg = response and response.error or "Unknown error"
        warn("[Lurkout] Failed to send player list:", errorMsg)
        notify("Lurkout", "Failed to send player data. Check console for details.")
    end
end

--// ==================== GUI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LurkoutGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Lurkout Loader"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Parent = Frame

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Position = UDim2.new(0, 10, 0, 50)
KeyLabel.Size = UDim2.new(0, 40, 0, 30)
KeyLabel.BackgroundTransparency = 1
KeyLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
KeyLabel.Font = Enum.Font.Gotham
KeyLabel.TextSize = 14
KeyLabel.Text = "Key:"
KeyLabel.Parent = Frame

local KeyBox = Instance.new("TextBox")
KeyBox.Position = UDim2.new(0, 50, 0, 50)
KeyBox.Size = UDim2.new(1, -140, 0, 30)
KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
KeyBox.BorderSizePixel = 0
KeyBox.TextColor3 = Color3.fromRGB(200, 200, 255)
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextSize = 14
KeyBox.TextEditable = false
KeyBox.ClearTextOnFocus = false
KeyBox.Parent = Frame
Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 6)

local CopyButton = Instance.new("TextButton")
CopyButton.Size = UDim2.new(0, 80, 0, 30)
CopyButton.Position = UDim2.new(1, -90, 0, 50)
CopyButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
CopyButton.TextColor3 = Color3.new(1, 1, 1)
CopyButton.Font = Enum.Font.GothamBold
CopyButton.TextSize = 14
CopyButton.Text = "Copy"
CopyButton.Parent = Frame
Instance.new("UICorner", CopyButton).CornerRadius = UDim.new(0, 6)

local PairButton = Instance.new("TextButton")
PairButton.Size = UDim2.new(1, -40, 0, 36)
PairButton.Position = UDim2.new(0, 20, 0, 90)
PairButton.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
PairButton.TextColor3 = Color3.new(1, 1, 1)
PairButton.Font = Enum.Font.GothamBold
PairButton.TextSize = 16
PairButton.Text = "Pair with Dashboard"
PairButton.Parent = Frame
Instance.new("UICorner", PairButton).CornerRadius = UDim.new(0, 8)

local SendButton = Instance.new("TextButton")
SendButton.Size = UDim2.new(1, -40, 0, 36)
SendButton.Position = UDim2.new(0, 20, 0, 135)
SendButton.BackgroundColor3 = Color3.fromRGB(80, 160, 240)
SendButton.TextColor3 = Color3.new(1, 1, 1)
SendButton.Font = Enum.Font.GothamBold
SendButton.TextSize = 16
SendButton.Text = "Send Player List"
SendButton.Parent = Frame
Instance.new("UICorner", SendButton).CornerRadius = UDim.new(0, 8)

--// ==================== MAIN FLOW ====================
local userKey = generateKey()
KeyBox.Text = userKey

CopyButton.MouseButton1Click:Connect(function()
    KeyBox:CaptureFocus()
    KeyBox.SelectionStart = 1
    KeyBox.CursorPosition = #userKey + 1
    notify("Lurkout", "Key selected! Press Ctrl+C to copy.")
end)

PairButton.MouseButton1Click:Connect(function()
    print("[Lurkout] Pairing user with key:", userKey)
    createUserDocument(userKey, Players.LocalPlayer.Name)
end)

SendButton.MouseButton1Click:Connect(function()
    print("[Lurkout] Sending player list...")
    sendPlayerList(userKey)
end)

notify("Lurkout", "Loader ready. Your pairing key is:\n" .. userKey)
print("[Lurkout] Loader initialized successfully!")