local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local NotificationService = require(script.Parent.NotificationService)
local ChallengeService = require(script.Parent.ChallengeService)

local RewardService = {}

function RewardService.grantZoneReward(player: Player, challengeId: string)
	local rewards = GameConfig.ZoneRewards and GameConfig.ZoneRewards[challengeId]
	if not rewards then
		return
	end

	local parts = {}
	for resourceId, amount in rewards do
		if amount > 0 then
			InventoryService.addResource(player, resourceId, amount)
			local cfg = GameConfig.Resources[resourceId]
			local name = cfg and cfg.displayName or resourceId
			table.insert(parts, "+" .. amount .. " " .. name)
		end
	end

	if #parts > 0 then
		NotificationService.send(player, "Recompensa: " .. table.concat(parts, ", "), "success")
	end
end

function RewardService.canClaimDaily(player: Player): boolean
	local data = DataService.get(player)
	local last = data.lastDailyClaim or 0
	return tick() - last >= (GameConfig.DailyReward.cooldown or 86400)
end

function RewardService.claimDaily(player: Player): (boolean, string?)
	if not RewardService.canClaimDaily(player) then
		return false, "Ya reclamaste hoy. Volvé mañana."
	end

	local data = DataService.get(player)
	local pool = GameConfig.DailyReward.rewards
	local pick = pool[math.random(1, #pool)]

	local parts = {}
	for resourceId, amount in pick do
		InventoryService.addResource(player, resourceId, amount)
		local cfg = GameConfig.Resources[resourceId]
		local name = cfg and cfg.displayName or resourceId
		table.insert(parts, "+" .. amount .. " " .. name)
	end

	data.lastDailyClaim = tick()
	DataService.save(player)
	ChallengeService.syncToClient(player)
	NotificationService.send(player, "🎁 Diario: " .. table.concat(parts, ", "), "success")
	return true, nil
end

return RewardService
