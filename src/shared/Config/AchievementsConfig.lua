--[[
	Logros del juego — desbloqueos por hitos de progresión.
]]

local AchievementsConfig = {}

AchievementsConfig.List = {
	FirstResource = {
		id = "FirstResource",
		displayName = "Primer botín",
		description = "Recolectá tu primer recurso",
		icon = "🎒",
		order = 1,
	},
	FirstCraft = {
		id = "FirstCraft",
		displayName = "Artesano novato",
		description = "Fabricá tu primer objeto",
		icon = "🔨",
		order = 2,
	},
	BeachHero = {
		id = "BeachHero",
		displayName = "Héroe de la playa",
		description = "Completá la llegada en balsa",
		icon = "🏖️",
		order = 3,
	},
	JungleExplorer = {
		id = "JungleExplorer",
		displayName = "Explorador de selva",
		description = "Salí del laberinto de selva",
		icon = "🌿",
		order = 4,
	},
	IslandEscape = {
		id = "IslandEscape",
		displayName = "¡Libre al fin!",
		description = "Escapá de la Isla del Volcán",
		icon = "⛵",
		order = 5,
	},
	FrozenArrival = {
		id = "FrozenArrival",
		displayName = "Pies helados",
		description = "Llegá a la Isla Helada",
		icon = "❄️",
		order = 6,
	},
	IceMazeMaster = {
		id = "IceMazeMaster",
		displayName = "Maestro del hielo",
		description = "Completá el laberinto de hielo",
		icon = "🧊",
		order = 7,
	},
	GlacierEscape = {
		id = "GlacierEscape",
		displayName = "Glaciar vencido",
		description = "Escapá del glaciar",
		icon = "🏔️",
		order = 8,
	},
	Collector = {
		id = "Collector",
		displayName = "Coleccionista",
		description = "Tené 5 tipos de recursos distintos",
		icon = "💎",
		order = 9,
	},
	Survivor = {
		id = "Survivor",
		displayName = "Superviviente",
		description = "Completá 6 zonas sin morir en la sesión",
		icon = "🛡️",
		order = 10,
	},
}

function AchievementsConfig.get(id: string)
	return AchievementsConfig.List[id]
end

function AchievementsConfig.getAllSorted(): { any }
	local list = {}
	for _, ach in AchievementsConfig.List do
		table.insert(list, ach)
	end
	table.sort(list, function(a, b)
		return a.order < b.order
	end)
	return list
end

return AchievementsConfig
