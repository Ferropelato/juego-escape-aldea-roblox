local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AchievementsConfig = require(Shared.Config.AchievementsConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local AchievementController = {}

function AchievementController.refreshPanel()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local list = refs.achievementList
	if not list then
		return
	end

	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") and child.Name ~= "UIListLayout" then
			child:Destroy()
		end
	end

	local layout = list:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
	end

	local data = PlayerDataController.get()
	local y = 0
	local order = 0

	for _, ach in AchievementsConfig.getAllSorted() do
		order += 1
		local unlocked = data and data.achievements and data.achievements[ach.id]

		local row = Instance.new("Frame")
		row.Name = ach.id
		row.Size = UDim2.new(1, -8, 0, 48)
		row.BackgroundColor3 = unlocked and Color3.fromRGB(35, 50, 40) or Color3.fromRGB(28, 30, 36)
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = row

		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 36, 1, 0)
		icon.BackgroundTransparency = 1
		icon.Text = unlocked and ach.icon or "🔒"
		icon.TextSize = 22
		icon.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -44, 0, 22)
		nameLabel.Position = UDim2.new(0, 40, 0, 4)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = ach.displayName
		nameLabel.TextColor3 = unlocked and Color3.fromRGB(255, 230, 140) or Color3.fromRGB(120, 120, 120)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -44, 0, 18)
		descLabel.Position = UDim2.new(0, 40, 0, 24)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = ach.description
		descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 10
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		y += 52
	end

	list.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 100))

	if refs.achievementCount then
		local total = 0
		local unlocked = 0
		for _, ach in AchievementsConfig.getAllSorted() do
			total += 1
			if data and data.achievements and data.achievements[ach.id] then
				unlocked += 1
			end
		end
		refs.achievementCount.Text = unlocked .. "/" .. total
	end
end

function AchievementController.togglePanel()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	if refs.achievementPanel then
		refs.achievementPanel.Visible = not refs.achievementPanel.Visible
		if refs.achievementPanel.Visible then
			AchievementController.refreshPanel()
		end
	end
end

function AchievementController.init()
	local refs = HudBuilder.ensure()

	if refs.achievementButton then
		refs.achievementButton.MouseButton1Click:Connect(AchievementController.togglePanel)
	end

	local closeBtn = refs.achievementPanel and refs.achievementPanel:FindFirstChild("CloseButton")
	if closeBtn and closeBtn:IsA("TextButton") then
		closeBtn.MouseButton1Click:Connect(function()
			if refs.achievementPanel then
				refs.achievementPanel.Visible = false
			end
		end)
	end

	PlayerDataController.Changed.Event:Connect(function()
		AchievementController.refreshPanel()
	end)
end

return AchievementController
