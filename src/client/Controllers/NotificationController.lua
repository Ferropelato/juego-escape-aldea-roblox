local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationController = {}

local COLORS = {
	info = Color3.fromRGB(50, 50, 60),
	success = Color3.fromRGB(30, 100, 60),
	error = Color3.fromRGB(120, 40, 40),
	resource = Color3.fromRGB(80, 70, 30),
}

function NotificationController.show(message: string, kind: string?)
	local screenGui = playerGui:FindFirstChild("EscapeIslandHUD") or playerGui:FindFirstChild("GameUI")
	if not screenGui then
		return
	end
	local container = screenGui:FindFirstChild("NotificationContainer")
	if not container then
		return
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.5, 0, 0, 40)
	frame.Position = UDim2.new(0.25, 0, 0, -50)
	frame.BackgroundColor3 = COLORS[kind] or COLORS.info
	frame.BorderSizePixel = 0
	frame.Parent = container

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextScaled = true
	label.Parent = frame

	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.3), { Position = UDim2.new(0.25, 0, 0, 10 + #container:GetChildren() * 45) })
	tweenIn:Play()

	task.delay(4, function()
		local tweenOut = TweenService:Create(frame, TweenInfo.new(0.3), { Position = UDim2.new(0.25, 0, 0, -50) })
		tweenOut:Play()
		tweenOut.Completed:Wait()
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
