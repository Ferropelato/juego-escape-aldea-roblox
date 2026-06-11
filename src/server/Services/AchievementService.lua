local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AchievementsConfig = require(Shared.Config.AchievementsConfig)

local DataService = require(script.Parent.DataService)
local NotificationService = require(script.Parent.NotificationService)
local ChallengeService = require(script.Parent.ChallengeService)

local AchievementService = {}

function AchievementService.has(player: Player, achievementId: string): boolean
	local data = DataService.get(player)
	return data.achievements[achievementId] == true
end

function AchievementService.grant(player: Player, achievementId: string): boolean
	if AchievementService.has(player, achievementId) then
		return false
	end

	local cfg = AchievementsConfig.get(achievementId)
	if not cfg then
		return false
	end

	local data = DataService.get(player)
	data.achievements[achievementId] = true
	NotificationService.send(player, "🏆 Logro: " .. cfg.displayName, "success")
	ChallengeService.syncToClient(player)
	return true
end

function AchievementService.onResourceCollected(player: Player)
	AchievementService.grant(player, "FirstResource")

	local data = DataService.get(player)
	local types = 0
	for resourceId, amount in data.inventory do
		if amount > 0 then
			types += 1
		end
	end
	if types >= 5 then
		AchievementService.grant(player, "Collector")
	end
end

function AchievementService.onCrafted(player: Player)
	AchievementService.grant(player, "FirstCraft")
end

function AchievementService.onChallengeCompleted(player: Player, challengeId: string)
	local map = {
		BeachLanding = "BeachHero",
		JungleMaze = "JungleExplorer",
		FinalEscape = "IslandEscape",
		IceMaze = "IceMazeMaster",
		FrozenEscape = "GlacierEscape",
		SandTemple = "TempleRaider",
		DuneEscape = "DesertLegend",
	}
	local achId = map[challengeId]
	if achId then
		AchievementService.grant(player, achId)
	end

	-- Survivor: 6 zonas completadas en la sesión actual SIN morir
	local SpawnService = require(script.Parent.SpawnService)
	local sessionDeaths = SpawnService.getSessionDeaths(player)
	if sessionDeaths == 0 then
		local data = DataService.get(player)
		local completed = 0
		for _ in data.completedChallenges do
			completed += 1
		end
		if completed >= 6 then
			AchievementService.grant(player, "Survivor")
		end
	end
end

return AchievementService
