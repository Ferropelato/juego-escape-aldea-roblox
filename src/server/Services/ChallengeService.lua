local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local PlayerDataModule = require(Shared.Types.PlayerData)

local DataService = require(script.Parent.DataService)

local ChallengeService = {}
ChallengeService._gates = {} :: { [string]: { Instance } }

function ChallengeService.isChallengeUnlocked(player: Player, challengeId: string): boolean
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge then
		return false
	end

	local data = DataService.get(player)
	if not data.unlockedIslands[challenge.island] then
		return false
	end

	if challenge.requiredChallenge then
		if not data.completedChallenges[challenge.requiredChallenge] then
			return false
		end
	end

	if challenge.requiredCraft then
		if not data.craftedItems[challenge.requiredCraft] then
			return false
		end
	end

	return true
end

function ChallengeService.completeChallenge(player: Player, challengeId: string): (boolean, string?)
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge then
		return false, "Desafío inválido"
	end

	if not ChallengeService.isChallengeUnlocked(player, challengeId) then
		return false, "Desafío bloqueado"
	end

	local data = DataService.get(player)
	if data.completedChallenges[challengeId] then
		return false, "Ya completado"
	end

	data.completedChallenges[challengeId] = true
	data.currentChallenge = challengeId
	data.lastCheckpoint = challenge.checkpointId

	if challenge.completesIsland then
		ChallengeService._unlockNextIsland(player, challenge.island)
	end

	local islandChallenges = GameConfig.getChallengesForIsland(challenge.island)
	for _, ch in islandChallenges do
		if ch.order == challenge.order + 1 then
			data.currentChallenge = ch.id
			break
		end
	end

	ChallengeService.updateGatesForPlayer(player)
	return true, challenge.displayName
end

function ChallengeService._unlockNextIsland(player: Player, completedIslandId: string)
	local data = DataService.get(player)
	for islandId, island in GameConfig.Islands do
		if island.requiredIsland == completedIslandId then
			data.unlockedIslands[islandId] = true
		end
	end
end

function ChallengeService.unlockChallengeGate(player: Player, challengeId: string)
	ChallengeService.updateGatesForPlayer(player)
end

function ChallengeService.registerGate(challengeId: string, gatePart: Instance)
	ChallengeService._gates[challengeId] = ChallengeService._gates[challengeId] or {}
	table.insert(ChallengeService._gates[challengeId], gatePart)
end

function ChallengeService.updateGatesForPlayer(player: Player)
	local data = DataService.get(player)
	for challengeId, gates in ChallengeService._gates do
		local unlocked = ChallengeService.isChallengeUnlocked(player, challengeId)
		for _, gate in gates do
			if gate:IsA("BasePart") then
				gate.CanCollide = not unlocked
				gate.Transparency = unlocked and 0.85 or 0.3
			end
		end
	end
end

function ChallengeService.syncToClient(player: Player)
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local data = DataService.get(player)
	Remotes.SyncPlayerData:FireClient(player, PlayerDataModule.serializeForClient(data))
end

function ChallengeService.completeAndSync(player: Player, challengeId: string): (boolean, string?)
	local ok, name = ChallengeService.completeChallenge(player, challengeId)
	if ok then
		DataService.save(player)
		ChallengeService.syncToClient(player)
		local ObjectiveService = require(script.Parent.ObjectiveService)
		ObjectiveService.syncObjectives(player)
	end
	return ok, name
end

return ChallengeService
