--[[
	Notificaciones apiladas en top-center.
	El contenedor usa UIListLayout para evitar solapamientos.
	Máximo 4 notificaciones simultáneas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationController = {}

local MAX_NOTIFS = 4
local NOTIF_H = 42
local NOTIF_GAP = 6

local COLORS = {
	info     = Color3.fromRGB(50, 50, 60),
	success  = Color3.fromRGB(30, 100, 60),
	error    = Color3.fromRGB(120, 40, 40),
	resource = Color3.fromRGB(80, 70, 30),
}

local function getContainer()
	local screenGui = playerGui:FindFirstChild("EscapeIslandHUD") or playerGui:FindFirstChild("GameUI")
	if not screenGui then return nil end
	local c = screenGui:FindFirstChild("NotificationContainer")
	if not c then return nil end

	-- Asegurar UIListLayout (idempotente)
	if not c:FindFirstChildOfClass("UIListLayout") then
		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, NOTIF_GAP)
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.Parent = c
	end
	return c
end

function NotificationController.show(message: string, kind: string?)
	local container = getContainer()
	if not container then return end

	-- Descartar si ya hay muchas
	local active = 0
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then active += 1 end
	end
	if active >= MAX_NOTIFS then return end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, NOTIF_H)
	frame.BackgroundColor3 = COLORS[kind] or COLORS.info
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = os.clock() * 1000 -- orden de inserción
	frame.BackgroundTransparency = 1      -- empieza invisible
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = frame

	-- Fade in
	local fadeIn = TweenService:Create(frame, TweenInfo.new(0.25), {
		BackgroundTransparency = 0.1,
	})
	fadeIn:Play()

	-- Auto-dismiss tras 4s con fade out
	task.delay(4, function()
		if not frame.Parent then return end
		local fadeOut = TweenService:Create(frame, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
		})
		fadeOut:Play()
		fadeOut.Completed:Wait()
		frame:Destroy()
	end)
end

function NotificationController.init()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	Remotes.ShowNotification.OnClientEvent:Connect(function(message, kind)
		NotificationController.show(message, kind)
	end)
end

return NotificationController
