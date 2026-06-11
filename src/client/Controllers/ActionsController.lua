local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local ActionsController = {}
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local DAILY_COOLDOWN = 86400

local ISLAND_ORDER = { "Island1_Tropical", "Island2_Frozen", "Island3_Desert" }

local function getNextUnlockedIsland(data): string?
	if not data or not data.unlockedIslands then
		return nil
	end

	local currentIdx = table.find(ISLAND_ORDER, data.currentIsland) or 1
	for offset = 1, #ISLAND_ORDER do
		local idx = ((currentIdx - 1 + offset) % #ISLAND_ORDER) + 1
		local islandId = ISLAND_ORDER[idx]
		if data.unlockedIslands[islandId] and islandId ~= data.currentIsland then
			return islandId
		end
	end
	return nil
end

function ActionsController.refreshIslandButton()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local btn = refs.islandButton
	if not btn then
		return
	end

	local data = PlayerDataController.get()
	btn.Visible = getNextUnlockedIsland(data) ~= nil
end

function ActionsController.refreshDailyButton()
	local refs = HudBuilder.getRefs()
	if not refs or not refs.dailyRewardButton then
		return
	end

	local data = PlayerDataController.get()
	if not data then
		return
	end

	local last = data.lastDailyClaim or 0
	local streak = data.loginStreak or 0
	local canClaim = (os.time() - last) >= DAILY_COOLDOWN

	if canClaim then
		refs.dailyRewardButton.BackgroundColor3 = Color3.fromRGB(160, 100, 20)
		refs.dailyRewardButton.Text = "🎁 Recompensa diaria (¡disponible!)"
		refs.dailyRewardButton.TextColor3 = Color3.new(1, 1, 1)
	else
		refs.dailyRewardButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		local remaining = math.ceil((DAILY_COOLDOWN - (os.time() - last)) / 3600)
		refs.dailyRewardButton.Text = "🎁 Diario (en ~" .. remaining .. "h)"
		refs.dailyRewardButton.TextColor3 = Color3.fromRGB(150, 150, 150)
	end

	if refs.streakLabel then
		if streak > 1 then
			refs.streakLabel.Text = "🔥 Racha: " .. streak .. " días consecutivos"
		else
			refs.streakLabel.Text = ""
		end
	end
end

function ActionsController.init()
	local refs = HudBuilder.ensure()

	if refs.respawnButton then
		refs.respawnButton.MouseButton1Click:Connect(function()
			Remotes.RequestRespawn:FireServer()
		end)
	end

	if refs.islandButton then
		refs.islandButton.MouseButton1Click:Connect(function()
			local data = PlayerDataController.get()
			if not data then
				return
			end
			local nextIsland = getNextUnlockedIsland(data)
			if nextIsland then
				Remotes.SelectIsland:FireServer(nextIsland)
			end
		end)
	end

	if refs.dailyRewardButton then
		refs.dailyRewardButton.MouseButton1Click:Connect(function()
			Remotes.ClaimDailyReward:FireServer()
		end)
	end

	PlayerDataController.Changed.Event:Connect(function()
		ActionsController.refreshIslandButton()
		ActionsController.refreshDailyButton()
	end)
	ActionsController.refreshIslandButton()
	ActionsController.refreshDailyButton()

	-- Re-evaluar cada minuto si el diario está disponible
	task.spawn(function()
		while true do
			task.wait(60)
			ActionsController.refreshDailyButton()
		end
	end)
end

return ActionsController
