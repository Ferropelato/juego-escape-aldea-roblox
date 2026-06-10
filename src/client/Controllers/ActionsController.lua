local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local ActionsController = {}
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

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

	PlayerDataController.Changed.Event:Connect(ActionsController.refreshIslandButton)
	ActionsController.refreshIslandButton()
end

return ActionsController
