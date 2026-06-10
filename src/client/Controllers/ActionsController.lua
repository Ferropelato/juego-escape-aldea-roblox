local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local HudBuilder = require(script.Parent.HudBuilder)
local PlayerDataController = require(script.Parent.PlayerDataController)

local ActionsController = {}
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

function ActionsController.refreshIslandButton()
	local refs = HudBuilder.getRefs() or HudBuilder.ensure()
	local btn = refs.islandButton
	if not btn then
		return
	end

	local data = PlayerDataController.get()
	local hasUnlocked = false
	if data and data.unlockedIslands then
		for islandId, unlocked in data.unlockedIslands do
			if unlocked and islandId ~= data.currentIsland then
				hasUnlocked = true
				break
			end
		end
	end
	btn.Visible = hasUnlocked
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
			for islandId, unlocked in data.unlockedIslands do
				if unlocked and islandId ~= data.currentIsland then
					local island = GameConfig.getIsland(islandId)
					if island then
						Remotes.SelectIsland:FireServer(islandId)
						return
					end
				end
			end
		end)
	end

	PlayerDataController.Changed.Event:Connect(ActionsController.refreshIslandButton)
	ActionsController.refreshIslandButton()
end

return ActionsController
