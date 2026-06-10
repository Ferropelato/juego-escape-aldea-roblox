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
		ingredients = { Wood = 8, Vine = 4, Stone = 3 },
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
		ingredients = { Ore = 5, Crystal = 3, Ember = 2 },
		unlocksChallenge = "VolcanoClimb",
	},
	EscapeBoat = {
		displayName = "Bote de escape",
		description = "Huye de la isla para siempre",
		ingredients = { Wood = 15, Vine = 8, Ore = 5, Crystal = 5 },
		unlocksChallenge = "FinalEscape",
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
		description = "Llegás a la isla congelada",
		difficulty = 1,
		checkpointId = "CP_FrozenShore",
		requiredChallenge = nil,
		requiredCraft = nil,
		zoneSize = Vector3.new(120, 30, 120),
	},
	IceMaze = {
		id = "IceMaze",
		island = "Island2_Frozen",
		order = 2,
		displayName = "Laberinto de hielo",
		description = "Resbalás y tenés que pensar cada paso",
		difficulty = 4,
		checkpointId = "CP_IceMaze",
		requiredChallenge = "FrozenShore",
		requiredCraft = nil,
		zoneSize = Vector3.new(180, 40, 180),
		puzzleType = "Maze",
	},
	FrozenEscape = {
		id = "FrozenEscape",
		island = "Island2_Frozen",
		order = 3,
		displayName = "Escape del glaciar",
		description = "Escapá antes de que el hielo se rompa",
		difficulty = 8,
		checkpointId = "CP_FrozenFinal",
		requiredChallenge = "IceMaze",
		requiredCraft = nil,
		zoneSize = Vector3.new(150, 60, 150),
		puzzleType = "Chase",
		completesIsland = true,
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
