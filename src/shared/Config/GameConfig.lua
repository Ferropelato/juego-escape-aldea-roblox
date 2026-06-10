--[[
	Configuración central del juego Escape Island.
	Editá aquí desafíos, recursos, islas y dificultad.
]]

local GameConfig = {}

GameConfig.GAME_NAME = "Escape Island"
GameConfig.AUTO_SAVE_INTERVAL = 45
GameConfig.RAFT_SPAWN_OFFSET = Vector3.new(0, 3, -80)

-- Recursos que el jugador puede recolectar
GameConfig.Resources = {
	Wood = { displayName = "Madera", icon = "🪵", maxStack = 99 },
	Stone = { displayName = "Piedra", icon = "🪨", maxStack = 99 },
	Vine = { displayName = "Liana", icon = "🌿", maxStack = 50 },
	Shell = { displayName = "Concha", icon = "🐚", maxStack = 30 },
	Ore = { displayName = "Mineral", icon = "⛏️", maxStack = 40 },
	Crystal = { displayName = "Cristal", icon = "💎", maxStack = 20 },
	Ember = { displayName = "Brasa", icon = "🔥", maxStack = 15 },
}

-- Recetas de crafteo (desbloquean desafíos)
GameConfig.CraftingRecipes = {
	Torch = {
		displayName = "Antorcha",
		description = "Ilumina cuevas oscuras",
		ingredients = { Wood = 2, Ember = 1 },
		unlocksChallenge = "CaveSystem",
	},
	Raft = {
		displayName = "Balsa pequeña",
		description = "Cruza el río caudaloso",
		ingredients = { Wood = 5, Vine = 3 },
		unlocksChallenge = "RiverCross",
	},
	BridgeKit = {
		displayName = "Kit de puente",
		description = "Arma un puente provisional",
		ingredients = { Wood = 7, Vine = 3, Stone = 3 },
		unlocksChallenge = "StoneJump",
	},
	DivingMask = {
		displayName = "Máscara de buceo",
		description = "Respira bajo la laguna",
		ingredients = { Shell = 4, Vine = 2 },
		unlocksChallenge = "LagoonDive",
	},
	CastleKey = {
		displayName = "Llave antigua",
		description = "Abre las puertas de las ruinas",
		ingredients = { Ore = 3, Crystal = 2, Stone = 2 },
		unlocksChallenge = "CastleRuins",
	},
	HeatShield = {
		displayName = "Escudo térmico",
		description = "Resiste el calor del volcán",
		ingredients = { Ore = 4, Crystal = 3, Ember = 2 },
		unlocksChallenge = "VolcanoClimb",
	},
	EscapeBoat = {
		displayName = "Bote de escape",
		description = "Huye de la isla para siempre",
		ingredients = { Wood = 12, Vine = 7, Ore = 5, Crystal = 4 },
		unlocksChallenge = "FinalEscape",
	},
	IcePick = {
		displayName = "Piolet de hielo",
		description = "Rompe el hielo del laberinto",
		ingredients = { Stone = 4, Crystal = 2 },
		unlocksChallenge = "IceMaze",
	},
	IceBoat = {
		displayName = "Bote de hielo",
		description = "Cruza el glaciar en ruptura",
		ingredients = { Wood = 8, Crystal = 4, Vine = 4 },
		unlocksChallenge = "FrozenEscape",
	},
	DesertKey = {
		displayName = "Llave del templo",
		description = "Abre las puertas de las ruinas enterradas",
		ingredients = { Ore = 3, Stone = 4, Shell = 3 },
		unlocksChallenge = "SandTemple",
	},
	SandGlider = {
		displayName = "Planeador de arena",
		description = "Surfea las dunas hasta la salida",
		ingredients = { Wood = 6, Vine = 4, Ember = 3 },
		unlocksChallenge = "DuneEscape",
	},
}

-- Islas del juego (se desbloquean al completar la anterior)
GameConfig.Islands = {
	Island1_Tropical = {
		id = "Island1_Tropical",
		displayName = "Isla del Volcán",
		description = "Selva, ríos, cuevas y un volcán activo",
		order = 1,
		spawnZone = "BeachLanding",
		requiredIsland = nil,
	},
	Island2_Frozen = {
		id = "Island2_Frozen",
		displayName = "Isla Helada",
		description = "Glaciares, cuevas de hielo y tormentas",
		order = 2,
		spawnZone = "FrozenShore",
		requiredIsland = "Island1_Tropical",
	},
	Island3_Desert = {
		id = "Island3_Desert",
		displayName = "Isla del Desierto",
		description = "Ruinas enterradas y dunas infinitas",
		order = 3,
		spawnZone = "DesertOasis",
		requiredIsland = "Island2_Frozen",
	},
}

-- Desafíos por isla (orden = progresión + dificultad creciente)
GameConfig.Challenges = {
	-- ISLA 1 - TROPICAL
	BeachLanding = {
		id = "BeachLanding",
		island = "Island1_Tropical",
		order = 1,
		displayName = "Llegada en balsa",
		description = "Recolectá materiales y llegá al portal verde para entrar a la selva",
		difficulty = 1,
		checkpointId = "CP_Beach",
		requiredChallenge = nil,
		requiredCraft = nil,
		zoneSize = Vector3.new(120, 30, 120),
		objectives = {
			{ type = "collect", resource = "Wood", amount = 3, text = "Recolectar madera (suelo o copas)" },
			{ type = "collect", resource = "Vine", amount = 2, text = "Recolectar lianas" },
			{ type = "reach", text = "Cruzar el puente a la selva (sin caer)" },
		},
	},
	JungleMaze = {
		id = "JungleMaze",
		island = "Island1_Tropical",
		order = 2,
		displayName = "Laberinto de selva",
		description = "Encontrá la salida del laberinto, seguí las señales 1→5 y juntá lianas",
		difficulty = 2,
		checkpointId = "CP_Jungle",
		requiredChallenge = "BeachLanding",
		requiredCraft = nil,
		zoneSize = Vector3.new(150, 30, 150),
		puzzleType = "Maze",
		objectives = {
			{ type = "signs", amount = 5, text = "Encontrar señales en orden (1 → 5)" },
			{ type = "collect", resource = "Vine", amount = 2, text = "Recolectar lianas" },
			{ type = "reach", text = "Encontrar la salida verde (este)" },
		},
	},
	RiverCross = {
		id = "RiverCross",
		island = "Island1_Tropical",
		order = 3,
		displayName = "Cruce del río",
		description = "Craftea una balsa para cruzar el río turbulento",
		difficulty = 3,
		checkpointId = "CP_River",
		requiredChallenge = "JungleMaze",
		requiredCraft = "Raft",
		zoneSize = Vector3.new(150, 40, 80),
		puzzleType = "CraftGate",
	},
	StoneJump = {
		id = "StoneJump",
		island = "Island1_Tropical",
		order = 4,
		displayName = "Salto entre piedras",
		description = "Parkour sobre rocas flotantes sin caer al agua",
		difficulty = 4,
		checkpointId = "CP_Stones",
		requiredChallenge = "RiverCross",
		requiredCraft = "BridgeKit",
		zoneSize = Vector3.new(100, 60, 200),
		puzzleType = "Parkour",
	},
	LagoonDive = {
		id = "LagoonDive",
		island = "Island1_Tropical",
		order = 5,
		displayName = "Laguna submarina",
		description = "Sumergite y resuelve el enigma de las conchas",
		difficulty = 5,
		checkpointId = "CP_Lagoon",
		requiredChallenge = "StoneJump",
		requiredCraft = "DivingMask",
		zoneSize = Vector3.new(120, 80, 120),
		puzzleType = "UnderwaterPuzzle",
	},
	CaveSystem = {
		id = "CaveSystem",
		island = "Island1_Tropical",
		order = 6,
		displayName = "Cuevas oscuras",
		description = "Atravesá las cuevas con antorcha y encontrá el cristal",
		difficulty = 6,
		checkpointId = "CP_Caves",
		requiredChallenge = "LagoonDive",
		requiredCraft = "Torch",
		zoneSize = Vector3.new(180, 60, 180),
		puzzleType = "DarkMaze",
	},
	CastleRuins = {
		id = "CastleRuins",
		island = "Island1_Tropical",
		order = 7,
		displayName = "Ruinas del castillo",
		description = "Resuelve el enigma de las estatuas para abrir la puerta",
		difficulty = 7,
		checkpointId = "CP_Castle",
		requiredChallenge = "CaveSystem",
		requiredCraft = "CastleKey",
		zoneSize = Vector3.new(140, 80, 140),
		puzzleType = "StatuePuzzle",
	},
	ChaseEscape = {
		id = "ChaseEscape",
		island = "Island1_Tropical",
		order = 8,
		displayName = "Persecución en la selva",
		description = "Escapá del guardián de la isla hasta la zona segura",
		difficulty = 8,
		checkpointId = "CP_Chase",
		requiredChallenge = "CastleRuins",
		requiredCraft = nil,
		zoneSize = Vector3.new(140, 30, 220),
		puzzleType = "Chase",
	},
	DodgeGauntlet = {
		id = "DodgeGauntlet",
		island = "Island1_Tropical",
		order = 9,
		displayName = "Campo de obstáculos",
		description = "Esquivá rocas y proyectiles volcánicos",
		difficulty = 9,
		checkpointId = "CP_Dodge",
		requiredChallenge = "ChaseEscape",
		requiredCraft = nil,
		zoneSize = Vector3.new(80, 40, 250),
		puzzleType = "Dodge",
	},
	VolcanoClimb = {
		id = "VolcanoClimb",
		island = "Island1_Tropical",
		order = 10,
		displayName = "Ascenso al volcán",
		description = "Trepa la montaña evitando la lava con escudo térmico",
		difficulty = 10,
		checkpointId = "CP_Volcano",
		requiredChallenge = "DodgeGauntlet",
		requiredCraft = "HeatShield",
		zoneSize = Vector3.new(100, 200, 100),
		puzzleType = "Climb",
	},
	VolcanoInterior = {
		id = "VolcanoInterior",
		island = "Island1_Tropical",
		order = 11,
		displayName = "Interior del volcán",
		description = "Navega el laberinto de lava y encontrá la salida",
		difficulty = 11,
		checkpointId = "CP_VolcanoIn",
		requiredChallenge = "VolcanoClimb",
		requiredCraft = "HeatShield",
		zoneSize = Vector3.new(120, 80, 120),
		puzzleType = "LavaMaze",
	},
	FinalEscape = {
		id = "FinalEscape",
		island = "Island1_Tropical",
		order = 12,
		displayName = "¡Escape final!",
		description = "Construí el bote y huye de la isla",
		difficulty = 12,
		checkpointId = "CP_Final",
		requiredChallenge = "VolcanoInterior",
		requiredCraft = "EscapeBoat",
		zoneSize = Vector3.new(100, 30, 100),
		puzzleType = "Final",
		completesIsland = true,
	},

	-- ISLA 2 - HELADA (misma estructura, distinto tema)
	FrozenShore = {
		id = "FrozenShore",
		island = "Island2_Frozen",
		order = 1,
		displayName = "Orilla helada",
		description = "Recolectá cristales de hielo y cruzá el puente glacial",
		difficulty = 1,
		checkpointId = "CP_FrozenShore",
		requiredChallenge = nil,
		requiredCraft = nil,
		zoneSize = Vector3.new(140, 30, 140),
		objectives = {
			{ type = "collect", resource = "Crystal", amount = 2, text = "Recolectar cristales de hielo" },
			{ type = "collect", resource = "Stone", amount = 2, text = "Recolectar piedras heladas" },
			{ type = "reach", text = "Cruzar el puente al laberinto" },
		},
	},
	IceMaze = {
		id = "IceMaze",
		island = "Island2_Frozen",
		order = 2,
		displayName = "Laberinto de hielo",
		description = "Seguí las señales heladas y no te resbales",
		difficulty = 4,
		checkpointId = "CP_IceMaze",
		requiredChallenge = "FrozenShore",
		requiredCraft = "IcePick",
		zoneSize = Vector3.new(160, 40, 140),
		puzzleType = "Maze",
		objectives = {
			{ type = "signs", amount = 3, text = "Encontrar señales en orden (1 → 3)" },
			{ type = "reach", text = "Salir del laberinto (portal verde)" },
		},
	},
	FrozenEscape = {
		id = "FrozenEscape",
		island = "Island2_Frozen",
		order = 3,
		displayName = "Escape del glaciar",
		description = "Escapá del yeti hasta la zona segura",
		difficulty = 8,
		checkpointId = "CP_FrozenFinal",
		requiredChallenge = "IceMaze",
		requiredCraft = "IceBoat",
		zoneSize = Vector3.new(180, 50, 200),
		puzzleType = "Chase",
		completesIsland = true,
	},

	-- ISLA 3 - DESIERTO
	DesertOasis = {
		id = "DesertOasis",
		island = "Island3_Desert",
		order = 1,
		displayName = "Oasis del desierto",
		description = "Encontrá agua y recursos en medio de las dunas",
		difficulty = 1,
		checkpointId = "CP_DesertOasis",
		requiredChallenge = nil,
		requiredCraft = nil,
		zoneSize = Vector3.new(140, 30, 140),
		objectives = {
			{ type = "collect", resource = "Ember", amount = 2, text = "Recolectar brasas del oasis" },
			{ type = "collect", resource = "Shell", amount = 2, text = "Recolectar conchas antiguas" },
			{ type = "reach", text = "Cruzar el puente de piedra al templo" },
		},
	},
	SandTemple = {
		id = "SandTemple",
		island = "Island3_Desert",
		order = 2,
		displayName = "Templo enterrado",
		description = "Activá los ídolos antiguos en el orden correcto",
		difficulty = 5,
		checkpointId = "CP_SandTemple",
		requiredChallenge = "DesertOasis",
		requiredCraft = "DesertKey",
		zoneSize = Vector3.new(150, 50, 150),
		puzzleType = "RelicPuzzle",
	},
	DuneEscape = {
		id = "DuneEscape",
		island = "Island3_Desert",
		order = 3,
		displayName = "Escape de las dunas",
		description = "Esquivá la tormenta de arena hasta el portal final",
		difficulty = 9,
		checkpointId = "CP_DesertFinal",
		requiredChallenge = "SandTemple",
		requiredCraft = "SandGlider",
		zoneSize = Vector3.new(100, 50, 260),
		puzzleType = "Dodge",
		completesIsland = true,
	},
}

-- Recompensas al completar cada zona (no pay-to-win, refuerzan progresión)
GameConfig.ZoneRewards = {
	BeachLanding = { Wood = 2 },
	JungleMaze = { Vine = 2, Shell = 1 },
	RiverCross = { Wood = 2 },
	StoneJump = { Stone = 2 },
	LagoonDive = { Crystal = 1 },
	CaveSystem = { Ore = 2, Ember = 1 },
	CastleRuins = { Ore = 2, Crystal = 1 },
	ChaseEscape = { Vine = 2 },
	DodgeGauntlet = { Ember = 1 },
	VolcanoClimb = { Crystal = 2 },
	VolcanoInterior = { Ore = 2 },
	FinalEscape = { Wood = 3, Crystal = 2 },
	FrozenShore = { Crystal = 2 },
	IceMaze = { Stone = 2 },
	FrozenEscape = { Crystal = 3, Vine = 2 },
	DesertOasis = { Shell = 2, Ember = 1 },
	SandTemple = { Ore = 2, Stone = 2 },
	DuneEscape = { Ember = 2, Crystal = 2 },
}

-- Recompensa diaria (retención, 1 vez cada 24h)
GameConfig.DailyReward = {
	cooldown = 86400,
	rewards = {
		{ Wood = 4, Vine = 2 },
		{ Stone = 3, Shell = 2 },
		{ Crystal = 1, Ore = 2 },
		{ Ember = 2, Wood = 2 },
	},
}

-- Dificultad escalada por orden (multiplicadores)
GameConfig.DifficultyScaling = {
	damageMultiplier = function(order: number): number
		return 1 + (order - 1) * 0.15
	end,
	chaseSpeed = function(order: number): number
		return 14 + order * 1.2
	end,
	dodgeInterval = function(order: number): number
		return math.max(0.8, 2.5 - order * 0.12)
	end,
}

function GameConfig.getChallengesForIsland(islandId: string): { any }
	local list = {}
	for _, challenge in GameConfig.Challenges do
		if challenge.island == islandId then
			table.insert(list, challenge)
		end
	end
	table.sort(list, function(a, b)
		return a.order < b.order
	end)
	return list
end

function GameConfig.getChallenge(challengeId: string)
	return GameConfig.Challenges[challengeId]
end

function GameConfig.getIsland(islandId: string)
	return GameConfig.Islands[islandId]
end

return GameConfig
