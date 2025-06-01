-- Universal ServerHop GUI with selectable options and "More coming soon" text
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local PLACE_ID = game.PlaceId

local guiVisible = true
local selectedOption = nil -- store user-selected serverhop strategy

-- GUI setup
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "ServerHopUniversalGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 270) -- extra height for "More coming soon"
frame.Position = UDim2.new(0.5, -150, 0.5, -135)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Visible = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 120, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 10)
toggleBtn.Text = "Toggle GUI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

toggleBtn.MouseButton1Click:Connect(function()
	guiVisible = not guiVisible
	frame.Visible = guiVisible
end)

-- ServerHop Button
local serverHopBtn = Instance.new("TextButton", frame)
serverHopBtn.Size = UDim2.new(1, -20, 0, 40)
serverHopBtn.Position = UDim2.new(0, 10, 0, 10)
serverHopBtn.Text = "ServerHop"
serverHopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
serverHopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", serverHopBtn).CornerRadius = UDim.new(0, 8)

-- Dropdown Toggle
local dropdownBtn = Instance.new("TextButton", frame)
dropdownBtn.Size = UDim2.new(1, -20, 0, 30)
dropdownBtn.Position = UDim2.new(0, 10, 0, 60)
dropdownBtn.Text = "Advanced Options ▼"
dropdownBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)

local optionsFrame = Instance.new("Frame", frame)
optionsFrame.Size = UDim2.new(1, -20, 0, 130)
optionsFrame.Position = UDim2.new(0, 10, 0, 100)
optionsFrame.BackgroundTransparency = 1
optionsFrame.Visible = false

dropdownBtn.MouseButton1Click:Connect(function()
	optionsFrame.Visible = not optionsFrame.Visible
	dropdownBtn.Text = optionsFrame.Visible and (selectedOption and selectedOption.name.." ▲" or "Advanced Options ▲") or (selectedOption and selectedOption.name.." ▼" or "Advanced Options ▼")
end)

-- More Coming Soon text
local comingSoonLabel = Instance.new("TextLabel", frame)
comingSoonLabel.Size = UDim2.new(1, -20, 0, 25)
comingSoonLabel.Position = UDim2.new(0, 10, 0, 235)
comingSoonLabel.BackgroundTransparency = 1
comingSoonLabel.Text = "More coming soon..."
comingSoonLabel.Font = Enum.Font.SourceSansItalic
comingSoonLabel.TextSize = 18
comingSoonLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
comingSoonLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Server Fetch
local function getServers()
	local servers = {}
	local cursor = ""
	repeat
		local url = "https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder=Asc&limit=100&cursor="..cursor
		local success, response = pcall(function()
			return HttpService:JSONDecode(game:HttpGet(url))
		end)
		if success and response and response.data then
			for _, server in ipairs(response.data) do
				if server.playing < server.maxPlayers and server.id ~= game.JobId then
					table.insert(servers, server)
				end
			end
			cursor = response.nextPageCursor or ""
		else
			break
		end
		wait(0.2)
	until cursor == ""
	return servers
end

-- Server option behaviors
local function hopOldest()
	local servers = getServers()
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[1].id, LocalPlayer)
	end
end

local function hopNewest()
	local servers = getServers()
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[#servers].id, LocalPlayer)
	end
end

local function hopMostPlayers()
	local servers = getServers()
	table.sort(servers, function(a, b) return a.playing > b.playing end)
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[1].id, LocalPlayer)
	end
end

local function hopLeastPlayers()
	local servers = getServers()
	table.sort(servers, function(a, b) return a.playing < b.playing end)
	if #servers > 0 then
		TeleportService:TeleportToPlaceInstance(PLACE_ID, servers[1].id, LocalPlayer)
	end
end

-- Create selectable options
local function createOptionBtn(name, func, yPos)
	local btn = Instance.new("TextButton", optionsFrame)
	btn.Size = UDim2.new(1, 0, 0, 25)
	btn.Position = UDim2.new(0, 0, 0, yPos)
	btn.Text = name
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
	btn.MouseButton1Click:Connect(function()
		selectedOption = { name = name, execute = func }
		dropdownBtn.Text = name.." ▼"
		optionsFrame.Visible = false
	end)
end

createOptionBtn("Oldest Server", hopOldest, 0)
createOptionBtn("Newest Server", hopNewest, 30)
createOptionBtn("Most Players (Not Full)", hopMostPlayers, 60)
createOptionBtn("Least Players", hopLeastPlayers, 90)

-- ServerHop behavior
serverHopBtn.MouseButton1Click:Connect(function()
	if selectedOption and selectedOption.execute then
		selectedOption.execute()
	else
		-- Default random hop
		local servers = getServers()
		if #servers > 0 then
			local rand = servers[math.random(1, #servers)]
			TeleportService:TeleportToPlaceInstance(PLACE_ID, rand.id, LocalPlayer)
		end
	end
end)
