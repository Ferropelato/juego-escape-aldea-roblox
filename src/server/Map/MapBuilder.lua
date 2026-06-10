--[[
	Genera el mapa completo de Escape Island con decoración procedural detallada.
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local PropGenerator = require(script.Parent.PropGenerator)
local HazardService = require(script.Parent.Parent.Services.HazardService)

local MapBuilder = {}

local ISLAND1_OFFSET = Vector3.new(0, 0, 0)
local ISLAND2_OFFSET = Vector3.new(2500, 0, 0)

local ZONE_LAYOUT_ISLAND1 = {
	BeachLanding = ISLAND1_OFFSET + Vector3.new(0, 5, 0),
	JungleMaze = ISLAND1_OFFSET + Vector3.new(200, 8, 150),
	RiverCross = ISLAND1_OFFSET + Vector3.new(400, 5, 0),
	StoneJump = ISLAND1_OFFSET + Vector3.new(550, 10, -120),
	LagoonDive = ISLAND1_OFFSET + Vector3.new(350, 3, -280),
	CaveSystem = ISLAND1_OFFSET + Vector3.new(150, 5, -350),
	CastleRuins = ISLAND1_OFFSET + Vector3.new(-100, 15, -200),
	ChaseEscape = ISLAND1_OFFSET + Vector3.new(380, 8, 350),
	DodgeGauntlet = ISLAND1_OFFSET + Vector3.new(500, 20, 200),
	VolcanoClimb = ISLAND1_OFFSET + Vector3.new(650, 40, 100),
	VolcanoInterior = ISLAND1_OFFSET + Vector3.new(700, 80, 100),
	FinalEscape = ISLAND1_OFFSET + Vector3.new(750, 5, -50),
}

local function makePart(props: {
	name: string,
	size: Vector3,
	position: Vector3,
	color: Color3?,
	material: Enum.Material?,
	parent: Instance,
	anchored: boolean?,
	canCollide: boolean?,
	transparency: number?,
}): Part
	local p = Instance.new("Part")
	p.Name = props.name
	p.Size = props.size
	p.Position = props.position
	p.Anchored = props.anchored ~= false
	p.CanCollide = props.canCollide ~= false
	p.Color = props.color or Color3.fromRGB(100, 140, 80)
	p.Material = props.material or Enum.Material.Grass
	p.Transparency = props.transparency or 0
	p.Parent = props.parent
	return p
end

local function createSpawn(parent: Instance, position: Vector3): Part
	return makePart({
		name = "Spawn",
		size = Vector3.new(6, 1, 6),
		position = position,
		color = Color3.fromRGB(80, 200, 120),
		material = Enum.Material.Neon,
		parent = parent,
		transparency = 0.5,
		canCollide = false,
	})
end

local function createZoneBounds(parent: Instance, challenge, center: Vector3): Part
	local size = challenge.zoneSize or Vector3.new(100, 50, 100)
	return makePart({
		name = "ZoneBounds",
		size = size,
		position = center + Vector3.new(0, size.Y / 2 - 10, 0),
		color = Color3.fromRGB(50, 50, 50),
		material = Enum.Material.ForceField,
		parent = parent,
		transparency = 0.95,
		canCollide = false,
	})
end

-- Suelo plano por zona (evita muros flotando sobre colinas del paisaje)
local function createZoneFloor(parent: Instance, center: Vector3, footprint: Vector3)
	local thickness = 2
	return makePart({
		name = "ZoneFloor",
		size = Vector3.new(footprint.X, thickness, footprint.Z),
		position = Vector3.new(center.X, center.Y - thickness / 2 + 0.25, center.Z),
		color = Color3.fromRGB(62, 110, 52),
		material = Enum.Material.Grass,
		parent = parent,
	})
end

-- Entrada estrecha en el borde de la zona (puente o camino), no en el centro
local ZONE_ENTRY_OFFSETS: { [string]: Vector3 } = {
	JungleMaze = Vector3.new(-82, 4, -55),
	RiverCross = Vector3.new(-62, 4, 0),
	StoneJump = Vector3.new(-95, 5, 0),
	LagoonDive = Vector3.new(0, 3, 52),
	CaveSystem = Vector3.new(-72, 4, 0),
	CastleRuins = Vector3.new(0, 4, 60),
	ChaseEscape = Vector3.new(-78, 4, -25),
	DodgeGauntlet = Vector3.new(-42, 12, 0),
	VolcanoClimb = Vector3.new(0, 4, -48),
	VolcanoInterior = Vector3.new(0, 12, -42),
	FinalEscape = Vector3.new(0, 4, -40),
}

local function createZoneEntry(parent: Instance, challenge, center: Vector3)
	if challenge.order <= 1 then
		return
	end
	local offset = ZONE_ENTRY_OFFSETS[challenge.id] or Vector3.new(0, 4, 0)
	local entry = makePart({
		name = "ZoneEntry",
		size = Vector3.new(26, 12, 26),
		position = center + offset,
		color = Color3.fromRGB(200, 50, 50),
		material = Enum.Material.ForceField,
		parent = parent,
		transparency = 0.98,
		canCollide = false,
	})
	entry:SetAttribute("ZoneChallengeId", challenge.id)
	return entry
end

local function createCheckpoint(islandFolder: Folder, id: string, position: Vector3, challengeId: string)
	local cpFolder = islandFolder:FindFirstChild("Checkpoints")
	if not cpFolder then
		cpFolder = Instance.new("Folder")
		cpFolder.Name = "Checkpoints"
		cpFolder.Parent = islandFolder
	end

	local cp = makePart({
		name = id,
		size = Vector3.new(8, 1, 8),
		position = position,
		color = Color3.fromRGB(0, 200, 255),
		material = Enum.Material.Neon,
		parent = cpFolder,
		transparency = 0.5,
	})
	cp:SetAttribute("ChallengeId", challengeId)

	makePart({
		name = "GlowPillar",
		size = Vector3.new(1.2, 7, 1.2),
		position = position + Vector3.new(0, 3.5, 0),
		color = Color3.fromRGB(0, 180, 220),
		material = Enum.Material.Neon,
		parent = cp,
		transparency = 0.35,
		canCollide = false,
	})

	return cp
end

local function createResourceNode(parent: Instance, resourceId: string, position: Vector3)
	local cfg = GameConfig.Resources[resourceId]
	local colors = {
		Wood = Color3.fromRGB(110, 75, 45),
		Vine = Color3.fromRGB(50, 110, 45),
		Stone = Color3.fromRGB(130, 125, 120),
		Shell = Color3.fromRGB(255, 220, 200),
		Ore = Color3.fromRGB(90, 85, 95),
		Crystal = Color3.fromRGB(100, 200, 255),
		Ember = Color3.fromRGB(255, 100, 40),
	}

	local node = makePart({
		name = "Resource_" .. resourceId,
		size = Vector3.new(3, 3, 3),
		position = position,
		color = colors[resourceId] or Color3.fromRGB(200, 180, 50),
		material = resourceId == "Crystal" and Enum.Material.Glass or Enum.Material.Wood,
		parent = parent,
	})
	if resourceId == "Wood" then
		makePart({
			name = "Stump",
			size = Vector3.new(2.5, 2, 2.5),
			position = position + Vector3.new(0, -0.5, 0),
			color = Color3.fromRGB(90, 60, 35),
			material = Enum.Material.Wood,
			parent = parent,
		})
	end
	node:SetAttribute("ResourceId", resourceId)
	node:SetAttribute("Amount", 1)

	node:SetAttribute("PickupBound", nil)
	return node
end

-- Cartel físico en el mundo (SurfaceGui, NO billboard en pantalla)
local function createMissionBoard(parent: Instance, position: Vector3, title: string, lines: { string })
	local board = makePart({
		name = "MissionBoard",
		size = Vector3.new(12, 8, 0.6),
		position = position,
		color = Color3.fromRGB(90, 65, 40),
		material = Enum.Material.WoodPlanks,
		parent = parent,
	})
	board.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(-25), 0)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local frame = Instance.new("TextLabel")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(25, 45, 35)
	frame.BackgroundTransparency = 0.1
	frame.TextColor3 = Color3.new(1, 1, 1)
	frame.TextScaled = false
	frame.TextSize = 22
	frame.Font = Enum.Font.GothamBold
	frame.TextWrapped = true
	frame.Text = title .. "\n\n" .. table.concat(lines, "\n")
	frame.Parent = gui
	return board
end

local function createGate(parent: Instance, challengeId: string, position: Vector3, size: Vector3)
	local gate = makePart({
		name = "Gate_" .. challengeId,
		size = size,
		position = position,
		color = Color3.fromRGB(255, 50, 50),
		material = Enum.Material.Glass,
		parent = parent,
		transparency = 0.3,
	})
	gate:SetAttribute("ChallengeId", challengeId)
	ChallengeService.registerGate(challengeId, gate)
	return gate
end

local function createFinish(parent: Instance, position: Vector3)
	return makePart({
		name = "Finish",
		size = Vector3.new(12, 6, 12),
		position = position,
		color = Color3.fromRGB(0, 255, 100),
		material = Enum.Material.Neon,
		parent = parent,
		transparency = 0.4,
		canCollide = false,
	})
end

-- Puente caminable: puerta al inicio + espinas/agua abajo (sin teletransporte)
local function createWalkBridge(
	parent: Instance,
	toChallengeId: string,
	fromPos: Vector3,
	toPos: Vector3,
	bridgeWidth: number?
)
	local folder = Instance.new("Folder")
	folder.Name = "BridgeTo_" .. toChallengeId
	folder.Parent = parent

	local width = bridgeWidth or 5
	local dir = toPos - fromPos
	local length = dir.Magnitude
	local segments = math.max(4, math.floor(length / 4))
	dir = dir.Unit

	-- Puerta al inicio del puente (madera, no pared roja en el laberinto)
	local gateCF = CFrame.lookAt(fromPos + Vector3.new(0, 5, 0), fromPos + Vector3.new(0, 5, 0) + dir)
	local gate = makePart({
		name = "Gate_" .. toChallengeId,
		size = Vector3.new(width + 2, 10, 2),
		position = gateCF.Position,
		color = Color3.fromRGB(95, 70, 45),
		material = Enum.Material.WoodPlanks,
		parent = folder,
		transparency = 0.15,
	})
	gate.CFrame = gateCF
	gate:SetAttribute("ChallengeId", toChallengeId)
	ChallengeService.registerGate(toChallengeId, gate)

	-- Tablones del puente
	local bridgeY = math.max(fromPos.Y, toPos.Y) + 4
	for i = 0, segments do
		local t = i / segments
		local pos = fromPos:Lerp(toPos, t)
		local plank = makePart({
			name = "BridgePlank",
			size = Vector3.new(width, 0.7, 4.2),
			position = Vector3.new(pos.X, bridgeY + math.sin(t * math.pi) * 0.3, pos.Z),
			color = Color3.fromRGB(110, 75, 45),
			material = Enum.Material.WoodPlanks,
			parent = folder,
		})
		plank.CFrame = CFrame.lookAt(plank.Position, plank.Position + dir)
	end

	-- Barandas bajas (visual)
	for side = -1, 1, 2 do
		for i = 0, segments, 2 do
			local t = i / segments
			local pos = fromPos:Lerp(toPos, t)
			local right = dir:Cross(Vector3.yAxis).Unit * side * (width / 2 + 0.5)
			makePart({
				name = "Railing",
				size = Vector3.new(0.4, 1.5, 4),
				position = Vector3.new(pos.X, bridgeY + 1, pos.Z) + right,
				color = Color3.fromRGB(90, 60, 35),
				material = Enum.Material.Wood,
				parent = folder,
				canCollide = false,
			})
		end
	end

	-- Mortal si caés: agua + espinas bajo todo el puente
	HazardService.createUnderBridge(folder, fromPos, toPos, width, -12)

	-- Detector de entrada solo al final del puente (no en todo el centro de la zona)
	local entry = makePart({
		name = "ZoneEntry",
		size = Vector3.new(22, 12, 22),
		position = toPos + Vector3.new(0, 5, 0),
		color = Color3.fromRGB(200, 50, 50),
		material = Enum.Material.ForceField,
		parent = folder,
		transparency = 0.98,
		canCollide = false,
	})
	entry:SetAttribute("ZoneChallengeId", toChallengeId)

	-- Cartel en el inicio
	local sign = makePart({
		name = "BridgeSign",
		size = Vector3.new(6, 4, 0.5),
		position = fromPos + Vector3.new(0, 9, 0) - dir * 3,
		color = Color3.fromRGB(80, 55, 35),
		material = Enum.Material.WoodPlanks,
		parent = folder,
	})
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 45
	sg.Parent = sign
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = "⚠️ Puente\nEspinas abajo"
	lbl.TextColor3 = Color3.new(1, 0.9, 0.9)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = sg

	return folder
end

-- ─── ZONAS ISLA 1 (con decoración) ─────────────────────────────

local function buildBeachZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center)
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	makePart({
		name = "Ocean",
		size = Vector3.new(450, 8, 220),
		position = center + Vector3.new(0, -3, -130),
		color = Color3.fromRGB(25, 90, 170),
		material = Enum.Material.Water,
		parent = zoneFolder,
	})

	makePart({
		name = "BeachSand",
		size = Vector3.new(180, 3, 100),
		position = center + Vector3.new(0, 0, -45),
		color = Color3.fromRGB(235, 210, 155),
		material = Enum.Material.Sand,
		parent = zoneFolder,
	})

	PropGenerator.woodenDock(deco, center + Vector3.new(-30, 0, -55), 50, 14)
	PropGenerator.wreckedBoat(deco, center + Vector3.new(50, 0, -30))
	-- Menos palmeras normales cerca de las escalables (evitar hojas que bloqueen)
	PropGenerator.scatterPalms(deco, center + Vector3.new(0, 0, 50), 45, 6, 101)
	PropGenerator.scatterRocks(deco, center + Vector3.new(0, 0, -20), 55, 12, "sand", 102)
	PropGenerator.scatterBushes(deco, center + Vector3.new(40, 0, 20), 35, 8, 103)

	-- Palmeras escalables con tesoro arriba
	local climbSpots = {
		{ pos = center + Vector3.new(-35, 0, 30), res = "Wood", seed = 501 },
		{ pos = center + Vector3.new(25, 0, 45), res = "Vine", seed = 502 },
		{ pos = center + Vector3.new(55, 0, 15), res = "Shell", seed = 503 },
	}
	for i, spot in climbSpots do
		local treeModel, topY = PropGenerator.climbablePalmTree(deco, spot.pos, 1, spot.res, spot.seed)
		local resPart = treeModel:FindFirstChild("Resource_" .. spot.res, true)
		if resPart and resPart:IsA("BasePart") then
			resPart:SetAttribute("Amount", 1)
		end
	end

	for i = 1, 6 do
		createResourceNode(zoneFolder, "Wood", center + Vector3.new(-50 + i * 12, 2, -10 + (i % 5) * 8))
		createResourceNode(zoneFolder, "Vine", center + Vector3.new(-30 + (i % 4) * 18, 2, 20 + (i % 3) * 12))
	end

	createMissionBoard(zoneFolder, center + Vector3.new(-15, 6, 35), "🏝️ Llegada", {
		"Completá objetivos (panel izquierdo).",
		"Cruzá el puente con cuidado.",
		"¡Espinas abajo si caés!",
	})

	createFinish(zoneFolder, center + Vector3.new(72, 3, 0))

	-- Puente a la selva (sin TP): playa → bosque
	local bridgeStart = center + Vector3.new(82, 4, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND1.JungleMaze + Vector3.new(-82, 4, -55)
	createWalkBridge(zoneFolder, "JungleMaze", bridgeStart, bridgeEnd, 5)

	-- Trampa bajo el muelle hacia el mar
	HazardService.createUnderBridge(deco, center + Vector3.new(-30, 0, -55), center + Vector3.new(20, 0, -55), 14, -8)
end

local function buildJungleZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(235, 0, 175))
	createSpawn(zoneFolder, center + Vector3.new(-82, 0, -55))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-82, 6, -68), "🌿 Laberinto de selva", {
		"Entrá solo por el arco oeste (no se puede rodear).",
		"Seguí las señales 1 → 5 (pulsa E).",
		"Pasá el arco SALIDA → y tocá el checkpoint verde.",
		"Palmeras con liana: subí la espiral caminando (podés moverte a los costados).",
	})

	local _, signSpots, _exitPos, mazeFinishPos = PropGenerator.jungleMazeWalls(deco, center, center.Y + 0.25)

	for _, spot in signSpots do
		local signModel = PropGenerator.signPost(deco, spot.position, spot.number, "→ " .. spot.number)
		local board = signModel:FindFirstChild("Board", true)
		if board then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Leer señal"
			prompt.ObjectText = "Señal " .. spot.number
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 12
			prompt.Parent = board
			local signNum = spot.number
			prompt.Triggered:Connect(function(player)
				local PuzzleManager = require(script.Parent.Parent.Challenges.PuzzleManager)
				PuzzleManager.handleInteraction(player, "MazeSign", signNum)
			end)
		end
	end

	-- Palmeras escalables FUERA del laberinto (junto a la entrada oeste)
	PropGenerator.climbablePalmTree(deco, center + Vector3.new(-98, 0, -68), 1, "Vine", 211)
	PropGenerator.climbablePalmTree(deco, center + Vector3.new(-98, 0, -42), 1, "Vine", 212)
	PropGenerator.scatterPalms(deco, center + Vector3.new(-98, 0, -55), 18, 3, 201)
	PropGenerator.scatterBushes(deco, center + Vector3.new(85, 0, 0), 25, 6, 203)
	PropGenerator.fern(deco, center + Vector3.new(-85, 0, 50))
	PropGenerator.fern(deco, center + Vector3.new(-85, 0, -20))

	createResourceNode(zoneFolder, "Vine", center + Vector3.new(-20, 3, 55))
	createResourceNode(zoneFolder, "Vine", center + Vector3.new(15, 3, 72))
	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-35, 3, 88))

	local finishPos = mazeFinishPos or (center + Vector3.new(92, 3, 38))
	createFinish(zoneFolder, finishPos)

	-- Puente al río, conectado DESPUÉS del checkpoint verde
	local bridgeStart = finishPos + Vector3.new(10, 1, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND1.RiverCross + Vector3.new(-62, 4, 0)
	createWalkBridge(zoneFolder, "RiverCross", bridgeStart, bridgeEnd, 5)

	makePart({
		name = "BridgeHint",
		size = Vector3.new(8, 5, 0.5),
		position = bridgeStart + Vector3.new(-6, 5, 0),
		color = Color3.fromRGB(80, 55, 35),
		material = Enum.Material.WoodPlanks,
		parent = zoneFolder,
	})
	local bridgeHint = zoneFolder:FindFirstChild("BridgeHint")
	if bridgeHint then
		local hintGui = Instance.new("SurfaceGui")
		hintGui.Face = Enum.NormalId.Front
		hintGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		hintGui.PixelsPerStud = 40
		hintGui.Parent = bridgeHint
		local hintLbl = Instance.new("TextLabel")
		hintLbl.Size = UDim2.fromScale(1, 1)
		hintLbl.BackgroundTransparency = 1
		hintLbl.Text = "🌉 Puente al río\n(se abre al completar)"
		hintLbl.TextColor3 = Color3.new(1, 1, 1)
		hintLbl.TextScaled = true
		hintLbl.Font = Enum.Font.GothamBold
		hintLbl.Parent = hintGui
	end
end

local function buildRiverZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(-65, 0, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.river(deco, center, 130, 32)

	-- Puente sobre el río + muerte si caés al agua
	local bridgeFrom = center + Vector3.new(-55, 6, 0)
	local bridgeTo = center + Vector3.new(55, 6, 0)
	createWalkBridge(zoneFolder, challenge.id, bridgeFrom, bridgeTo, 6)
	-- Agua del río = mortal (hay que usar el puente)
	HazardService.createDeathPit(zoneFolder, center + Vector3.new(0, -4, 0), Vector3.new(34, 10, 130))

	createGate(zoneFolder, challenge.id, center, Vector3.new(32, 15, 4))
	PropGenerator.scatterPalms(deco, center + Vector3.new(60, 0, 0), 40, 6, 301)

	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-45, 3, 55))
	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-40, 3, -45))
	createResourceNode(zoneFolder, "Vine", center + Vector3.new(-50, 3, 0))
	createFinish(zoneFolder, center + Vector3.new(85, 3, 0))
end

local function buildStoneJumpZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(-95, 5, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	for i = 0, 14 do
		local pos = center + Vector3.new(i * 11, 2 + math.sin(i * 0.7) * 3.5, math.sin(i * 0.45) * 9)
		PropGenerator.jumpStone(zoneFolder, pos, i, i * 19)
	end

	PropGenerator.scatterRocks(deco, center + Vector3.new(60, 0, 40), 50, 8, "moss", 401)
	PropGenerator.scatterRocks(deco, center + Vector3.new(60, 0, -40), 50, 8, "moss", 402)

	makePart({
		name = "KillWater",
		size = Vector3.new(220, 6, 100),
		position = center + Vector3.new(65, -6, 0),
		color = Color3.fromRGB(25, 75, 140),
		material = Enum.Material.Water,
		parent = zoneFolder,
	}).Touched:Connect(function(hit)
		local hum = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
		if hum then
			hum.Health = 0
		end
	end)

	createFinish(zoneFolder, center + Vector3.new(135, 10, 0))
end

local function buildLagoonZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(0, 2, 55))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.lagoon(deco, center, 55)

	local shellPositions = {
		Vector3.new(22, -4, 12),
		Vector3.new(-18, -5, -22),
		Vector3.new(8, -6, 28),
		Vector3.new(-28, -4, 8),
	}
	for i, pos in shellPositions do
		local shellModel = PropGenerator.shell(deco, center + pos, i, i == 3 or i == 1)
		local base = shellModel:FindFirstChild("ShellBase")
		if base then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Activar concha"
			prompt.ObjectText = "Concha " .. i
			prompt.Parent = base
			prompt.Triggered:Connect(function(player)
				local PuzzleManager = require(script.Parent.Parent.Challenges.PuzzleManager)
				PuzzleManager.handleInteraction(player, "ShellSequence", i)
			end)
		end
	end

	createResourceNode(zoneFolder, "Shell", center + Vector3.new(35, 2, 40))
	createResourceNode(zoneFolder, "Shell", center + Vector3.new(-35, 2, 35))
end

local function buildCaveZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(-75, 0, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.caveEntrance(deco, center)
	PropGenerator.scatterRocks(deco, center + Vector3.new(25, 0, 0), 30, 6, "moss", 501)
	PropGenerator.wallTorch(deco, center + Vector3.new(-8, 5, 15))
	PropGenerator.wallTorch(deco, center + Vector3.new(8, 5, 45))
	PropGenerator.wallTorch(deco, center + Vector3.new(-6, 5, 75))

	createResourceNode(zoneFolder, "Ore", center + Vector3.new(12, 2, 72))
	createResourceNode(zoneFolder, "Crystal", center + Vector3.new(-8, 2, 92))
	createResourceNode(zoneFolder, "Ember", center + Vector3.new(2, 2, 42))
	createResourceNode(zoneFolder, "Stone", center + Vector3.new(20, 2, 55))
	createFinish(zoneFolder, center + Vector3.new(0, 4, 105))
end

local function buildCastleZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(0, 0, 65))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.castleRuins(deco, center)
	PropGenerator.scatterPalms(deco, center, 55, 4, 601)

	local PuzzleManager = require(script.Parent.Parent.Challenges.PuzzleManager)
	for i = 1, 4 do
		local statuePos = center + Vector3.new((i - 2.5) * 16, 0, 5)
		PropGenerator.statue(zoneFolder, statuePos, i)
		local statue = zoneFolder:FindFirstChild("Statue_" .. i)
		if statue then
			local base = statue:FindFirstChild("Base")
			if base then
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Activar"
				prompt.ObjectText = "Estatua " .. i
				prompt.Parent = base
				local idx = i
				prompt.Triggered:Connect(function(player)
					PuzzleManager.onStatueActivated(player, idx)
				end)
			end
		end
	end

	createGate(zoneFolder, challenge.id, center + Vector3.new(0, 6, -32), Vector3.new(18, 14, 3))
	createResourceNode(zoneFolder, "Ore", center + Vector3.new(42, 3, 22))
	createResourceNode(zoneFolder, "Stone", center + Vector3.new(-38, 3, 18))
end

local function buildChaseZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(200, 0, 280))
	createSpawn(zoneFolder, center + Vector3.new(-75, 0, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-72, 6, -10), "👹 Persecución", {
		"¡Un guardián te persigue!",
		"Corré hasta la zona VERDE segura al este.",
		"No te detengas en callejones sin salida.",
	})

	PropGenerator.dirtPath(deco, center + Vector3.new(-70, 0.5, 0), center + Vector3.new(115, 0.5, 0), 12, 701)
	PropGenerator.scatterPalms(deco, center, 120, 22, 702)
	PropGenerator.scatterBushes(deco, center, 100, 30, 703)

	-- Guardián visible (ChallengeBehaviors lo reutiliza)
	makePart({
		name = "ChaseGuard",
		size = Vector3.new(5, 7, 5),
		position = center + Vector3.new(-55, 5, 15),
		color = Color3.fromRGB(120, 20, 20),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		canCollide = false,
	})

	makePart({
		name = "SafeZone",
		size = Vector3.new(35, 12, 35),
		position = center + Vector3.new(125, 6, 0),
		color = Color3.fromRGB(0, 255, 100),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		transparency = 0.5,
		canCollide = false,
	})
end

local function buildDodgeZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(-40, 12, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	-- Pasarela de rocas volcánicas
	for i = 0, 10 do
		PropGenerator.rock(deco, center + Vector3.new(math.sin(i) * 12, 8 + i * 2, i * 10), 1.2, "volcanic", 800 + i)
	end
	PropGenerator.scatterRocks(deco, center, 40, 15, "volcanic", 801)

	createFinish(zoneFolder, center + Vector3.new(0, 8, 115))
end

local function buildVolcanoZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(0, 0, -50))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.volcano(deco, center, 55, 95)

	-- Lava adicional en la base (gameplay)
	local baseLava = makePart({
		name = "Lava",
		size = Vector3.new(30, 3, 30),
		position = center + Vector3.new(0, 4, 0),
		color = Color3.fromRGB(255, 70, 10),
		material = Enum.Material.Neon,
		parent = zoneFolder,
	})
	baseLava:SetAttribute("IsLava", true)

	createFinish(zoneFolder, center + Vector3.new(0, 92, 0))
end

local function buildVolcanoInterior(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center + Vector3.new(0, 12, -45))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.volcanoInterior(deco, center)
	PropGenerator.wallTorch(deco, center + Vector3.new(-18, 8, 20))
	PropGenerator.wallTorch(deco, center + Vector3.new(18, 8, 60))

	createFinish(zoneFolder, center + Vector3.new(0, 5, 105))
end

local function buildFinalZone(zoneFolder: Folder, center: Vector3, challenge)
	createSpawn(zoneFolder, center)
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	PropGenerator.woodenDock(deco, center, 55, 18)
	PropGenerator.scatterPalms(deco, center, 50, 6, 901)
	PropGenerator.wreckedBoat(deco, center + Vector3.new(-25, 0, 15))

	makePart({
		name = "EscapeDock",
		size = Vector3.new(50, 2, 35),
		position = center,
		color = Color3.fromRGB(105, 72, 42),
		material = Enum.Material.WoodPlanks,
		parent = zoneFolder,
	})

	-- Bote grande para el escape final
	local boat = makePart({
		name = "EscapeBoatHull",
		size = Vector3.new(14, 4, 22),
		position = center + Vector3.new(0, 3, 25),
		color = Color3.fromRGB(120, 85, 50),
		material = Enum.Material.WoodPlanks,
		parent = deco,
	})
	makePart({
		name = "Mast",
		size = Vector3.new(1, 14, 1),
		position = center + Vector3.new(0, 10, 20),
		color = Color3.fromRGB(90, 65, 40),
		material = Enum.Material.Wood,
		parent = deco,
	})

	createFinish(zoneFolder, center + Vector3.new(0, 5, 45))
end

local BUILDERS = {
	BeachLanding = buildBeachZone,
	JungleMaze = buildJungleZone,
	RiverCross = buildRiverZone,
	StoneJump = buildStoneJumpZone,
	LagoonDive = buildLagoonZone,
	CaveSystem = buildCaveZone,
	CastleRuins = buildCastleZone,
	ChaseEscape = buildChaseZone,
	DodgeGauntlet = buildDodgeZone,
	VolcanoClimb = buildVolcanoZone,
	VolcanoInterior = buildVolcanoInterior,
	FinalEscape = buildFinalZone,
}

-- Sin billboards gigantes en el mundo (el cliente muestra zona actual arriba)
local function addZoneLabel(_zoneFolder: Folder, _challenge) end

local function buildIsland1Base(islandFolder: Folder, offset: Vector3)
	-- Terreno principal con variación
	makePart({
		name = "IslandBase",
		size = Vector3.new(1300, 22, 1300),
		position = offset + Vector3.new(400, -8, 0),
		color = Color3.fromRGB(65, 118, 58),
		material = Enum.Material.Grass,
		parent = islandFolder,
	})

	-- Parches de arena y roca
	local patches = {
		{ Vector3.new(0, 0, -80), Vector3.new(200, 4, 120), Enum.Material.Sand, Color3.fromRGB(220, 200, 145) },
		{ Vector3.new(550, 0, -120), Vector3.new(180, 4, 100), Enum.Material.Sand, Color3.fromRGB(210, 195, 140) },
		{ Vector3.new(650, 0, 100), Vector3.new(200, 6, 200), Enum.Material.Basalt, Color3.fromRGB(55, 48, 42) },
		{ Vector3.new(350, 0, -280), Vector3.new(140, 3, 140), Enum.Material.Sand, Color3.fromRGB(200, 185, 135) },
	}
	for i, patch in patches do
		makePart({
			name = "TerrainPatch_" .. i,
			size = patch[2],
			position = offset + patch[1] + Vector3.new(0, -5, 0),
			color = patch[4],
			material = patch[3],
			parent = islandFolder,
		})
	end

	PropGenerator.island1Landscape(islandFolder, offset, ZONE_LAYOUT_ISLAND1)
end

local function buildIsland(islandId: string, offset: Vector3)
	local islandFolder = Instance.new("Folder")
	islandFolder.Name = islandId

	if islandId == "Island1_Tropical" then
		buildIsland1Base(islandFolder, offset)
	else
		makePart({
			name = "IslandBase",
			size = Vector3.new(600, 15, 600),
			position = offset + Vector3.new(300, -5, 0),
			color = Color3.fromRGB(70, 120, 60),
			material = Enum.Material.Grass,
			parent = islandFolder,
		})
	end

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = islandFolder

	local challenges = GameConfig.getChallengesForIsland(islandId)
	for _, challenge in challenges do
		local layout = ZONE_LAYOUT_ISLAND1[challenge.id]
		if not layout and islandId == "Island2_Frozen" then
			layout = offset + Vector3.new(challenge.order * 80, 5, 0)
		end
		if not layout then
			continue
		end

		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = challenge.id
		zoneFolder.Parent = zonesFolder

		local builder = BUILDERS[challenge.id]
		if builder then
			builder(zoneFolder, layout, challenge)
		else
			createSpawn(zoneFolder, layout)
			createZoneBounds(zoneFolder, challenge, layout)
		end

		if not zoneFolder:FindFirstChild("ZoneBounds") then
			createZoneBounds(zoneFolder, challenge, layout)
		end
		-- JungleMaze y RiverCross registran entrada al final del puente
		if challenge.id ~= "JungleMaze" and challenge.id ~= "RiverCross" then
			createZoneEntry(zoneFolder, challenge, layout)
		end

		createCheckpoint(islandFolder, challenge.checkpointId, layout + Vector3.new(0, 6, 0), challenge.id)
		addZoneLabel(zoneFolder, challenge)
	end

	return islandFolder
end

function MapBuilder.build()
	local existing = Workspace:FindFirstChild("EscapeIsland")
	if existing then
		existing:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "EscapeIsland"

	local island1 = buildIsland("Island1_Tropical", ISLAND1_OFFSET)
	island1.Parent = map

	local island2 = buildIsland("Island2_Frozen", ISLAND2_OFFSET)
	makePart({
		name = "FrozenGround",
		size = Vector3.new(600, 15, 600),
		position = ISLAND2_OFFSET + Vector3.new(300, 0, 0),
		color = Color3.fromRGB(220, 240, 255),
		material = Enum.Material.Snow,
		parent = island2,
	})
	island2.Parent = map

	map.Parent = Workspace
	return map
end

return MapBuilder
