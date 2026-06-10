local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.Parent.Services.DataService)
local CraftingService = require(script.Parent.Parent.Services.CraftingService)
local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local CheckpointService = require(script.Parent.Parent.Services.CheckpointService)
local SpawnService = require(script.Parent.Parent.Services.SpawnService)
local NotificationService = require(script.Parent.Parent.Services.NotificationService)

local ObjectiveService = require(script.Parent.Parent.Services.ObjectiveService)
local MonetizationService = require(script.Parent.Parent.Services.MonetizationService)
local RewardService = require(script.Parent.Parent.Services.RewardService)

local RemoteHandlers = {}

function RemoteHandlers.init()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")

	Remotes.RequestSync.OnServerEvent:Connect(function(player)
		MonetizationService.refreshEntitlements(player)
		ChallengeService.syncToClient(player)
		ObjectiveService.syncObjectives(player)
	end)

	Remotes.CraftItem.OnServerEvent:Connect(function(player, recipeId: string)
		if type(recipeId) ~= "string" or not GameConfig.CraftingRecipes[recipeId] then
			return
		end
		local ok, result = CraftingService.craft(player, recipeId)
		if ok then
			NotificationService.send(player, "Crafteaste: " .. result, "success")
			DataService.save(player)
		else
			NotificationService.send(player, result or "No se pudo craftear", "error")
		end
		ChallengeService.syncToClient(player)
	end)

	Remotes.RequestRespawn.OnServerEvent:Connect(function(player)
		local usedToken = MonetizationService.tryUseReviveToken(player)
		if not usedToken then
			local cooldown = MonetizationService.getRespawnCooldown(player)
			local last = player:GetAttribute("LastRespawn") or 0
			if tick() - last < cooldown then
				NotificationService.send(player, "Esperá un momento antes de reaparecer", "error")
				return
			end
		end
		player:SetAttribute("LastRespawn", tick())

		if player.Character then
			player.Character:BreakJoints()
		end
		task.wait(0.3)
		SpawnService.spawnPlayer(player, false)
		NotificationService.send(player, "Reapareciste en el último checkpoint", "info")
	end)

	Remotes.SelectIsland.OnServerEvent:Connect(function(player, islandId: string)
		if type(islandId) ~= "string" then
			return
		end
		local data = DataService.get(player)
		if not data.unlockedIslands[islandId] then
			NotificationService.send(player, "Isla bloqueada", "error")
			return
		end
		local island = GameConfig.getIsland(islandId)
		if not island then
			return
		end
		data.currentIsland = islandId
		data.currentChallenge = island.spawnZone
		local AchievementService = require(script.Parent.Parent.Services.AchievementService)
		if islandId == "Island2_Frozen" then
			AchievementService.grant(player, "FrozenArrival")
		elseif islandId == "Island3_Desert" then
			AchievementService.grant(player, "DesertArrival")
		end
		NotificationService.send(player, "Viajaste a: " .. island.displayName, "success")
		SpawnService.spawnPlayer(player, false)
		DataService.save(player)
		ChallengeService.syncToClient(player)
		ObjectiveService.syncObjectives(player)
	end)

	Remotes.SetCosmetic.OnServerEvent:Connect(function(player, trailId: string)
		MonetizationService.setCosmetic(player, trailId)
	end)

	Remotes.ClaimDailyReward.OnServerEvent:Connect(function(player)
		local ok, err = RewardService.claimDaily(player)
		if not ok then
			NotificationService.send(player, err or "No disponible", "error")
		end
	end)
end

return RemoteHandlers
