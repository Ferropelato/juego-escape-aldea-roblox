local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local CraftingController = {}
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function formatIngredients(ingredients: { [string]: number }): string
	local parts = {}
	for resourceId, amount in ingredients do
		local cfg = GameConfig.Resources[resourceId]
		local name = cfg and cfg.displayName or resourceId
		table.insert(parts, name .. "×" .. tostring(amount))
	end
	table.sort(parts)
	return table.concat(parts, ", ")
end

local function canCraftRecipe(data, recipeId: string): boolean
	if not data then
		return false
	end
	if data.craftedItems[recipeId] then
		return false
	end
	local recipe = GameConfig.CraftingRecipes[recipeId]
	if not recipe then
		return false
	end
	for resourceId, need in recipe.ingredients do
		local have = data.inventory[resourceId] or 0
		if have < need then
			return false
		end
	end
	return true
end

function CraftingController.refreshRecipes()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local list = refs.recipeList
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
		layout.Padding = UDim.new(0, 6)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = list
	end

	local data = PlayerDataController.get()
	local y = 0
	local order = 0

	for recipeId, recipe in GameConfig.CraftingRecipes do
		order += 1
		local crafted = data and data.craftedItems[recipeId]
		local canCraft = canCraftRecipe(data, recipeId)

		local row = Instance.new("Frame")
		row.Name = recipeId
		row.Size = UDim2.new(1, -8, 0, 72)
		row.BackgroundColor3 = crafted and Color3.fromRGB(30, 55, 35) or Color3.fromRGB(30, 32, 40)
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -70, 0, 22)
		nameLabel.Position = UDim2.new(0, 8, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = recipe.displayName .. (crafted and " ✓" or "")
		nameLabel.TextColor3 = Color3.fromRGB(255, 230, 140)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -8, 0, 18)
		descLabel.Position = UDim2.new(0, 8, 0, 26)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = recipe.description
		descLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 11
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		local ingLabel = Instance.new("TextLabel")
		ingLabel.Size = UDim2.new(1, -70, 0, 18)
		ingLabel.Position = UDim2.new(0, 8, 0, 46)
		ingLabel.BackgroundTransparency = 1
		ingLabel.Text = formatIngredients(recipe.ingredients)
		ingLabel.TextColor3 = canCraft and Color3.fromRGB(140, 220, 140) or Color3.fromRGB(200, 140, 140)
		ingLabel.Font = Enum.Font.Gotham
		ingLabel.TextSize = 10
		ingLabel.TextXAlignment = Enum.TextXAlignment.Left
		ingLabel.TextTruncate = Enum.TextTruncate.AtEnd
		ingLabel.Parent = row

		if not crafted then
			local craftBtn = Instance.new("TextButton")
			craftBtn.Size = UDim2.new(0, 56, 0, 28)
			craftBtn.Position = UDim2.new(1, -62, 0.5, -14)
			craftBtn.BackgroundColor3 = canCraft and Color3.fromRGB(45, 110, 70) or Color3.fromRGB(60, 60, 65)
			craftBtn.BorderSizePixel = 0
			craftBtn.Text = "Craft"
			craftBtn.TextColor3 = Color3.new(1, 1, 1)
			craftBtn.Font = Enum.Font.GothamBold
			craftBtn.TextSize = 12
			craftBtn.AutoButtonColor = canCraft
			craftBtn.Parent = row

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = craftBtn

			if canCraft then
				craftBtn.MouseButton1Click:Connect(function()
					Remotes.CraftItem:FireServer(recipeId)
				end)
			end
		end

		y += 78
	end

	list.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 100))
end

function CraftingController.togglePanel()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	if refs.craftingPanel then
		refs.craftingPanel.Visible = not refs.craftingPanel.Visible
		if refs.craftingPanel.Visible then
			CraftingController.refreshRecipes()
		end
	end
end

function CraftingController.init()
	local refs = HudBuilder.ensure()

	if refs.craftButton then
		refs.craftButton.MouseButton1Click:Connect(CraftingController.togglePanel)
	end

	local closeBtn = refs.craftingPanel and refs.craftingPanel:FindFirstChild("CloseButton")
	if closeBtn and closeBtn:IsA("TextButton") then
		closeBtn.MouseButton1Click:Connect(function()
			if refs.craftingPanel then
				refs.craftingPanel.Visible = false
			end
		end)
	end

	PlayerDataController.Changed.Event:Connect(function()
		if refs.craftingPanel and refs.craftingPanel.Visible then
			CraftingController.refreshRecipes()
		end
	end)
end

return CraftingController
