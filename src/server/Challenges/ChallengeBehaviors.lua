--[[
	Comportamientos activos por zona: persecución, dodge, lava, etc.
	Se inician cuando el jugador entra en la zona del desafío.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)

local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local NotificationService = require(script.Parent.Parent.Services.NotificationService)
local DataService = require(script.Parent.Parent.Services.DataService)

local ChallengeBehaviors = {}
ChallengeBehaviors._active = {} :: { [Player]: string? }

local function getPlayersInZone(zonePart: BasePart): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			local localPos = zonePart.CFrame:PointToObjectSpace(hrp.Position)
			local half = zonePart.Size / 2
			if math.abs(localPos.X) <= half.X and math.abs(localPos.Y) <= half.Y and math.abs(localPos.Z) <= half.Z then
				table.insert(list, player)
			end
		end
	end
	return list
end

-- Solo aplica desafíos activos a quien está EN esa zona de progreso
local function getPlayersInActiveChallenge(zonePart: BasePart, challengeId: string): { Player }
	local list = {}
	for _, player in getPlayersInZone(zonePart) do
		local data = DataService.get(player)
		if data.currentChallenge == challengeId then
			table.insert(list, player)
		end
	end
	return list
end

function ChallengeBehaviors.startChase(zoneFolder: Folder, challengeId: string)
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge then
		return
	end

	local zoneBounds = zoneFolder:FindFirstChild("ZoneBounds") :: BasePart?
	if not zoneBounds then
		return
	end

	local guard = zoneFolder:FindFirstChild("ChaseGuard") :: BasePart?
	if not guard then
		guard = Instance.new("Part")
		guard.Name = "ChaseGuard"
		guard.Size = Vector3.new(5, 7, 5)
		guard.Color = Color3.fromRGB(120, 20, 20)
		guard.Material = Enum.Material.Neon
		guard.Anchored = true
		guard.CanCollide = false
		local spawn = zoneFolder:FindFirstChild("Spawn") :: BasePart?
		local basePos = spawn and spawn.Position or zoneBounds.Position
		guard.Position = basePos + Vector3.new(25, 5, 10)
		guard.Parent = zoneFolder
	end

	local speed = GameConfig.DifficultyScaling.chaseSpeed(challenge.order)
	local safeZone = zoneFolder:FindFirstChild("SafeZone") :: BasePart?

	RunService.Heartbeat:Connect(function(dt)
		for _, player in getPlayersInActiveChallenge(zoneBounds, challengeId) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?
				if hrp and hum and hum.Health > 0 then
				local dir = (hrp.Position - guard.Position)
				if dir.Magnitude > 0.1 then
					dir = dir.Unit
					guard.Position += Vector3.new(dir.X, 0, dir.Z) * speed * dt
				end

				if (hrp.Position - guard.Position).Magnitude < 5 then
					hum:TakeDamage(25 * GameConfig.DifficultyScaling.damageMultiplier(challenge.order))
				end

				if safeZone then
					local localPos = safeZone.CFrame:PointToObjectSpace(hrp.Position)
					local half = safeZone.Size / 2
					if math.abs(localPos.X) <= half.X and math.abs(localPos.Z) <= half.Z then
						local data = DataService.get(player)
						if not data.completedChallenges[challengeId] then
							local ok = ChallengeService.completeAndSync(player, challengeId)
							if ok then
								NotificationService.send(player, "¡Escapaste de la persecución!", "success")
							end
						end
					end
				end
			end
		end
	end)
end

function ChallengeBehaviors.startDodge(zone: BasePart, challengeId: string)
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge then
		return
	end

	local interval = GameConfig.DifficultyScaling.dodgeInterval(challenge.order)

	task.spawn(function()
		while zone.Parent do
			for _, player in getPlayersInActiveChallenge(zone, challengeId) do
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local projectile = Instance.new("Part")
					projectile.Size = Vector3.new(2, 2, 2)
					projectile.Shape = Enum.PartType.Ball
					projectile.Color = Color3.fromRGB(255, 100, 0)
					projectile.Material = Enum.Material.Neon
					projectile.Anchored = true
					projectile.CanCollide = false
					projectile.Position = hrp.Position + Vector3.new(math.random(-20, 20), 25, math.random(-5, 5))
					projectile.Parent = workspace

					local target = hrp.Position
					local start = projectile.Position
					local duration = 1.2
					local elapsed = 0

					local conn
					conn = RunService.Heartbeat:Connect(function(dt)
						elapsed += dt
						local alpha = math.min(elapsed / duration, 1)
						projectile.Position = start:Lerp(target, alpha)
						if (projectile.Position - hrp.Position).Magnitude < 3 then
							local hum = char:FindFirstChild("Humanoid")
							if hum then
								hum:TakeDamage(15 * GameConfig.DifficultyScaling.damageMultiplier(challenge.order))
							end
						end
						if alpha >= 1 then
							conn:Disconnect()
							projectile:Destroy()
						end
					end)
					Debris:AddItem(projectile, 2)
				end
			end
			task.wait(interval)
		end
	end)
end

function ChallengeBehaviors.startLavaDamage(zone: BasePart, challengeId: string)
	local challenge = GameConfig.getChallenge(challengeId)
	if not challenge then
		return
	end

	for _, part in zone:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "Lava" or part:GetAttribute("IsLava")) then
			part.Touched:Connect(function(hit)
				local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
				if hum then
					hum:TakeDamage(20 * GameConfig.DifficultyScaling.damageMultiplier(challenge.order))
				end
			end)
		end
	end
end

function ChallengeBehaviors.bindZones(map: Folder)
	for _, island in map:GetChildren() do
		if not island:IsA("Folder") then
			continue
		end
		local zones = island:FindFirstChild("Zones")
		if not zones then
			continue
		end

		for _, zoneFolder in zones:GetChildren() do
			local zonePart = zoneFolder:FindFirstChild("ZoneBounds") :: BasePart?
			if not zonePart then
				continue
			end
			local challengeId = zoneFolder.Name
			local challenge = GameConfig.getChallenge(challengeId)
			if not challenge then
				continue
			end

			if challenge.puzzleType == "Chase" then
				ChallengeBehaviors.startChase(zoneFolder, challengeId)
			elseif challenge.puzzleType == "Dodge" then
				ChallengeBehaviors.startDodge(zonePart, challengeId)
			elseif challenge.puzzleType == "Climb" or challenge.puzzleType == "LavaMaze" then
				ChallengeBehaviors.startLavaDamage(zoneFolder, challengeId)
			end

			-- Zonas sin lista de objetivos: el Finish completa directo
			if not challenge.objectives then
				local finish = zoneFolder:FindFirstChild("Finish") :: BasePart?
				if finish then
					finish.Touched:Connect(function(hit)
						local player = Players:GetPlayerFromCharacter(hit.Parent)
						if not player then
							return
						end
						local data = DataService.get(player)
						if data.currentChallenge ~= challengeId or data.completedChallenges[challengeId] then
							return
						end
						local ok = ChallengeService.completeAndSync(player, challengeId)
						if ok then
							NotificationService.send(player, "¡Zona superada!", "success")
						end
					end)
				end
			end
		end
	end
end

return ChallengeBehaviors
