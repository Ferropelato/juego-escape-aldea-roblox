--[[
	Genera el mapa completo de Escape Island con decoración procedural detallada.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local ChallengeService = require(script.Parent.Parent.Services.ChallengeService)
local NotificationService = require(script.Parent.Parent.Services.NotificationService)
local PropGenerator = require(script.Parent.PropGenerator)
local HazardService = require(script.Parent.Parent.Services.HazardService)

local MapBuilder = {}

local ISLAND1_OFFSET = Vector3.new(0, 0, 0)
local ISLAND2_OFFSET = Vector3.new(2500, 0, 0)
local ISLAND3_OFFSET = Vector3.new(5000, 0, 0)

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

local ZONE_LAYOUT_ISLAND2 = {
	FrozenShore = ISLAND2_OFFSET + Vector3.new(0, 5, 0),
	IceMaze = ISLAND2_OFFSET + Vector3.new(200, 8, 120),
	FrozenEscape = ISLAND2_OFFSET + Vector3.new(420, 12, 80),
}

local ZONE_LAYOUT_ISLAND3 = {
	DesertOasis = ISLAND3_OFFSET + Vector3.new(0, 5, 0),
	SandTemple = ISLAND3_OFFSET + Vector3.new(200, 10, 100),
	DuneEscape = ISLAND3_OFFSET + Vector3.new(400, 15, 60),
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
	JungleMaze = Vector3.new(-114, 4, -55),  -- frente a la entrada oeste del laberinto
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
	FrozenShore = Vector3.new(0, 4, 55),
	IceMaze = Vector3.new(-70, 4, -50),
	FrozenEscape = Vector3.new(-75, 4, -20),
	DesertOasis = Vector3.new(0, 4, 55),
	SandTemple = Vector3.new(-70, 4, -45),
	DuneEscape = Vector3.new(-42, 12, 0),
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
-- addGaps: agrega tramos sin tablones que requieren saltar (puente desafiante)
local function createWalkBridge(
	parent: Instance,
	toChallengeId: string,
	fromPos: Vector3,
	toPos: Vector3,
	bridgeWidth: number?,
	addGaps: boolean?
)
	local folder = Instance.new("Folder")
	folder.Name = "BridgeTo_" .. toChallengeId
	folder.Parent = parent

	local width = bridgeWidth or 5
	local dir = toPos - fromPos
	local length = dir.Magnitude
	local segments = math.max(4, math.floor(length / 4))
	dir = dir.Unit

	-- Puerta al inicio del puente: ancha, alta y baja para que no se pueda pasar por debajo ni saltar
	local gateCF = CFrame.lookAt(fromPos + Vector3.new(0, 8, 0), fromPos + Vector3.new(0, 8, 0) + dir)
	local gate = makePart({
		name = "Gate_" .. toChallengeId,
		size = Vector3.new(16, 34, 6),  -- cubre desde Y≈-9 hasta Y≈+25 desde fromPos
		position = gateCF.Position,
		color = Color3.fromRGB(95, 70, 45),
		material = Enum.Material.WoodPlanks,
		parent = folder,
		transparency = 0.15,
	})
	gate.CFrame = gateCF
	gate:SetAttribute("ChallengeId", toChallengeId)
	ChallengeService.registerGate(toChallengeId, gate)

	-- Notificación cuando el jugador toca la puerta bloqueada
	local _lastGateWarn: { [number]: number } = {}
	gate.Touched:Connect(function(hit)
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if not plr then return end
		local now = tick()
		if (_lastGateWarn[plr.UserId] or 0) + 3 > now then return end
		_lastGateWarn[plr.UserId] = now
		if not ChallengeService.isChallengeUnlocked(plr, toChallengeId) then
			NotificationService.send(plr, "🔒 ¡Completá los objetivos del panel izquierdo para abrir el puente!", "error")
		end
	end)

	-- Tablones del puente (con curva lateral y brechas opcionales)
	local bridgeY = math.max(fromPos.Y, toPos.Y) + 4
	local right = dir:Cross(Vector3.yAxis).Unit  -- vector lateral
	-- Índices de tablones faltantes (brechas de salto) si addGaps=true
	local gapSet: { [number]: boolean } = {}
	if addGaps then
		local g1 = math.floor(segments * 0.33)
		local g2 = math.floor(segments * 0.66)
		gapSet[g1] = true ; gapSet[g1 + 1] = true  -- brecha de 2 tablones = ~8 studs
		gapSet[g2] = true ; gapSet[g2 + 1] = true
	end

	for i = 0, segments do
		if gapSet[i] then continue end  -- saltar tablones de la brecha
		local t = i / segments
		-- Curva lateral: zigzag suave que pega contra las barandas, alternando lados
		local sway = math.sin(t * math.pi * 2) * (addGaps and 0.6 or 0.2) * width
		local pos = fromPos:Lerp(toPos, t) + right * sway
		local archY = bridgeY + math.sin(t * math.pi) * 1.2  -- arco sutil
		local plank = makePart({
			name = "BridgePlank",
			size = Vector3.new(width, 0.7, 4.2),
			position = Vector3.new(pos.X, archY, pos.Z),
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

	-- Balsa amarrada al muelle (decoración estática, bandera ondea en el viento)
	local raftPos = center + Vector3.new(-30, 1, -62)
	makePart({
		name = "ArrivalRaft",
		size = Vector3.new(10, 0.8, 16),
		position = raftPos,
		color = Color3.fromRGB(115, 80, 48),
		material = Enum.Material.WoodPlanks,
		parent = deco,
	})
	makePart({
		name = "RaftMast",
		size = Vector3.new(0.7, 10, 0.7),
		position = raftPos + Vector3.new(0, 5.4, -3),
		color = Color3.fromRGB(85, 58, 32),
		material = Enum.Material.Wood,
		parent = deco,
	})
	local flag = makePart({
		name = "RaftFlag",
		size = Vector3.new(4, 2.5, 0.15),
		position = raftPos + Vector3.new(2, 10.5, -3),
		color = Color3.fromRGB(220, 50, 50),
		material = Enum.Material.SmoothPlastic,
		parent = deco,
		canCollide = false,
	})
	-- Bandera que ondea en el lugar (sin tween, sin weld)
	task.spawn(function()
		local flagOffset = 0
		local flagBasePos = raftPos + Vector3.new(2, 10.5, -3)
		game:GetService("RunService").Heartbeat:Connect(function(dt)
			if not flag.Parent then return end
			flagOffset += dt * 3
			flag.CFrame = CFrame.new(flagBasePos + Vector3.new(math.sin(flagOffset) * 0.5, 0, 0))
		end)
	end)

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
		"1) Recolectá 3 maderitas + 2 lianas.",
		"2) Tocá el PORTAL VERDE (junto al puente).",
		"3) ¡El puente se abrirá! Cruzá con cuidado.",
		"¡Espinas abajo si caés del puente!",
	})

	-- Portal verde: más alto y con cartel para que sea obvio
	local finishPos = center + Vector3.new(72, 3, 0)
	createFinish(zoneFolder, finishPos)
	-- Arco de entrada al portal (hace visible que hay algo interactivo aquí)
	makePart({
		name = "PortalArch_L",
		size = Vector3.new(1.5, 10, 1.5),
		position = finishPos + Vector3.new(-7, 2, 0),
		color = Color3.fromRGB(0, 230, 90),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		canCollide = false,
	})
	makePart({
		name = "PortalArch_R",
		size = Vector3.new(1.5, 10, 1.5),
		position = finishPos + Vector3.new(7, 2, 0),
		color = Color3.fromRGB(0, 230, 90),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		canCollide = false,
	})
	makePart({
		name = "PortalArch_Top",
		size = Vector3.new(16, 1.5, 1.5),
		position = finishPos + Vector3.new(0, 7, 0),
		color = Color3.fromRGB(0, 230, 90),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		canCollide = false,
	})
	-- Letrero encima del portal
	local portalSign = makePart({
		name = "PortalSign",
		size = Vector3.new(14, 5, 0.5),
		position = finishPos + Vector3.new(0, 12, 0),
		color = Color3.fromRGB(20, 60, 30),
		material = Enum.Material.SmoothPlastic,
		parent = zoneFolder,
		canCollide = false,
	})
	local psg = Instance.new("SurfaceGui")
	psg.Face = Enum.NormalId.Front
	psg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	psg.PixelsPerStud = 40
	psg.Parent = portalSign
	local psl = Instance.new("TextLabel")
	psl.Size = UDim2.fromScale(1, 1)
	psl.BackgroundTransparency = 1
	psl.Text = "⬇️ TOCA EL PORTAL\nPara abrir el puente ⬇️"
	psl.TextColor3 = Color3.fromRGB(0, 255, 100)
	psl.TextScaled = true
	psl.Font = Enum.Font.GothamBold
	psl.Parent = psg

	-- Puente a la selva: termina justo frente a la entrada oeste del laberinto
	local bridgeStart = center + Vector3.new(82, 4, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND1.JungleMaze + Vector3.new(-114, 4, -55)
	createWalkBridge(zoneFolder, "JungleMaze", bridgeStart, bridgeEnd, 5, true)

	-- Trampa bajo el muelle hacia el mar
	HazardService.createUnderBridge(deco, center + Vector3.new(-30, 0, -55), center + Vector3.new(20, 0, -55), 14, -8)
end

local function buildJungleZone(zoneFolder: Folder, center: Vector3, challenge)
	print("[MapBuilder] buildJungleZone START center=" .. tostring(center))
	createZoneFloor(zoneFolder, center, Vector3.new(250, 0, 200))
	createSpawn(zoneFolder, center + Vector3.new(-114, 0, -55))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-110, 6, -55), "🌿 Laberinto de selva", {
		"1) Agarrá las 2 LIANAS (bloques marrones en esta zona).",
		"2) Entrá al laberinto por el arco oeste.",
		"3) Navegá hasta la SALIDA al este.",
		"4) Tocá el portal verde para avanzar.",
	})

	-- Laberinto: señales son decorativas (ya no son requisito)
	local _, signSpots, _exitPos, mazeFinishPos = PropGenerator.jungleMazeWalls(deco, center, center.Y + 0.25)
	print("[MapBuilder] jungleMazeWalls OK, signSpots=" .. #signSpots)

	for _, spot in signSpots do
		-- Señales visuales (sin ProximityPrompt — ya no son requisito de objetivo)
		PropGenerator.signPost(deco, spot.position, spot.number, "")
	end

	-- Decoración
	PropGenerator.climbablePalmTree(deco, center + Vector3.new(-98, 0, -68), 1, "Vine", 211)
	PropGenerator.climbablePalmTree(deco, center + Vector3.new(-98, 0, -42), 1, "Vine", 212)
	PropGenerator.scatterPalms(deco, center + Vector3.new(-98, 0, -55), 18, 3, 201)
	PropGenerator.scatterBushes(deco, center + Vector3.new(85, 0, 0), 25, 6, 203)
	PropGenerator.fern(deco, center + Vector3.new(-85, 0, 50))
	PropGenerator.fern(deco, center + Vector3.new(-85, 0, -20))

	-- *** RECURSOS: posiciones verificadas FUERA de los muros del laberinto ***
	-- Laberinto ocupa X:90-310, Z:78.5-221.5 (con cell=11, cols=20, rows=13)
	-- Spawn está en center+(-114,0,-55) = (86,8,95). Recursos al OESTE del muro (X<90):
	createResourceNode(zoneFolder, "Vine", center + Vector3.new(-116, 3, -55))  -- X=84, Z=95 (spawn area)
	createResourceNode(zoneFolder, "Vine", center + Vector3.new(-116, 3, -38))  -- X=84, Z=112 (junto al arco)
	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-116, 3, -72))  -- X=84, Z=78 (norte del spawn)
	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-116, 3, -20))  -- X=84, Z=130 (sur del arco)
	print("[MapBuilder] recursos creados OK")

	local finishPos = mazeFinishPos or (center + Vector3.new(92, 3, 38))
	createFinish(zoneFolder, finishPos)

	-- Señal grande "SIGUIENTE ZONA →" al salir del laberinto
	local dirSign = makePart({
		name = "DirectionSign",
		size = Vector3.new(14, 9, 0.6),
		position = finishPos + Vector3.new(5, 7, 0),
		color = Color3.fromRGB(75, 50, 30),
		material = Enum.Material.WoodPlanks,
		parent = zoneFolder,
	})
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	signGui.PixelsPerStud = 40
	signGui.Parent = dirSign
	local signFrame = Instance.new("Frame")
	signFrame.Size = UDim2.fromScale(1, 1)
	signFrame.BackgroundColor3 = Color3.fromRGB(25, 55, 35)
	signFrame.BackgroundTransparency = 0.05
	signFrame.Parent = signGui
	local signLbl = Instance.new("TextLabel")
	signLbl.Size = UDim2.fromScale(1, 1)
	signLbl.BackgroundTransparency = 1
	signLbl.Text = "🌊 SIGUIENTE:\nRío → seguí el camino →"
	signLbl.TextColor3 = Color3.fromRGB(255, 240, 140)
	signLbl.TextScaled = true
	signLbl.Font = Enum.Font.GothamBold
	signLbl.Parent = signFrame

	-- Puente al río con tramos desafiantes
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
					PuzzleManager.onStatueActivated(player, idx, "CastleRuins")
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

	-- Puente con gate hacia DodgeGauntlet (impide saltarse la zona)
	local chaseBridgeStart = center + Vector3.new(115, 6, 0)
	local chaseBridgeEnd = ZONE_LAYOUT_ISLAND1.DodgeGauntlet + Vector3.new(-52, 12, 0)
	createWalkBridge(zoneFolder, "DodgeGauntlet", chaseBridgeStart, chaseBridgeEnd, 5)

	createMissionBoard(zoneFolder, chaseBridgeStart + Vector3.new(0, 9, 8), "🌋 Siguiente: Gauntlet", {
		"Cruzá el puente hacia la pasarela volcánica.",
		"Esquivá las rocas en movimiento.",
		"¡No caigas al vacío!",
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

	-- Bridge con gate hacia la base del volcán
	local dodgeBridgeStart = center + Vector3.new(0, 10, 120)
	local dodgeBridgeEnd = ZONE_LAYOUT_ISLAND1.VolcanoClimb + Vector3.new(0, 4, -55)
	createWalkBridge(zoneFolder, "VolcanoClimb", dodgeBridgeStart, dodgeBridgeEnd, 5)
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

-- ─── ZONAS ISLA 2 (helada) ─────────────────────────────────────

local function buildFrozenShoreZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(150, 0, 130))
	createSpawn(zoneFolder, center)
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	makePart({
		name = "FrozenOcean",
		size = Vector3.new(400, 8, 180),
		position = center + Vector3.new(0, -3, -100),
		color = Color3.fromRGB(80, 140, 200),
		material = Enum.Material.Glass,
		parent = zoneFolder,
		transparency = 0.3,
	})

	makePart({
		name = "SnowBeach",
		size = Vector3.new(160, 3, 90),
		color = Color3.fromRGB(235, 245, 255),
		material = Enum.Material.Snow,
		position = center + Vector3.new(0, 0, -35),
		parent = zoneFolder,
	})

	for i = 1, 4 do
		local icebergPos = center + Vector3.new(-50 + i * 25, 0, -20 + (i % 2) * 15)
		makePart({
			name = "Iceberg_" .. i,
			size = Vector3.new(12 + i * 2, 8 + i, 10 + i),
			position = icebergPos + Vector3.new(0, 4, 0),
			color = Color3.fromRGB(180, 220, 255),
			material = Enum.Material.Ice,
			parent = deco,
		})
	end

	createResourceNode(zoneFolder, "Crystal", center + Vector3.new(-30, 2, 10))
	createResourceNode(zoneFolder, "Crystal", center + Vector3.new(25, 2, 20))
	createResourceNode(zoneFolder, "Stone", center + Vector3.new(-15, 2, 35))
	createResourceNode(zoneFolder, "Stone", center + Vector3.new(40, 2, 5))
	createResourceNode(zoneFolder, "Wood", center + Vector3.new(-45, 2, 25))

	createMissionBoard(zoneFolder, center + Vector3.new(-10, 6, 40), "❄️ Orilla helada", {
		"Recolectá cristales y piedras heladas.",
		"Fabricá el Piolet de hielo (🔨 Craft).",
		"Cruzá el puente glacial con cuidado.",
	})

	createFinish(zoneFolder, center + Vector3.new(68, 3, 0))

	local bridgeStart = center + Vector3.new(78, 4, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND2.IceMaze + Vector3.new(-70, 4, -50)
	createWalkBridge(zoneFolder, "IceMaze", bridgeStart, bridgeEnd, 5)
end

local function buildIceMazeZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(180, 0, 150))
	createSpawn(zoneFolder, center + Vector3.new(-70, 0, -50))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-72, 6, -62), "🧊 Laberinto de hielo", {
		"Entrá por el arco oeste.",
		"Seguí las señales 1 → 3 (pulsa E).",
		"¡El suelo resbala! Caminá con cuidado.",
		"Salí por el portal verde al este.",
	})

	local _, signSpots, _, mazeFinishPos = PropGenerator.iceMazeWalls(deco, center, center.Y + 0.25)

	for _, spot in signSpots do
		local signModel = PropGenerator.signPost(deco, spot.position, spot.number, "❄ " .. spot.number)
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

	createResourceNode(zoneFolder, "Crystal", center + Vector3.new(-20, 3, 40))
	createResourceNode(zoneFolder, "Vine", center + Vector3.new(30, 3, -30))

	local finishPos = mazeFinishPos or (center + Vector3.new(70, 3, 30))
	createFinish(zoneFolder, finishPos)

	createGate(zoneFolder, challenge.id, center + Vector3.new(-75, 6, -50), Vector3.new(14, 12, 3))

	local bridgeStart = finishPos + Vector3.new(12, 1, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND2.FrozenEscape + Vector3.new(-75, 4, -20)
	createWalkBridge(zoneFolder, "FrozenEscape", bridgeStart, bridgeEnd, 5)
end

local function buildFrozenEscapeZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(200, 0, 220))
	createSpawn(zoneFolder, center + Vector3.new(-75, 0, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-72, 6, -10), "🏔️ Escape del glaciar", {
		"¡Un yeti te persigue!",
		"Corré hasta la zona VERDE segura.",
		"Fabricá el Bote de hielo antes de entrar.",
	})

	for i = 1, 8 do
		makePart({
			name = "IceSpire",
			size = Vector3.new(4, 8 + (i % 4) * 2, 4),
			position = center + Vector3.new(-60 + i * 18, 4, math.sin(i) * 30),
			color = Color3.fromRGB(160, 210, 250),
			material = Enum.Material.Ice,
			parent = deco,
		})
	end

	PropGenerator.dirtPath(deco, center + Vector3.new(-70, 0.5, 0), center + Vector3.new(100, 0.5, 0), 10, 801)

	makePart({
		name = "ChaseGuard",
		size = Vector3.new(6, 8, 6),
		position = center + Vector3.new(-55, 5, 15),
		color = Color3.fromRGB(80, 120, 180),
		material = Enum.Material.Ice,
		parent = zoneFolder,
	})

	makePart({
		name = "SafeZone",
		size = Vector3.new(30, 2, 30),
		position = center + Vector3.new(95, 1, 0),
		color = Color3.fromRGB(0, 255, 120),
		material = Enum.Material.Neon,
		parent = zoneFolder,
		transparency = 0.5,
		canCollide = false,
	})

	createGate(zoneFolder, challenge.id, center + Vector3.new(-78, 6, 0), Vector3.new(14, 12, 3))
	createFinish(zoneFolder, center + Vector3.new(110, 4, 0))

	makePart({
		name = "EscapeBoatHull",
		size = Vector3.new(14, 4, 22),
		position = center + Vector3.new(105, 3, 30),
		color = Color3.fromRGB(180, 220, 255),
		material = Enum.Material.Ice,
		parent = deco,
	})
end

-- ─── ZONAS ISLA 3 (desierto) ───────────────────────────────────

local function buildDesertOasisZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(150, 0, 130))
	createSpawn(zoneFolder, center)
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	makePart({
		name = "OasisPool",
		size = Vector3.new(40, 3, 30),
		position = center + Vector3.new(-10, 0, 10),
		color = Color3.fromRGB(40, 120, 180),
		material = Enum.Material.Glass,
		parent = zoneFolder,
		transparency = 0.35,
	})

	makePart({
		name = "SandRing",
		size = Vector3.new(160, 3, 100),
		position = center + Vector3.new(0, 0, -20),
		color = Color3.fromRGB(220, 190, 130),
		material = Enum.Material.Sand,
		parent = zoneFolder,
	})

	for i = 1, 6 do
		local cactusPos = center + Vector3.new(-55 + i * 18, 0, 25 + (i % 3) * 12)
		makePart({
			name = "Cactus_" .. i,
			size = Vector3.new(2, 5 + (i % 3), 2),
			position = cactusPos + Vector3.new(0, 2.5, 0),
			color = Color3.fromRGB(50, 120, 60),
			material = Enum.Material.Grass,
			parent = deco,
		})
	end

	PropGenerator.scatterRocks(deco, center, 60, 10, "sand", 901)
	PropGenerator.scatterPalms(deco, center + Vector3.new(0, 0, 15), 35, 4, 902)

	createResourceNode(zoneFolder, "Ember", center + Vector3.new(-20, 2, 15))
	createResourceNode(zoneFolder, "Ember", center + Vector3.new(30, 2, 8))
	createResourceNode(zoneFolder, "Shell", center + Vector3.new(-35, 2, 30))
	createResourceNode(zoneFolder, "Shell", center + Vector3.new(15, 2, 35))
	createResourceNode(zoneFolder, "Stone", center + Vector3.new(40, 2, 20))
	createResourceNode(zoneFolder, "Ore", center + Vector3.new(-40, 2, 5))

	createMissionBoard(zoneFolder, center + Vector3.new(-5, 6, 42), "🏜️ Oasis del desierto", {
		"Recolectá brasas y conchas del oasis.",
		"Fabricá la Llave del templo (🔨 Craft).",
		"Cruzá el puente de piedra hacia las ruinas.",
	})

	createFinish(zoneFolder, center + Vector3.new(68, 3, 0))

	local bridgeStart = center + Vector3.new(78, 4, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND3.SandTemple + Vector3.new(-70, 4, -45)
	createWalkBridge(zoneFolder, "SandTemple", bridgeStart, bridgeEnd, 5)
end

local function buildSandTempleZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(160, 0, 150))
	createSpawn(zoneFolder, center + Vector3.new(-70, 0, -45))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-72, 6, -58), "🏛️ Templo enterrado", {
		"Necesitás la Llave del templo para entrar.",
		"Activá los 3 ídolos en orden: 1 → 3 → 2",
		"Las ruinas se abrirán al resolver el enigma.",
	})

	-- Pirámide parcial enterrada
	makePart({
		name = "PyramidBase",
		size = Vector3.new(80, 20, 80),
		position = center + Vector3.new(0, 8, 0),
		color = Color3.fromRGB(200, 170, 110),
		material = Enum.Material.Sand,
		parent = deco,
	})
	makePart({
		name = "PyramidTop",
		size = Vector3.new(50, 15, 50),
		position = center + Vector3.new(0, 22, 0),
		color = Color3.fromRGB(210, 180, 120),
		material = Enum.Material.Sand,
		parent = deco,
	})

	PropGenerator.scatterRocks(deco, center, 70, 12, "sand", 911)

	local PuzzleManager = require(script.Parent.Parent.Challenges.PuzzleManager)
	for i = 1, 3 do
		local relicPos = center + Vector3.new((i - 2) * 18, 0, 20)
		PropGenerator.statue(zoneFolder, relicPos, i)
		local statue = zoneFolder:FindFirstChild("Statue_" .. i)
		if statue then
			local base = statue:FindFirstChild("Base")
			if base then
				base.Color = Color3.fromRGB(180, 140, 80)
				base.Material = Enum.Material.Sandstone
				local prompt = Instance.new("ProximityPrompt")
				prompt.ActionText = "Activar"
				prompt.ObjectText = "Ídolo " .. i
				prompt.Parent = base
				local idx = i
				prompt.Triggered:Connect(function(player)
					PuzzleManager.onStatueActivated(player, idx, "SandTemple")
				end)
			end
		end
	end

	createGate(zoneFolder, challenge.id, center + Vector3.new(-72, 6, -45), Vector3.new(14, 12, 3))
	createResourceNode(zoneFolder, "Ore", center + Vector3.new(35, 3, -15))
	createResourceNode(zoneFolder, "Crystal", center + Vector3.new(-25, 3, 10))

	local bridgeStart = center + Vector3.new(55, 4, 0)
	local bridgeEnd = ZONE_LAYOUT_ISLAND3.DuneEscape + Vector3.new(-42, 12, 0)
	createWalkBridge(zoneFolder, "DuneEscape", bridgeStart, bridgeEnd, 5)
end

local function buildDuneEscapeZone(zoneFolder: Folder, center: Vector3, challenge)
	createZoneFloor(zoneFolder, center, Vector3.new(110, 0, 270))
	createSpawn(zoneFolder, center + Vector3.new(-40, 12, 0))
	createZoneBounds(zoneFolder, challenge, center)
	local deco = PropGenerator.decoFolder(zoneFolder)

	createMissionBoard(zoneFolder, center + Vector3.new(-38, 18, -15), "🌪️ Escape de las dunas", {
		"Fabricá el Planeador de arena antes de entrar.",
		"Esquivá los proyectiles de la tormenta.",
		"Llegá al portal verde al final del cañón.",
	})

	for i = 0, 12 do
		local dunePos = center + Vector3.new(math.sin(i * 0.8) * 15, 2 + (i % 4), i * 18)
		makePart({
			name = "Dune_" .. i,
			size = Vector3.new(18 + (i % 3) * 4, 4 + (i % 2) * 2, 14),
			position = dunePos,
			color = Color3.fromRGB(210, 175, 120),
			material = Enum.Material.Sand,
			parent = deco,
		})
	end

	PropGenerator.dirtPath(deco, center + Vector3.new(-35, 0.5, 0), center + Vector3.new(0, 0.5, 120), 8, 921)

	createGate(zoneFolder, challenge.id, center + Vector3.new(-44, 14, 0), Vector3.new(12, 10, 3))
	createFinish(zoneFolder, center + Vector3.new(0, 10, 125))

	makePart({
		name = "EscapeGlider",
		size = Vector3.new(12, 2, 8),
		position = center + Vector3.new(5, 12, 130),
		color = Color3.fromRGB(160, 120, 70),
		material = Enum.Material.Fabric,
		parent = deco,
	})
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
	FrozenShore = buildFrozenShoreZone,
	IceMaze = buildIceMazeZone,
	FrozenEscape = buildFrozenEscapeZone,
	DesertOasis = buildDesertOasisZone,
	SandTemple = buildSandTempleZone,
	DuneEscape = buildDuneEscapeZone,
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

local function buildIsland2Base(islandFolder: Folder, offset: Vector3)
	makePart({
		name = "IslandBase",
		size = Vector3.new(700, 20, 700),
		position = offset + Vector3.new(300, -6, 0),
		color = Color3.fromRGB(200, 220, 240),
		material = Enum.Material.Snow,
		parent = islandFolder,
	})

	makePart({
		name = "FrozenLake",
		size = Vector3.new(120, 4, 80),
		position = offset + Vector3.new(150, -2, -80),
		color = Color3.fromRGB(100, 160, 220),
		material = Enum.Material.Ice,
		parent = islandFolder,
		transparency = 0.2,
	})

	PropGenerator.island2Landscape(islandFolder, offset, ZONE_LAYOUT_ISLAND2)
end

local function buildIsland3Base(islandFolder: Folder, offset: Vector3)
	makePart({
		name = "IslandBase",
		size = Vector3.new(700, 18, 700),
		position = offset + Vector3.new(300, -5, 0),
		color = Color3.fromRGB(210, 175, 115),
		material = Enum.Material.Sand,
		parent = islandFolder,
	})

	makePart({
		name = "DuneField",
		size = Vector3.new(200, 8, 200),
		position = offset + Vector3.new(450, 2, -100),
		color = Color3.fromRGB(225, 190, 130),
		material = Enum.Material.Sand,
		parent = islandFolder,
	})

	PropGenerator.island3Landscape(islandFolder, offset, ZONE_LAYOUT_ISLAND3)
end

local function buildIsland(islandId: string, offset: Vector3)
	local islandFolder = Instance.new("Folder")
	islandFolder.Name = islandId

	if islandId == "Island1_Tropical" then
		buildIsland1Base(islandFolder, offset)
	elseif islandId == "Island2_Frozen" then
		buildIsland2Base(islandFolder, offset)
	elseif islandId == "Island3_Desert" then
		buildIsland3Base(islandFolder, offset)
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

	local zoneLayout = ZONE_LAYOUT_ISLAND1
	if islandId == "Island2_Frozen" then
		zoneLayout = ZONE_LAYOUT_ISLAND2
	elseif islandId == "Island3_Desert" then
		zoneLayout = ZONE_LAYOUT_ISLAND3
	end

	local challenges = GameConfig.getChallengesForIsland(islandId)
	for _, challenge in challenges do
		local layout = zoneLayout[challenge.id]
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
		-- Zonas con bridge propio registran su entrada en el puente, no aquí
		local bridgeEntryZones = {
			JungleMaze = true, RiverCross = true,
			IceMaze = true, SandTemple = true,
			ChaseEscape = true, DodgeGauntlet = true,
			VolcanoClimb = true, VolcanoInterior = true,
		}
		if not bridgeEntryZones[challenge.id] then
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
	island2.Parent = map

	local island3 = buildIsland("Island3_Desert", ISLAND3_OFFSET)
	island3.Parent = map

	map.Parent = Workspace
	return map
end

return MapBuilder
