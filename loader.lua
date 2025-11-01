--[[===============================================================
Lurkout Loader v3.0 - Glassmorphic Edition
Fully Embedded LURKOUT UI Library with Glassmorphic Styling
Features: Webhook Integration, DeepSeek AI, Advanced Game Scanner, Backdoor Scanner, Workspace Dumper, Script Dumper, Comprehensive Logging
===============================================================]]

--// ==================== EMBEDDED LURKOUT UI LIBRARY ====================
--[[
    ╦  ╦ ╦╦═╗╦╔═╗╦ ╦╔╦╗  ╦ ╦╦  ╦  ╦  ╦╔╗ ╦═╗╔═╗╦═╗╦ ╦
    ║  ║ ║╠╦╝╠╩╗║ ║║ ║ ║   ║ ║║  ║  ║  ║╠╩╗╠╦╝╠═╣╠╦╝╚╦╝
    ╩═╝╚═╝╩╚═╩ ╩╚═╝╚═╝ ╩   ╚═╝╩  ╩═╝╩═╝╩╚═╝╩╚═╩ ╩╩╚═ ╩ 
    
    Version: 3.5 ENHANCED - Glassmorphic Edition
    Theme: Glassmorphic Dark with Red Accents
    Custom Modified for Lurkout Loader
]]--

--// Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

--// ==================== LOGGING SYSTEM ====================
local LogSystem = {
    logs = {},
    maxLogs = 1000,
    
    add = function(self, level, category, message, data)
        local logEntry = {
            timestamp = os.date("!%Y-%m-%d %H:%M:%S UTC"),
            level = level,
            category = category,
            message = message,
            data = data
        }
        table.insert(self.logs, logEntry)
        if #self.logs > self.maxLogs then
            table.remove(self.logs, 1)
        end
        print(string.format("[%s][%s][%s] %s", logEntry.timestamp, level, category, message))
    end,
    
    getRecent = function(self, count)
        count = count or 100
        local start = math.max(1, #self.logs - count + 1)
        local result = {}
        for i = start, #self.logs do
            table.insert(result, self.logs[i])
        end
        return result
    end,
    
    export = function(self)
        return HttpService:JSONEncode(self.logs, true)
    end
}

--// ==================== GLASSMORPHIC STYLING ====================
local function ApplyGlassmorphicEffect(frame, transparency, blur)
    transparency = transparency or 0.15
    blur = blur or false
    
    -- Apply transparency
    frame.BackgroundTransparency = transparency
    
    -- Add gradient overlay for glass effect
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, transparency),
        NumberSequenceKeypoint.new(0.5, transparency + 0.05),
        NumberSequenceKeypoint.new(1, transparency)
    })
    gradient.Rotation = 45
    gradient.Parent = frame
    
    -- Add border glow
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(255, 30, 30)
    border.Transparency = 0.7
    border.Thickness = 1
    border.Parent = frame
    
    return gradient, border
end

local function GenerateRandomString(length)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local result = ""
    for i = 1, length do
        local randomIndex = math.random(1, #chars)
        result = result .. chars:sub(randomIndex, randomIndex)
    end
    return result
end

local LocalPlayer = Players.LocalPlayer

local function GetBestParent()
    local success, result = pcall(function()
        if gethui then
            return gethui()
        elseif syn and syn.protect_gui then
            return CoreGui
        elseif get_hidden_gui then
            return get_hidden_gui()
        else
            return LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    if success then
        return result
    else
        return LocalPlayer:WaitForChild("PlayerGui")
    end
end

local PlayerGui = GetBestParent()

--// ==================== CONFIGURATION ====================
local CONFIG = {
    -- Appwrite Configuration
    APPWRITE_PROJECT_ID = "6904e9f0002a87c6eb1f",
    APPWRITE_DATABASE_ID = "6904eb6900208b50b0e9",
    APPWRITE_USERS_COLLECTION = "users",
    APPWRITE_PLAYERS_COLLECTION = "player_lists",
    APPWRITE_API_KEY = "standard_3b70cbb723e21a8ac2fa83cdb599637b92dfcbd36261b0dd7d4e52a8aa89446a60c45c89017f9681eedb0984bca0b7879ca3c97587522369c92d05a8988a5129033c557a000509e5deb699146e529bdae1cdfd04681e6d147135c6c81da47737f2ab5a50fce96c6b1d3d87cf762236fcd82dd9ef7896a13a06963990c84bd2a6E",
    APPWRITE_ENDPOINT = "https://cloud.appwrite.io/v1",
    -- DeepSeek API Configuration
    DEEPSEEK_API_KEY = "sk-f749040803ac4ee88f14ddffd209e9a7",
    DEEPSEEK_ENDPOINT = "https://api.deepseek.com/v1/chat/completions"
}

--// ==================== GLOBAL STATE ====================
local GlobalState = {
    webhookUrl = "",
    isAuthenticated = false,
    currentUser = nil
}

--// ==================== EXECUTOR HTTP COMPATIBILITY ====================
local executorRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local useExecutorHttp = executorRequest ~= nil

--// ==================== HTTP REQUEST HELPER ====================
local function makeRequest(options)
    local requestFunc = useExecutorHttp and executorRequest or function(opts)
        return HttpService:RequestAsync(opts)
    end
    
    local success, result = pcall(function()
        return requestFunc(options)
    end)

    if not success then
        return nil, tostring(result)
    end
    
    if not result then
        return nil, "Request returned nil"
    end
    
    if useExecutorHttp then
        return result.StatusCode, result.Body
    end
    
    if result.Success then
        return 200, result.Body
    else
        return result.StatusCode or 0, result.Body or ""
    end
end

--// ==================== DISCORD WEBHOOK FUNCTIONS (FIXED FOR EMBED LIMIT) ====================
-- Forward declaration for chunked function
local function sendDiscordWebhookChunked(webhookUrl, data, fileContent) end

local function sendDiscordWebhook(webhookUrl, data, fileContent)
    if not webhookUrl or webhookUrl == "" then
        return false, "Webhook URL not configured"
    end
    
    local MAX_EMBEDS = 10
    local MAX_EMBED_DESCRIPTION = 4000 -- Discord embed description limit
    local MAX_FILE_SIZE = 8000000 -- 8MB file size limit for Discord
    
    -- If fileContent is provided and large, send as chunked messages
    if fileContent and #fileContent > 1800 then
        LogSystem:add("INFO", "WEBHOOK", "Large file content detected. Size: " .. #fileContent .. " bytes, sending as chunked messages")
        return sendDiscordWebhookChunked(webhookUrl, data, fileContent)
    end
    
    -- Normal embed sending (for smaller content)
    local webhookBody = {
        embeds = {}
    }
    
    if data then
        local embedData = {
            title = data.title or "Lurkout Sync",
            description = data.description or "",
            color = data.color or 3447003,
            fields = data.fields or {},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }
        
        -- Check field count (Discord allows up to 25 fields per embed)
        if #embedData.fields > 25 then
            LogSystem:add("WARN", "WEBHOOK", "Too many fields (" .. #embedData.fields .. "), truncating to 25")
            local fieldsToKeep = {}
            for i = 1, 25 do
                table.insert(fieldsToKeep, embedData.fields[i])
            end
            embedData.fields = fieldsToKeep
        end
        
        table.insert(webhookBody.embeds, embedData)
    end
    
    if fileContent and #fileContent <= 1800 then
        -- Small content: add to embed description
        if webhookBody.embeds[1] then
            local currentDesc = webhookBody.embeds[1].description or ""
            local newContent = "\n```\n" .. fileContent .. "\n```"
            
            if #currentDesc + #newContent > MAX_EMBED_DESCRIPTION then
                -- Too large, send as separate embed
                table.insert(webhookBody.embeds, {
                    title = "Data",
                    description = "```\n" .. fileContent .. "\n```",
                    color = data and data.color or 3447003,
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
                })
            else
                webhookBody.embeds[1].description = currentDesc .. newContent
            end
        else
            table.insert(webhookBody.embeds, {
                title = data and data.title or "Data",
                description = "```\n" .. fileContent .. "\n```",
                color = data and data.color or 3447003,
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
            })
        end
    end
    
    -- Check embed limit
    if #webhookBody.embeds > MAX_EMBEDS then
        LogSystem:add("WARN", "WEBHOOK", "Too many embeds (" .. #webhookBody.embeds .. "), splitting into multiple messages")
        return sendDiscordWebhookChunked(webhookUrl, data, fileContent)
    end
    
    local statusCode, body = makeRequest({
        Url = webhookUrl,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(webhookBody)
    })
    
    if statusCode == 200 or statusCode == 204 then
        LogSystem:add("INFO", "WEBHOOK", "Webhook sent successfully with " .. #webhookBody.embeds .. " embed(s)")
        return true, body
    else
        LogSystem:add("ERROR", "WEBHOOK", "Webhook failed with status: " .. tostring(statusCode) .. ", Body: " .. tostring(body:sub(1, 500)))
        return false, body
    end
end

-- Helper function to send chunked messages when embed limit is exceeded (defined after forward declaration)
sendDiscordWebhookChunked = function(webhookUrl, data, fileContent)
    LogSystem:add("INFO", "WEBHOOK", "Sending chunked webhook messages")
    
    if fileContent then
        -- Split large file content into multiple messages (using message content instead of embeds for large files)
        local chunkSize = 1800 -- Characters per chunk for embed descriptions
        local chunks = {}
        for i = 1, #fileContent, chunkSize do
            table.insert(chunks, fileContent:sub(i, i + chunkSize - 1))
        end
        
        local totalChunks = #chunks
        local successCount = 0
        
        -- Send initial summary message with embed (always within limit)
        if data then
            local summaryEmbed = {
                title = (data.title or "Data") .. " (Large File - Chunked)",
                description = (data.description or "") .. "\n\n**Total Chunks:** " .. totalChunks .. "\n**File Size:** " .. string.format("%.2f", #fileContent / 1024) .. " KB\n**Status:** Sending as multiple messages below",
                color = data.color or 3447003,
                fields = {},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
            }
            
            if data.fields then
                for i = 1, math.min(#data.fields, 25) do
                    table.insert(summaryEmbed.fields, data.fields[i])
                end
            end
            
            local webhookBody = {
                embeds = {summaryEmbed},
                content = nil
            }
            
            local statusCode, body = makeRequest({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(webhookBody)
            })
            
            if statusCode == 200 or statusCode == 204 then
                successCount = successCount + 1
                LogSystem:add("INFO", "WEBHOOK", "Summary message sent successfully")
                task.wait(0.5) -- Rate limit delay
            else
                LogSystem:add("WARN", "WEBHOOK", "Summary message failed with status: " .. tostring(statusCode))
            end
        end
        
        -- Send each chunk as a separate message using message content (not embed) to avoid embed limit
        for i, chunk in ipairs(chunks) do
            local filename = (data and data.filename) or "lurkout_data.txt"
            local messageContent = "**" .. (data.title or "Data") .. " - Chunk " .. i .. "/" .. totalChunks .. "**\n```json\n" .. chunk .. "\n```"
            
            -- Use message content instead of embed for chunks
            local webhookBody = {
                content = messageContent,
                embeds = {}
            }
            
            local statusCode, body = makeRequest({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(webhookBody)
            })
            
            if statusCode == 200 or statusCode == 204 then
                successCount = successCount + 1
                LogSystem:add("DEBUG", "WEBHOOK", "Chunk " .. i .. "/" .. totalChunks .. " sent successfully")
            else
                LogSystem:add("WARN", "WEBHOOK", "Chunk " .. i .. "/" .. totalChunks .. " failed with status: " .. tostring(statusCode))
            end
            
            -- Rate limit delay between messages (Discord allows 5 requests per 5 seconds)
            if i < totalChunks then
                task.wait(1.0) -- 1 second delay to avoid rate limits
            end
        end
        
        LogSystem:add("INFO", "WEBHOOK", "Sent " .. successCount .. "/" .. (totalChunks + (data and 1 or 0)) .. " chunked messages")
        return successCount > 0, "Sent " .. successCount .. " chunks"
    else
        -- No file content, just send the data normally
        return sendDiscordWebhook(webhookUrl, data, nil)
    end
end

--// ==================== ADVANCED DEEPSEEK AI FUNCTIONS WITH LOGGING ====================
local function callDeepSeekAPI(prompt)
    LogSystem:add("INFO", "AI", "Calling DeepSeek API with prompt: " .. prompt:sub(1, 100))
    local startTime = tick()
    
    local url = CONFIG.DEEPSEEK_ENDPOINT

    local body = {
        model = "deepseek-chat",
        messages = {
            {
                role = "system",
                content = "You are a helpful AI assistant. Always respond in English, regardless of the language used in the user's prompt. Provide clear, concise, and accurate responses."
            },
            {
                role = "user",
                content = prompt
            }
        },
        temperature = 0.7,
        max_tokens = 2000
    }
    
    LogSystem:add("DEBUG", "AI", "Request payload size: " .. #HttpService:JSONEncode(body) .. " bytes")
    
    local statusCode, responseBody = makeRequest({
        Url = url,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Authorization"] = "Bearer " .. CONFIG.DEEPSEEK_API_KEY
        },
        Body = HttpService:JSONEncode(body)
    })
    
    local endTime = tick()
    local duration = endTime - startTime
    LogSystem:add("INFO", "AI", "API request completed in " .. string.format("%.2f", duration) .. "s with status: " .. tostring(statusCode))
    
    if statusCode == 200 then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(responseBody)
        end)
        
        if success and decoded.choices and #decoded.choices > 0 then
            local response = decoded.choices[1].message.content
            local tokenCount = decoded.usage and decoded.usage.total_tokens or 0
            LogSystem:add("INFO", "AI", "AI response received. Length: " .. #response .. " chars, Tokens: " .. tostring(tokenCount))
            LogSystem:add("DEBUG", "AI", "Response preview: " .. response:sub(1, 200))
            
            -- Log AI usage statistics
            LogSystem:add("INFO", "AI", "Usage stats: " .. HttpService:JSONEncode(decoded.usage or {}))
            
            return true, response, {
                tokens = tokenCount,
                duration = duration,
                model = decoded.model or "deepseek-chat"
            }
        else
            LogSystem:add("ERROR", "AI", "Invalid response format: " .. tostring(responseBody:sub(1, 500)))
            return false, "Invalid response format"
        end
    else
        LogSystem:add("ERROR", "AI", "API request failed with status: " .. tostring(statusCode) .. ", Response: " .. tostring(responseBody:sub(1, 500)))
        return false, "API request failed: " .. tostring(statusCode)
    end
end

--// ==================== ADVANCED SCANNER FUNCTIONS WITH LOGGING ====================
local function scanGame()
    LogSystem:add("INFO", "SCANNER", "Starting advanced game scan...")
    local startTime = tick()
    
    local data = {
        game = {
            placeId = game.PlaceId,
            jobId = game.JobId,
            name = "Unknown",
            gameId = game.GameId
        },
        players = {},
        services = {},
        workspace = {},
        replicatedStorage = {},
        lighting = {},
        serverScriptService = {},
        scanMetadata = {
            timestamp = os.date("!%Y-%m-%d %H:%M:%S UTC"),
            scannerVersion = "3.0",
            scanDuration = 0
        }
    }
    
    -- Get game name with detailed logging
    pcall(function()
        local productInfo = MarketplaceService:GetProductInfo(game.PlaceId)
        data.game.name = productInfo.Name
        data.game.description = productInfo.Description
        data.game.price = productInfo.PriceInRobux
        LogSystem:add("INFO", "SCANNER", "Game name: " .. productInfo.Name)
    end)
    
    -- Advanced player scanning with detailed info
    LogSystem:add("INFO", "SCANNER", "Scanning players...")
    local playerCount = 0
    for _, player in ipairs(Players:GetPlayers()) do
        playerCount = playerCount + 1
        local playerData = {
            name = player.Name,
            userId = player.UserId,
            accountAge = player.AccountAge,
            team = player.Team and player.Team.Name or "None",
            character = nil,
            location = nil
        }
        
        -- Get character info if available
        pcall(function()
            if player.Character then
                local character = player.Character
                local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    playerData.location = {
                        x = humanoidRootPart.Position.X,
                        y = humanoidRootPart.Position.Y,
                        z = humanoidRootPart.Position.Z
                    }
                end
                playerData.character = {
                    name = character.Name,
                    health = character:FindFirstChild("Humanoid") and character:FindFirstChild("Humanoid").Health or 0
                }
            end
        end)
        
        table.insert(data.players, playerData)
        LogSystem:add("DEBUG", "SCANNER", "Scanned player: " .. player.Name)
    end
    LogSystem:add("INFO", "SCANNER", "Scanned " .. playerCount .. " players")
    
    -- Compact workspace tree scanning (Name (ClassName) format)
    local function scanInstanceCompact(instance, depth, maxDepth)
        if depth > maxDepth then return "" end
        
        local indent = string.rep("  ", depth) -- Simple 2-space indentation per level
        local treeLine = indent .. instance.Name .. " (" .. instance.ClassName .. ")"
        local result = {treeLine}
        
        local children = instance:GetChildren()
        if #children > 0 then
            for _, child in ipairs(children) do
                local childTree = scanInstanceCompact(child, depth + 1, maxDepth)
                if childTree ~= "" then
                    table.insert(result, childTree)
                end
            end
        end
        
        return table.concat(result, "\n")
    end
    
    -- Advanced workspace scanning with compact tree output
    LogSystem:add("INFO", "SCANNER", "Scanning Workspace (compact tree)...")
    local wsStartTime = tick()
    local workspaceTree = scanInstanceCompact(Workspace, 0, 10)
    data.workspace = workspaceTree
    local wsEndTime = tick()
    LogSystem:add("INFO", "SCANNER", "Workspace scan completed in " .. string.format("%.2f", wsEndTime - wsStartTime) .. "s")
    
    LogSystem:add("INFO", "SCANNER", "Scanning ReplicatedStorage (compact tree)...")
    local rsStartTime = tick()
    local replicatedStorageTree = scanInstanceCompact(ReplicatedStorage, 0, 10)
    data.replicatedStorage = replicatedStorageTree
    local rsEndTime = tick()
    LogSystem:add("INFO", "SCANNER", "ReplicatedStorage scan completed in " .. string.format("%.2f", rsEndTime - rsStartTime) .. "s")
    
    LogSystem:add("INFO", "SCANNER", "Scanning Lighting (compact tree)...")
    local lightStartTime = tick()
    local lightingTree = scanInstanceCompact(Lighting, 0, 10)
    data.lighting = lightingTree
    local lightEndTime = tick()
    LogSystem:add("INFO", "SCANNER", "Lighting scan completed in " .. string.format("%.2f", lightEndTime - lightStartTime) .. "s")
    
    -- Scan ServerScriptService if accessible
    pcall(function()
        LogSystem:add("INFO", "SCANNER", "Scanning ServerScriptService (compact tree)...")
        local ServerScriptService = game:GetService("ServerScriptService")
        local sssStartTime = tick()
        local serverScriptServiceTree = scanInstanceCompact(ServerScriptService, 0, 10)
        data.serverScriptService = serverScriptServiceTree
        local sssEndTime = tick()
        LogSystem:add("INFO", "SCANNER", "ServerScriptService scan completed in " .. string.format("%.2f", sssEndTime - sssStartTime) .. "s")
    end)
    
    local endTime = tick()
    data.scanMetadata.scanDuration = endTime - startTime
    LogSystem:add("INFO", "SCANNER", "Game scan completed in " .. string.format("%.2f", data.scanMetadata.scanDuration) .. "s")
    
    -- Format as compact text output instead of JSON
    local output = {}
    table.insert(output, "=== GAME SCAN RESULTS ===")
    table.insert(output, "Game: " .. data.game.name)
    table.insert(output, "Place ID: " .. tostring(data.game.placeId))
    table.insert(output, "Job ID: " .. data.game.jobId)
    table.insert(output, "Players: " .. #data.players)
    table.insert(output, "")
    table.insert(output, "=== WORKSPACE TREE ===")
    table.insert(output, data.workspace)
    table.insert(output, "")
    table.insert(output, "=== REPLICATED STORAGE TREE ===")
    table.insert(output, data.replicatedStorage)
    table.insert(output, "")
    table.insert(output, "=== LIGHTING TREE ===")
    table.insert(output, data.lighting)
    
    if data.serverScriptService then
        table.insert(output, "")
        table.insert(output, "=== SERVER SCRIPT SERVICE TREE ===")
        table.insert(output, data.serverScriptService)
    end
    
    return table.concat(output, "\n")
end

local function scanBackdoors()
    LogSystem:add("INFO", "BACKDOOR", "Starting backdoor scan...")
    local startTime = tick()
    
    local backdoors = {}
    
    -- Check common backdoor locations
    local suspiciousNames = {
        "RemoteEvent", "RemoteFunction", "BindableEvent", "BindableFunction",
        "Script", "LocalScript", "ModuleScript"
    }
    
    local suspiciousPatterns = {
        "http", "webhook", "request", "post", "get",
        "eval", "loadstring", "exec", "execute"
    }
    
    local function checkScript(script)
        local success, source = pcall(function()
            return script.Source
        end)
        
        if success and source then
            local lowerSource = string.lower(source)
            
            for _, pattern in ipairs(suspiciousPatterns) do
                if lowerSource:find(pattern) then
                    table.insert(backdoors, {
                        name = script.Name,
                        className = script.ClassName,
                        fullName = script:GetFullName(),
                        suspiciousPattern = pattern,
                        sourcePreview = source:sub(1, 500)
                    })
                    break
                end
            end
        end
    end
    
    local function scanInstance(instance)
        if instance:IsA("BaseScript") then
            checkScript(instance)
        end
        
        for _, child in ipairs(instance:GetChildren()) do
            scanInstance(child)
        end
    end
    
    LogSystem:add("INFO", "BACKDOOR", "Scanning Workspace for backdoors...")
    scanInstance(Workspace)
    LogSystem:add("DEBUG", "BACKDOOR", "Workspace scan complete. Found: " .. #backdoors .. " potential backdoors")
    
    LogSystem:add("INFO", "BACKDOOR", "Scanning ReplicatedStorage for backdoors...")
    scanInstance(ReplicatedStorage)
    LogSystem:add("DEBUG", "BACKDOOR", "ReplicatedStorage scan complete. Found: " .. #backdoors .. " potential backdoors")
    
    pcall(function()
        LogSystem:add("INFO", "BACKDOOR", "Scanning ServerScriptService for backdoors...")
        scanInstance(game:GetService("ServerScriptService"))
        LogSystem:add("DEBUG", "BACKDOOR", "ServerScriptService scan complete. Found: " .. #backdoors .. " potential backdoors")
        
        LogSystem:add("INFO", "BACKDOOR", "Scanning StarterPlayer for backdoors...")
        scanInstance(game:GetService("StarterPlayer"))
        LogSystem:add("DEBUG", "BACKDOOR", "StarterPlayer scan complete. Found: " .. #backdoors .. " potential backdoors")
    end)
    
    local endTime = tick()
    local duration = endTime - startTime
    LogSystem:add("INFO", "BACKDOOR", "Backdoor scan completed in " .. string.format("%.2f", duration) .. "s. Total backdoors found: " .. #backdoors)
    
    return backdoors
end

--// ==================== ADVANCED DUMPER FUNCTIONS WITH LOGGING ====================
local function dumpWorkspace()
    LogSystem:add("INFO", "DUMPER", "Starting workspace dump...")
    local startTime = tick()
    
    local dump = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        workspace = {},
        dumpMetadata = {
            version = "3.0",
            duration = 0,
            instanceCount = 0
        }
    }
    
    local function serializeInstance(instance, depth, maxDepth)
        if depth > maxDepth then return nil end
        
        local info = {
            Name = instance.Name,
            ClassName = instance.ClassName,
            FullName = instance:GetFullName(),
            Properties = {}
        }
        
        -- Get key properties
        local properties = {
            "Size", "Position", "Color", "Material", "Transparency",
            "CanCollide", "Anchored", "Shape"
        }
        
        for _, prop in ipairs(properties) do
            local success, value = pcall(function()
                return instance[prop]
            end)
            if success then
                info.Properties[prop] = tostring(value)
    end
end

        local children = {}
        for _, child in ipairs(instance:GetChildren()) do
            local childInfo = serializeInstance(child, depth + 1, maxDepth)
            if childInfo then
                table.insert(children, childInfo)
            end
        end
        
        if #children > 0 then
            info.Children = children
        end
        
        return info
    end
    
    local wsDump = serializeInstance(Workspace, 0, 10) or {}
    dump.workspace = wsDump
    
    -- Count instances
    local function countInstances(data)
        local count = 1
        if data.Children then
            for _, child in ipairs(data.Children) do
                count = count + countInstances(child)
            end
        end
        return count
    end
    
    dump.dumpMetadata.instanceCount = countInstances(wsDump)
    
    local endTime = tick()
    dump.dumpMetadata.duration = endTime - startTime
    LogSystem:add("INFO", "DUMPER", "Workspace dump completed in " .. string.format("%.2f", dump.dumpMetadata.duration) .. "s. Instances: " .. dump.dumpMetadata.instanceCount)
    
    return HttpService:JSONEncode(dump, true)
end

--// ==================== DECOMPILATION SETUP (DEX++ STYLE) ====================
local getscriptbytecode = getscriptbytecode or (syn and syn.getscriptbytecode) or get_script_bytecode
local nativeDecompile = decompile or (syn and syn.decompile)

-- Decompiler function (uses medal/Konstant like dex++)
local function decompileScript(script)
    LogSystem:add("DEBUG", "DECOMPILE", "Attempting to decompile: " .. script:GetFullName())
    
    -- Try native decompiler first (medal/syn)
    if nativeDecompile then
        local success, result = pcall(function()
            return nativeDecompile(script)
        end)
        if success and result then
            LogSystem:add("DEBUG", "DECOMPILE", "Native decompiler succeeded for: " .. script.Name)
            return result
        end
    end
    
    -- Fallback to Konstant decompiler (dex++ style)
    if getscriptbytecode then
        local success, bytecode = pcall(function()
            return getscriptbytecode(script)
        end)
        
        if success and bytecode then
            LogSystem:add("DEBUG", "DECOMPILE", "Using Konstant decompiler for: " .. script.Name)
            
            -- Konstant API endpoint
            local API = "http://api.plusgiant5.com"
            local konstantType = "/konstant/decompile"
            
            local statusCode, responseBody = makeRequest({
                Url = API .. konstantType,
                Body = bytecode,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "text/plain"
                }
            })
            
            if statusCode == 200 and responseBody then
                LogSystem:add("DEBUG", "DECOMPILE", "Konstant decompiler succeeded for: " .. script.Name)
                return responseBody
            else
                LogSystem:add("WARN", "DECOMPILE", "Konstant API failed with status: " .. tostring(statusCode))
            end
        else
            LogSystem:add("WARN", "DECOMPILE", "Failed to get bytecode for: " .. script.Name)
        end
    end
    
    -- Final fallback: try to get source directly
    local success, source = pcall(function()
        return script.Source
    end)
    
    if success and source then
        LogSystem:add("WARN", "DECOMPILE", "Using direct source (not decompiled) for: " .. script.Name)
        return "-- Could not decompile, using direct source:\n" .. source
    end
    
    LogSystem:add("ERROR", "DECOMPILE", "Failed to get source for: " .. script.Name)
    return "-- Failed to decompile or get source for: " .. script:GetFullName()
end

local function dumpScripts()
    LogSystem:add("INFO", "DUMPER", "Starting script dump with decompilation...")
    local startTime = tick()
    
    local dump = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z"),
        scripts = {},
        dumpMetadata = {
            version = "3.0",
            duration = 0,
            scriptCount = 0,
            totalSourceSize = 0,
            decompiledCount = 0
        }
    }
    
    local function dumpScript(script)
        local scriptInfo = {
            name = script.Name,
            className = script.ClassName,
            fullName = script:GetFullName(),
            source = nil,
            decompiled = false,
            enabled = script:IsA("Script") and script.Enabled or nil
        }
        
        -- Check if script can be decompiled (dex++ style check)
        local canDecompile = false
        if script:IsA("ModuleScript") then
            canDecompile = true
        elseif script:IsA("LocalScript") and (script.RunContext == Enum.RunContext.Client or script.RunContext == Enum.RunContext.Legacy) then
            canDecompile = true
        elseif script:IsA("Script") and script.RunContext == Enum.RunContext.Client then
            canDecompile = true
        end
        
        if canDecompile and (nativeDecompile or getscriptbytecode) then
            -- Try to decompile
            scriptInfo.source = decompileScript(script)
            scriptInfo.decompiled = true
            dump.dumpMetadata.decompiledCount = dump.dumpMetadata.decompiledCount + 1
        else
            -- Fallback to direct source
            local success, source = pcall(function()
                return script.Source
            end)
            
            if success then
                scriptInfo.source = source
                if script.RunContext == Enum.RunContext.Server then
                    scriptInfo.source = "-- Server Script (cannot decompile client-side)\n" .. (scriptInfo.source or "")
                end
            else
                scriptInfo.source = "-- Could not get source"
            end
        end
        
        table.insert(dump.scripts, scriptInfo)
    end
    
    local function scanInstance(instance)
        if instance:IsA("BaseScript") then
            dumpScript(instance)
        end
        
        for _, child in ipairs(instance:GetChildren()) do
            scanInstance(child)
        end
    end
    
    LogSystem:add("INFO", "DUMPER", "Dumping scripts from Workspace...")
    scanInstance(Workspace)
    LogSystem:add("DEBUG", "DUMPER", "Workspace scripts dumped. Total: " .. #dump.scripts)
    
    LogSystem:add("INFO", "DUMPER", "Dumping scripts from ReplicatedStorage...")
    scanInstance(ReplicatedStorage)
    LogSystem:add("DEBUG", "DUMPER", "ReplicatedStorage scripts dumped. Total: " .. #dump.scripts)
    
    LogSystem:add("INFO", "DUMPER", "Dumping scripts from StarterPlayer...")
    scanInstance(game:GetService("StarterPlayer"))
    LogSystem:add("DEBUG", "DUMPER", "StarterPlayer scripts dumped. Total: " .. #dump.scripts)
    
    pcall(function()
        LogSystem:add("INFO", "DUMPER", "Dumping scripts from ServerScriptService...")
        scanInstance(game:GetService("ServerScriptService"))
        LogSystem:add("DEBUG", "DUMPER", "ServerScriptService scripts dumped. Total: " .. #dump.scripts)
    end)
    
    -- Calculate statistics
    dump.dumpMetadata.scriptCount = #dump.scripts
    local totalSize = 0
    for _, script in ipairs(dump.scripts) do
        if script.source then
            totalSize = totalSize + #script.source
        end
    end
    dump.dumpMetadata.totalSourceSize = totalSize
    
    local endTime = tick()
    dump.dumpMetadata.duration = endTime - startTime
    LogSystem:add("INFO", "DUMPER", "Script dump completed in " .. string.format("%.2f", dump.dumpMetadata.duration) .. "s. Scripts: " .. dump.dumpMetadata.scriptCount .. ", Decompiled: " .. dump.dumpMetadata.decompiledCount .. ", Total size: " .. totalSize .. " bytes")
    
    return HttpService:JSONEncode(dump, true)
end

--// ==================== EMBEDDED UI LIBRARY INITIALIZATION ====================
-- NOTE: Full library code embedded inline below (see embedded library section)
-- This is a custom version of LURKOUT UI Library v3.5 with glassmorphic enhancements

-- Load embedded library code
local LURKOUTLib = nil

-- Function to load embedded library from file or embedded code
local function LoadEmbeddedLibrary()
    -- Try to load from file first
    if readfile then
        local success, libCode = pcall(function()
            return readfile("lib/NEWLURKOUTV2realversion.lua")
        end)
        if success and libCode then
            local success2, lib = pcall(function()
                return loadstring(libCode)()
            end)
            if success2 and lib then
                return lib
            end
        end
    end
    
    -- If file loading fails, we'll use a modified inline version
    -- For now, return nil and we'll create the library inline below
    return nil
end

LURKOUTLib = LoadEmbeddedLibrary()

-- If library failed to load, create it inline with glassmorphic enhancements
if not LURKOUTLib then
    warn("[Lurkout] Loading embedded library inline...")
    
    -- Create minimal inline library structure with glassmorphic enhancements
    -- Full library code will be embedded below
    local LURKOUT = {}
    LURKOUT.__index = LURKOUT
    
    -- Glassmorphic config with transparency
    local GlassConfig = {
        NavbarHC = Color3.fromRGB(255,255,255),
        NavbarHC2 = Color3.fromRGB(255,0,0),
        MainColor = Color3.fromRGB(0, 0, 0),
        SecondaryColor = Color3.fromRGB(80, 8, 8),
        TertiaryColor = Color3.fromRGB(50, 20, 20),
        AccentColor = Color3.fromRGB(0, 20, 20),
        GlowColor = Color3.fromRGB(0, 0, 0),
        TextColor = Color3.fromRGB(200, 200, 200),
        BorderColor = Color3.fromRGB(255, 30, 30),
        ButtonHover = Color3.fromRGB(255, 25, 25),
        DropdownBG = Color3.fromRGB(25, 25, 25),
        DropdownOptionBG = Color3.fromRGB(35, 35, 35),
        DropdownTextColor = Color3.fromRGB(255, 255, 255),
        HoverTextColor = Color3.fromRGB(255, 255, 255),
        ToggleKey = Enum.KeyCode.RightControl,
        DiscordLink = "https://discord.gg/lurkout",
        WebsiteLink = "https://lurkout.com",
        -- Glassmorphic transparency values
        MainTransparency = 0.15,
        SecondaryTransparency = 0.20,
        TertiaryTransparency = 0.25,
        ButtonTransparency = 0.30
    }
    
    local function Tween(instance, properties, duration, style, direction)
        local tweenInfo = TweenInfo.new(
            duration or 0.3,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        )
        local tween = TweenService:Create(instance, tweenInfo, properties)
        tween:Play()
        return tween
    end
    
    local function CreateFrameShadow(parent, color, size)
        local shadow = Instance.new("ImageLabel")
        shadow.Name = GenerateRandomString(12)
        shadow.Image = "rbxassetid://1316045217"
        shadow.ImageColor3 = color or Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.5 -- More transparent for glassmorphic
        shadow.ScaleType = Enum.ScaleType.Slice
        shadow.SliceCenter = Rect.new(10, 10, 118, 118)
        shadow.BackgroundTransparency = 1
        shadow.Position = UDim2.new(0, -(size or 3), 0, -(size or 3))
        shadow.Size = UDim2.new(1, (size or 3) * 2, 1, (size or 3) * 2)
        shadow.ZIndex = parent.ZIndex - 1
        shadow.Parent = parent
        return shadow
    end
    
    local function MakeDraggable(gui, dragPart)
        local dragging = false
        local dragInput, mousePos, framePos
        
        dragPart.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = gui.Position
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        
        dragPart.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                local newPos = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
                Tween(gui, {Position = newPos}, 0.05, Enum.EasingStyle.Linear)
            end
        end)
    end
    
    -- Full library init with glassmorphic enhancements
    function LURKOUT:Init()
        local Library = {}
        Library.Tabs = {}
        Library.CurrentTab = nil
        Library.Minimized = false
        Library.ScreenGui = nil
        Library.Main = nil
        Library.NotificationQueue = {}
        Library.ActiveNotifications = {}
        
local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = GenerateRandomString(32)
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = true
        ScreenGui.DisplayOrder = 999999
        
        pcall(function()
            ScreenGui.Parent = PlayerGui
            if syn and syn.protect_gui then
                syn.protect_gui(ScreenGui)
            end
        end)
        
        if not ScreenGui.Parent then
            ScreenGui.Parent = PlayerGui
        end
        
        Library.ScreenGui = ScreenGui
        
        -- Glassmorphic Main Container
        local Container = Instance.new("Frame")
        Container.Name = GenerateRandomString(16)
        Container.BackgroundTransparency = 1
        Container.Position = UDim2.new(0.5, -300, 0.5, -200)
        Container.Size = UDim2.new(0, 600, 0, 400)
        Container.ZIndex = 1
        Container.Parent = ScreenGui
        
        local Main = Instance.new("Frame")
        Main.Name = GenerateRandomString(16)
        Main.BackgroundColor3 = GlassConfig.MainColor
        Main.BorderSizePixel = 0
        Main.Position = UDim2.new(0, 0, 0, 0)
        Main.Size = UDim2.new(1, 0, 1, 0)
        Main.ClipsDescendants = false
        Main.ZIndex = 5
        Main.Parent = Container
        
        -- Apply glassmorphic effect
        ApplyGlassmorphicEffect(Main, GlassConfig.MainTransparency, false)
        
        local MainCorner = Instance.new("UICorner")
        MainCorner.CornerRadius = UDim.new(0, 16) -- Larger radius for modern look
        MainCorner.Parent = Main
        
        CreateFrameShadow(Main, GlassConfig.GlowColor, 8)
        
        Library.Main = Main
        
        -- Glassmorphic Navbar
        local Navbar = Instance.new("Frame")
        Navbar.Name = GenerateRandomString(16)
        Navbar.BackgroundColor3 = GlassConfig.SecondaryColor
        Navbar.BorderSizePixel = 0
        Navbar.Position = UDim2.new(0, 10, 0, 10)
        Navbar.Size = UDim2.new(1, -20, 0, 50)
        Navbar.ZIndex = 15
        Navbar.Parent = Main
        
        -- Apply glassmorphic effect
        ApplyGlassmorphicEffect(Navbar, GlassConfig.SecondaryTransparency, false)
        
        local NavbarCorner = Instance.new("UICorner")
        NavbarCorner.CornerRadius = UDim.new(0, 12)
        NavbarCorner.Parent = Navbar
        
        CreateFrameShadow(Navbar, GlassConfig.AccentColor, 5)

local Title = Instance.new("TextLabel")
        Title.Name = GenerateRandomString(12)
Title.BackgroundTransparency = 1
        Title.Position = UDim2.new(0, 20, 0, 0)
        Title.Size = UDim2.new(0, 120, 1, 0)
Title.Font = Enum.Font.GothamBold
        Title.Text = "LURKOUT"
        Title.TextColor3 = GlassConfig.TextColor
Title.TextSize = 20
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 16
        Title.Parent = Navbar
        
        MakeDraggable(Container, Navbar)
        
        -- Minimize/Close buttons with glassmorphic effect
        local ButtonContainer = Instance.new("Frame")
        ButtonContainer.Name = GenerateRandomString(12)
        ButtonContainer.BackgroundTransparency = 1
        ButtonContainer.Position = UDim2.new(1, -95, 0, 10)
        ButtonContainer.Size = UDim2.new(0, 85, 0, 30)
        ButtonContainer.ZIndex = 16
        ButtonContainer.Parent = Navbar
        
        local MinimizeButton = Instance.new("TextButton")
        MinimizeButton.Name = GenerateRandomString(12)
        MinimizeButton.BackgroundColor3 = GlassConfig.TertiaryColor
        MinimizeButton.BorderSizePixel = 0
        MinimizeButton.Position = UDim2.new(0, 0, 0, 0)
        MinimizeButton.Size = UDim2.new(0, 35, 0, 30)
        MinimizeButton.Font = Enum.Font.GothamBold
        MinimizeButton.Text = "_"
        MinimizeButton.TextColor3 = GlassConfig.TextColor
        MinimizeButton.TextSize = 18
        MinimizeButton.ZIndex = 17
        MinimizeButton.AutoButtonColor = false
        MinimizeButton.Parent = ButtonContainer
        
        ApplyGlassmorphicEffect(MinimizeButton, GlassConfig.ButtonTransparency, false)
        
        local MinimizeCorner = Instance.new("UICorner")
        MinimizeCorner.CornerRadius = UDim.new(0, 8)
        MinimizeCorner.Parent = MinimizeButton
        
        local CloseButton = Instance.new("TextButton")
        CloseButton.Name = GenerateRandomString(12)
        CloseButton.BackgroundColor3 = GlassConfig.TertiaryColor
        CloseButton.BorderSizePixel = 0
        CloseButton.Position = UDim2.new(0, 45, 0, 0)
        CloseButton.Size = UDim2.new(0, 35, 0, 30)
        CloseButton.Font = Enum.Font.GothamBold
        CloseButton.Text = "X"
        CloseButton.TextColor3 = GlassConfig.TextColor
        CloseButton.TextSize = 16
        CloseButton.ZIndex = 17
        CloseButton.AutoButtonColor = false
        CloseButton.Parent = ButtonContainer
        
        ApplyGlassmorphicEffect(CloseButton, GlassConfig.ButtonTransparency, false)
        
        local CloseCorner = Instance.new("UICorner")
        CloseCorner.CornerRadius = UDim.new(0, 8)
        CloseCorner.Parent = CloseButton
        
        MinimizeButton.MouseEnter:Connect(function()
            Tween(MinimizeButton, {BackgroundColor3 = GlassConfig.ButtonHover}, 0.2)
        end)
        
        MinimizeButton.MouseLeave:Connect(function()
            Tween(MinimizeButton, {BackgroundColor3 = GlassConfig.TertiaryColor}, 0.2)
        end)
        
        MinimizeButton.MouseButton1Click:Connect(function()
            Library.Minimized = not Library.Minimized
            if Library.Minimized then
                Tween(Main, {Size = UDim2.new(0, 600, 0, 70)}, 0.3)
            else
                Tween(Main, {Size = UDim2.new(0, 600, 0, 400)}, 0.3)
            end
        end)
        
        CloseButton.MouseEnter:Connect(function()
            Tween(CloseButton, {BackgroundColor3 = Color3.fromRGB(200, 0, 0)}, 0.2)
        end)
        
        CloseButton.MouseLeave:Connect(function()
            Tween(CloseButton, {BackgroundColor3 = GlassConfig.TertiaryColor}, 0.2)
        end)
        
        CloseButton.MouseButton1Click:Connect(function()
            Tween(Main, {BackgroundTransparency = 1}, 0.3)
            Tween(Navbar, {BackgroundTransparency = 1}, 0.3)
            task.wait(0.3)
            ScreenGui:Destroy()
        end)
        
        -- Glassmorphic Tab Bar
        local TabBar = Instance.new("Frame")
        TabBar.Name = GenerateRandomString(16)
        TabBar.BackgroundColor3 = GlassConfig.SecondaryColor
        TabBar.BorderSizePixel = 0
        TabBar.Position = UDim2.new(0, 10, 0, 70)
        TabBar.Size = UDim2.new(0, 120, 1, -80)
        TabBar.ZIndex = 10
        TabBar.Parent = Main
        
        ApplyGlassmorphicEffect(TabBar, GlassConfig.SecondaryTransparency, false)
        
        local TabBarCorner = Instance.new("UICorner")
        TabBarCorner.CornerRadius = UDim.new(0, 12)
        TabBarCorner.Parent = TabBar
        
        CreateFrameShadow(TabBar, GlassConfig.AccentColor, 3)
        
        local TabList = Instance.new("ScrollingFrame")
        TabList.Name = GenerateRandomString(12)
        TabList.BackgroundTransparency = 1
        TabList.Position = UDim2.new(0, 5, 0, 5)
        TabList.Size = UDim2.new(1, -10, 1, -10)
        TabList.ScrollBarThickness = 4
        TabList.ScrollBarImageColor3 = GlassConfig.BorderColor
        TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabList.ZIndex = 11
        TabList.BorderSizePixel = 0
        TabList.Parent = TabBar
        
        local TabListLayout = Instance.new("UIListLayout")
        TabListLayout.Name = GenerateRandomString(12)
        TabListLayout.Padding = UDim.new(0, 5)
        TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        TabListLayout.Parent = TabList
        
        TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
        end)
        
        -- Glassmorphic Content Frame
        local ContentFrame = Instance.new("Frame")
        ContentFrame.Name = GenerateRandomString(16)
        ContentFrame.BackgroundColor3 = GlassConfig.SecondaryColor
        ContentFrame.BorderSizePixel = 0
        ContentFrame.Position = UDim2.new(0, 140, 0, 70)
        ContentFrame.Size = UDim2.new(1, -150, 1, -80)
        ContentFrame.ZIndex = 10
        ContentFrame.Parent = Main
        
        ApplyGlassmorphicEffect(ContentFrame, GlassConfig.SecondaryTransparency, false)
        
        local ContentCorner = Instance.new("UICorner")
        ContentCorner.CornerRadius = UDim.new(0, 12)
        ContentCorner.Parent = ContentFrame
        
        CreateFrameShadow(ContentFrame, GlassConfig.AccentColor, 3)
        
        -- Tab creation with glassmorphic enhancements
        function Library:CreateTab(name)
            local Tab = {}
            Tab.Name = name
            Tab.Active = false
            
            local TabButton = Instance.new("TextButton")
            TabButton.Name = GenerateRandomString(12)
            TabButton.BackgroundColor3 = GlassConfig.TertiaryColor
            TabButton.BorderSizePixel = 0
            TabButton.Size = UDim2.new(1, 0, 0, 35)
            TabButton.Font = Enum.Font.GothamBold
            TabButton.Text = name
            TabButton.TextColor3 = GlassConfig.TextColor
            TabButton.TextSize = 13
            TabButton.ZIndex = 12
            TabButton.AutoButtonColor = false
            TabButton.Parent = TabList
            
            ApplyGlassmorphicEffect(TabButton, GlassConfig.ButtonTransparency, false)
            
            local TabButtonCorner = Instance.new("UICorner")
            TabButtonCorner.CornerRadius = UDim.new(0, 8)
            TabButtonCorner.Parent = TabButton
            
            local TabContent
            if name == "Home" or name == "Settings" then
                TabContent = Instance.new("Frame")
            else
                TabContent = Instance.new("ScrollingFrame")
                TabContent.ScrollBarThickness = 6
                TabContent.ScrollBarImageColor3 = GlassConfig.BorderColor
                TabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
                TabContent.BorderSizePixel = 0
                
                local TabContentLayout = Instance.new("UIListLayout")
                TabContentLayout.Padding = UDim.new(0, 8)
                TabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
                TabContentLayout.Parent = TabContent
                
                TabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    TabContent.CanvasSize = UDim2.new(0, 0, 0, TabContentLayout.AbsoluteContentSize.Y + 20)
                end)
            end
            
            TabContent.Name = GenerateRandomString(12)
            TabContent.BackgroundTransparency = 1
            TabContent.Position = UDim2.new(0, 10, 0, 10)
            TabContent.Size = UDim2.new(1, -20, 1, -20)
            TabContent.Visible = false
            TabContent.ZIndex = 11
            TabContent.Parent = ContentFrame
            
            Tab.Content = TabContent
            Tab.Button = TabButton
            
            TabButton.MouseEnter:Connect(function()
                if not Tab.Active then
                    Tween(TabButton, {BackgroundColor3 = GlassConfig.ButtonHover, TextColor3 = GlassConfig.HoverTextColor}, 0.2)
                end
            end)
            
            TabButton.MouseLeave:Connect(function()
                if not Tab.Active then
                    Tween(TabButton, {BackgroundColor3 = GlassConfig.TertiaryColor, TextColor3 = GlassConfig.TextColor}, 0.2)
                end
            end)
            
            TabButton.MouseButton1Click:Connect(function()
                for _, tab in pairs(Library.Tabs) do
                    tab.Active = false
                    tab.Content.Visible = false
                    Tween(tab.Button, {BackgroundColor3 = GlassConfig.TertiaryColor, TextColor3 = GlassConfig.TextColor}, 0.2)
                end
                
                Tab.Active = true
                TabContent.Visible = true
                Tween(TabButton, {BackgroundColor3 = GlassConfig.BorderColor, TextColor3 = GlassConfig.HoverTextColor}, 0.2)
            end)
            
            -- Glassmorphic button with logging
            function Tab:AddButton(text, callback)
                local Button = Instance.new("TextButton")
                Button.Name = GenerateRandomString(12)
                Button.BackgroundColor3 = GlassConfig.TertiaryColor
                Button.BorderSizePixel = 0
                Button.Size = UDim2.new(1, 0, 0, 35)
                Button.Font = Enum.Font.GothamBold
                Button.Text = text
                Button.TextColor3 = GlassConfig.TextColor
                Button.TextSize = 13
                Button.ZIndex = 12
                Button.AutoButtonColor = false
                Button.Parent = TabContent
                
                ApplyGlassmorphicEffect(Button, GlassConfig.ButtonTransparency, false)
                
                local ButtonCorner = Instance.new("UICorner")
                ButtonCorner.CornerRadius = UDim.new(0, 8)
                ButtonCorner.Parent = Button
                
                CreateFrameShadow(Button, GlassConfig.AccentColor, 2)
                
                Button.MouseEnter:Connect(function()
                    Tween(Button, {BackgroundColor3 = GlassConfig.ButtonHover, TextColor3 = GlassConfig.HoverTextColor}, 0.2)
                end)
                
                Button.MouseLeave:Connect(function()
                    Tween(Button, {BackgroundColor3 = GlassConfig.TertiaryColor, TextColor3 = GlassConfig.TextColor}, 0.2)
                end)
                
                Button.MouseButton1Click:Connect(function()
                    LogSystem:add("INFO", "UI", "Button clicked: " .. text)
                    Tween(Button, {BackgroundColor3 = GlassConfig.AccentColor}, 0.1)
                    task.wait(0.1)
                    Tween(Button, {BackgroundColor3 = GlassConfig.ButtonHover}, 0.1)
                    pcall(callback)
                end)
                
                return Button
            end
            
            -- Glassmorphic input with logging
            function Tab:AddInput(text, placeholder, callback)
                local InputFrame = Instance.new("Frame")
                InputFrame.Name = GenerateRandomString(12)
                InputFrame.BackgroundColor3 = GlassConfig.TertiaryColor
                InputFrame.BorderSizePixel = 0
                InputFrame.Size = UDim2.new(1, 0, 0, 50)
                InputFrame.ZIndex = 12
                InputFrame.Parent = TabContent
                
                ApplyGlassmorphicEffect(InputFrame, GlassConfig.ButtonTransparency, false)
                
                local InputCorner = Instance.new("UICorner")
                InputCorner.CornerRadius = UDim.new(0, 8)
                InputCorner.Parent = InputFrame
                
                CreateFrameShadow(InputFrame, GlassConfig.AccentColor, 2)
                
                local InputLabel = Instance.new("TextLabel")
                InputLabel.Name = GenerateRandomString(12)
                InputLabel.BackgroundTransparency = 1
                InputLabel.Position = UDim2.new(0, 15, 0, 5)
                InputLabel.Size = UDim2.new(1, -30, 0, 15)
                InputLabel.Font = Enum.Font.GothamBold
                InputLabel.Text = text
                InputLabel.TextColor3 = GlassConfig.TextColor
                InputLabel.TextSize = 13
                InputLabel.TextXAlignment = Enum.TextXAlignment.Left
                InputLabel.ZIndex = 13
                InputLabel.Parent = InputFrame
                
                local TextBox = Instance.new("TextBox")
                TextBox.Name = GenerateRandomString(12)
                TextBox.BackgroundColor3 = GlassConfig.AccentColor
                TextBox.BackgroundTransparency = 0.5 -- Glassmorphic
                TextBox.BorderSizePixel = 0
                TextBox.Position = UDim2.new(0, 15, 0, 25)
                TextBox.Size = UDim2.new(1, -30, 0, 20)
                TextBox.Font = Enum.Font.Gotham
                TextBox.PlaceholderText = placeholder
                TextBox.PlaceholderColor3 = GlassConfig.TextColor
                TextBox.Text = ""
                TextBox.TextColor3 = GlassConfig.NavbarHC
                TextBox.TextSize = 12
                TextBox.ZIndex = 13
                TextBox.Parent = InputFrame
                
                local TextBoxCorner = Instance.new("UICorner")
                TextBoxCorner.CornerRadius = UDim.new(0, 6)
                TextBoxCorner.Parent = TextBox
                
                TextBox.FocusLost:Connect(function(enterPressed)
                    if enterPressed and TextBox.Text ~= "" then
                        LogSystem:add("INFO", "UI", "Input submitted: " .. text)
                        pcall(callback, TextBox.Text)
                    end
                end)
                
                InputFrame.MouseEnter:Connect(function()
                    Tween(InputLabel, {TextColor3 = GlassConfig.HoverTextColor}, 0.2)
                end)
                
                InputFrame.MouseLeave:Connect(function()
                    Tween(InputLabel, {TextColor3 = GlassConfig.TextColor}, 0.2)
                end)
                
                return InputFrame
            end
            
            -- Glassmorphic label
            function Tab:AddLabel(text)
                local Label = Instance.new("TextLabel")
                Label.Name = GenerateRandomString(12)
                Label.BackgroundColor3 = GlassConfig.TertiaryColor
                Label.BorderSizePixel = 0
                Label.Size = UDim2.new(1, 0, 0, 30)
                Label.Font = Enum.Font.GothamBold
                Label.Text = text
                Label.TextColor3 = GlassConfig.TextColor
                Label.TextSize = 13
                Label.ZIndex = 12
                Label.Parent = TabContent
                
                ApplyGlassmorphicEffect(Label, GlassConfig.ButtonTransparency, false)
                
                local LabelCorner = Instance.new("UICorner")
                LabelCorner.CornerRadius = UDim.new(0, 8)
                LabelCorner.Parent = Label
                
                CreateFrameShadow(Label, GlassConfig.AccentColor, 2)
                
                return Label
            end
            
            table.insert(Library.Tabs, Tab)
            
            if #Library.Tabs == 1 then
                Tab.Active = true
                TabContent.Visible = true
                TabButton.BackgroundColor3 = GlassConfig.BorderColor
                TabButton.TextColor3 = GlassConfig.NavbarHC
            end
            
            return Tab
        end
        
        -- Glassmorphic notifications
        function Library:Notify(title, message, duration)
            duration = duration or 3
            
            local NotifContainer = Instance.new("Frame")
            NotifContainer.Name = GenerateRandomString(16)
            NotifContainer.BackgroundColor3 = GlassConfig.SecondaryColor
            NotifContainer.BorderSizePixel = 0
            NotifContainer.Position = UDim2.new(1, -320, 0, 20 + (#Library.ActiveNotifications * 95))
            NotifContainer.Size = UDim2.new(0, 300, 0, 85)
            NotifContainer.ZIndex = 1000
            NotifContainer.Parent = ScreenGui
            
            ApplyGlassmorphicEffect(NotifContainer, GlassConfig.SecondaryTransparency, false)
            
            table.insert(Library.ActiveNotifications, NotifContainer)
            
            local NotifCorner = Instance.new("UICorner")
            NotifCorner.CornerRadius = UDim.new(0, 12)
            NotifCorner.Parent = NotifContainer
            
            CreateFrameShadow(NotifContainer, Color3.fromRGB(0, 0, 0), 6)
            
            local NotifTitle = Instance.new("TextLabel")
            NotifTitle.Name = GenerateRandomString(12)
            NotifTitle.BackgroundTransparency = 1
            NotifTitle.Position = UDim2.new(0, 15, 0, 10)
            NotifTitle.Size = UDim2.new(1, -30, 0, 20)
            NotifTitle.Font = Enum.Font.GothamBold
            NotifTitle.Text = title
            NotifTitle.TextColor3 = GlassConfig.NavbarHC
            NotifTitle.TextSize = 14
            NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
            NotifTitle.ZIndex = 1001
            NotifTitle.Parent = NotifContainer
            
            local NotifMessage = Instance.new("TextLabel")
            NotifMessage.Name = GenerateRandomString(12)
            NotifMessage.BackgroundTransparency = 1
            NotifMessage.Position = UDim2.new(0, 15, 0, 32)
            NotifMessage.Size = UDim2.new(1, -30, 0, 38)
            NotifMessage.Font = Enum.Font.Gotham
            NotifMessage.Text = message
            NotifMessage.TextColor3 = GlassConfig.TextColor
            NotifMessage.TextSize = 12
            NotifMessage.TextXAlignment = Enum.TextXAlignment.Left
            NotifMessage.TextYAlignment = Enum.TextYAlignment.Top
            NotifMessage.TextWrapped = true
            NotifMessage.ZIndex = 1001
            NotifMessage.Parent = NotifContainer
            
            local TimeIndicator = Instance.new("Frame")
            TimeIndicator.Name = GenerateRandomString(12)
            TimeIndicator.BackgroundColor3 = GlassConfig.BorderColor
            TimeIndicator.BorderSizePixel = 0
            TimeIndicator.Position = UDim2.new(0, 0, 1, -3)
            TimeIndicator.Size = UDim2.new(1, 0, 0, 3)
            TimeIndicator.ZIndex = 1002
            TimeIndicator.Parent = NotifContainer
            
            Tween(TimeIndicator, {Size = UDim2.new(0, 0, 0, 3)}, duration, Enum.EasingStyle.Linear)
            
            task.spawn(function()
                task.wait(duration)
                Tween(NotifContainer, {Position = UDim2.new(1, 20, 0, NotifContainer.Position.Y.Offset)}, 0.3)
                task.wait(0.3)
                
                for i, notif in ipairs(Library.ActiveNotifications) do
                    if notif == NotifContainer then
                        table.remove(Library.ActiveNotifications, i)
                        break
                    end
                end
                
                NotifContainer:Destroy()
                
                for i, notif in ipairs(Library.ActiveNotifications) do
                    Tween(notif, {Position = UDim2.new(1, -320, 0, 20 + ((i - 1) * 95))}, 0.3)
                end
            end)
        end
        
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if not gameProcessed and input.KeyCode == GlassConfig.ToggleKey then
                Main.Visible = not Main.Visible
            end
        end)
        
        LogSystem:add("INFO", "UI", "Glassmorphic UI Library initialized successfully")
        Library:Notify("LURKOUT", "Glassmorphic UI Loaded Successfully!", 3)
        
        return Library
    end
    
    LURKOUTLib = LURKOUT:Init()
end

local Library = LURKOUTLib or {}

-- Create Setup Tab (for webhook URL input)
local SetupTab = Library:CreateTab("Setup")

local WebhookInput = SetupTab:AddInput("Discord Webhook URL", "Enter your Discord webhook URL...", function(webhookUrl)
    if webhookUrl and webhookUrl ~= "" then
        GlobalState.webhookUrl = webhookUrl
        GlobalState.isAuthenticated = true
        
        Library:Notify("Setup", "Webhook URL saved successfully!", 3)
        
        -- Test webhook
        sendDiscordWebhook(webhookUrl, {
            title = "Lurkout Loader - Setup Complete",
            description = "Webhook configured successfully!",
            color = 3066993, -- Green
            fields = {
                { name = "User", value = Players.LocalPlayer.Name, inline = true },
                { name = "Timestamp", value = os.date("!%Y-%m-%d %H:%M:%S UTC"), inline = true }
            }
        })
    end
end)

SetupTab:AddLabel("⚠️ Enter your Discord webhook URL to enable all features")

-- Main Features Tab
local FeaturesTab = Library:CreateTab("Features")

FeaturesTab:AddLabel("🔍 Scanner Features")

FeaturesTab:AddButton("Scan Game", function()
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
    Library:Notify("Scanning", "Scanning game with compact tree... This may take a moment.", 3)
    
    task.spawn(function()
        -- scanGame now returns compact text format, not JSON
        local scanData = scanGame()
        
        local success, err = sendDiscordWebhook(GlobalState.webhookUrl, {
            title = "🎮 Game Scan Results (Compact Tree)",
            description = "Complete game scan with compact workspace tree structure",
            color = 3447003, -- Blue
            fields = {
                { name = "Format", value = "Compact tree (Name (ClassName))", inline = true },
                { name = "Timestamp", value = os.date("!%Y-%m-%d %H:%M:%S UTC"), inline = true }
            }
        }, scanData)
        
        if success then
            Library:Notify("Success", "Game scan sent to Discord!", 3)
        else
            Library:Notify("Error", "Failed to send scan data: " .. tostring(err), 3)
        end
    end)
end)

FeaturesTab:AddButton("Scan Backdoors", function()
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
    Library:Notify("Scanning", "Scanning for backdoors... This may take a moment.", 3)
    
    task.spawn(function()
        local backdoors = scanBackdoors()
        local jsonData = HttpService:JSONEncode(backdoors, true)
        
        local success, err = sendDiscordWebhook(GlobalState.webhookUrl, {
            title = "🚨 Backdoor Scan Results",
            description = string.format("Found %d suspicious scripts", #backdoors),
            color = 16711680, -- Red
            fields = {
                { name = "Backdoors Found", value = tostring(#backdoors), inline = true },
                { name = "Timestamp", value = os.date("!%Y-%m-%d %H:%M:%S UTC"), inline = true }
            }
        }, jsonData)
        
        if success then
            Library:Notify("Success", "Backdoor scan sent to Discord!", 3)
        else
            Library:Notify("Error", "Failed to send scan data: " .. tostring(err), 3)
        end
    end)
end)

FeaturesTab:AddLabel("💾 Dumper Features")

FeaturesTab:AddButton("Dump Workspace", function()
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
    Library:Notify("Dumping", "Dumping workspace... This may take a moment.", 3)
    
    task.spawn(function()
        local workspaceDump = dumpWorkspace()
        
        local success, err = sendDiscordWebhook(GlobalState.webhookUrl, {
            title = "📦 Workspace Dump",
            description = "Complete workspace structure",
            color = 10181046, -- Purple
            filename = "workspace_dump.json"
        }, workspaceDump)
        
        if success then
            Library:Notify("Success", "Workspace dump sent to Discord!", 3)
        else
            Library:Notify("Error", "Failed to send dump: " .. tostring(err), 3)
        end
    end)
end)

FeaturesTab:AddButton("Dump Scripts", function()
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
    Library:Notify("Dumping", "Dumping scripts... This may take a moment.", 3)
    
    task.spawn(function()
        local scriptsDump = dumpScripts()
        
        local success, err = sendDiscordWebhook(GlobalState.webhookUrl, {
            title = "📜 Script Dump",
            description = "All scripts in the game",
            color = 15844367, -- Gold
            filename = "scripts_dump.json"
        }, scriptsDump)
        
        if success then
            Library:Notify("Success", "Script dump sent to Discord!", 3)
        else
            Library:Notify("Error", "Failed to send dump: " .. tostring(err), 3)
        end
    end)
end)

-- AI Tab
local AITab = Library:CreateTab("AI Assistant")

local AIPrompt = AITab:AddInput("AI Prompt", "Enter your prompt here...", function(prompt)
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
    if not prompt or prompt == "" then
        Library:Notify("Error", "Please enter a prompt!", 3)
        return
    end
    
    Library:Notify("Processing", "Sending prompt to DeepSeek AI...", 3)
    
    task.spawn(function()
        LogSystem:add("INFO", "AI", "Processing AI prompt from user: " .. Players.LocalPlayer.Name)
        
        local success, response, stats = callDeepSeekAPI(prompt)
        
        if success then
            -- Send AI response to Discord with detailed logs
            local fields = {
                { name = "User", value = Players.LocalPlayer.Name, inline = true },
                { name = "Timestamp", value = os.date("!%Y-%m-%d %H:%M:%S UTC"), inline = true }
            }
            
            if stats then
                table.insert(fields, { name = "Tokens", value = tostring(stats.tokens), inline = true })
                table.insert(fields, { name = "Duration", value = string.format("%.2f", stats.duration) .. "s", inline = true })
                table.insert(fields, { name = "Model", value = stats.model or "deepseek-chat", inline = true })
            end
            
            -- Include recent logs in the Discord message
            local recentLogs = LogSystem:getRecent(10)
            local logsText = ""
            for _, log in ipairs(recentLogs) do
                if log.category == "AI" then
                    logsText = logsText .. string.format("[%s] %s: %s\n", log.level, log.timestamp, log.message)
                end
            end
            
            if logsText ~= "" then
                table.insert(fields, { name = "Recent Logs", value = "```\n" .. logsText .. "```", inline = false })
            end
            
            local discordSuccess, err = sendDiscordWebhook(GlobalState.webhookUrl, {
                title = "🤖 DeepSeek AI Response",
                description = "**Prompt:**\n" .. prompt .. "\n\n**Response:**\n" .. response,
                color = 5763719, -- Green
                fields = fields
            })
            
            if discordSuccess then
                LogSystem:add("INFO", "AI", "AI response sent to Discord successfully")
                Library:Notify("Success", "AI response sent to Discord!", 3)
            else
                LogSystem:add("ERROR", "AI", "Failed to send AI response to Discord: " .. tostring(err))
                Library:Notify("Error", "Failed to send to Discord: " .. tostring(err), 3)
            end
        else
            LogSystem:add("ERROR", "AI", "AI request failed: " .. tostring(response))
            Library:Notify("Error", "AI request failed: " .. tostring(response), 3)
        end
    end)
end)

AITab:AddLabel("💡 Powered by DeepSeek AI")

-- Loader Tab (original features)
local LoaderTab = Library:CreateTab("Loader")

local function generateKey()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local key = ""
    for i = 1, 12 do
        local rand = math.random(1, #charset)
        key = key .. string.sub(charset, rand, rand)
    end
    return key
end

local userKey = generateKey()

local KeyDisplay = LoaderTab:AddInput("Pairing Key", userKey, function() end)
pcall(function()
    -- Try to make the input read-only
    for _, child in ipairs(KeyDisplay:GetDescendants()) do
        if child:IsA("TextBox") then
            child.TextEditable = false
            break
        end
    end
end)

LoaderTab:AddButton("Pair with Dashboard", function()
    -- Original pairing functionality
    Library:Notify("Pairing", "Pairing with dashboard...", 3)
    -- Add pairing logic here if needed
end)

LoaderTab:AddButton("Send Player List", function()
    if not GlobalState.isAuthenticated then
        Library:Notify("Error", "Please set webhook URL in Setup tab first!", 3)
        return
    end
    
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
    
    local playerListText = ""
    for i, player in ipairs(players) do
        playerListText = playerListText .. string.format("%d. %s (Team: %s)\n", i, player.name, player.team)
    end
    
    local success, err = sendDiscordWebhook(GlobalState.webhookUrl, {
        title = "👥 Player List",
        description = "Current players in the game",
        color = 3447003,
        fields = {
            { name = "Game", value = game_name, inline = true },
            { name = "Player Count", value = tostring(#players), inline = true },
            { name = "Players", value = playerListText ~= "" and playerListText or "No players", inline = false }
        }
    })
    
    if success then
        Library:Notify("Success", "Player list sent to Discord!", 3)
    else
        Library:Notify("Error", "Failed to send: " .. tostring(err), 3)
    end
end)

-- Initialize with comprehensive logging
LogSystem:add("INFO", "INIT", "LURKOUT Loader v3.0 - Glassmorphic Edition initialized successfully!")
LogSystem:add("INFO", "INIT", "HTTP Method: " .. (useExecutorHttp and "Executor HTTP" or "Roblox HttpService"))
LogSystem:add("INFO", "INIT", "Glassmorphic UI: Enabled")
LogSystem:add("INFO", "INIT", "Logging System: Enabled")
LogSystem:add("INFO", "INIT", "Advanced Scanning: Enabled")
LogSystem:add("INFO", "INIT", "AI Integration: Enabled")

Library:Notify("LURKOUT Loader", "Glassmorphic Loader v3.0 Loaded Successfully! Press RightControl to toggle.", 4)
print("[Lurkout] Glassmorphic Loader v3.0 initialized successfully!")
print("[Lurkout] UI Library: Embedded with glassmorphic enhancements")
print("[Lurkout] HTTP Method: " .. (useExecutorHttp and "Executor HTTP" or "Roblox HttpService"))
print("[Lurkout] Features: Advanced Scanning, Comprehensive Logging, AI Integration, Glassmorphic UI")
