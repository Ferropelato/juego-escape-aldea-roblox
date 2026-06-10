local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local UIController = {}
local player = Players.LocalPlayer

function UIController.refreshInventory()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local invFrame = refs.inventoryFrame
	if not invFrame then
		return
	end

	for _, child in invFrame:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local data = PlayerDataController.get()
	local y = 4
	local count = 0

	if data and data.inventory then
		for resourceId, amount in data.inventory do
			local cfg = GameConfig.Resources[resourceId]
			if cfg and amount > 0 then
				count += 1
				local label = Instance.new("TextLabel")
				label.Size = UDim2.new(1, -8, 0, 22)
				label.Position = UDim2.new(0, 4, 0, y)
				label.BackgroundTransparency = 1
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.Text = cfg.icon .. "  " .. cfg.displayName .. "  ×" .. tostring(amount)
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
				label.Font = Enum.Font.GothamBold
				label.TextSize = 14
				label.Parent = invFrame
				y += 24
			end
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -8, 0, 40)
		empty.Position = UDim2.new(0, 4, 0, 4)
		empty.BackgroundTransparency = 1
		empty.Text = "Vacío — pulsa E en objetos brillantes"
		empty.TextColor3 = Color3.fromRGB(160, 160, 160)
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 12
		empty.TextWrapped = true
		empty.Parent = invFrame
		y = 44
	end

	invFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 50))
end

function UIController.refreshProgress()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local progressLabel = refs.progressLabel
	if not progressLabel then
		return
	end

	local data = PlayerDataController.get()
	if not data then
		progressLabel.Text = "Conectando..."
		return
	end

	local challenge = GameConfig.getChallenge(data.currentChallenge)
	local island = GameConfig.getIsland(data.currentIsland)
	local completed = 0
	for _ in data.completedChallenges do
		completed += 1
	end

	progressLabel.Text = string.format(
		"%s\n%s\nZonas listas: %d",
		island and island.displayName or "?",
		challenge and challenge.displayName or "?",
		completed
	)
end

function UIController.refreshAll()
	UIController.refreshInventory()
	UIController.refreshProgress()
end

function UIController.init()
	HudBuilder.ensure()
	UIController.refreshAll()

	PlayerDataController.Changed.Event:Connect(function()
		UIController.refreshAll()
	end)

	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	task.delay(0.5, function()
		Remotes.RequestSync:FireServer()
	end)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		Remotes.RequestSync:FireServer()
		UIController.refreshAll()
	end)
end

return UIController
