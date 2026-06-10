--[[
	Impide entrar a zonas futuras sin completar las anteriores (en orden).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local ChallengeService = require(script.Parent.ChallengeService)
local CheckpointService = require(script.Parent.CheckpointService)
local NotificationService = require(script.Parent.NotificationService)

local ZoneProgressionService = {}
ZoneProgressionService._entries = {} :: { { challengeId: string, part: BasePart, order: number } }

function ZoneProgressionService.canEnterZone(player: Player, challengeId: string): boolean
	local data = require(script.Parent.DataService).get(player)
	if data.completedChallenges[challengeId] then
		return true
	end
	return ChallengeService.isChallengeUnlocked(player, challengeId)
end

local function isInsidePart(pos: Vector3, part: BasePart): boolean
	local localPos = part.CFrame:PointToObjectSpace(pos)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y + 4 and math.abs(localPos.Z) <= half.Z
end

function ZoneProgressionService.registerEntry(part: BasePart, challengeId: string)
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge or challenge.order <= 1 then
		return
	end
	part:SetAttribute("ZoneChallengeId", challengeId)
	table.insert(ZoneProgressionService._entries, {
		challengeId = challengeId,
		part = part,
		order = challenge.order,
	})
end

function ZoneProgressionService._pushPlayerBack(player: Player, challengeId: string)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local challenge = GameConfig.getChallenge(challengeId)
	local name = challenge and challenge.displayName or challengeId
	NotificationService.send(player, "🔒 " .. name .. " bloqueada. Completá las zonas anteriores en orden.", "error")

	local cf = CheckpointService.getSpawnCFrame(player)
	if cf then
		hrp.CFrame = cf + Vector3.new(0, 0, 5)
	end
end

function ZoneProgressionService._checkPlayer(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end

	-- Si está en una zona bloqueada de orden alto, lo devolvemos
	local blockedId: string? = nil
	local blockedOrder = 0

	for _, entry in ZoneProgressionService._entries do
		if isInsidePart(hrp.Position, entry.part) then
			if not ZoneProgressionService.canEnterZone(player, entry.challengeId) then
				if entry.order > blockedOrder then
					blockedOrder = entry.order
					blockedId = entry.challengeId
				end
			end
		end
	end

	if blockedId then
		ZoneProgressionService._pushPlayerBack(player, blockedId)
	end
end

function ZoneProgressionService.initMap(map: Folder)
	ZoneProgressionService._entries = {}

	for _, desc in map:GetDescendants() do
		if desc:IsA("BasePart") and desc.Name == "ZoneEntry" then
			local cid = desc:GetAttribute("ZoneChallengeId")
			if cid then
				ZoneProgressionService.registerEntry(desc, cid)
			end
		end
	end
end

function ZoneProgressionService.init()
	local lastCheck = {} :: { [Player]: number }

	RunService.Heartbeat:Connect(function()
		local now = tick()
		for _, player in Players:GetPlayers() do
			if (lastCheck[player] or 0) + 0.4 > now then
				continue
			end
			lastCheck[player] = now
			ZoneProgressionService._checkPlayer(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastCheck[player] = nil
	end)
end

return ZoneProgressionService
