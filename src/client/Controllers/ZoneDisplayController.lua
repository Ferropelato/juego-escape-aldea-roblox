--[[
	Etiqueta top-center que muestra zona activa.
	Usa AnchorPoint(0.5, 0) para centrado real en cualquier resolución.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local PlayerDataController = require(script.Parent.PlayerDataController)

local player = Players.LocalPlayer
local ZoneDisplayController = {}

function ZoneDisplayController.ensureLabel()
	local gui = player.PlayerGui:FindFirstChild("EscapeIslandHUD") or player.PlayerGui:FindFirstChild("GameUI")
	if not gui then return nil end
	local label = gui:FindFirstChild("ZoneHint")
	if label then return label end

	label = Instance.new("TextLabel")
	label.Name = "ZoneHint"
	-- Centrado real: ancla en 0.5,0 y posición relativa
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Size = UDim2.new(0.45, 0, 0, 30)
	label.Position = UDim2.new(0.5, 0, 0, 8)
	label.BackgroundColor3 = Color3.fromRGB(15, 25, 20)
	label.BackgroundTransparency = 0.3
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextScaled = false
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = ""
	label.ZIndex = 5
	label.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = label

	return label
end

function ZoneDisplayController.update()
	local label = ZoneDisplayController.ensureLabel()
	if not label then return end

	local data = PlayerDataController.get()
	if not data or not data.currentChallenge then
		label.Visible = false
		return
	end

	local challenge = GameConfig.getChallenge(data.currentChallenge)
	if challenge then
		label.Visible = true
		label.Text = string.format("📍 %s  ·  Dific. %d", challenge.displayName, challenge.difficulty)
	else
		label.Visible = false
	end
end

function ZoneDisplayController.init()
	PlayerDataController.Changed.Event:Connect(function()
		ZoneDisplayController.update()
	end)
	ZoneDisplayController.update()
end

return ZoneDisplayController
