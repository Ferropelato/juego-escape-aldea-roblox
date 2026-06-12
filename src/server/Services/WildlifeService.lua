--[[
	Animales ambientales: algunos pasivos, otros agresivos.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local WildlifeService = {}
WildlifeService._creatures = {} :: { {
	model: Model,
	aggressive: boolean,
	home: Vector3,
	waypoints: { Vector3 },
	wpIndex: number,
	speed: number,
} }

local function bindDamage(part: BasePart, damage: number)
	local damageCooldown: { [Model]: number } = {}
	part.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end
		local now = tick()
		if not damageCooldown[char] or now - damageCooldown[char] >= 1 then
			damageCooldown[char] = now
			hum:TakeDamage(damage)
		end
	end)
end

function WildlifeService.createCreature(
	parent: Instance,
	position: Vector3,
	kind: string,
	aggressive: boolean,
	waypoints: { Vector3 }?
)
	local colors = {
		Parrot = Color3.fromRGB(220, 60, 60),
		Monkey = Color3.fromRGB(120, 80, 50),
		Boar = Color3.fromRGB(70, 55, 45),
		Crab = Color3.fromRGB(180, 80, 70),
		Turtle = Color3.fromRGB(80, 120, 70),
	}
	local sizes = {
		Parrot = Vector3.new(2.2, 1.6, 2.4),
		Monkey = Vector3.new(2.5, 2.2, 2.8),
		Boar = Vector3.new(3.2, 2.2, 4.2),
		Crab = Vector3.new(2.4, 1.2, 2.6),
		Turtle = Vector3.new(2.8, 1.4, 3.2),
	}

	local model = Instance.new("Model")
	model.Name = kind .. "_Wild"

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = sizes[kind] or Vector3.new(2.5, 2, 3)
	body.Color = colors[kind] or Color3.fromRGB(100, 100, 100)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Position = position
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = body.Size * 0.55
	head.Color = body.Color:Lerp(Color3.new(1, 1, 1), 0.08)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = body.CFrame * CFrame.new(0, body.Size.Y * 0.35, -body.Size.Z * 0.35)
	head.Parent = model

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Health = aggressive and 80 or 40
	hum.MaxHealth = hum.Health
	hum.Parent = model

	model.PrimaryPart = body
	model.Parent = parent

	if aggressive then
		bindDamage(body, 12)
	end

	local wps = waypoints or { position, position + Vector3.new(12, 0, 0), position + Vector3.new(-8, 0, 10) }
	table.insert(WildlifeService._creatures, {
		model = model,
		aggressive = aggressive,
		home = position,
		waypoints = wps,
		wpIndex = 1,
		speed = aggressive and 11 or 5,
	})

	return model
end

function WildlifeService.init()
	-- Cada criatura tiene su propio timer para limitar frecuencia de búsqueda de target
	local PASSIVE_TICK = 0.1    -- 10 Hz para criaturas pasivas
	local AGGRESSIVE_TARGET_TICK = 0.5  -- Re-busca target cada 0.5s (no 60/s)
	local CHASE_RADIUS = 28  -- reducido: solo persigue de cerca

	for _, creature in WildlifeService._creatures do
		creature._moveTimer = 0
		creature._targetTimer = 0
		creature._cachedTarget = nil :: Vector3?
	end

	RunService.Heartbeat:Connect(function(dt)
		local now = tick()
		for _, creature in WildlifeService._creatures do
			local model = creature.model
			local body = model and model.PrimaryPart
			if not body or not body.Parent then
				continue
			end

			creature._moveTimer = (creature._moveTimer or 0) + dt

			-- Pasivas: actualizar solo a 10 Hz
			local tickRate = creature.aggressive and 0 or PASSIVE_TICK
			if creature._moveTimer < tickRate then
				continue
			end
			creature._moveTimer = 0

			local targetPos: Vector3

			if creature.aggressive then
				-- Re-buscar target solo cada 0.5s
				creature._targetTimer = (creature._targetTimer or 0) + dt
				if creature._targetTimer >= AGGRESSIVE_TARGET_TICK or not creature._cachedTarget then
					creature._targetTimer = 0
					local nearest: Player? = nil
					local nearestDist = CHASE_RADIUS
					for _, player in Players:GetPlayers() do
						local char = player.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
						if hrp then
							local d = (hrp.Position - body.Position).Magnitude
							if d < nearestDist then
								nearestDist = d
								nearest = player
							end
						end
					end
					if nearest then
						local char = nearest.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
						creature._cachedTarget = hrp and hrp.Position or nil
					else
						creature._cachedTarget = nil
					end
				end

				if creature._cachedTarget then
					targetPos = creature._cachedTarget
				else
					local wp = creature.waypoints[creature.wpIndex]
					targetPos = wp
					if (body.Position - wp).Magnitude < 4 then
						creature.wpIndex = (creature.wpIndex % #creature.waypoints) + 1
					end
				end
			else
				local wp = creature.waypoints[creature.wpIndex]
				targetPos = wp
				if (body.Position - wp).Magnitude < 3 then
					creature.wpIndex = (creature.wpIndex % #creature.waypoints) + 1
				end
			end

			local effectiveDt = creature.aggressive and dt or PASSIVE_TICK
			local flat = Vector3.new(targetPos.X - body.Position.X, 0, targetPos.Z - body.Position.Z)
			if flat.Magnitude > 0.5 then
				local step = flat.Unit * creature.speed * effectiveDt
				body.CFrame = CFrame.lookAt(body.Position + step, body.Position + step + flat.Unit)
				if model:FindFirstChild("Head") then
					model.Head.CFrame = body.CFrame * CFrame.new(0, body.Size.Y * 0.35, -body.Size.Z * 0.35)
				end
			end
		end
	end)
end

function WildlifeService.populateIsland(map: Folder)
	local island = map:FindFirstChild("Island1_Tropical")
	if not island then
		return
	end

	local wildlifeFolder = Instance.new("Folder")
	wildlifeFolder.Name = "Wildlife"
	wildlifeFolder.Parent = island

	-- Playa: cangrejos y tortugas pasivos
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(30, 6, -20), "Crab", false, {
		Vector3.new(30, 6, -20),
		Vector3.new(45, 6, -15),
		Vector3.new(20, 6, -30),
	})
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(-25, 6, 10), "Turtle", false, {
		Vector3.new(-25, 6, 10),
		Vector3.new(-10, 6, 18),
		Vector3.new(-35, 6, 22),
	})

	-- Selva: monos pasivos cerca del laberinto, fuera de sus muros
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(130, 9, 100), "Monkey", false, {
		Vector3.new(130, 9, 100),
		Vector3.new(145, 9, 115),
		Vector3.new(118, 9, 120),
	})
	-- Jabalíes reubicados al área del RÍO (X>350), lejos del laberinto (X:90-310)
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(355, 6, 55), "Boar", true, {
		Vector3.new(355, 6, 55),
		Vector3.new(370, 6, 40),
		Vector3.new(340, 6, 65),
	})
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(380, 6, -30), "Boar", true, {
		Vector3.new(380, 6, -30),
		Vector3.new(395, 6, -15),
		Vector3.new(365, 6, -45),
	})

	-- Loros volando bajo (caminan rápido)
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(180, 12, 80), "Parrot", false, {
		Vector3.new(180, 12, 80),
		Vector3.new(210, 12, 95),
		Vector3.new(195, 12, 60),
		Vector3.new(165, 12, 70),
	})

	-- Zona persecución: jabalí extra agresivo
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(400, 10, 340), "Boar", true, {
		Vector3.new(400, 10, 340),
		Vector3.new(420, 10, 360),
		Vector3.new(385, 10, 370),
	})
end

return WildlifeService
