--[[
	WebSync Module
	
	Handles communication between Dex Explorer and the LURKOUT LITE web interface
	Uses HTTP requests for polling-based communication
]]

-- Common Locals
local Main, Lib, Apps, Settings
local Explorer, Properties, ScriptViewer, ModelViewer, Notebook
local API, RMD, env, service, plr, create, createSimple

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	ModelViewer = Apps.ModelViewer
	Notebook = Apps.Notebook
end

local function main()
	local WebSync = {}
	local HttpService = game:GetService("HttpService")
	local RunService = game:GetService("RunService")
	
	-- Configuration
	WebSync.Config = {
		BaseURL = "https://lurkout.app/api", -- Change this to your actual domain
		PollInterval = 2, -- seconds
		SessionKey = nil,
		Connected = false,
		LastSync = 0
	}
	
	-- Session state
	local sessionData = {
		treeCache = {},
		selectedObject = nil,
		connectionStatus = "Disconnected"
	}
	
	-- Prompts the user to enter their session key
	WebSync.PromptSessionKey = function()
		local keyWindow = Lib.Window.new()
		keyWindow:SetTitle("LURKOUT LITE - Enter Session Key")
		keyWindow:Resize(400, 150)
		
		local container = Instance.new("Frame")
		container.Parent = keyWindow.GuiElems.Content
		container.Size = UDim2.new(1, 0, 1, 0)
		container.BackgroundTransparency = 1
		
		local label = Lib.Label.new()
		label.Gui.Parent = container
		label.Gui.Position = UDim2.new(0, 10, 0, 10)
		label.Gui.Size = UDim2.new(1, -20, 0, 30)
		label.Gui.Text = "Enter your session key from the LURKOUT LITE website:"
		label.Gui.TextWrapped = true
		label.Gui.TextXAlignment = Enum.TextXAlignment.Left
		
		local textBox = Lib.ViewportTextBox.new()
		textBox.Gui.Parent = container
		textBox.Gui.Position = UDim2.new(0, 10, 0, 50)
		textBox.Gui.Size = UDim2.new(1, -20, 0, 30)
		textBox.TextBox.PlaceholderText = "Enter key here..."
		textBox.TextBox.ClearTextOnFocus = false
		
		local connectBtn = Instance.new("TextButton")
		connectBtn.Parent = container
		connectBtn.Position = UDim2.new(0, 10, 0, 90)
		connectBtn.Size = UDim2.new(0.48, -5, 0, 35)
		connectBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		connectBtn.BorderSizePixel = 0
		connectBtn.Text = "Connect"
		connectBtn.TextColor3 = Color3.new(1, 1, 1)
		connectBtn.Font = Enum.Font.SourceSans
		connectBtn.TextSize = 16
		
		local cancelBtn = Instance.new("TextButton")
		cancelBtn.Parent = container
		cancelBtn.Position = UDim2.new(0.52, 5, 0, 90)
		cancelBtn.Size = UDim2.new(0.48, -5, 0, 35)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		cancelBtn.BorderSizePixel = 0
		cancelBtn.Text = "Cancel"
		cancelBtn.TextColor3 = Color3.new(1, 1, 1)
		cancelBtn.Font = Enum.Font.SourceSans
		cancelBtn.TextSize = 16
		
		connectBtn.MouseButton1Click:Connect(function()
			local key = textBox.TextBox.Text
			if key and key ~= "" then
				WebSync.Config.SessionKey = key
				keyWindow:Hide()
				WebSync.StartSync()
				
				-- Save key for future sessions
				if env.writefile then
					env.writefile("dex/websync_key.dat", key)
				end
			end
		end)
		
		cancelBtn.MouseButton1Click:Connect(function()
			keyWindow:Hide()
		end)
		
		keyWindow:Show()
	end
	
	-- Load saved session key
	WebSync.LoadSessionKey = function()
		if env.readfile and env.isfile and env.isfile("dex/websync_key.dat") then
			local success, key = pcall(env.readfile, "dex/websync_key.dat")
			if success and key and key ~= "" then
				WebSync.Config.SessionKey = key
				return true
			end
		end
		return false
	end
	
	-- HTTP Request wrapper with error handling
	local function safeRequest(options)
		local success, result = pcall(function()
			return HttpService:RequestAsync(options)
		end)
		
		if success and result.Success then
			return true, result.Body
		else
			return false, (result and result.StatusMessage) or "Request failed"
		end
	end
	
	-- Send game tree data to web interface
	WebSync.SendGameTree = function()
		if not WebSync.Config.Connected or not WebSync.Config.SessionKey then
			return false
		end
		
		local treeData = {}
		local rootServices = {
			game:GetService("Workspace"),
			game:GetService("Players"),
			game:GetService("Lighting"),
			game:GetService("ReplicatedStorage"),
			game:GetService("ReplicatedFirst"),
			game:GetService("StarterGui"),
			game:GetService("StarterPlayer"),
			game:GetService("StarterPack"),
			game:GetService("Teams")
		}
		
		local function buildNode(obj, depth)
			if depth > 10 then return nil end -- Limit depth to prevent huge payloads
			
			local nodeData = {
				Name = obj.Name,
				ClassName = obj.ClassName,
				Path = obj:GetFullName(),
				Children = {}
			}
			
			if depth < 3 then -- Only expand first few levels
				for _, child in ipairs(obj:GetChildren()) do
					local childNode = buildNode(child, depth + 1)
					if childNode then
						table.insert(nodeData.Children, childNode)
					end
				end
			end
			
			return nodeData
		end
		
		for _, service in ipairs(rootServices) do
			table.insert(treeData, buildNode(service, 0))
		end
		
		local jsonData = HttpService:JSONEncode({
			type = "tree_update",
			sessionKey = WebSync.Config.SessionKey,
			placeId = game.PlaceId,
			placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
			tree = treeData,
			timestamp = os.time()
		})
		
		local success, response = safeRequest({
			Url = WebSync.Config.BaseURL .. "/sync",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Session-Key"] = WebSync.Config.SessionKey
			},
			Body = jsonData
		})
		
		return success, response
	end
	
	-- Send connection status
	WebSync.SendStatus = function(status)
		if not WebSync.Config.SessionKey then return end
		
		local jsonData = HttpService:JSONEncode({
			type = "status",
			sessionKey = WebSync.Config.SessionKey,
			status = status,
			executor = identifyexecutor and ({identifyexecutor()})[1] or "Unknown",
			placeId = game.PlaceId,
			timestamp = os.time()
		})
		
		safeRequest({
			Url = WebSync.Config.BaseURL .. "/sync",
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Session-Key"] = WebSync.Config.SessionKey
			},
			Body = jsonData
		})
	end
	
	-- Poll for commands from web interface
	WebSync.PollCommands = function()
		if not WebSync.Config.Connected or not WebSync.Config.SessionKey then
			return
		end
		
		local success, response = safeRequest({
			Url = WebSync.Config.BaseURL .. "/commands?key=" .. HttpService:UrlEncode(WebSync.Config.SessionKey),
			Method = "GET",
			Headers = {
				["Session-Key"] = WebSync.Config.SessionKey
			}
		})
		
		if success then
			local data = HttpService:JSONDecode(response)
			if data.commands then
				for _, command in ipairs(data.commands) do
					WebSync.ExecuteCommand(command)
				end
			end
		end
	end
	
	-- Execute commands from web interface
	WebSync.ExecuteCommand = function(command)
		if command.type == "refresh_tree" then
			WebSync.SendGameTree()
		elseif command.type == "select_object" then
			local success, obj = pcall(function()
				return game:FindFirstChild(command.path, true)
			end)
			if success and obj then
				if nodes[obj] then
					selection:Set(nodes[obj])
					Explorer.ViewNode(nodes[obj])
				end
			end
		elseif command.type == "scan_game" then
			WebSync.SendGameTree()
		end
	end
	
	-- Main sync loop
	local syncConnection
	WebSync.StartSync = function()
		if not WebSync.Config.SessionKey then
			WebSync.PromptSessionKey()
			return
		end
		
		WebSync.Config.Connected = true
		sessionData.connectionStatus = "Connected"
		
		-- Send initial connection status
		WebSync.SendStatus("connected")
		
		-- Send initial tree data
		task.spawn(function()
			task.wait(1)
			WebSync.SendGameTree()
		end)
		
		-- Start polling loop
		if syncConnection then
			syncConnection:Disconnect()
		end
		
		syncConnection = RunService.Heartbeat:Connect(function()
			local currentTime = tick()
			if currentTime - WebSync.Config.LastSync >= WebSync.Config.PollInterval then
				WebSync.Config.LastSync = currentTime
				WebSync.PollCommands()
			end
		end)
		
		-- Update status indicator
		print("[LURKOUT LITE] WebSync connected with key: " .. WebSync.Config.SessionKey:sub(1, 8) .. "...")
	end
	
	-- Stop sync
	WebSync.StopSync = function()
		WebSync.Config.Connected = false
		sessionData.connectionStatus = "Disconnected"
		
		if syncConnection then
			syncConnection:Disconnect()
			syncConnection = nil
		end
		
		WebSync.SendStatus("disconnected")
		print("[LURKOUT LITE] WebSync disconnected")
	end
	
	-- Initialize
	WebSync.Init = function()
		-- Try to load saved session key
		if WebSync.LoadSessionKey() then
			print("[LURKOUT LITE] Loaded saved session key")
			-- Auto-connect after a short delay
			task.spawn(function()
				task.wait(2)
				WebSync.StartSync()
			end)
		end
		
		-- Add menu option to connect/disconnect
		-- This would integrate with the Dex menu system
	end
	
	return WebSync
end

-- Export module
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end