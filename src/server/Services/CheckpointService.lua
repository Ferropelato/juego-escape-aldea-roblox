local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local DataService = require(script.Parent.DataService)

local CheckpointService = {}

function CheckpointService.saveCheckpoint(player: Player, checkpointId: string, position: Vector3?, challengeId: string?)
	local data = DataService.get(player)

	if challengeId then
		local challenge = GameConfig.getChallenge(challengeId)
		if not challenge then
			return
		end
		local current = GameConfig.getChallenge(data.currentChallenge)
		local currentOrder = current and current.order or 1
		-- No guardar checkpoints de zonas futuras (evita saltar a "Persecución" al caminar)
		if challenge.order > currentOrder and not data.completedChallenges[challengeId] then
			return
		end
	end

	data.lastCheckpoint = checkpointId
	data.lastCheckpointPosition = position
	-- currentChallenge solo cambia al completar objetivos, no al tocar checkpoints
end

function CheckpointService.getSpawnCFrame(player: Player): CFrame?
	local data = DataService.get(player)

	if data.lastCheckpointPosition then
		return CFrame.new(data.lastCheckpointPosition + Vector3.new(0, 4, 0))
	end

	local map = Workspace:FindFirstChild("EscapeIsland")
	if not map then
		return CFrame.new(0, 10, 0)
	end

	local islandFolder = map:FindFirstChild(data.currentIsland)
	if not islandFolder then
		islandFolder = map:FindFirstChild("Island1_Tropical")
	end

	if data.lastCheckpoint and islandFolder then
		local cpFolder = islandFolder:FindFirstChild("Checkpoints")
		if cpFolder then
			local cp = cpFolder:FindFirstChild(data.lastCheckpoint)
			if cp and cp:IsA("BasePart") then
				return cp.CFrame + Vector3.new(0, 4, 0)
			end
		end
	end

	local challenge = GameConfig.getChallenge(data.currentChallenge)
	if challenge and islandFolder then
		local zones = islandFolder:FindFirstChild("Zones")
		if zones then
			local zone = zones:FindFirstChild(challenge.id)
			if zone then
				local spawn = zone:FindFirstChild("Spawn")
				if spawn and spawn:IsA("BasePart") then
					return spawn.CFrame + Vector3.new(0, 4, 0)
				end
			end
		end
	end

	return CFrame.new(0, 15, 0)
end

function CheckpointService.bindCheckpointParts()
	local map = Workspace:WaitForChild("EscapeIsland", 30)
	if not map then
		return
	end

	for _, islandFolder in map:GetChildren() do
		if not islandFolder:IsA("Folder") then
			continue
		end
		local cpFolder = islandFolder:FindFirstChild("Checkpoints")
		if not cpFolder then
			continue
		end

		for _, part in cpFolder:GetChildren() do
			if part:IsA("BasePart") then
				part.CanTouch = true
				part.Transparency = 0.6
				part.Anchored = true

				local challengeId = part:GetAttribute("ChallengeId")
				local checkpointId = part.Name

				part.Touched:Connect(function(hit)
					local character = hit.Parent
					local player = game.Players:GetPlayerFromCharacter(character)
					if not player then
						return
					end
					CheckpointService.saveCheckpoint(
						player,
						checkpointId,
						part.Position,
						challengeId
					)
				end)
			end
		end
	end
end

return CheckpointService
