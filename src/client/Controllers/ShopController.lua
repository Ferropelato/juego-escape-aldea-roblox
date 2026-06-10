local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationConfig = require(Shared.Config.MonetizationConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local ShopController = {}
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local player = Players.LocalPlayer

local function promptGamepass(passCfg)
	if passCfg.gamePassId <= 0 then
		return false, "Configurá el Gamepass ID en MonetizationConfig (Studio)"
	end
	MarketplaceService:PromptGamePassPurchase(player, passCfg.gamePassId)
	return true
end

local function promptProduct(productCfg)
	if productCfg.productId <= 0 then
		return false, "Configurá el Product ID en MonetizationConfig (Studio)"
	end
	MarketplaceService:PromptProductPurchase(player, productCfg.productId)
	return true
end

function ShopController.refreshShop()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local list = refs.shopList
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
	local order = 0

	local function addSection(title: string)
		order += 1
		local label = Instance.new("TextLabel")
		label.Name = "Section_" .. title
		label.Size = UDim2.new(1, -8, 0, 22)
		label.BackgroundTransparency = 1
		label.Text = title
		label.TextColor3 = Color3.fromRGB(255, 220, 120)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.LayoutOrder = order
		label.Parent = list
	end

	local function addItem(cfg, itemType: string, owned: boolean?)
		order += 1
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 64)
		row.BackgroundColor3 = Color3.fromRGB(30, 32, 40)
		row.BorderSizePixel = 0
		row.LayoutOrder = order
		row.Parent = list

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -80, 0, 20)
		nameLabel.Position = UDim2.new(0, 8, 0, 6)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = (cfg.icon or "") .. " " .. cfg.displayName .. (owned and " ✓" or "")
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 13
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -8, 0, 28)
		descLabel.Position = UDim2.new(0, 8, 0, 26)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = cfg.description
		descLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 10
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = row

		if not owned then
			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0, 56, 0, 26)
			buyBtn.Position = UDim2.new(1, -62, 0.5, -13)
			buyBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 70)
			buyBtn.BorderSizePixel = 0
			buyBtn.Text = cfg.priceRobux .. " R$"
			buyBtn.TextColor3 = Color3.new(1, 1, 1)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 11
			buyBtn.Parent = row
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 6)
			bc.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function()
				if itemType == "gamepass" then
					promptGamepass(cfg)
				else
					promptProduct(cfg)
				end
			end)
		end
	end

	addSection("— Gamepasses —")
	for _, pass in MonetizationConfig.Gamepasses do
		local owned = false
		if pass.id == "VipExplorer" and data and data.entitlements then
			owned = data.entitlements.vip
		elseif pass.id == "TrailMaster" and data and data.entitlements then
			owned = data.entitlements.trails
		end
		addItem(pass, "gamepass", owned)
	end

	addSection("— Productos —")
	for _, product in MonetizationConfig.DeveloperProducts do
		addItem(product, "product", false)
	end

	addSection("— Rastros cosméticos —")
	local ent = data and data.entitlements
	local canTrails = ent and (ent.trails or ent.vip)
	if canTrails then
		for trailId, trail in MonetizationConfig.Trails do
			if trailId == "none" then
				continue
			end
			order += 1
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, -8, 0, 28)
			btn.BackgroundColor3 = Color3.fromRGB(40, 55, 75)
			btn.BorderSizePixel = 0
			btn.Text = "Rastro: " .. trail.displayName
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 12
			btn.LayoutOrder = order
			btn.Parent = list
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent = btn
			btn.MouseButton1Click:Connect(function()
				Remotes.SetCosmetic:FireServer(trailId)
			end)
		end
	else
		order += 1
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.new(1, -8, 0, 24)
		hint.BackgroundTransparency = 1
		hint.Text = "Comprá Maestro de rastros o VIP"
		hint.TextColor3 = Color3.fromRGB(140, 140, 140)
		hint.Font = Enum.Font.Gotham
		hint.TextSize = 11
		hint.LayoutOrder = order
		hint.Parent = list
	end

	addSection("— Recompensa diaria —")
	order += 1
	local dailyBtn = Instance.new("TextButton")
	dailyBtn.Size = UDim2.new(1, -8, 0, 32)
	dailyBtn.BackgroundColor3 = Color3.fromRGB(70, 55, 100)
	dailyBtn.BorderSizePixel = 0
	dailyBtn.Text = "🎁 Reclamar recompensa diaria"
	dailyBtn.TextColor3 = Color3.new(1, 1, 1)
	dailyBtn.Font = Enum.Font.GothamBold
	dailyBtn.TextSize = 12
	dailyBtn.LayoutOrder = order
	dailyBtn.Parent = list
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 6)
	dc.Parent = dailyBtn
	dailyBtn.MouseButton1Click:Connect(function()
		Remotes.ClaimDailyReward:FireServer()
	end)

	list.CanvasSize = UDim2.new(0, 0, 0, order * 72 + 40)
end

function ShopController.togglePanel()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	if refs.shopPanel then
		refs.shopPanel.Visible = not refs.shopPanel.Visible
		if refs.shopPanel.Visible then
			ShopController.refreshShop()
		end
	end
end

function ShopController.init()
	local refs = HudBuilder.ensure()

	if refs.shopButton then
		refs.shopButton.MouseButton1Click:Connect(ShopController.togglePanel)
	end

	local closeBtn = refs.shopPanel and refs.shopPanel:FindFirstChild("CloseButton")
	if closeBtn and closeBtn:IsA("TextButton") then
		closeBtn.MouseButton1Click:Connect(function()
			if refs.shopPanel then
				refs.shopPanel.Visible = false
			end
		end)
	end

	PlayerDataController.Changed.Event:Connect(function()
		if refs.shopPanel and refs.shopPanel.Visible then
			ShopController.refreshShop()
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, _id, purchased)
		if plr == player and purchased then
			task.delay(1, function()
				Remotes.RequestSync:FireServer()
			end)
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(plr, _id, purchased)
		if plr == player and purchased then
			task.delay(1, function()
				Remotes.RequestSync:FireServer()
			end)
		end
	end)
end

return ShopController
