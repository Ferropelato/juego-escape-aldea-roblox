--[[
	Pasos del tutorial guiado (primeros minutos).
]]

local OnboardingConfig = {}

OnboardingConfig.Steps = {
	{
		id = "welcome",
		title = "🏝️ Bienvenido",
		text = "Usá WASD para moverte por la isla",
		icon = "👟",
	},
	{
		id = "collect",
		title = "Recolectar",
		text = "Acercate a objetos brillantes y pulsa E",
		icon = "✨",
	},
	{
		id = "objectives",
		title = "Objetivos",
		text = "Seguí la lista de objetivos en el panel izquierdo",
		icon = "📋",
	},
	{
		id = "craft",
		title = "Fabricar",
		text = "Cuando tengas materiales, tocá 🔨 Craft",
		icon = "🔨",
	},
	{
		id = "advance",
		title = "Avanzar",
		text = "Completá objetivos y llegá al portal verde",
		icon = "🟢",
	},
}

return OnboardingConfig
