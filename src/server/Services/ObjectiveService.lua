local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local PlayerDataModule = require(Shared.Types.PlayerData)

local DataService = require(script.Parent.DataService)
local ChallengeService = require(script.Parent.ChallengeService)
local NotificationService = require(script.Parent.NotificationService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local ObjectiveService = {}
ObjectiveService._progress = {} :: { [Player]: { [string]: any } }

local function getProgress(player: Player, challengeId: string)
	ObjectiveService._progress[player] = ObjectiveService._progress[player] or {}
	if not ObjectiveService._progress[player][challengeId] then
		ObjectiveService._progress[player][challengeId] = {
			collected = {},
			reachedFinish = false,
			signsRead = 0,
		}
	end
	return ObjectiveService._progress[player][challengeId]
end

function ObjectiveService.getObjectives(challengeId: string)
	local challenge = GameConfig.getChallenge(challengeId)
	return challenge and challenge.objectives
end

function ObjectiveService.buildStatus(player: Player, challengeId: string)
	local objectives = ObjectiveService.getObjectives(challengeId)
	if not objectives then
		return nil
	end

	local prog = getProgress(player, challengeId)
	local lines = {}
	local allDone = true

	for i, obj in objectives do
		local done = false
		local text = obj.text or "?"

		if obj.type == "collect" then
			local have = prog.collected[obj.resource] or 0
			local need = obj.amount or 1
			done = have >= need
			text = string.format("%s (%d/%d)", text, have, need)
		elseif obj.type == "reach" then
			done = prog.reachedFinish
		elseif obj.type == "signs" then
			local need = obj.amount or 5
			local have = prog.signsRead or 0
			done = have >= need
			text = string.format("%s (%d/%d)", text, have, need)
		end

		if not done then
			allDone = false
		end
		table.insert(lines, {
			index = i,
			text = text,
			done = done,
		})
	end

	return {
		challengeId = challengeId,
		lines = lines,
		allComplete = allDone,
		description = GameConfig.getChallenge(challengeId).description,
	}
end

function ObjectiveService.syncObjectives(player: Player)
	local data = DataService.get(player)
	local challengeId = data.currentChallenge
	local status = ObjectiveService.buildStatus(player, challengeId)
	if status then
		Remotes.SyncObjectives:FireClient(player, status)
	end
end

function ObjectiveService.onResourceCollected(player: Player, resourceId: string, amount: number)
	local data = DataService.get(player)
	local challengeId = data.currentChallenge
	local objectives = ObjectiveService.getObjectives(challengeId)
	if not objectives then
		return
	end

	local prog = getProgress(player, challengeId)
	prog.collected[resourceId] = (prog.collected[resourceId] or 0) + (amount or 1)

	ObjectiveService.syncObjectives(player)
	ObjectiveService.tryCompleteChallenge(player, challengeId)
end

function ObjectiveService.onSignRead(player: Player, signIndex: number)
	local data = DataService.get(player)
	local challengeId = data.currentChallenge
	if challengeId ~= "JungleMaze" then
		return
	end

	local objectives = ObjectiveService.getObjectives(challengeId)
	if not objectives then
		return
	end

	local prog = getProgress(player, challengeId)
	local expected = (prog.signsRead or 0) + 1
	if signIndex ~= expected then
		NotificationService.send(player, "Seguí las señales en orden: buscá la " .. expected, "error")
		return
	end

	prog.signsRead = signIndex
	NotificationService.send(player, "Señal " .. signIndex .. " ✓ — seguí al " .. (signIndex + 1), "success")
	ObjectiveService.syncObjectives(player)
	ObjectiveService.tryCompleteChallenge(player, challengeId)
end

function ObjectiveService.onReachFinish(player: Player, challengeId: string)
	local prog = getProgress(player, challengeId)
	prog.reachedFinish = true
	ObjectiveService.syncObjectives(player)
	ObjectiveService.tryCompleteChallenge(player, challengeId)
end

function ObjectiveService.tryCompleteChallenge(player: Player, challengeId: string)
	local status = ObjectiveService.buildStatus(player, challengeId)
	if not status or not status.allComplete then
		if status and status.lines[#status.lines] and getProgress(player, challengeId).reachedFinish then
			NotificationService.send(player, "Completá todos los objetivos antes de avanzar", "error")
		end
		return
	end

	local data = DataService.get(player)
	if data.completedChallenges[challengeId] then
		return
	end

	local ok, name = ChallengeService.completeChallenge(player, challengeId)
	if ok then
		NotificationService.send(player, "¡Zona completada: " .. name .. "! El puente se abrió →", "success")
		ChallengeService.updateGatesForPlayer(player)
		ObjectiveService.syncObjectives(player)
		ChallengeService.syncToClient(player)
	end
end

function ObjectiveService.initMap(map: Folder)
	for _, zone in map:GetDescendants() do
		if zone:IsA("BasePart") and zone.Name == "Finish" then
			local zoneFolder = zone.Parent
			local challengeId = zoneFolder and zoneFolder.Name
			local challenge = challengeId and GameConfig.getChallenge(challengeId)
			if challenge and challenge.objectives then
				zone.Touched:Connect(function(hit)
					local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
					if not plr then
						return
					end
					local data = DataService.get(plr)
					if data.currentChallenge ~= challengeId and not data.completedChallenges[challengeId] then
						return
					end
					ObjectiveService.onReachFinish(plr, challengeId)
				end)
			end
		end
	end
end

game.Players.PlayerRemoving:Connect(function(player)
	ObjectiveService._progress[player] = nil
end)

return ObjectiveService
