-- Add this to the Main.ModuleList in the original main.lua (around line 168)
-- Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer","WebSync"}

-- Add this to the initialization section (around line 1505, after ModelViewer.Init())

-- WebSync Integration
local WebSync
if Main.ModuleList then
	for i, moduleName in ipairs(Main.ModuleList) do
		if moduleName == "WebSync" then
			WebSync = Apps.WebSync
			break
		end
	end
end

if WebSync then
	-- Initialize WebSync
	WebSync.Init()
	
	-- Create menu app for WebSync control
	Main.CreateApp({
		Name = "Web Connection", 
		IconMap = Main.MiscIcons, 
		Icon = "Group", 
		OnClick = function(enabled)
			if enabled then
				if not WebSync.Config.Connected then
					WebSync.PromptSessionKey()
				end
			else
				WebSync.StopSync()
			end
		end
	})
	
	-- Add console command for WebSync
	if Console then
		Console.AddCommand("websync", function(args)
			if args[1] == "connect" then
				WebSync.PromptSessionKey()
			elseif args[1] == "disconnect" then
				WebSync.StopSync()
			elseif args[1] == "status" then
				if WebSync.Config.Connected then
					print("[WebSync] Connected with key: " .. (WebSync.Config.SessionKey or "None"):sub(1, 8) .. "...")
				else
					print("[WebSync] Not connected")
				end
			elseif args[1] == "sync" then
				WebSync.SendGameTree()
				print("[WebSync] Tree data sent")
			else
				print("[WebSync] Commands: connect, disconnect, status, sync")
			end
		end)
	end
end

-- PATCH INSTRUCTIONS FOR main.lua:
-- 
-- 1. Add "WebSync" to Main.ModuleList (line 168):
--    Main.ModuleList = {"Explorer","Properties","ScriptViewer","Console","SaveInstance","ModelViewer","WebSync"}
--
-- 2. After line 1505 (ModelViewer.Init()), add the WebSync integration code above
--
-- 3. Make sure the WebSync.lua module is loaded alongside other modules