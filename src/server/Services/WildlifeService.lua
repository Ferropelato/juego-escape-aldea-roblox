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
	part.Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
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
	RunService.Heartbeat:Connect(function(dt)
		for _, creature in WildlifeService._creatures do
			local model = creature.model
			local body = model and model.PrimaryPart
			if not body or not body.Parent then
				continue
			end

			local targetPos: Vector3

			if creature.aggressive then
				local nearest: Player? = nil
				local nearestDist = 55
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
					if hrp then
						targetPos = hrp.Position
					else
						targetPos = creature.waypoints[creature.wpIndex]
					end
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

			local flat = Vector3.new(targetPos.X - body.Position.X, 0, targetPos.Z - body.Position.Z)
			if flat.Magnitude > 0.5 then
				local step = flat.Unit * creature.speed * dt
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

	-- Selva / laberinto: monos pasivos + jabalíes agresivos afuera del laberinto
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(130, 9, 100), "Monkey", false, {
		Vector3.new(130, 9, 100),
		Vector3.new(145, 9, 115),
		Vector3.new(118, 9, 120),
	})
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(260, 9, 180), "Boar", true, {
		Vector3.new(260, 9, 180),
		Vector3.new(275, 9, 195),
		Vector3.new(248, 9, 200),
	})
	WildlifeService.createCreature(wildlifeFolder, Vector3.new(285, 9, 120), "Boar", true, {
		Vector3.new(285, 9, 120),
		Vector3.new(300, 9, 135),
		Vector3.new(270, 9, 140),
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
