--[[
	Generador procedural de decoración para Escape Island.
	Palmeras, rocas, vegetación, volcán, ruinas, etc.
]]

local PropGenerator = {}

-- RNG determinista por semilla (mismo mapa cada vez)
local function rng(seed: number)
	local state = seed % 2147483647
	return function(min: number?, max: number?): number
		state = (state * 1103515245 + 12345) % 2147483647
		local v = state / 2147483647
		if min and max then
			return min + v * (max - min)
		end
		return v
	end
end

local function part(props: {
	name: string?,
	size: Vector3,
	cframe: CFrame?,
	position: Vector3?,
	color: Color3?,
	material: Enum.Material?,
	shape: Enum.PartType?,
	parent: Instance,
	anchored: boolean?,
	canCollide: boolean?,
	transparency: number?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Size = props.size
	if props.cframe then
		p.CFrame = props.cframe
	elseif props.position then
		p.Position = props.position
	end
	p.Color = props.color or Color3.fromRGB(128, 128, 128)
	p.Material = props.material or Enum.Material.SmoothPlastic
	p.Shape = props.shape or Enum.PartType.Block
	p.Anchored = props.anchored ~= false
	p.CanCollide = props.canCollide ~= false
	p.Transparency = props.transparency or 0
	p.Parent = props.parent
	return p
end

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function PropGenerator.decoFolder(zoneFolder: Instance): Folder
	local existing = zoneFolder:FindFirstChild("Decorations")
	if existing then
		return existing
	end
	return folder(zoneFolder, "Decorations")
end

-- ─── Palmera ───────────────────────────────────────────────
function PropGenerator.palmTree(parent: Instance, position: Vector3, scale: number?, seed: number?)
	local rand = rng(seed or math.floor(position.X * 7 + position.Z * 13))
	local s = scale or (0.85 + rand() * 0.4)
	local model = folder(parent, "PalmTree")

	local trunkH = 14 * s
	part({
		name = "Trunk",
		size = Vector3.new(2.2 * s, trunkH, 2.2 * s),
		position = position + Vector3.new(0, trunkH / 2, 0),
		color = Color3.fromRGB(110, 75, 45),
		material = Enum.Material.Wood,
		parent = model,
	})

	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2 + rand(-0.2, 0.2)
		local len = 10 * s
		local base = position + Vector3.new(0, trunkH - 1, 0)
		local offset = Vector3.new(math.cos(angle) * len * 0.5, 2 * s, math.sin(angle) * len * 0.5)
		part({
			name = "Leaf",
			size = Vector3.new(2 * s, 0.6 * s, len),
			cframe = CFrame.new(base + offset) * CFrame.Angles(0, angle, math.rad(25)),
			color = Color3.fromRGB(35, 120, 50),
			material = Enum.Material.Grass,
			parent = model,
			canCollide = false,
		})
	end

	-- Plataforma para pararse en la copa (delgada, hojas arriba sin bloquear)
	part({
		name = "CanopyStand",
		size = Vector3.new(6 * s, 0.45 * s, 6 * s),
		position = position + Vector3.new(0, trunkH + 0.25 * s, 0),
		color = Color3.fromRGB(40, 115, 52),
		material = Enum.Material.Grass,
		parent = model,
	})

	-- Cocos opcionales
	if rand() > 0.6 then
		part({
			name = "Coconut",
			size = Vector3.new(1.2 * s, 1.2 * s, 1.2 * s),
			shape = Enum.PartType.Ball,
			position = position + Vector3.new(rand(-1, 1), trunkH - 2, rand(-1, 1)),
			color = Color3.fromRGB(80, 55, 30),
			material = Enum.Material.Wood,
			parent = model,
		})
	end

	return model
end

-- Palmera escalable: escalera en espiral (podés moverte a los costados mientras subís)
function PropGenerator.climbablePalmTree(
	parent: Instance,
	position: Vector3,
	scale: number?,
	resourceId: string?,
	seed: number?
)
	local s = scale or 1
	local model = folder(parent, "ClimbablePalm")
	local trunkH = 11 * s
	local platformTop = trunkH + 2.5 * s
	local platformThickness = 0.45 * s

	part({
		name = "Trunk",
		size = Vector3.new(2.2 * s, trunkH, 2.2 * s),
		position = position + Vector3.new(0, trunkH / 2, 0),
		color = Color3.fromRGB(110, 75, 45),
		material = Enum.Material.Wood,
		parent = model,
	})

	-- Escalera en espiral: cada peldaño desplazado en ángulo → movimiento lateral al subir
	local stepCount = 14
	local stepTop = platformTop - platformThickness - 0.5 * s
	local startAngle = -math.pi / 2
	local sweepAngle = math.pi * 1.45
	local stepRadius = 3.6 * s
	local stepSize = 4.8 * s

	for i = 0, stepCount do
		local t = i / stepCount
		local y = 0.9 * s + t * (stepTop - 0.9 * s)
		local angle = startAngle + t * sweepAngle
		local x = math.cos(angle) * stepRadius
		local z = math.sin(angle) * stepRadius
		part({
			name = "ClimbStep_" .. i,
			size = Vector3.new(stepSize, 0.38 * s, stepSize),
			position = position + Vector3.new(x, y, z),
			color = Color3.fromRGB(100, 70, 40),
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
	end

	-- Tramo final ancho hacia la plataforma (aterrizaje cómodo)
	part({
		name = "ClimbLanding",
		size = Vector3.new(6 * s, 0.38 * s, 6 * s),
		position = position + Vector3.new(2.8 * s, platformTop - platformThickness - 0.15 * s, 1.2 * s),
		color = Color3.fromRGB(95, 68, 38),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})

	-- Plataforma delgada, amplia y despejada arriba
	part({
		name = "CanopyPlatform",
		size = Vector3.new(11 * s, platformThickness, 11 * s),
		position = position + Vector3.new(0, platformTop - platformThickness / 2, 0),
		color = Color3.fromRGB(50, 140, 60),
		material = Enum.Material.Grass,
		parent = model,
	})

	-- Barandilla baja (sin bloquear movimiento ni cabeza)
	for _, offset in { Vector3.new(5 * s, 0.6 * s, 0), Vector3.new(-5 * s, 0.6 * s, 0), Vector3.new(0, 0.6 * s, 5 * s), Vector3.new(0, 0.6 * s, -5 * s) } do
		part({
			name = "Railing",
			size = Vector3.new(0.25 * s, 1.2 * s, 5 * s),
			position = position + offset + Vector3.new(0, platformTop + 0.6 * s, 0),
			color = Color3.fromRGB(90, 60, 35),
			material = Enum.Material.Wood,
			parent = model,
			canCollide = false,
		})
	end

	-- Hojas decorativas MUY arriba (sin colisión)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		part({
			name = "TopLeaf",
			size = Vector3.new(2 * s, 0.35 * s, 5 * s),
			cframe = CFrame.new(position + Vector3.new(0, platformTop + 9 * s, 0)) * CFrame.Angles(0, angle, math.rad(22)),
			color = Color3.fromRGB(35, 120, 50),
			material = Enum.Material.Grass,
			parent = model,
			canCollide = false,
		})
	end

	if resourceId then
		local res = part({
			name = "Resource_" .. resourceId,
			size = Vector3.new(2.5, 2.5, 2.5),
			position = position + Vector3.new(0, platformTop + 1.8 * s, 0),
			color = Color3.fromRGB(255, 220, 80),
			material = Enum.Material.Neon,
			parent = model,
			canCollide = false,
		})
		res:SetAttribute("ResourceId", resourceId)
		res:SetAttribute("Amount", 1)
	end

	return model, platformTop
end

-- ─── Roca ──────────────────────────────────────────────────
function PropGenerator.rock(parent: Instance, position: Vector3, scale: number?, style: string?, seed: number?)
	local rand = rng(seed or 42)
	local s = scale or rand(0.6, 1.8)
	local model = folder(parent, "Rock")

	local styles = {
		gray = { Color3.fromRGB(110, 108, 105), Enum.Material.Rock },
		moss = { Color3.fromRGB(85, 100, 75), Enum.Material.Grass },
		volcanic = { Color3.fromRGB(55, 48, 45), Enum.Material.Basalt },
		sand = { Color3.fromRGB(180, 165, 130), Enum.Material.Sandstone },
	}
	local st = styles[style or "gray"] or styles.gray

	local mainSize = Vector3.new(4 * s, 3 * s, 3.5 * s)
	part({
		name = "Main",
		size = mainSize,
		position = position + Vector3.new(0, mainSize.Y / 2 - 0.5, 0),
		color = st[1],
		material = st[2],
		parent = model,
		cframe = CFrame.new(position + Vector3.new(0, mainSize.Y / 2, 0))
			* CFrame.Angles(rand(-0.15, 0.15), rand(0, math.pi * 2), rand(-0.2, 0.2)),
	})

	for i = 1, math.floor(rand(1, 3)) do
		local subS = s * rand(0.3, 0.6)
		part({
			name = "Chunk",
			size = Vector3.new(2 * subS, 1.5 * subS, 2 * subS),
			position = position
				+ Vector3.new(rand(-2, 2) * s, subS * 0.5, rand(-2, 2) * s),
			color = st[1]:Lerp(Color3.new(0, 0, 0), 0.1),
			material = st[2],
			parent = model,
		})
	end

	return model
end

-- ─── Arbusto / helecho ─────────────────────────────────────
function PropGenerator.bush(parent: Instance, position: Vector3, scale: number?)
	local s = scale or 1
	local model = folder(parent, "Bush")
	for i = 1, 4 do
		part({
			name = "LeafBall",
			size = Vector3.new(3 * s, 2.5 * s, 3 * s),
			shape = Enum.PartType.Ball,
			position = position + Vector3.new((i % 2) * 1.2 * s, 1.2 * s, math.floor(i / 2) * 1.2 * s),
			color = Color3.fromRGB(30 + i * 8, 100 + i * 5, 40),
			material = Enum.Material.LeafyGrass,
			parent = model,
			canCollide = false,
		})
	end
	return model
end

function PropGenerator.fern(parent: Instance, position: Vector3)
	local model = folder(parent, "Fern")
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		part({
			name = "Frond",
			size = Vector3.new(0.4, 0.3, 4),
			cframe = CFrame.new(position + Vector3.new(0, 1, 0)) * CFrame.Angles(0, angle, math.rad(70)),
			color = Color3.fromRGB(40, 130, 55),
			material = Enum.Material.Grass,
			parent = model,
			canCollide = false,
		})
	end
	return model
end

-- ─── Scatter helpers ─────────────────────────────────────────
function PropGenerator.scatterPalms(parent: Instance, center: Vector3, radius: number, count: number, seed: number)
	local rand = rng(seed)
	for _ = 1, count do
		local angle = rand(0, math.pi * 2)
		local dist = rand(radius * 0.2, radius)
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		PropGenerator.palmTree(parent, pos, rand(0.7, 1.3), math.floor(rand(1, 9999)))
	end
end

function PropGenerator.scatterRocks(parent: Instance, center: Vector3, radius: number, count: number, style: string?, seed: number)
	local rand = rng(seed)
	for i = 1, count do
		local angle = rand(0, math.pi * 2)
		local dist = rand(radius * 0.1, radius)
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		PropGenerator.rock(parent, pos, rand(0.5, 1.6), style, seed + i)
	end
end

function PropGenerator.scatterBushes(parent: Instance, center: Vector3, radius: number, count: number, seed: number)
	local rand = rng(seed)
	for _ = 1, count do
		local angle = rand(0, math.pi * 2)
		local dist = rand(radius * 0.15, radius)
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		if rand() > 0.5 then
			PropGenerator.bush(parent, pos, rand(0.6, 1.2))
		else
			PropGenerator.fern(parent, pos)
		end
	end
end

-- ─── Poste señal mejorado ────────────────────────────────────
function PropGenerator.signPost(parent: Instance, position: Vector3, number: number, text: string?)
	local model = folder(parent, "Sign_" .. number)
	part({
		name = "Pole",
		size = Vector3.new(0.6, 7, 0.6),
		position = position + Vector3.new(0, 3.5, 0),
		color = Color3.fromRGB(90, 60, 35),
		material = Enum.Material.Wood,
		parent = model,
	})
	part({
		name = "Board",
		size = Vector3.new(5, 3, 0.4),
		position = position + Vector3.new(0, 6.5, 0),
		color = Color3.fromRGB(200, 160, 80),
		material = Enum.Material.WoodPlanks,
		parent = model,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = model.Board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text or ("→ " .. number)
	label.TextColor3 = Color3.fromRGB(40, 30, 20)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
	return model
end

-- ─── Muelle / dock ───────────────────────────────────────────
function PropGenerator.woodenDock(parent: Instance, position: Vector3, length: number, width: number?)
	local w = width or 12
	local model = folder(parent, "Dock")
	for i = 0, math.floor(length / 4) do
		part({
			name = "Plank",
			size = Vector3.new(w, 0.5, 4),
			position = position + Vector3.new(0, 0.25, i * 4),
			color = Color3.fromRGB(120, 85, 50),
			material = Enum.Material.WoodPlanks,
			parent = model,
		})
	end
	-- Pilotes
	for x = -w / 2 + 2, w / 2 - 2, 4 do
		for z = 0, length, 8 do
			part({
				name = "Pile",
				size = Vector3.new(1, 6, 1),
				shape = Enum.PartType.Cylinder,
				cframe = CFrame.new(position + Vector3.new(x, -2, z)) * CFrame.Angles(0, 0, math.rad(90)),
				color = Color3.fromRGB(80, 55, 35),
				material = Enum.Material.Wood,
				parent = model,
			})
		end
	end
	return model
end

-- ─── Volcán detallado ────────────────────────────────────────
function PropGenerator.volcano(parent: Instance, center: Vector3, baseRadius: number, height: number)
	local model = folder(parent, "VolcanoStructure")
	local rand = rng(7777)

	-- Base rocosa
	for i = 1, 24 do
		local angle = (i / 24) * math.pi * 2
		local dist = baseRadius + rand(-8, 8)
		PropGenerator.rock(model, center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist), rand(1.2, 2.5), "volcanic", i)
	end

	-- Anillos del cono con textura
	local rings = 12
	for ring = 0, rings do
		local t = ring / rings
		local r = baseRadius * (1 - t * 0.85)
		local y = t * height
		part({
			name = "ConeLayer_" .. ring,
			size = Vector3.new(r * 2, height / rings + 2, r * 2),
			position = center + Vector3.new(0, y, 0),
			color = Color3.fromRGB(55 + ring * 4, 38 + ring * 2, 32),
			material = ring > rings - 3 and Enum.Material.Basalt or Enum.Material.Slate,
			parent = model,
		})
	end

	-- Cráter con lava
	local crater = part({
		name = "CraterLava",
		size = Vector3.new(baseRadius * 0.45, 4, baseRadius * 0.45),
		position = center + Vector3.new(0, height - 2, 0),
		color = Color3.fromRGB(255, 90, 20),
		material = Enum.Material.Neon,
		parent = model,
	})
	crater:SetAttribute("IsLava", true)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 40)
	light.Brightness = 2
	light.Range = 60
	light.Parent = crater

	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0), Color3.fromRGB(80, 20, 0))
	fire.Size = NumberSequence.new(2, 5)
	fire.Lifetime = NumberRange.new(1, 2.5)
	fire.Rate = 15
	fire.Speed = NumberRange.new(8, 18)
	fire.SpreadAngle = Vector2.new(25, 25)
	fire.Parent = crater

	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 80, 80), Color3.fromRGB(40, 40, 40))
	smoke.Size = NumberSequence.new(4, 12)
	smoke.Lifetime = NumberRange.new(3, 6)
	smoke.Rate = 8
	smoke.Speed = NumberRange.new(5, 12)
	smoke.SpreadAngle = Vector2.new(15, 15)
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Parent = crater

	-- Sendero de ascenso (piedras en espiral)
	local pathSteps = 20
	for step = 1, pathSteps do
		local t = step / pathSteps
		local angle = t * math.pi * 3
		local r = baseRadius * (1 - t * 0.75) + 8
		local y = t * height * 0.9 + 3
		part({
			name = "PathStone_" .. step,
			size = Vector3.new(5, 1.2, 5),
			position = center + Vector3.new(math.cos(angle) * r, y, math.sin(angle) * r),
			color = Color3.fromRGB(100, 95, 90),
			material = Enum.Material.Cobblestone,
			parent = model,
		})
	end

	-- Rocas volcánicas en ladera
	for i = 1, 15 do
		local t = rand(0.2, 0.9)
		local angle = rand(0, math.pi * 2)
		local r = baseRadius * (1 - t * 0.7)
		PropGenerator.rock(
			model,
			center + Vector3.new(math.cos(angle) * r, t * height, math.sin(angle) * r),
			rand(0.8, 1.5),
			"volcanic",
			100 + i
		)
	end

	return model
end

-- ─── Interior volcán (cueva de lava) ─────────────────────────
function PropGenerator.volcanoInterior(parent: Instance, center: Vector3)
	local model = folder(parent, "VolcanoCave")

	-- Paredes de caverna
	for side = -1, 1, 2 do
		part({
			name = "CaveWall",
			size = Vector3.new(8, 18, 100),
			position = center + Vector3.new(side * 22, 8, 40),
			color = Color3.fromRGB(45, 40, 38),
			material = Enum.Material.Basalt,
			parent = model,
		})
	end

	part({
		name = "CaveCeiling",
		size = Vector3.new(44, 4, 100),
		position = center + Vector3.new(0, 18, 40),
		color = Color3.fromRGB(35, 32, 30),
		material = Enum.Material.Basalt,
		parent = model,
	})

	-- Estalactitas
	local rand = rng(8888)
	for i = 1, 20 do
		local z = rand(0, 90)
		local x = rand(-15, 15)
		part({
			name = "Stalactite",
			size = Vector3.new(rand(0.8, 2), rand(3, 8), rand(0.8, 2)),
			position = center + Vector3.new(x, 16 - rand(2, 6), z),
			color = Color3.fromRGB(70, 65, 60),
			material = Enum.Material.Slate,
			parent = model,
		})
	end

	-- Grietas con luz
	for i = 1, 6 do
		local lava = part({
			name = "Lava",
			size = Vector3.new(rand(5, 12), 2, rand(8, 20)),
			position = center + Vector3.new(rand(-12, 12), 1, rand(5, 95)),
			color = Color3.fromRGB(255, 70, 10),
			material = Enum.Material.Neon,
			parent = model,
		})
		lava:SetAttribute("IsLava", true)
	end

	return model
end

-- ─── Cueva selvática ───────────────────────────────────────────
function PropGenerator.caveEntrance(parent: Instance, center: Vector3)
	local model = folder(parent, "CaveStructure")

	-- Arco de rocas
	for i = 1, 8 do
		local angle = math.pi + (i / 8) * math.pi
		local r = 14
		PropGenerator.rock(
			model,
			center + Vector3.new(math.cos(angle) * r, 4 + math.sin(angle) * 4, -5),
			1.2 + (i % 3) * 0.2,
			"moss",
			i
		)
	end

	part({
		name = "CaveMouth",
		size = Vector3.new(18, 14, 8),
		position = center + Vector3.new(0, 6, 0),
		color = Color3.fromRGB(25, 22, 20),
		material = Enum.Material.Slate,
		parent = model,
		transparency = 0,
	})

	-- Túnel interior oscuro
	part({
		name = "Tunnel",
		size = Vector3.new(12, 10, 90),
		position = center + Vector3.new(0, 4, 50),
		color = Color3.fromRGB(30, 28, 26),
		material = Enum.Material.Slate,
		parent = model,
	})

	-- Estalactitas / estalagmitas
	local rand = rng(3333)
	for i = 1, 12 do
		local z = center.Z + rand(10, 85)
		part({
			name = "Stalactite",
			size = Vector3.new(1.5, rand(4, 9), 1.5),
			position = Vector3.new(center.X + rand(-4, 4), center.Y + 10, z),
			color = Color3.fromRGB(90, 85, 80),
			material = Enum.Material.Slate,
			parent = model,
		})
		part({
			name = "Stalagmite",
			size = Vector3.new(2, rand(2, 6), 2),
			position = Vector3.new(center.X + rand(-5, 5), center.Y + 1, z),
			color = Color3.fromRGB(75, 70, 65),
			material = Enum.Material.Slate,
			parent = model,
		})
	end

	-- Cristales brillantes
	for i = 1, 5 do
		local crystal = part({
			name = "CrystalFormation",
			size = Vector3.new(2, 5, 2),
			position = center + Vector3.new(rand(-5, 5), 3, rand(30, 80)),
			color = Color3.fromRGB(100, 200, 255),
			material = Enum.Material.Glass,
			parent = model,
			transparency = 0.3,
		})
		local cl = Instance.new("PointLight")
		cl.Color = Color3.fromRGB(100, 200, 255)
		cl.Brightness = 1
		cl.Range = 12
		cl.Parent = crystal
	end

	PropGenerator.scatterRocks(model, center + Vector3.new(0, 0, 30), 35, 10, "moss", 44)

	return model
end

-- ─── Ruinas del castillo ───────────────────────────────────────
function PropGenerator.castleRuins(parent: Instance, center: Vector3)
	local model = folder(parent, "CastleStructure")
	local rand = rng(5555)

	-- Murallas rotas
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		local dist = 35
		local wallPos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		part({
			name = "WallSection",
			size = Vector3.new(4, rand(8, 18), 20),
			position = wallPos + Vector3.new(0, 6, 0),
			color = Color3.fromRGB(130, 125, 120),
			material = Enum.Material.Cobblestone,
			parent = model,
			cframe = CFrame.new(wallPos + Vector3.new(0, 6, 0)) * CFrame.Angles(0, angle, rand(-0.1, 0.1)),
		})
	end

	-- Torres
	for i, offset in { Vector3.new(-25, 0, -25), Vector3.new(25, 0, -25), Vector3.new(-25, 0, 25) } do
		local towerPos = center + offset
		part({
			name = "Tower",
			size = Vector3.new(12, 28, 12),
			position = towerPos + Vector3.new(0, 14, 0),
			color = Color3.fromRGB(120, 115, 110),
			material = Enum.Material.Cobblestone,
			parent = model,
		})
		-- Mitad rota
		part({
			name = "TowerRuin",
			size = Vector3.new(10, 12, 10),
			position = towerPos + Vector3.new(3, 22, 2),
			color = Color3.fromRGB(100, 95, 90),
			material = Enum.Material.Cobblestone,
			parent = model,
			cframe = CFrame.new(towerPos + Vector3.new(3, 22, 2)) * CFrame.Angles(math.rad(15), 0, math.rad(8)),
		})
	end

	-- Puerta principal (arco)
	part({
		name = "GateArch",
		size = Vector3.new(16, 2, 4),
		position = center + Vector3.new(0, 12, -32),
		color = Color3.fromRGB(110, 105, 100),
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	part({
		name = "GatePillarL",
		size = Vector3.new(3, 14, 3),
		position = center + Vector3.new(-7, 7, -32),
		color = Color3.fromRGB(115, 110, 105),
		material = Enum.Material.Cobblestone,
		parent = model,
	})
	part({
		name = "GatePillarR",
		size = Vector3.new(3, 14, 3),
		position = center + Vector3.new(7, 7, -32),
		color = Color3.fromRGB(115, 110, 105),
		material = Enum.Material.Cobblestone,
		parent = model,
	})

	-- Patio empedrado
	part({
		name = "Courtyard",
		size = Vector3.new(55, 1, 55),
		position = center + Vector3.new(0, 0.5, 0),
		color = Color3.fromRGB(100, 95, 90),
		material = Enum.Material.Cobblestone,
		parent = model,
	})

	PropGenerator.scatterRocks(model, center, 40, 8, "gray", 55)

	return model
end

-- ─── Estatua de castillo ───────────────────────────────────────
function PropGenerator.statue(parent: Instance, position: Vector3, index: number)
	local model = folder(parent, "Statue_" .. index)
	part({
		name = "Base",
		size = Vector3.new(5, 2, 5),
		position = position + Vector3.new(0, 1, 0),
		color = Color3.fromRGB(120, 115, 110),
		material = Enum.Material.Marble,
		parent = model,
	})
	part({
		name = "Body",
		size = Vector3.new(3, 6, 2.5),
		position = position + Vector3.new(0, 5, 0),
		color = Color3.fromRGB(160, 155, 150),
		material = Enum.Material.Marble,
		parent = model,
	})
	part({
		name = "Head",
		size = Vector3.new(2.5, 2.5, 2.5),
		shape = Enum.PartType.Ball,
		position = position + Vector3.new(0, 9, 0),
		color = Color3.fromRGB(170, 165, 160),
		material = Enum.Material.Marble,
		parent = model,
	})
	return model
end

-- ─── Piedras de salto (parkour) ───────────────────────────────
function PropGenerator.jumpStone(parent: Instance, position: Vector3, index: number, seed: number?)
	local rand = rng(seed or index * 17)
	local model = folder(parent, "JumpStone_" .. index)
	local w = rand(4, 7)
	local h = rand(1.5, 3)
	part({
		name = "JumpStone",
		size = Vector3.new(w, h, w * rand(0.8, 1.1)),
		position = position + Vector3.new(0, h / 2, 0),
		color = Color3.fromRGB(115, 118, 125),
		material = Enum.Material.Rock,
		parent = model,
		cframe = CFrame.new(position + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rand(-0.08, 0.08), rand(0, 6), 0),
	})
	-- Musgo en algunas
	if rand() > 0.4 then
		part({
			name = "Moss",
			size = Vector3.new(w * 0.9, 0.4, w * 0.9),
			position = position + Vector3.new(0, h + 0.1, 0),
			color = Color3.fromRGB(60, 100, 55),
			material = Enum.Material.Grass,
			parent = model,
			canCollide = false,
		})
	end
	return model
end

-- ─── Concha de laguna ──────────────────────────────────────────
function PropGenerator.shell(parent: Instance, position: Vector3, index: number, glow: boolean?)
	local model = folder(parent, "ShellPuzzle_" .. index)
	part({
		name = "ShellBase",
		size = Vector3.new(3.5, 1.5, 4),
		position = position,
		color = Color3.fromRGB(255, 230, 210),
		material = Enum.Material.SmoothPlastic,
		parent = model,
		cframe = CFrame.new(position) * CFrame.Angles(math.rad(15), 0, 0),
	})
	part({
		name = "ShellSpiral",
		size = Vector3.new(2, 2, 2),
		shape = Enum.PartType.Ball,
		position = position + Vector3.new(0, 1, 0),
		color = Color3.fromRGB(255, 200, 180),
		material = Enum.Material.SmoothPlastic,
		parent = model,
	})
	if glow then
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(150, 255, 255)
		light.Brightness = 0.8
		light.Range = 10
		light.Parent = model.ShellSpiral
	end
	return model
end

-- ─── Río con orillas ───────────────────────────────────────────
function PropGenerator.river(parent: Instance, center: Vector3, length: number, width: number?)
	local w = width or 28
	local model = folder(parent, "RiverStructure")
	local rand = rng(2222)

	part({
		name = "River",
		size = Vector3.new(w, 7, length),
		position = center,
		color = Color3.fromRGB(45, 110, 190),
		material = Enum.Material.Water,
		parent = model,
		transparency = 0.15,
	})

	-- Orillas de arena/roca
	for side = -1, 1, 2 do
		part({
			name = "RiverBank",
			size = Vector3.new(12, 3, length),
			position = center + Vector3.new(side * (w / 2 + 6), 1, 0),
			color = Color3.fromRGB(180, 160, 120),
			material = Enum.Material.Sand,
			parent = model,
		})
	end

	-- Rocas en el río (algunas sobresalen)
	for i = 1, 8 do
		local z = center.Z + rand(-length / 2 + 10, length / 2 - 10)
		PropGenerator.rock(model, Vector3.new(center.X + rand(-4, 4), center.Y + 1, z), rand(0.6, 1.2), "moss", i)
	end

	-- Puente de cuerda visual (decorativo)
	part({
		name = "RopeBridgeAnchorL",
		size = Vector3.new(2, 10, 2),
		position = center + Vector3.new(-w / 2 - 2, 6, -length / 2 + 10),
		color = Color3.fromRGB(90, 60, 35),
		material = Enum.Material.Wood,
		parent = model,
	})
	part({
		name = "RopeBridgeAnchorR",
		size = Vector3.new(2, 10, 2),
		position = center + Vector3.new(w / 2 + 2, 6, -length / 2 + 10),
		color = Color3.fromRGB(90, 60, 35),
		material = Enum.Material.Wood,
		parent = model,
	})

	PropGenerator.scatterBushes(model, center + Vector3.new(w / 2 + 15, 0, 0), 25, 6, 33)
	PropGenerator.scatterBushes(model, center + Vector3.new(-w / 2 - 15, 0, 0), 25, 6, 34)

	return model
end

-- ─── Laguna ────────────────────────────────────────────────────
function PropGenerator.lagoon(parent: Instance, center: Vector3, radius: number)
	local model = folder(parent, "LagoonStructure")
	local rand = rng(4444)

	part({
		name = "LagoonWater",
		size = Vector3.new(radius * 2, 18, radius * 2),
		position = center + Vector3.new(0, -6, 0),
		color = Color3.fromRGB(35, 150, 170),
		material = Enum.Material.Water,
		parent = model,
		transparency = 0.25,
	})

	-- Orilla de arena
	for i = 1, 16 do
		local angle = (i / 16) * math.pi * 2
		local dist = radius + rand(2, 8)
		part({
			name = "Shore",
			size = Vector3.new(rand(8, 15), 2, rand(8, 15)),
			position = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist),
			color = Color3.fromRGB(220, 200, 150),
			material = Enum.Material.Sand,
			parent = model,
		})
	end

	-- Rocas alrededor
	PropGenerator.scatterRocks(model, center, radius + 15, 14, "moss", 66)

	-- Juncos / cañas
	for i = 1, 20 do
		local angle = rand(0, math.pi * 2)
		local dist = radius + rand(3, 12)
		local pos = center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		part({
			name = "Reed",
			size = Vector3.new(0.3, rand(4, 8), 0.3),
			position = pos + Vector3.new(0, 2, 0),
			color = Color3.fromRGB(60, 120, 50),
			material = Enum.Material.Grass,
			parent = model,
			canCollide = false,
		})
	end

	PropGenerator.scatterPalms(model, center, radius + 25, 5, 77)

	return model
end

-- ─── Laberinto de selva (pasillos, callejones sin salida, muros altos) ──
local JUNGLE_MAZE_COLS = 20
local JUNGLE_MAZE_ROWS = 13

-- Camino correcto obligatorio (x, z). Señales en índices 1, 7, 13, 19, 25
local JUNGLE_SOLUTION_PATH = {
	{ 2, 2 },
	{ 3, 2 },
	{ 4, 2 },
	{ 5, 2 },
	{ 6, 2 },
	{ 7, 2 },
	{ 8, 2 },
	{ 8, 3 },
	{ 8, 4 },
	{ 8, 5 },
	{ 8, 6 },
	{ 7, 6 },
	{ 6, 6 },
	{ 5, 6 },
	{ 5, 7 },
	{ 5, 8 },
	{ 6, 8 },
	{ 7, 8 },
	{ 8, 8 },
	{ 9, 8 },
	{ 10, 8 },
	{ 11, 8 },
	{ 12, 8 },
	{ 13, 8 },
	{ 14, 8 },
	{ 15, 8 },
	{ 15, 9 },
	{ 15, 10 },
	{ 16, 10 },
	{ 17, 10 },
	{ 18, 10 },
	{ 19, 10 },
	{ 20, 10 },
}

local JUNGLE_SIGN_INDEX = { [1] = 1, [7] = 2, [13] = 3, [19] = 4, [25] = 5 }

-- Callejones sin salida (no conectan atajos hacia la salida)
local JUNGLE_DEAD_ENDS = {
	{ 4, 3 },
	{ 5, 3 },
	{ 6, 3 },
	{ 7, 3 },
	{ 9, 3 },
	{ 10, 3 },
	{ 3, 4 },
	{ 4, 4 },
	{ 5, 4 },
	{ 6, 4 },
	{ 7, 4 },
	{ 9, 4 },
	{ 10, 4 },
	{ 10, 5 },
	{ 10, 6 },
	{ 3, 6 },
	{ 4, 6 },
	{ 9, 6 },
	{ 10, 7 },
	{ 3, 8 },
	{ 4, 8 },
	{ 9, 9 },
	{ 10, 9 },
	{ 11, 9 },
	{ 12, 9 },
	{ 13, 9 },
}

function PropGenerator.jungleMazeWalls(parent: Instance, center: Vector3, groundY: number?)
	local model = folder(parent, "MazeStructure")
	local floorY = groundY or center.Y
	local cell = 11
	local wallH = 26
	local cols = JUNGLE_MAZE_COLS
	local rows = JUNGLE_MAZE_ROWS
	local origin = center + Vector3.new(-cols * cell / 2, 0, -rows * cell / 2)

	local grid: { { number } } = {}
	for z = 1, rows do
		grid[z] = {}
		for x = 1, cols do
			grid[z][x] = 1
		end
	end

	local function openCell(x: number, z: number)
		if x >= 1 and x <= cols and z >= 1 and z <= rows then
			grid[z][x] = 0
		end
	end

	local function cellWorld(x: number, z: number): Vector3
		return Vector3.new(
			origin.X + (x - 0.5) * cell,
			floorY,
			origin.Z + (z - 0.5) * cell
		)
	end

	for _, p in JUNGLE_SOLUTION_PATH do
		openCell(p[1], p[2])
	end
	for _, p in JUNGLE_DEAD_ENDS do
		openCell(p[1], p[2])
	end
	openCell(1, 2) -- entrada oeste
	-- Pasillo de salida al este (cols 17-20)
	for x = 17, 20 do
		for z = 9, 11 do
			openCell(x, z)
		end
	end

	local signSpots: { { position: Vector3, number: number } } = {}
	local exitPos: Vector3? = nil
	local finishPos: Vector3? = nil

	for z = 1, rows do
		for x = 1, cols do
			if grid[z][x] == 1 then
				local wx = origin.X + (x - 0.5) * cell
				local wz = origin.Z + (z - 0.5) * cell
				part({
					name = "MazeWall",
					size = Vector3.new(cell, wallH, cell),
					position = Vector3.new(wx, floorY + wallH / 2, wz),
					color = Color3.fromRGB(38, 98, 42),
					material = Enum.Material.LeafyGrass,
					parent = model,
				})
			end
		end
	end

	-- Techo en pasillos interiores (cols 1-16), no en el pasillo de salida abierto
	for z = 1, rows do
		for x = 1, 16 do
			if grid[z][x] == 0 then
				local wx = origin.X + (x - 0.5) * cell
				local wz = origin.Z + (z - 0.5) * cell
				part({
					name = "MazeCeiling",
					size = Vector3.new(cell, 1, cell),
					position = Vector3.new(wx, floorY + wallH + 0.5, wz),
					color = Color3.fromRGB(30, 80, 35),
					material = Enum.Material.LeafyGrass,
					parent = model,
					transparency = 0.92,
					canCollide = true,
				})
			end
		end
	end

	-- Suelo del pasillo de salida (fuera del laberinto cerrado)
	for x = 17, 20 do
		for z = 9, 11 do
			local pos = cellWorld(x, z)
			part({
				name = "ExitPath",
				size = Vector3.new(cell - 1, 0.4, cell - 1),
				position = pos + Vector3.new(0, 0.2, 0),
				color = Color3.fromRGB(130, 95, 60),
				material = Enum.Material.Ground,
				parent = model,
				canCollide = true,
			})
		end
	end

	for i, p in JUNGLE_SOLUTION_PATH do
		local pos = cellWorld(p[1], p[2])
		local signNum = JUNGLE_SIGN_INDEX[i]
		if signNum then
			table.insert(signSpots, { position = pos, number = signNum })
		end
	end

	-- Salida física + checkpoint FUERA del muro este
	exitPos = cellWorld(17, 10) + Vector3.new(0, 3, 0)
	finishPos = cellWorld(20, 10) + Vector3.new(0, 3, 0)

	part({
		name = "MazeEntranceArch",
		size = Vector3.new(2, wallH + 2, cell + 2),
		position = Vector3.new(origin.X - 1, floorY + wallH / 2, origin.Z + 1.5 * cell),
		color = Color3.fromRGB(80, 55, 35),
		material = Enum.Material.Wood,
		parent = model,
		canCollide = false,
		transparency = 0.85,
	})

	local exitArch = part({
		name = "MazeExitArch",
		size = Vector3.new(2, wallH + 2, cell * 2.5),
		position = Vector3.new(origin.X + 16.5 * cell + 1, floorY + wallH / 2, origin.Z + 9.5 * cell),
		color = Color3.fromRGB(80, 55, 35),
		material = Enum.Material.Wood,
		parent = model,
		canCollide = false,
		transparency = 0.85,
	})
	local exitGui = Instance.new("SurfaceGui")
	exitGui.Face = Enum.NormalId.Front
	exitGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	exitGui.PixelsPerStud = 45
	exitGui.Parent = exitArch
	local exitLbl = Instance.new("TextLabel")
	exitLbl.Size = UDim2.fromScale(1, 1)
	exitLbl.BackgroundTransparency = 1
	exitLbl.Text = "SALIDA →"
	exitLbl.TextColor3 = Color3.fromRGB(255, 240, 120)
	exitLbl.TextScaled = true
	exitLbl.Font = Enum.Font.GothamBold
	exitLbl.Parent = exitGui

	-- Cerco perimetral: no se puede rodear el laberinto por fuera
	local minX = origin.X
	local maxX = origin.X + cols * cell
	local minZ = origin.Z
	local maxZ = origin.Z + rows * cell
	local thick = 4
	local midY = floorY + wallH / 2
	local wallColor = Color3.fromRGB(32, 88, 38)

	local function perimeterWall(name: string, size: Vector3, pos: Vector3)
		part({
			name = name,
			size = size,
			position = pos,
			color = wallColor,
			material = Enum.Material.LeafyGrass,
			parent = model,
		})
	end

	local entranceZ = origin.Z + 1.5 * cell
	local entranceGap = cell * 1.1
	local exitCenterZ = origin.Z + 10 * cell
	local exitGap = cell * 3.2

	-- Norte y sur (cerrados)
	perimeterWall(
		"PerimeterNorth",
		Vector3.new(cols * cell + thick * 2, wallH, thick),
		Vector3.new((minX + maxX) / 2, midY, minZ - thick / 2)
	)
	perimeterWall(
		"PerimeterSouth",
		Vector3.new(cols * cell + thick * 2, wallH, thick),
		Vector3.new((minX + maxX) / 2, midY, maxZ + thick / 2)
	)

	-- Oeste: hueco solo en la entrada
	local westNorthLen = math.max(4, entranceZ - entranceGap / 2 - minZ)
	if westNorthLen > 2 then
		perimeterWall(
			"PerimeterWestN",
			Vector3.new(thick, wallH, westNorthLen),
			Vector3.new(minX - thick / 2, midY, minZ + westNorthLen / 2)
		)
	end
	local westSouthStart = entranceZ + entranceGap / 2
	local westSouthLen = math.max(4, maxZ - westSouthStart)
	if westSouthLen > 2 then
		perimeterWall(
			"PerimeterWestS",
			Vector3.new(thick, wallH, westSouthLen),
			Vector3.new(minX - thick / 2, midY, westSouthStart + westSouthLen / 2)
		)
	end

	-- Este: hueco solo en el pasillo de salida
	local eastNorthLen = math.max(4, exitCenterZ - exitGap / 2 - minZ)
	if eastNorthLen > 2 then
		perimeterWall(
			"PerimeterEastN",
			Vector3.new(thick, wallH, eastNorthLen),
			Vector3.new(maxX + thick / 2, midY, minZ + eastNorthLen / 2)
		)
	end
	local eastSouthStart = exitCenterZ + exitGap / 2
	local eastSouthLen = math.max(4, maxZ - eastSouthStart)
	if eastSouthLen > 2 then
		perimeterWall(
			"PerimeterEastS",
			Vector3.new(thick, wallH, eastSouthLen),
			Vector3.new(maxX + thick / 2, midY, eastSouthStart + eastSouthLen / 2)
		)
	end

	-- Techo perimetral bajo (impide saltar por encima del cerco)
	for _, seg in {
		{ Vector3.new(cols * cell + thick * 2, 1.5, thick), Vector3.new((minX + maxX) / 2, floorY + wallH + 1, minZ - thick / 2) },
		{ Vector3.new(cols * cell + thick * 2, 1.5, thick), Vector3.new((minX + maxX) / 2, floorY + wallH + 1, maxZ + thick / 2) },
	} do
		part({
			name = "PerimeterCap",
			size = seg[1],
			position = seg[2],
			color = wallColor,
			material = Enum.Material.LeafyGrass,
			parent = model,
			transparency = 0.9,
			canCollide = true,
		})
	end

	return model, signSpots, exitPos, finishPos
end

-- ─── Camino de tierra ──────────────────────────────────────────
function PropGenerator.dirtPath(parent: Instance, fromPos: Vector3, toPos: Vector3, width: number?, seed: number?)
	local model = folder(parent, "Path")
	local dir = (toPos - fromPos)
	local dist = dir.Magnitude
	local mid = fromPos + dir / 2
	local w = width or 8
	local segments = math.max(3, math.floor(dist / 6))
	local rand = rng(seed or 1)

	for i = 0, segments do
		local t = i / segments
		local pos = fromPos:Lerp(toPos, t) + Vector3.new(rand(-1, 1), 0.2, rand(-1, 1))
		part({
			name = "PathSegment",
			size = Vector3.new(w + rand(-1, 1), 0.4, 6),
			position = pos,
			color = Color3.fromRGB(130, 100, 70),
			material = Enum.Material.Ground,
			parent = model,
			cframe = CFrame.new(pos, pos + dir) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0),
		})
	end
	return model
end

-- ─── Colina / elevación ────────────────────────────────────────
function PropGenerator.hill(parent: Instance, position: Vector3, radius: number, height: number)
	local model = folder(parent, "Hill")
	part({
		name = "HillBase",
		size = Vector3.new(radius * 2, height, radius * 2),
		shape = Enum.PartType.Ball,
		position = position + Vector3.new(0, height / 2 - 2, 0),
		color = Color3.fromRGB(65, 115, 55),
		material = Enum.Material.Grass,
		parent = model,
	})
	PropGenerator.scatterRocks(model, position, radius * 0.6, 4, "moss", math.floor(position.X))
	return model
end

-- ─── Barca varada / restos ─────────────────────────────────────
function PropGenerator.wreckedBoat(parent: Instance, position: Vector3)
	local model = folder(parent, "WreckedBoat")
	part({
		name = "Hull",
		size = Vector3.new(8, 3, 14),
		position = position + Vector3.new(0, 1.5, 0),
		color = Color3.fromRGB(100, 70, 45),
		material = Enum.Material.Wood,
		parent = model,
		cframe = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0.3, math.rad(12)),
	})
	part({
		name = "Mast",
		size = Vector3.new(0.8, 10, 0.8),
		position = position + Vector3.new(1, 6, -2),
		color = Color3.fromRGB(80, 55, 35),
		material = Enum.Material.Wood,
		parent = model,
		cframe = CFrame.new(position + Vector3.new(1, 6, -2)) * CFrame.Angles(math.rad(25), 0, 0),
	})
	return model
end

-- ─── Antorcha en pared ─────────────────────────────────────────
function PropGenerator.wallTorch(parent: Instance, position: Vector3)
	local model = folder(parent, "Torch")
	part({
		name = "Bracket",
		size = Vector3.new(0.5, 1, 0.5),
		position = position,
		color = Color3.fromRGB(60, 55, 50),
		material = Enum.Material.Metal,
		parent = model,
	})
	local flame = part({
		name = "Flame",
		size = Vector3.new(1.2, 1.5, 1.2),
		shape = Enum.PartType.Ball,
		position = position + Vector3.new(0, 1.5, 0.5),
		color = Color3.fromRGB(255, 150, 50),
		material = Enum.Material.Neon,
		parent = model,
		canCollide = false,
	})
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 180, 50))
	fire.Size = NumberSequence.new(0.5, 1.2)
	fire.Lifetime = NumberRange.new(0.3, 0.6)
	fire.Rate = 20
	fire.Speed = NumberRange.new(1, 3)
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 50)
	light.Brightness = 1.5
	light.Range = 18
	light.Parent = flame
	return model
end

-- ─── Decoración isla global (colinas, costa, senderos) ─────────
function PropGenerator.island1Landscape(islandFolder: Folder, offset: Vector3, layout: { [string]: Vector3 })
	local landscape = folder(islandFolder, "Landscape")
	local rand = rng(10001)

	-- Capas de terreno (colinas)
	local hills = {
		{ Vector3.new(120, 0, 55), 50, 16 },
		{ Vector3.new(500, 0, 150), 100, 35 },
		{ Vector3.new(350, 0, -200), 90, 20 },
		{ Vector3.new(650, 0, 80), 120, 45 },
		{ Vector3.new(100, 0, -300), 70, 18 },
		{ Vector3.new(-80, 0, -180), 65, 22 },
	}
	for i, h in hills do
		PropGenerator.hill(landscape, offset + h[1], h[2], h[3])
	end

	-- Costa rocosa al norte/oeste
	for i = 1, 30 do
		local angle = rand(math.pi * 0.5, math.pi * 1.5)
		local dist = rand(480, 580)
		PropGenerator.rock(
			landscape,
			offset + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist),
			rand(1, 2.2),
			"sand",
			i + 200
		)
	end

	-- Palmeras dispersas en toda la isla
	PropGenerator.scatterPalms(landscape, offset + Vector3.new(400, 0, 0), 500, 45, 301)
	PropGenerator.scatterRocks(landscape, offset + Vector3.new(400, 0, 0), 480, 60, "moss", 302)
	PropGenerator.scatterBushes(landscape, offset + Vector3.new(400, 0, 0), 450, 80, 303)

	-- Senderos entre zonas principales
	local paths = {
		{ layout.BeachLanding, layout.JungleMaze },
		{ layout.JungleMaze, layout.RiverCross },
		{ layout.RiverCross, layout.StoneJump },
		{ layout.StoneJump, layout.LagoonDive },
		{ layout.LagoonDive, layout.CaveSystem },
		{ layout.CaveSystem, layout.CastleRuins },
		{ layout.CastleRuins, layout.ChaseEscape },
		{ layout.ChaseEscape, layout.DodgeGauntlet },
		{ layout.DodgeGauntlet, layout.VolcanoClimb },
		{ layout.VolcanoClimb, layout.FinalEscape },
	}
	for i, path in paths do
		PropGenerator.dirtPath(landscape, path[1] + Vector3.new(0, 0.5, 0), path[2] + Vector3.new(0, 0.5, 0), 10, 400 + i)
	end

	return landscape
end

-- ─── Laberinto de hielo (más compacto, 3 señales) ───────────────
local ICE_SOLUTION_PATH = {
	{ 2, 2 }, { 3, 2 }, { 4, 2 }, { 5, 2 }, { 6, 2 },
	{ 6, 3 }, { 6, 4 }, { 7, 4 }, { 8, 4 }, { 8, 5 },
	{ 8, 6 }, { 9, 6 }, { 10, 6 }, { 11, 6 }, { 12, 6 },
}
local ICE_SIGN_INDEX = { [1] = 1, [5] = 2, [10] = 3 }

function PropGenerator.iceMazeWalls(parent: Instance, center: Vector3, groundY: number?)
	local model = folder(parent, "IceMazeStructure")
	local floorY = groundY or center.Y
	local cell = 10
	local wallH = 18
	local cols = 14
	local rows = 8
	local origin = center + Vector3.new(-cols * cell / 2, 0, -rows * cell / 2)
	local iceColor = Color3.fromRGB(180, 220, 255)
	local wallMat = Enum.Material.Ice

	local grid: { { number } } = {}
	for x = 1, cols do
		grid[x] = {}
		for z = 1, rows do
			grid[x][z] = 1
		end
	end

	for _, p in ICE_SOLUTION_PATH do
		grid[p[1]][p[2]] = 0
	end

	local function cellWorld(cx: number, cz: number): Vector3
		return origin + Vector3.new((cx - 0.5) * cell, 0, (cz - 0.5) * cell)
	end

	for x = 1, cols do
		for z = 1, rows do
			local pos = cellWorld(x, z)
			part({
				name = "IceFloor",
				size = Vector3.new(cell - 0.5, 0.5, cell - 0.5),
				position = Vector3.new(pos.X, floorY - 0.2, pos.Z),
				color = iceColor,
				material = Enum.Material.Ice,
				parent = model,
			})
			if grid[x][z] == 1 then
				part({
					name = "IceWall",
					size = Vector3.new(cell - 1, wallH, cell - 1),
					position = Vector3.new(pos.X, floorY + wallH / 2, pos.Z),
					color = Color3.fromRGB(140, 190, 240),
					material = wallMat,
					parent = model,
				})
			end
		end
	end

	local signSpots = {}
	for i, p in ICE_SOLUTION_PATH do
		local pos = cellWorld(p[1], p[2])
		local signNum = ICE_SIGN_INDEX[i]
		if signNum then
			table.insert(signSpots, { position = pos + Vector3.new(0, 2, 0), number = signNum })
		end
	end

	local finishPos = cellWorld(12, 6) + Vector3.new(0, 3, 0)
	local exitPos = cellWorld(11, 6) + Vector3.new(0, 3, 0)

	part({
		name = "MazeEntranceArch",
		size = Vector3.new(2, wallH + 2, cell + 2),
		position = Vector3.new(origin.X - 1, floorY + wallH / 2, origin.Z + 1.5 * cell),
		color = Color3.fromRGB(160, 200, 240),
		material = Enum.Material.Ice,
		parent = model,
		canCollide = false,
		transparency = 0.5,
	})

	return model, signSpots, exitPos, finishPos
end

function PropGenerator.island2Landscape(islandFolder: Folder, offset: Vector3, layout: { [string]: Vector3 })
	local landscape = folder(islandFolder, "Landscape")
	local rand = rng(20001)

	for i = 1, 12 do
		local angle = rand(0, math.pi * 2)
		local dist = rand(80, 280)
		part({
			name = "Iceberg",
			size = Vector3.new(rand(15, 40), rand(8, 25), rand(15, 40)),
			position = offset + Vector3.new(math.cos(angle) * dist, rand(2, 8), math.sin(angle) * dist),
			color = Color3.fromRGB(200, 230, 255),
			material = Enum.Material.Ice,
			parent = landscape,
		})
	end

	PropGenerator.scatterRocks(landscape, offset + Vector3.new(300, 0, 0), 200, 25, "sand", 401)

	local paths = {
		{ layout.FrozenShore, layout.IceMaze },
		{ layout.IceMaze, layout.FrozenEscape },
	}
	for i, path in paths do
		part({
			name = "SnowPath",
			size = Vector3.new((path[2] - path[1]).Magnitude, 0.4, 8),
			position = path[1]:Lerp(path[2], 0.5) + Vector3.new(0, 0.3, 0),
			color = Color3.fromRGB(240, 245, 255),
			material = Enum.Material.Snow,
			parent = landscape,
			cframe = CFrame.lookAt(path[1]:Lerp(path[2], 0.5), path[2]),
		})
	end

	return landscape
end

function PropGenerator.island3Landscape(islandFolder: Folder, offset: Vector3, layout: { [string]: Vector3 })
	local landscape = folder(islandFolder, "Landscape")
	local rand = rng(30001)

	for i = 1, 18 do
		local angle = rand(0, math.pi * 2)
		local dist = rand(60, 300)
		part({
			name = "Dune",
			size = Vector3.new(rand(20, 45), rand(5, 14), rand(18, 40)),
			position = offset + Vector3.new(math.cos(angle) * dist, rand(1, 5), math.sin(angle) * dist),
			color = Color3.fromRGB(215, 180, 120),
			material = Enum.Material.Sand,
			parent = landscape,
		})
	end

	PropGenerator.scatterRocks(landscape, offset + Vector3.new(300, 0, 0), 220, 20, "sand", 501)

	for i = 1, 8 do
		part({
			name = "DeadTree",
			size = Vector3.new(1.5, rand(6, 12), 1.5),
			position = offset + Vector3.new(rand(-200, 200), rand(3, 6), rand(-200, 200)),
			color = Color3.fromRGB(90, 70, 50),
			material = Enum.Material.Wood,
			parent = landscape,
		})
	end

	local paths = {
		{ layout.DesertOasis, layout.SandTemple },
		{ layout.SandTemple, layout.DuneEscape },
	}
	for i, path in paths do
		PropGenerator.dirtPath(landscape, path[1] + Vector3.new(0, 0.5, 0), path[2] + Vector3.new(0, 0.5, 0), 9, 600 + i)
	end

	return landscape
end

return PropGenerator
